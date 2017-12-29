local submenu = require("scripts/menus/pause_submenu")
local quest_status_submenu = submenu:new()

function quest_status_submenu:on_started()
  submenu.on_started(self)
  local font, font_size = sol.language.get_menu_font()
  self.quest_items_surface = sol.surface.create(320, 240)
  self.quest_dialog_surface = sol.surface.create(160, 48)
  self.cursor_sprite = sol.sprite.create("menus/pause_cursor")
  self.quest_cursor_sprite = sol.sprite.create("menus/quests_cursor")
  self.quest_dialog_sprite = sol.sprite.create("menus/menu_dialog")
  self.cursor_sprite_x = 0
  self.cursor_sprite_y = 0
  self.cursor_position = nil
  self.quest_cursor_sprite_x = 0
  self.quest_cursor_sprite_y = 0
  self.quest_cursor_position = 1
  self.quest_dialog_state = 0
  self.caption_text_keys = {}
  self.tunic = self.game:get_item("tunic"):get_variant()
  
  self.quests_num = 0
  self.quests_texts = {}
  self.quests_icons = {}
  self.quests_saves = {}
  self.quests_highest_visible = 0
  self.quests_visible_y = 0
  self.quests_main_list = { "i1027","i1029","i1030","i1032","i1068","i1807" }
  self.quests_side_list = { "i1601","i1602","i1603","i1604","i1605","i1606","i1607","i1608","i1612","i1615","i1631","i1651","i1652","i1840" }

  -- If quest has been initialized, add to the quest list first.
  for i = 1, #self.quests_main_list do
    if self.game:get_value(self.quests_main_list[i]) ~= nil and self.game:get_value(self.quests_main_list[i]) > 0 then -- If quest is initialized...
      if sol.language.get_dialog("_quests." .. self.quests_main_list[i] .. "." .. self.game:get_value(self.quests_main_list[i])) ~= nil then -- and not completed...
        self.quests_num = self.quests_num + 1
        self.quests_texts[self.quests_num] = sol.text_surface.create{
          horizontal_alignment = "left",
          vertical_alignment = "top",
          font = font,
          font_size = 7,
          color = {0,0,0},
          text_key = "quests.title." .. self.quests_main_list[i]
        }
        self.quests_saves[self.quests_num] = self.quests_main_list[i]
        self.quests_icons[self.quests_num] = sol.sprite.create("menus/quest_icons")
        self.quests_icons[self.quests_num]:set_direction(1)
      end
    end
  end
  for j = 1, #self.quests_side_list do
    if self.game:get_value(self.quests_side_list[j]) ~= nil and self.game:get_value(self.quests_side_list[j]) > 0 then -- If quest is initialized...
      if sol.language.get_dialog("_quests." .. self.quests_side_list[j] .. "." .. self.game:get_value(self.quests_side_list[j])) ~= nil then -- and not complete...
        self.quests_num = self.quests_num + 1
        self.quests_texts[self.quests_num] = sol.text_surface.create{
          horizontal_alignment = "left",
          vertical_alignment = "top",
          font = font,
          font_size = 7,
          color = {0,0,0},
          text_key = "quests.title." .. self.quests_side_list[j]
        }
        self.quests_saves[self.quests_num] = self.quests_side_list[j]
        self.quests_icons[self.quests_num] = sol.sprite.create("menus/quest_icons")
        self.quests_icons[self.quests_num]:set_direction(0)
      end
    end
  end

  -- If quest is complete, show it and count it, but it should be greyed out (and displayed last).
  for i = 1, #self.quests_main_list do
    if self.game:get_value(self.quests_main_list[i]) ~= nil and self.game:get_value(self.quests_main_list[i]) > 0 then
      if sol.language.get_dialog("_quests." .. self.quests_main_list[i] .. "." .. self.game:get_value(self.quests_main_list[i])) == nil then
        self.quests_num = self.quests_num + 1
        self.quests_texts[self.quests_num] = sol.text_surface.create{
          horizontal_alignment = "left",
          vertical_alignment = "top",
          font = font,
          font_size = 7,
          color = {220,220,220},
          text_key = "quests.title." .. self.quests_main_list[i]
        }
        self.quests_saves[self.quests_num] = self.quests_main_list[i]
        self.quests_icons[self.quests_num] = sol.sprite.create("menus/quest_icons")
        self.quests_icons[self.quests_num]:set_direction(1)
      end
    end
  end
  for j = 1, #self.quests_side_list do
    if self.game:get_value(self.quests_side_list[j]) ~= nil and self.game:get_value(self.quests_side_list[j]) > 0 then
    if sol.language.get_dialog("_quests." .. self.quests_side_list[j] .. "." .. self.game:get_value(self.quests_side_list[j])) == nil then
      self.quests_num = self.quests_num + 1
        self.quests_texts[self.quests_num] = sol.text_surface.create{
          horizontal_alignment = "left",
          vertical_alignment = "top",
          font = font,
          font_size = 7,
          color = {220,220,220},
          text_key = "quests.title." .. self.quests_side_list[j]
        }
        self.quests_saves[self.quests_num] = self.quests_side_list[j]
        self.quests_icons[self.quests_num] = sol.sprite.create("menus/quest_icons")
        self.quests_icons[self.quests_num]:set_direction(0)
      end
    end
  end
  
  self.quests_surface = sol.surface.create(102, (#self.quests_texts * 13) + 2)
  self.quests_surface:set_xy(87, 81)
  
  for i = 1, #self.quests_texts do
    local y = 13 * i - 5
    self.quests_icons[i]:draw(self.quests_surface, 10, y)
    self.quests_texts[i]:draw(self.quests_surface, 6, y - 6)
  end
  
  self.up_arrow_sprite = sol.sprite.create("menus/arrow")
  self.up_arrow_sprite:set_direction(1)
  self.up_arrow_sprite:set_xy(175, 72)
  self.down_arrow_sprite = sol.sprite.create("menus/arrow")
  self.down_arrow_sprite:set_direction(3)
  self.down_arrow_sprite:set_xy(175, 138)
  
  -- Dungeons finished
  local dungeons_img = sol.surface.create("menus/quest_status_dungeons.png")
  local dst_positions = {
    { 225,  69 },
    { 243,  74 },
    { 248,  97 },
    { 243, 120 },
    { 225, 127 },
    { 205, 120 },
    { 197,  97 },
    { 205,  74 },
  }
  for i, dst_position in ipairs(dst_positions) do
    if self.game:is_dungeon_finished(i) then
      dungeons_img:draw_region(20 * (i - 1), 0, 20, 20,
          self.quest_items_surface, dst_position[1], dst_position[2])
    end
  end

  -- Cursor.
  self:set_cursor_position(0)
end

function quest_status_submenu:set_cursor_position(position)
    self.cursor_position = position
    if position == 0 then

    elseif position <= 4 then
      self.cursor_sprite_x = 67
    elseif position == 5 then
      self.cursor_sprite_x = 96
    else
      self.cursor_sprite_x = -36 + 29 * position
    end
    
    if position == 1 then
      self.cursor_sprite_y = 85
    elseif position == 2 then
      self.cursor_sprite_y = 114
    elseif position == 3 then
      self.cursor_sprite_y = 143
    else
      self.cursor_sprite_y = 172
    end
    if position == 8 and self.tunic > 1 then
      self.game:set_custom_command_effect("action", "change")
    elseif position == 0 then
      self.game:set_custom_command_effect("action", "info")
    else
      self.game:set_custom_command_effect("action", nil)
    end
    
    self:set_caption(self.caption_text_keys[position])
    
    -- Make sure the selected command is visible.
    while self.quest_cursor_position <= self.quests_highest_visible do
      self.quests_highest_visible = self.quests_highest_visible - 1
      self.quests_visible_y = self.quests_visible_y - 13
    end
    
    while self.quest_cursor_position > self.quests_highest_visible + 4 do
      self.quests_highest_visible = self.quests_highest_visible + 1
      self.quests_visible_y = self.quests_visible_y + 13
    end
    
    self.quest_cursor_sprite_x = 88
    self.quest_cursor_sprite_y = 71 + 13 * (self.quest_cursor_position - self.quests_highest_visible)
end

function quest_status_submenu:on_command_pressed(command)
  local handled = submenu.on_command_pressed(self, command)
  
  if self.quest_dialog_state == 1 then
    if command == "left" or command == "down" then
      self.quest_dialog_choice = self.quest_dialog_choice - 1
      if self.quest_dialog_choice < 0 then self.quest_dialog_choice = self.tunic - 1 end
      self.quest_dialog_sprite:set_direction(self.quest_dialog_choice)
      self:set_caption("quest_status.caption.tunic_" .. self.quest_dialog_choice + 1)
    elseif command == "right" or command == "up" then
      self.quest_dialog_choice = self.quest_dialog_choice + 1
      if self.quest_dialog_choice >= self.tunic then self.quest_dialog_choice = 0 end
      self.quest_dialog_sprite:set_direction(self.quest_dialog_choice)
      self:set_caption("quest_status.caption.tunic_" .. self.quest_dialog_choice + 1)
    elseif command == "action" or command == "attack" then
      self.game:set_value("tunic_equipped", self.quest_dialog_choice + 1)
      self.tunic_equipped = self.quest_dialog_choice + 1
      sol.audio.play_sound("throw")
      self.quest_dialog_state = 0
      -- Redraw the new tunic in the menu
      self.quest_dialog_surface:clear()
      self.game:set_custom_command_effect("action", nil)
      local item_sprite = sol.sprite.create("entities/items")
      item_sprite:set_animation("tunic")
      item_sprite:set_direction(self.quest_dialog_choice)
      item_sprite:draw(self.quest_items_surface, 196, 177)
      self.caption_text_keys[7] = "quest_status.caption.tunic_" .. self.tunic_equipped
      self.game:get_hero():set_tunic_sprite_id("hero/tunic" .. self.tunic_equipped)
    end
  elseif not handled then
    if command == "left" then
      if self.cursor_position == 0 then
        self:set_cursor_position(1)
      elseif self.cursor_position == 1 then
        self:previous_submenu()
      else
        sol.audio.play_sound("cursor")
        self:set_cursor_position(self.cursor_position - 1)
      end
      handled = true
    elseif command == "right" then
      if self.cursor_position == 0 then
        self:set_cursor_position(10)
      elseif self.cursor_position == 10 then
        self:next_submenu()
      else
        sol.audio.play_sound("cursor")
        self:set_cursor_position(self.cursor_position + 1)
      end
      handled = true
    elseif command == "down" then
      sol.audio.play_sound("cursor")
      if self.quest_cursor_position < self.quests_num then
        self.quest_cursor_position = self.quest_cursor_position + 1
      end
      self:set_cursor_position(0)
      handled = true
    elseif command == "up" then
      sol.audio.play_sound("cursor")
      if self.quest_cursor_position > 1 then
        self.quest_cursor_position = self.quest_cursor_position - 1
      end
      self:set_cursor_position(0)
      handled = true
    elseif command == "action" then
      if self.cursor_position == 8 and self.tunic > 1 then
        -- Cursor is over the Tunic
        sol.audio.play_sound("message_end")
        self.quest_dialog_choice = (self.tunic_equipped - 1) or 0
        self.quest_dialog_sprite:set_direction(self.quest_dialog_choice)
        self.game:set_custom_command_effect("action", "validate")
        self.quest_dialog_state = 1
        handled = true
      elseif self.cursor_position == 0 then
        -- Cursor is over Quests Details
        if sol.language.get_dialog("_quests." .. self.quests_saves[self.quest_cursor_position] .. "." .. self.game:get_value(self.quests_saves[self.quest_cursor_position])) ~= nil then
          sol.audio.play_sound("message_end")
          self.game:start_dialog("_quests." .. self.quests_saves[self.quest_cursor_position] .. "." .. self.game:get_value(self.quests_saves[self.quest_cursor_position]))
        else
          sol.audio.play_sound("wrong")
        end
      end
    end
  end

  return handled
end

function quest_status_submenu:on_draw(dst_surface)
  local width, height = dst_surface:get_size()
  local x = width / 2 - 160
  local y = height / 2 - 120
  self:draw_background(dst_surface)
  self:draw_caption(dst_surface)
  self.quest_items_surface:draw(dst_surface, x, y)
  self.quests_surface:draw_region(0, self.quests_visible_y, 215, 57, dst_surface)

  if self.cursor_position > 0 then
    self.cursor_sprite:draw(dst_surface, x + self.cursor_sprite_x, y + self.cursor_sprite_y)
  else
    self.quest_cursor_sprite:draw(dst_surface, x + self.quest_cursor_sprite_x, y + self.quest_cursor_sprite_y)
  end
  if self.quest_dialog_state == 1 then
    self.quest_dialog_sprite:draw(self.quest_dialog_surface, 0, 0)
    local item_sprite = sol.sprite.create("entities/items")
    item_sprite:set_animation("tunic")
    for i = 0, self.tunic - 1 do
      item_sprite:set_direction(i)
      item_sprite:draw(self.quest_dialog_surface, 23+(i*38), 30)
    end
    self.quest_dialog_surface:draw(dst_surface, x + 105, y + 145)
  end
  
  -- Arrows.
  if self.quests_visible_y > 0 then
    self.up_arrow_sprite:draw(dst_surface)
  end
  if self.quests_visible_y < ((#self.quests_texts - 4) * 13) then
    self.down_arrow_sprite:draw(dst_surface)
  end
  
  self:draw_save_dialog_if_any(dst_surface)
end

return quest_status_submenu