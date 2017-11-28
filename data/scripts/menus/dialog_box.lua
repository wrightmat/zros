local dialog_box = {
  -- Dialog box properties.
  dialog = nil,                -- Dialog being displayed or nil.
  first = true,                -- Whether this is the first dialog of a sequence.
  style = nil,                 -- "default", "wood", "stone" or "empty".
  name = nil,                  -- Name to display above the dialog box (for example, of an NPC)
  vertical_position = "auto",  -- "auto", "top" or "bottom".
  skip_mode = nil,             -- "none", "current", "all" or "unchanged".
  icon_index = nil,            -- Index of the 16x16 icon in hud/dialog_icons.png or nil.
  info = nil,                  -- Parameter passed to start_dialog().
  skipped = false,             -- Whether the player skipped the dialog.
  selected_answer = nil,       -- Selected answer (1 or 2) or nil if there is no question.
  game = nil,

  -- Displaying text gradually.
  next_line = nil,             -- Next line to display or nil.
  line_it = nil,               -- Iterator over of all lines of the dialog.
  lines = {},                  -- Array of the text of the 3 visible lines.
  line_surfaces = {},          -- Array of the 3 text surfaces.
  text_properties = {},        -- Array of properties to create the text surfaces.
  line_index = nil,            -- Line currently being shown.
  char_index = nil,            -- Next character to show in the current line.
  char_delay = nil,            -- Delay between two characters in milliseconds.
  full = false,                -- Whether the 3 visible lines have shown all content.
  need_letter_sound = false,   -- Whether a sound should be played with the next character.
  gradual = true,              -- Whether text is displayed gradually.

  -- Graphics.
  dialog_surface = nil,
  box_img = nil,
  icons_img = nil,
  end_lines_sprite = nil,
  box_dst_position = nil,      -- Destination coordinates of the dialog box.
  question_dst_position = nil, -- Destination coordinates of the question icon.
  icon_dst_position = nil,     -- Destination coordinates of the icon.
}

-- Constants.
local nb_visible_lines = 3     -- Maximum number of lines in the dialog box.
local char_delays = {
  slow = 60,
  medium = 40,
  fast = 20  -- Default.
}
local letter_sound_delay = 100
local box_width = 220
local box_height = 60

local game_meta = sol.main.get_metatable("game")

game_meta:register_event("on_started", function(game)
  game.dialog_box = dialog_box
  dialog_box.game = game
  -- Initialize dialog box data.
  dialog_box.line_surfaces.default = {}
  dialog_box.current_line_surface = dialog_box.line_surfaces.default
  -- Text properties used to initialize surfaces.
  local font, font_size = sol.language.get_dialog_font()
  dialog_box.text_properties = { 
    horizontal_alignment = "left",
    vertical_alignment = "top",
    font = font,
    font_size = font_size,
    rendering_mode = "solid"
  }
  for i = 1, nb_visible_lines do
    dialog_box.lines[i] = ""
    dialog_box.line_surfaces.default[i] = sol.text_surface.create(dialog_box.text_properties)
  end
  
  dialog_box.dialog_surface = sol.surface.create(sol.video.get_quest_size())
  dialog_box.icons_img = sol.surface.create("hud/dialog_icons.png")
  dialog_box.end_lines_sprite = sol.sprite.create("hud/dialog_box_message_end")
  dialog_box.game:set_dialog_style("default")
end)

-- Exits the dialog box system.
game_meta:register_event("quit_dialog_box", function(game)
  if dialog_box ~= nil then
    if game:is_dialog_enabled() then sol.menu.stop(dialog_box) end
    game.dialog_box = nil
  end
end)

-- Called by the engine when a dialog starts.
game_meta:register_event("on_dialog_started", function(game, dialog, info)
  dialog_box.dialog = dialog
  dialog_box.info = info
  dialog_box:set_color({255,255,255}) -- Reset color text to white.
  sol.menu.start(dialog_box.game, dialog_box)
end)

-- Called by the engine when a dialog finishes.
game_meta:register_event("on_dialog_finished", function(game, dialog)
  sol.menu.stop(dialog_box)
  dialog_box.dialog = nil
  dialog_box.info = nil
  -- Delete the new surfaces and restore the default one.
  for k, _ in pairs(dialog_box.line_surfaces) do
    if k ~= "default" then dialog_box.line_surfaces[k] = nil end
  end
  dialog_box.current_line_surface = dialog_box.line_surfaces.default
end)

