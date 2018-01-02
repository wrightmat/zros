local submenu = require("scripts/menus/pause_submenu")
local collection_submenu = submenu:new()

local item_names = {
  "food_meat_1",
  "food_mushroom_1",
  "food_plant_1",
  "food_vegetable_1",
  "food_fruit_1",
  "monster_jelly",
  "insect_butterfly",

  "food_meat_2",
  "food_mushroom_2",
  "food_plant_2",
  "food_vegetable_2",
  "food_fruit_2",
  "monster_wings",
  "insect_dragonfly",

  "food_meat_3",
  "food_mushroom_3",
  "food_plant_3",
  "food_vegetable_3",
  "food_fruit_3",
  "monster_tails",
  "insect_mayfly",

  "food_meat_4",
  "food_mushroom_4",
  "food_plant_4",
  "food_vegetable_4",
  "food_fruit_4",
  "monster_guts",
  "insect_beetle"
}

function collection_submenu:on_started()
  submenu.on_started(self)
  self.cursor_sprite = sol.sprite.create("menus/pause_cursor")
  self.collection_sprite = {}
  self.collection = {}
  self.sprites = {}
  self.counters = {}
  self.captions = {}
  
  if self.game.cooking_enabled then
    item_names[7] = "bottle_1"; item_names[14] = "bottle_2"; item_names[21] = "bottle_3"; item_names[28] = "bottle_4"
  else
    item_names[7] = "insect_butterfly"; item_names[14] = "insect_dragonfly"; item_names[21] = "insect_mayfly"; item_names[28] = "insect_beetle"
  end
  
  for k = 1, #item_names do
    -- Get the item, its possession state and amount.
    local item = self.game:get_item(item_names[k])
    local variant = item:get_variant()

    if variant > 0 then
      if item:has_amount() then
        -- Show a counter in this case.
        local amount = item:get_amount()
        local maximum = item:get_max_amount()

        self.counters[k] = sol.text_surface.create{
          horizontal_alignment = "center",
          vertical_alignment = "top",
          text = item:get_amount(),
          font = (amount == maximum) and "green_digits" or "white_digits",
        }
      end

      -- Initialize the sprite and the caption string.
      self.sprites[k] = sol.sprite.create("entities/items")
      self.sprites[k]:set_animation(item_names[k])
      self.sprites[k]:set_direction(variant - 1)
    end
  end

  -- Initialize the cursor.
  local index = self.game:get_value("pause_inventory_last_item_index") or 0
  local row = math.floor(index / 7)
  local column = index % 7
  self:set_cursor_position(row, column)
end

function collection_submenu:on_finished()
  if submenu.on_finished then
    submenu.on_finished(self)
  end

  if self:is_assigning_item() then
    self:finish_assigning_item()
  end

  if self.game.hud ~= nil then
    self.game.hud.primary[5].surface:set_opacity(255)
    self.game.hud.primary[6].surface:set_opacity(255)
  end
end

function collection_submenu:set_cursor_position(row, column)
  self.cursor_row = row
  self.cursor_column = column
  local index = row * 7 + column
  self.game:set_value("pause_inventory_last_item_index", index)

  -- Update the caption text and the action icon.
  local item_name = item_names[index + 1]
  local item = item_name and self.game:get_item(item_name) or nil
  local variant = item and item:get_variant() or 0

  local item_icon_opacity = 128
  if variant > 0 then
    if string.find(item_name, "insect") then variant = 5 end
    self:set_caption("inventory.caption.item." .. item_name .. "." .. variant)
    self.game:set_custom_command_effect("action", "change")
    if item:is_assignable() then item_icon_opacity = 255 end
  else
    self:set_caption(nil)
    self.game:set_custom_command_effect("action", nil)
  end
  if item_name ~= nil then
    if string.find(item_name, "bottle") and self.game.cooking_enabled then self:set_caption("inventory.caption.cooking") end
  end
  self.game.hud.primary[5].surface:set_opacity(item_icon_opacity) -- item_icon_1
  self.game.hud.primary[6].surface:set_opacity(item_icon_opacity) -- item_icon_2
