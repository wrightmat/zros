local submenu = require("scripts/menus/pause_submenu")
local inventory_submenu = submenu:new()

local item_names = {
  -- 1st row: Equippable
  "lamp",
  "bow",
  "bomb",
  "boomerang",
  "hookshot",
  "cane",
  -- 2nd row: Equippable
  "feather",
  "shovel",
  "hammer",
  -- 3rd row: Switchable
  "sword",
  "shield",
  "tunic",
  "boots"
}

function inventory_submenu:on_started()
  submenu.on_started(self)
  self.inventory_items_surface = sol.surface.create(320, 240)
  self.inventory_dialog_surface = sol.surface.create(160, 48)
  self.inventory_cursor_sprite = sol.sprite.create("menus/quests_cursor")
  self.inventory_dialog_sprite = sol.sprite.create("menus/menu_dialog")
  self.cursor_sprite = sol.sprite.create("menus/pause_cursor")
  self.sprites = {}
  self.counters = {}
  self.captions = {}
  self.caption_text_keys = {}
  
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

  -- Draw the items on a surface.
  local item_sprite = sol.sprite.create("entities/items")
  self.inventory_items_surface:clear()
  self.caption_text_keys[0] = "quest_status.caption.quests"  
  
  -- Pieces of heart.
  local pieces_of_heart = self.game:get_value("i1700") or 0
  item_sprite:set_animation("pieces_of_heart")
  item_sprite:set_direction(pieces_of_heart)
  item_sprite:draw(self.inventory_items_surface, 68, 129)
  self.caption_text_keys[1] = "quest_status.caption.pieces_of_heart"
  
  -- Trading sequence.
  --local trading_sequence = self.game:get_value("i1800") or 0
  --item_sprite:set_animation("trading_sequence")
  --item_sprite:set_direction(trading_sequence)
  --item_sprite:draw(self.inventory_items_surface, 100, 129)
  --self.caption_text_keys[2] = "quest_status.caption.trading_sequence"
  
  -- Rupee bag.
  local rupee_bag = self.game:get_item("rupee_bag"):get_variant()
  if rupee_bag > 0 then
    item_sprite:set_animation("rupee_bag")
    item_sprite:set_direction(rupee_bag - 1)
    item_sprite:draw(self.inventory_items_surface, 68, 161)
    self.caption_text_keys[3] = "quest_status.caption.rupee_bag_" .. rupee_bag
  end
  
  -- Bomb bag.
  if self.game:get_item("bomb_bag") ~= nil then
    local bomb_bag = self.game:get_item("bomb_bag"):get_variant()
    if bomb_bag > 0 then
      item_sprite:set_animation("bomb_bag")
      item_sprite:set_direction(bomb_bag - 1)
      item_sprite:draw(self.inventory_items_surface, 100, 161)
      self.caption_text_keys[4] = "quest_status.caption.bomb_bag_" .. bomb_bag
    end
  end
  
  -- Quiver.
  if self.game:get_item("quiver") ~= nil then
    local quiver = self.game:get_item("quiver"):get_variant()
    if quiver > 0 then
      item_sprite:set_animation("quiver")
      item_sprite:set_direction(quiver - 1)
      item_sprite:draw(self.inventory_items_surface, 132, 161)
      self.caption_text_keys[5] = "quest_status.caption.quiver_" .. quiver
    end
  end
  
  -- Bracelet/Glove.
  local glove = self.game:get_item("glove"):get_variant()
  if glove > 0 then
    item_sprite:set_animation("glove")
    item_sprite:set_direction(glove - 1)
    item_sprite:draw(self.inventory_items_surface, 164, 161)
    self.caption_text_keys[6] = "quest_status.caption.glove_" .. glove
  end
  
  -- Flippers.
  local flippers = self.game:get_item("flippers"):get_variant()
  if flippers > 0 then
    item_sprite:set_animation("flippers")
    item_sprite:set_direction(flippers - 1)
    item_sprite:draw(self.inventory_items_surface, 196, 161)
    self.caption_text_keys[7] = "quest_status.caption.flippers_" .. flippers
  end
  
  -- Ocarina.
  local ocarina = self.game:get_item("ocarina"):get_variant()
  if ocarina > 0 then
    item_sprite:set_animation("ocarina")
    item_sprite:set_direction(ocarina - 1)
    item_sprite:draw(self.inventory_items_surface, 228, 161)
    self.caption_text_keys[8] = "quest_status.caption.ocarina_" .. ocarina
  end
  
  -- Sword.
  local sword = self.game:get_item("sword"):get_variant()
  if sword > 0 then
    item_sprite:set_animation("sword")
    item_sprite:set_direction(sword - 1)
    item_sprite:draw(self.inventory_items_surface, 132, 129)
    self.caption_text_keys[9] = "quest_status.caption.sword_" .. sword
  end
  
  -- Shield.
  local shield = self.game:get_item("shield"):get_variant()
  if shield > 0 then
    item_sprite:set_animation("shield")
    item_sprite:set_direction(shield - 1)
    item_sprite:draw(self.inventory_items_surface, 164, 129)
    self.caption_text_keys[10] = "quest_status.caption.shield_" .. shield
  end
  
  -- Tunic.
  self.tunic = self.game:get_item("tunic"):get_variant()
  if self.game:get_value("tunic_equipped") == nil then self.game:set_value("tunic_equipped", self.game:get_item("tunic"):get_variant()) end
  self.tunic_equipped = self.game:get_value("tunic_equipped")
  item_sprite:set_animation("tunic")
  item_sprite:set_direction(self.tunic_equipped - 1)
  item_sprite:draw(self.inventory_items_surface, 196, 129)
  self.caption_text_keys[11] = "quest_status.caption.tunic_" .. self.tunic_equipped
  
  -- Boots.
  self.tunic = self.game:get_item("tunic"):get_variant()
  if self.game:get_value("tunic_equipped") == nil then self.game:set_value("tunic_equipped", self.game:get_item("tunic"):get_variant()) end
  self.tunic_equipped = self.game:get_value("tunic_equipped")
  item_sprite:set_animation("tunic")
  item_sprite:set_direction(self.tunic_equipped - 1)
  item_sprite:draw(self.inventory_items_surface, 228, 129)
  self.caption_text_keys[12] = "quest_status.caption.tunic_" .. self.tunic_equipped
  
  -- Initialize the cursor
  local index = self.game:get_value("pause_inventory_last_item_index") or 0
  local row = math.floor(index / 6)
  local column = index % 6
  self:set_cursor_position(row, column)