-- Sets the style of the dialog box for subsequent dialogs. Style must be one of:
-- - "default" (default): Usual dialog box.
-- - "wood": Wooden design (for example, signs).
-- - "stone": Stone design (for example, hint stones).
-- - "empty": No decoration.
game_meta:register_event("set_dialog_style", function(game, style)
  dialog_box.style = style
  if style == "wood" then
    dialog_box.box_img = sol.surface.create("hud/dialog_box_wood.png")
    dialog_box.end_lines_sprite:set_animation("wood")
  elseif style == "stone" then
    dialog_box.box_img = sol.surface.create("hud/dialog_box_stone.png")
    dialog_box.end_lines_sprite:set_animation("stone")
  else
    dialog_box.box_img = sol.surface.create("hud/dialog_box.png")
    dialog_box.end_lines_sprite:set_animation("default")
  end
end)

game_meta:register_event("set_dialog_name", function(game, name)
  dialog_box.name = name
end)

-- Sets the vertical position of the dialog box for subsequent dialogs.
-- vertical_position must be one of:
-- - "auto" (default): Choose automatically so that the hero is not hidden.
-- - "top": Top of the screen.
-- - "bottom": Bottom of the screen.
game_meta:register_event("set_dialog_position", function(game, position)
  dialog_box.vertical_position = position
end)

game_meta:register_event("get_dialog_property", function(game, prop, dialog)
  if dialog ~= nil then dialog_box.dialog = sol.language.get_dialog(dialog) end
  if dialog_box.dialog ~= nil then
    if prop == "importance" then value = dialog_box.dialog.importance or 1
    elseif prop == "inheritance" then value = dialog_box.dialog.inheritance or 0
    elseif prop == "var_require" then value = dialog_box.dialog.var_require
    elseif prop == "var_exclude" then value = dialog_box.dialog.var_exclude
    elseif prop == "var_boolean" then value = dialog_box.dialog.var_boolean
    elseif prop == "var_integer" then value = dialog_box.dialog.var_integer
    elseif prop == "known" then value = dialog_box.dialog.known or false end
    return value
  end
end)

local function repeat_show_character()
  dialog_box:check_full()
  while not dialog_box:is_full()
      and dialog_box.char_index > #dialog_box.lines[dialog_box.line_index] do
    -- The current line is finished.
    dialog_box.char_index = 1
    dialog_box.line_index = dialog_box.line_index + 1
    dialog_box:check_full()
  end

  if not dialog_box:is_full() then
    dialog_box:add_character()
  else
    sol.audio.play_sound("message_end")
    if dialog_box:has_more_lines()
        or dialog_box.dialog.next ~= nil
        or dialog_box.selected_answer ~= nil then
      dialog_box.end_lines_sprite:set_direction(0)
      dialog_box.game:set_custom_command_effect("action", "next")
    else
      dialog_box.end_lines_sprite:set_direction(1)
      dialog_box.game:set_custom_command_effect("action", "return")
    end
    dialog_box.game:set_custom_command_effect("attack", nil)
  end
end

-- The first dialog of a sequence starts.
function dialog_box:on_started()
  -- Set the initial properties.
  -- Subsequent dialogs in the same sequence do not reset them.
  dialog_box.icon_index = nil
  dialog_box.skip_mode = "none"
  dialog_box.char_delay = char_delays["fast"]
  dialog_box.selected_answer = nil

  -- Determine the position of the dialog box on the screen.
  local map = dialog_box.game:get_map()
  local camera_x, camera_y = map:get_camera():get_position()
  local camera_width, camera_height = map:get_camera():get_size()
  local top = false
  if dialog_box.vertical_position == "top" then
    top = true
  elseif dialog_box.vertical_position == "auto" then
    local hero_x, hero_y = map:get_entity("hero"):get_position()
    if hero_y >= camera_y + (camera_height / 2 + 10) then top = true end
  end

  -- Set the coordinates of graphic objects.
  local x = camera_width / 2 - 110
  local y = top and 32 or (camera_height - 96)

  if dialog_box.style == "empty" then
    y = y + (top and -24 or 24)
  end

  dialog_box.box_dst_position = { x = x, y = y }
  dialog_box.question_dst_position = { x = x + 18, y = y + 27 }
  dialog_box.icon_dst_position = { x = x + 18, y = y + 22 }

  dialog_box:show_dialog()
end

-- The dialog box is being closed.
function dialog_box:on_finished()
  -- Remove overriden command effects.
  dialog_box.game:set_custom_command_effect("action", nil)
  dialog_box.game:set_custom_command_effect("attack", nil)
  
  -- Restore default style and name.
  dialog_box.game:set_dialog_style("default")
  dialog_box.game:set_dialog_name(nil)