end

function collection_submenu:get_selected_index()
  return self.cursor_row * 7 + self.cursor_column
end

function collection_submenu:is_item_selected()
  local item_name = item_names[self:get_selected_index() + 1]
  return self.game:get_item(item_name):get_variant() > 0
end

function collection_submenu:on_command_pressed(command)
  local handled = submenu.on_command_pressed(self, command)
  local item = item_names[self:get_selected_index() + 1]
  local item_index = 0
  local cooking_type = ""
  local cooking_effect = ""

  local function has_monster()
    if table_has_value(self.collection, "monster_guts") or
    table_has_value(self.collection, "monster_jelly") or
    table_has_value(self.collection, "monster_tails") or
    table_has_value(self.collection, "monster_wings") then return true end
  end
  local function has_meat()
    if table_has_value(self.collection, "food_meat_1") or
    table_has_value(self.collection, "food_meat_2") or
    table_has_value(self.collection, "food_meat_3") or
    table_has_value(self.collection, "food_meat_4") then return true end
  end
  local function has_fruit()
    if table_has_value(self.collection, "food_fruit_1") or
    table_has_value(self.collection, "food_fruit_2") or
    table_has_value(self.collection, "food_fruit_3") or
    table_has_value(self.collection, "food_fruit_4") then return true end
  end
  local function has_mushroom()
    if table_has_value(self.collection, "food_mushroom_1") or
    table_has_value(self.collection, "food_mushroom_2") or
    table_has_value(self.collection, "food_mushroom_3") or
    table_has_value(self.collection, "food_mushroom_4") then return true end
  end
  local function has_vegetable()
    if table_has_value(self.collection, "food_vegetable_1") or
    table_has_value(self.collection, "food_vegetable_2") or
    table_has_value(self.collection, "food_vegetable_3") or
    table_has_value(self.collection, "food_vegetable_4") then return true end
  end
  local function has_plant()
    if table_has_value(self.collection, "food_plant_1") or
    table_has_value(self.collection, "food_plant_2") or
    table_has_value(self.collection, "food_plant_3") or
    table_has_value(self.collection, "food_plant_4") then return true end
  end
  if (#self.collection > 1 and self.cursor_column == 6 and command == "action") or (#self.collection == 4 and command == "action") then
    if has_monster() and has_monster() then
      cooking_type = "Elixir"
    elseif has_monster() and (has_meat() or has_fruit() or has_mushroom() or has_vegetable() or has_plant()) then
      cooking_type = "Potion"
    elseif has_meat() and has_meat() then
      cooking_type = "Seared Meat"
    elseif has_fruit() and has_fruit() then
      cooking_type = "Simmered Fruit"
    elseif has_mushroom() and has_mushroom() then
      cooking_type = "Fried Mushrooms"
    elseif has_vegetable() and has_vegetable() then
      cooking_type = "Grilled Veggies"
    elseif has_plant() and has_vegetable() then
      cooking_type = "Bread"
    elseif has_plant() and has_fruit() then
      cooking_type = "Cake"
    elseif has_meat() and (has_vegetable() or has_mushroom()) then
      cooking_type = "Stew"
    end
    if table_has_value(self.collection,"food_plant_3") then cooking_effect = "Powerful"
    elseif table_has_value(self.collection,"food_plant_4") then cooking_effect = "Courageous"
    elseif table_has_value(self.collection,"food_vegetable_4") then cooking_effect = "Wise"
    elseif table_has_value(self.collection,"food_fruit_1") or table_has_value(self.collection, "food_mushroom_4") then cooking_effect = "Powerful"
    elseif table_has_value(self.collection,"food_vegetable_2") or table_has_value(self.collection, "food_meat_4") then cooking_effect = "Enduring"
    elseif table_has_value(self.collection,"food_meat_3") then cooking_effect = "Brave"
    elseif table_has_value(self.collection,"food_mushroom_2") or table_has_value(self.collection, "food_plant_3") then cooking_effect = "Chilly"
    elseif table_has_value(self.collection,"food_mushroom_3") or table_has_value(self.collection, "food_plant_4") then cooking_effect = "Spicy"
    elseif table_has_value(self.collection,"food_mushroom_1") or table_has_value(self.collection, "food_plant_2") then cooking_effect = "Electric"
    elseif table_has_value(self.collection,"food_vegetable_1") then cooking_effect = "Hasty"
    elseif table_has_value(self.collection,"food_fruit_1") then cooking_effect = "Energizing"
    else cooking_effect = "Hylian" end

    if self.game:has_item("bottle_"..self.cursor_row+1) and self.game:get_item("bottle_"..self.cursor_row+1):get_variant() == 1 then
      self.game:start_dialog("_info.cooking", cooking_effect.." "..cooking_type, function(answer)
        if answer == 1 then
          -- Fill the bottle.
          self.game:get_item("bottle_" .. self.cursor_row+1):set_variant(8)
          -- Remove individual ingredient amounts and empty the array.
          for index, value in ipairs(self.collection) do
            self.game:get_item(value):remove_amount(1)
          end
          self.collection = {}
          self.game.cooking_enabled = false
          self.game:set_paused(false)
        end
      end)
    end
    handled = true
  else
    if command == "action" and self.game.cooking_enabled then
      if self:is_item_selected() and #self.collection < 4 and self.cursor_column < 6 then
        if table_has_value(self.collection, item) then
          sol.audio.play_sound("message_end")
          self.game:set_custom_command_effect("action", nil)
          for index, value in ipairs(self.collection) do
            item_index = item_index + 1
            if value == item then break end
          end
          table.remove(self.collection, item_index)
          self.collection_sprite[item] = nil
        else
          sol.audio.play_sound("message_end")
          self.game:set_custom_command_effect("action", "validate")
          self.collection_sprite[item] = sol.sprite.create("menus/pause_cursor")
          self.collection_sprite[item]:set_animation("locked")
          self.collection_sprite[item]:set_xy((320/2-96)+32*self.cursor_column, (240/2-38)-5+32*self.cursor_row)
          self.collection[#self.collection + 1] = item
        end
        handled = true
      end
    elseif command == "item_1" then
      --if self:is_item_selected() then
      --  self:assign_item(1)
      --  handled = true
      --end
    elseif command == "item_2" then
      --if self:is_item_selected() then
      --  self:assign_item(2)
      --  handled = true
      --end
    elseif command == "left" then
      if self.cursor_column == 0 then
        if not self.game.cooking_enabled then
          self:previous_submenu()
        else
          return true
        end
      else
        sol.audio.play_sound("cursor")
        self:set_cursor_position(self.cursor_row, self.cursor_column - 1)
      end
      handled = true
    elseif command == "right" then
      if self.cursor_column == 6 then
        if not self.game.cooking_enabled then
          self:next_submenu()
        else
          return true
        end
      else
        sol.audio.play_sound("cursor")
        self:set_cursor_position(self.cursor_row, self.cursor_column + 1)
      end
      handled = true
    elseif command == "up" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position((self.cursor_row + 3) % 4, self.cursor_column)
      handled = true
    elseif command == "down" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position((self.cursor_row + 1) % 4, self.cursor_column)
      handled = true
    end
  end

  return handled
end

function collection_submenu:on_draw(dst_surface)
  self:draw_background(dst_surface)
  self:draw_caption(dst_surface)

  -- Draw each inventory item.
  local quest_width, quest_height = dst_surface:get_size()
  local initial_x = quest_width / 2 - 96
  local initial_y = quest_height / 2 - 38
  local y = initial_y
  local k = 0

  for i = 0, 3 do
    local x = initial_x

    for j = 0, 6 do
      k = k + 1
      if item_names[k] ~= nil then
        local item = self.game:get_item(item_names[k])
        if item ~= nil and item:get_variant() > 0 then
          -- The player has this item: draw it.
          self.sprites[k]:draw(dst_surface, x, y)
          if self.counters[k] ~= nil then
            self.counters[k]:draw(dst_surface, x + 8, y)
          end
        end
      end
      x = x + 32
    end
    y = y + 32
  end

  -- Draw the cursor.
  self.cursor_sprite:draw(dst_surface, initial_x + 32 * self.cursor_column, initial_y - 5 + 32 * self.cursor_row)

  -- Draw collection selections.
  for i = 0, #self.collection do
    if self.collection_sprite[self.collection[i]] ~= nil then
      self.collection_sprite[self.collection[i]]:draw(dst_surface)
    end
  end

  -- Draw the item being assigned if any.
  if self:is_assigning_item() then
    self.item_assigned_sprite:draw(dst_surface)
  end

  self:draw_save_dialog_if_any(dst_surface)
end

-- Shows a message describing the item currently selected.
-- The player is supposed to have this item.
function collection_submenu:show_info_message()
  local item_name = item_names[self:get_selected_index() + 1]
  local variant = self.game:get_item(item_name):get_variant()
  local map = self.game:get_map()

  -- Position of the dialog (top or bottom).
  if self.cursor_row >= 2 then
    self.game:set_dialog_position("top")  -- Top of the screen.
  else
    self.game:set_dialog_position("bottom")  -- Bottom of the screen.
  end

  self.game:set_custom_command_effect("action", nil)
  self.game:set_custom_command_effect("attack", nil)
  self.game:start_dialog("_item_description." .. item_name .. "." .. variant, function()
    self.game:set_custom_command_effect("action", "info")
    self.game:set_custom_command_effect("attack", "save")
    self.game:set_dialog_position("auto")  -- Back to automatic position.
  end)
end

-- Assigns the selected item to a slot (1 or 2).
-- The operation does not take effect immediately: the item picture is thrown to
-- its destination icon, then the assignment is done.
-- Nothing is done if the item is not assignable.
function collection_submenu:assign_item(slot)
  local index = self:get_selected_index() + 1
  local item_name = item_names[index]
  local item = self.game:get_item(item_name)

  -- If this item is not assignable, do nothing.
  if not item:is_assignable() then
    return
  end

  -- If another item is being assigned, finish it immediately.
  if self:is_assigning_item() then
    self:finish_assigning_item()
  end

  -- Memorize this item.
  self.item_assigned = item
  self.item_assigned_sprite = sol.sprite.create("entities/items")
  self.item_assigned_sprite:set_animation(item_name)
  self.item_assigned_sprite:set_direction(item:get_variant() - 1)
  self.item_assigned_destination = slot

  -- Play the sound.
  sol.audio.play_sound("throw")

  -- Compute the movement.
  local x1 = 60 + 32 * self.cursor_column
  local y1 = 75 + 32 * self.cursor_row
  local x2 = (slot == 1) and 20 or 72
  local y2 = 46

  self.item_assigned_sprite:set_xy(x1, y1)
  local movement = sol.movement.create("target")
  movement:set_target(x2, y2)
  movement:set_speed(500)
  movement:start(self.item_assigned_sprite, function()
    self:finish_assigning_item()
  end)
end

-- Returns whether an item is currently being thrown to an icon.
function collection_submenu:is_assigning_item()
  return self.item_assigned_sprite ~= nil
end

-- Stops assigning the item right now.
-- This function is called when we want to assign the item without
-- waiting for its throwing movement to end, for example when the inventory submenu
-- is being closed.
function collection_submenu:finish_assigning_item()
  -- If the item to assign is already assigned to the other icon, switch both items.
  local slot = self.item_assigned_destination
  local current_item = self.game:get_item_assigned(slot)
  local other_item = self.game:get_item_assigned(3 - slot)

  if other_item == self.item_assigned then
    self.game:set_item_assigned(3 - slot, current_item)
  end
  self.game:set_item_assigned(slot, self.item_assigned)

  self.item_assigned_sprite:stop_movement()
  self.item_assigned_sprite = nil
  self.item_assigned = nil
end

return collection_submenu