end

function inventory_submenu:on_finished()
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

function inventory_submenu:set_cursor_position(row, column)
  self.cursor_row = row
  self.cursor_column = column
  
  local index = row * 6 + column
  self.game:set_value("pause_inventory_last_item_index", index)
  
  -- Update the caption text and the action icon.
  local item_name = item_names[index + 1]
  local item = item_name and self.game:get_item(item_name) or nil
  local variant = item and item:get_variant() or 0
  
  local item_icon_opacity = 128
  if variant > 0 then
    self:set_caption("inventory.caption.item." .. item_name .. "." .. variant)
    self.game:set_custom_command_effect("action", "info")
    if item:is_assignable() then
      item_icon_opacity = 255
    end
  else
    self:set_caption(nil)
    self.game:set_custom_command_effect("action", nil)
  end
  self.game.hud.primary[5].surface:set_opacity(item_icon_opacity) --item_icon_1
  self.game.hud.primary[6].surface:set_opacity(item_icon_opacity) --item_icon_2
end

function inventory_submenu:get_selected_index()
  return self.cursor_row * 6 + self.cursor_column
end

function inventory_submenu:is_item_selected()
  local item_name = item_names[self:get_selected_index() + 1]
  return self.game:get_item(item_name):get_variant() > 0
end

function inventory_submenu:on_command_pressed(command)
  local handled = submenu.on_command_pressed(self, command)

  if not handled then
    if command == "action" then
      if self.game:get_command_effect("action") == nil
            and self.game:get_custom_command_effect("action") == "info" then
        self:show_info_message()
        handled = true
      end

    elseif command == "item_1" then
      if self:is_item_selected() then
        self:assign_item(1)
        handled = true
      end

    elseif command == "item_2" then
      if self:is_item_selected() then
        self:assign_item(2)
        handled = true
      end

    elseif command == "left" then
      if self.cursor_column == 0 then
        self:previous_submenu()
      else
        sol.audio.play_sound("cursor")
        self:set_cursor_position(self.cursor_row, self.cursor_column - 1)
      end
      handled = true

    elseif command == "right" then
      if self.cursor_column == 5 then
        self:next_submenu()
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

function inventory_submenu:on_draw(dst_surface)
  self:draw_background(dst_surface)
  self:draw_caption(dst_surface)
  -- Draw each inventory item.
  local quest_width, quest_height = dst_surface:get_size()
  local initial_x = quest_width / 2 - 80
  local initial_y = quest_height / 2 - 42
  local y = initial_y
  local k = 0
  for i = 0, 3 do
    local x = initial_x
    for j = 0, 5 do
      k = k + 1
      if item_names[k] ~= nil then
        local item = self.game:get_item(item_names[k])
        if item ~= nil and item:get_variant() > 0 then
          -- The player has this item: draw it.
          self.sprites[k]:draw(dst_surface, x, y + 6)
          if self.counters[k] ~= nil then
            -- This item has a counter: draw it.
            self.counters[k]:draw(dst_surface, x + 6, y + 4)
          end
        end
      end
      x = x + 32
    end
    y = y + 32
  end
  -- Draw the un-equippable items.
  self.inventory_items_surface:draw(dst_surface, x, y)
  -- Draw the cursor.
  self.cursor_sprite:draw(dst_surface, initial_x + 32 * self.cursor_column, initial_y + 32 * self.cursor_row)
  -- Draw the item being assigned if any.
  if self:is_assigning_item() then
    self.item_assigned_sprite:draw(dst_surface)
  end
  -- Draw the save dialog if it exists.
  self:draw_save_dialog_if_any(dst_surface)
end

-- Shows a message describing the item currently selected.
-- The player is supposed to have this item.
function inventory_submenu:show_info_message()
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
function inventory_submenu:assign_item(slot)
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
function inventory_submenu:is_assigning_item()
  return self.item_assigned_sprite ~= nil
end

-- Stops assigning the item right now.
-- This function is called when we want to assign the item without waiting for its
-- throwing movement to end, for example when the inventory submenu is being closed.
function inventory_submenu:finish_assigning_item()
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

return inventory_submenu