end

-- A dialog starts (not necessarily the first one of its sequence).
function dialog_box:show_dialog()
  -- Initialize this dialog.
  local dialog = dialog_box.dialog

  local text = dialog.text
  if dialog_box.info ~= nil then
    -- There is a "$v" sequence to substitute.
    text = text:gsub("%$v", dialog_box.info)
  end
  -- Split the text in lines.
  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
  dialog_box.line_it = text:gmatch("([^\n]*)\n")  -- Each line including empty ones.

  dialog_box.next_line = self.line_it()
  dialog_box.line_index = 1
  dialog_box.char_index = 1
  dialog_box.skipped = false
  dialog_box.full = false
  dialog_box.need_letter_sound = dialog_box.style ~= "empty"

  if dialog.skip ~= nil then
    -- The skip mode changes for this dialog.
    dialog_box.skip_mode = dialog.skip
  end

  if dialog.icon ~= nil then
    -- The icon changes for this dialog ("-1" means none).
    if dialog.icon == "-1" then
      dialog_box.icon_index = nil
    else
      dialog_box.icon_index = dialog.icon
    end
  end

  if dialog.question == "1" then
    -- This dialog is a question.
    dialog_box.selected_answer = 1  -- The answer will be 1 or 2.
  end

  -- Additional dialog properties.
  dialog_box.importance = dialog.importance or 1
  dialog_box.inheritance = dialog.inheritance or 0
  dialog_box.var_require = dialog.var_require or nil
  dialog_box.var_exclude = dialog.var_exclude or nil
  dialog_box.var_boolean = dialog.var_boolean or nil
  dialog_box.var_include = dialog.var_include or nil
  dialog_box.known = dialog.known or false

  -- Start displaying text.
  dialog_box:show_more_lines()
end

-- Returns whether there are more lines remaining to display after the current
-- 3 lines.
function dialog_box:has_more_lines()
  return dialog_box.next_line ~= nil
end

-- Updates the result of is_full().
function dialog_box:check_full()
  if dialog_box.line_index >= nb_visible_lines
      and dialog_box.char_index > #dialog_box.lines[nb_visible_lines] then
    dialog_box.full = true
  else
    dialog_box.full = false
  end
end

-- Returns whether all 3 current lines of the dialog box are entirely
-- displayed.
function dialog_box:is_full()
  return dialog_box.full
end

-- Shows the next dialog of the sequence.
-- Closes the dialog box if there is no next dialog.
function dialog_box:show_next_dialog()
  local next_dialog_id
  if dialog_box.selected_answer ~= 2 then
    -- No question or first answer
    next_dialog_id = dialog_box.dialog.next
  else
    -- Second answer.
    next_dialog_id = dialog_box.dialog.next2
  end

  if next_dialog_id ~= nil and next_dialog_id ~= "_unknown" then
    -- Show the next dialog.
    dialog_box.first = false
    dialog_box.selected_answer = nil
    dialog_box.dialog = sol.language.get_dialog(next_dialog_id)
    dialog_box:show_dialog()
  else
    -- Finish the dialog, returning the answer or nil if there was no question.
    local status = dialog_box.selected_answer
    -- Conform to the built-in handling of shop items.
    if dialog_box.dialog.id == "_shop.question" then
      -- The engine expects a boolean answer after the "do you want to buy"
      -- shop item dialog.
      status = dialog_box.selected_answer == 1
    end

    dialog_box.game:stop_dialog(status)
  end
end

-- Starts showing a new group of 3 lines in the dialog.
-- Shows the next dialog (if any) if there are no remaining lines.
function dialog_box:show_more_lines()
  dialog_box.gradual = true
  
  if not dialog_box:has_more_lines() then
    dialog_box:show_next_dialog()
    return
  end
  
  -- Hide the action icon and change the sword icon.
  dialog_box.game:set_custom_command_effect("action", nil)
  if dialog_box.skip_mode ~= "none" then
    dialog_box.game:set_custom_command_effect("attack", "skip")
    dialog_box.game:set_custom_command_effect("action", "next")
  else
    dialog_box.game:set_custom_command_effect("attack", nil)
  end
  
  -- Prepare the 3 lines.
  for i = 1, nb_visible_lines do
    for _, line_surface in pairs(self.line_surfaces) do line_surface[i]:set_text("") end
	if dialog_box:has_more_lines() then
      dialog_box.lines[i] = dialog_box.next_line
      dialog_box.next_line = dialog_box.line_it()
    else
      dialog_box.lines[i] = ""
    end
  end
  dialog_box.line_index = 1
  dialog_box.char_index = 1

  if dialog_box.gradual then
    sol.timer.start(self, dialog_box.char_delay, repeat_show_character)
  end
