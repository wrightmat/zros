local item = ...

function item:on_created()
  self:set_savegame_variable("i1804")
  self:set_amount_savegame_variable("i1805")
  self:set_assignable(true)

  self:set_can_disappear(true)
  self:set_brandish_when_picked(false)
end

function item:on_started()
  -- Disable pickable bombs if the player has no bomb bag.
  -- We can't do this from on_created() because we don't know if the bomb bag is created.
  local bomb_bag = self:get_game():get_item("bomb_bag")
  self:set_obtainable(bomb_bag:has_variant())
end

function item:on_obtaining(variant, savegame_variable)
  -- Obtaining bombs increases the bombs counter.
  local amounts = {1, 3, 5}
  local amount = amounts[variant]
  if amount == nil then
    error("Invalid variant '" .. variant .. "' for item 'bomb'")
  end
  self:add_amount(amount)
end

-- Called when the player uses the bombs of his inventory by pressing the corresponding item key.
function item:on_using()
  if self:get_amount() == 0 then
    sol.audio.play_sound("wrong")
  else
    self:remove_amount(1)
    local x, y, layer = self:create_bomb()
    sol.audio.play_sound("bomb")
  end
  self:set_finished()
end

function item:create_bomb()
  local hero = self:get_map():get_entity("hero")
  local x, y, layer = hero:get_position()
  local direction = hero:get_direction()
  if direction == 0 then
    x = x + 16
  elseif direction == 1 then
    y = y - 16
  elseif direction == 2 then
    x = x - 16
  elseif direction == 3 then
    y = y + 16
  end
  self:get_map():create_bomb{ x = x, y = y, layer = layer }
end