end

-- Adds the next character to the dialog box.
-- If this is a special character (like $0, $v, etc.),
-- the corresponding action is performed.
function dialog_box:add_character()
  local line = dialog_box.lines[dialog_box.line_index]
  local current_char = line:sub(dialog_box.char_index, dialog_box.char_index)
  if current_char == "" then
    error("No remaining character to add on this line")
  end
  dialog_box.char_index = dialog_box.char_index + 1
  local additional_delay = 0
  local text_surface = dialog_box.current_line_surface[dialog_box.line_index]

  -- Special characters:
  -- - $1, $2 and $3: slow, medium and fast
  -- - $0: pause
  -- - $v: variable
  -- - space: don't add the delay
  -- - 110xxxx: multibyte character
  -- - $r, $g, $b, $y, $c, $m, $w: set text color 
  
  local special = false
  if current_char == "$" then
    -- Special character.

    special = true
    current_char = line:sub(dialog_box.char_index, dialog_box.char_index)
    dialog_box.char_index = dialog_box.char_index + 1

    if current_char == "0" then
      -- Pause.
      additional_delay = 1000

    elseif current_char == "1" then
      -- Slow.
      dialog_box.char_delay = char_delays["slow"]

    elseif current_char == "2" then
      -- Medium.
      dialog_box.char_delay = char_delays["medium"]

    elseif current_char == "3" then
      -- Fast.
      dialog_box.char_delay = char_delays["fast"]
	
    elseif current_char == "r" then
      self:create_surface("red")
      self:set_color({255,102,102})

    elseif current_char == "g" then
      self:create_surface("green")
      self:set_color({102,255,102})

    elseif current_char == "b" then
      self:create_surface("blue")
      self:set_color({122,122,255})

    elseif current_char == "y" then
      self:create_surface("yellow")
      self:set_color({255,255,0})

    elseif current_char == "c" then
      self:create_surface("cyan")
      self:set_color({0,255,255})

    elseif current_char == "m" then
      self:create_surface("magenta")
      self:set_color({255,102,255})

    elseif current_char == "o" then
      self:create_surface("orange")
      self:set_color({255,165,0})

    elseif current_char == "p" then
      self:create_surface("purple")
      self:set_color({181,102,181})

    elseif current_char == "s" then
      self:create_surface("silver")
      self:set_color({192,192,192})

    elseif current_char == "w" then
      self:create_surface("default")
      self:set_color({255,255,255})
	 
    else
      -- Not a special char, actually.
      text_surface:set_text(text_surface:get_text() .. "$")
      special = false
    end
  end

  if not special then
    -- Normal character to be displayed.
    text_surface:set_text(text_surface:get_text() .. current_char)

    -- If this is a multibyte character, also add the next byte.
    local byte = current_char:byte()
    if byte >= 192 and byte < 224 then
      -- The first byte is 110xxxxx: the character is stored with
      -- two bytes (utf-8).
      current_char = line:sub(self.char_index, self.char_index)
      self.char_index = self.char_index + 1
      text_surface:set_text(text_surface:get_text() .. current_char)
    end

    if current_char == " " then
      -- Remove the delay for whitespace characters.
      additional_delay = -self.char_delay
    end
  end
   
  if not special and current_char ~= nil and self.need_letter_sound then
    -- Play a letter sound sometimes.
    sol.audio.play_sound("message_letter")
    self.need_letter_sound = false
    sol.timer.start(self, letter_sound_delay, function()
      self.need_letter_sound = true
    end)
  end

  if self.gradual then
    sol.timer.start(self, self.char_delay + additional_delay, repeat_show_character)
  end
end

-- Stops displaying gradually the current 3 lines, shows them immediately.
-- If the 3 lines were already finished, the next group of 3 lines starts
-- (if any).
function dialog_box:show_all_now()
  if dialog_box:is_full() then
    dialog_box:show_more_lines()
  else
    dialog_box.gradual = false
    -- Check the end of the current line.
    dialog_box:check_full()
    while not dialog_box:is_full() do

      while not dialog_box:is_full()
          and dialog_box.char_index > #dialog_box.lines[dialog_box.line_index] do
        dialog_box.char_index = 1
        dialog_box.line_index = dialog_box.line_index + 1
        dialog_box:check_full()
      end

      if not dialog_box:is_full() then
        dialog_box:add_character()
      end
      dialog_box:check_full()
    end
  end
end

function dialog_box:on_command_pressed(command)
  if command == "action" then
    -- Display more lines.
    if dialog_box:is_full() then
      dialog_box:show_more_lines()
    elseif dialog_box.skip_mode ~= "none" then
      dialog_box:show_all_now()
    end

  elseif command == "attack" then
    -- Attempt to skip the dialog.
    if dialog_box.skip_mode == "all" then
      dialog_box.skipped = true
      dialog_box.game:stop_dialog("skipped")
    elseif dialog_box:is_full() then
      dialog_box:show_more_lines()
    elseif dialog_box.skip_mode == "current" then
      dialog_box:show_all_now()
    end
  elseif command == "up" or command == "down" then
    if dialog_box.selected_answer ~= nil and not dialog_box:has_more_lines() and dialog_box:is_full() then
      sol.audio.play_sound("cursor")
      dialog_box.selected_answer = 3 - dialog_box.selected_answer  -- Switch between 1 and 2.
      dialog_box.question_dst_position.y = dialog_box.box_dst_position.y + (dialog_box.selected_answer == 1 and 27 or 40)
    end
  end

  -- Don't propagate the event to anything below the dialog box.
  return true
end

function dialog_box:on_draw(dst_surface)
  local x, y = self.box_dst_position.x, self.box_dst_position.y
  
  self.dialog_surface:clear()
  
  if self.style == "empty" then
    -- Draw a dark rectangle.
    dst_surface:fill_color({0, 0, 0}, x, y, 220, 60)
  else
    -- Draw the dialog box.
    self.box_img:draw_region(0, 0, box_width, box_height, self.dialog_surface, x, y)
  end
  
  -- Draw the name (if applicable).
  if dialog_box.name ~= nil then
    local font, font_size = sol.language.get_dialog_font()
    local name_surface = sol.text_surface.create({ font = font, font_size = font_size, text = dialog_box.name, color = {0,0,0} })
    name_surface:draw(self.dialog_surface, x + 10, y - 5)
    local name_surface = sol.text_surface.create({ font = font, font_size = font_size, text = dialog_box.name, color = {255,255,255} })
    name_surface:draw(self.dialog_surface, x + 11, y - 4)
  end
  
  -- Draw the text.
  local text_x = x + (self.icon_index == nil and 12 or 48) --16 or 48
  local text_y = y - 1
  for i = 1, nb_visible_lines do
    text_y = text_y + 13
    if self.selected_answer ~= nil
        and i == nb_visible_lines - 1
        and not self:has_more_lines() then
      -- The last two lines are the answer to a question.
      text_x = text_x + 24
    end
	for _, surface in pairs(self.line_surfaces) do
      surface[i]:draw(self.dialog_surface, text_x, text_y)
    end
  end

  -- Draw the icon.
  if self.icon_index ~= nil then
    local row, column = math.floor(self.icon_index / 10), self.icon_index % 10
    self.icons_img:draw_region(16 * column, 16 * row, 16, 16,
        self.dialog_surface,
        self.icon_dst_position.x, self.icon_dst_position.y)
    self.question_dst_position.x = x + 50
  else
    self.question_dst_position.x = x + 18
  end

  -- Draw the question arrow.
  if self.selected_answer ~= nil
      and self:is_full()
      and not self:has_more_lines() then
    self.box_img:draw_region(128, 60, 16, 16, self.dialog_surface,
        self.question_dst_position.x, self.question_dst_position.y)
  end

  -- Draw the end message arrow.
  if self:is_full() then
    self.end_lines_sprite:draw(self.dialog_surface, x + 103, y + 56)
  end

  -- Final blit.
  self.dialog_surface:draw(dst_surface)
end

function dialog_box:create_surface(name)
  -- Create the new surface if it does not exist.
  if not self.line_surfaces[name] then
    self.line_surfaces[name] = {}
    for i = 1, nb_visible_lines do
      self.line_surfaces[name][i] = sol.text_surface.create(dialog_box.text_properties)
    end
  end
  -- Fill with spaces in the current line of the new surface until the current position. 
  local current_line = self.current_line_surface[self.line_index]
  local new_line = self.line_surfaces[name][self.line_index]
  local nb_spaces = #current_line:get_text() - #new_line:get_text() + 1
  if nb_spaces > 0 then
    for i = 1, nb_spaces do new_line:set_text(new_line:get_text() .. " ") end
  end
  -- Change the current surface to the new surface.
  self.current_line_surface = self.line_surfaces[name]
end

function dialog_box:set_color(color)
  -- Change color.
  for i = 1, nb_visible_lines do self.current_line_surface[i]:set_color(color) end
end

return dialog_box