local behavior = {}

-- Behavior of a generic food item.

function behavior:create(item, properties)
  -- Set default properties.
  if properties.shadow == nil then
    properties.shadow = "small"
  end
  if properties.disappear == nil then
    properties.disappear = false
  end
  if properties.assignable == nil then
    properties.assignable = false
  end
  if properties.savegame_variable == nil then
    properties.savegame_variable = item:get_name()
  end
  if properties.amount_variable == nil then
    properties.amount_variable = item:get_name() .. "_counter"
  end
  if properties.max_amount == nil then
    properties.max_amount = 999
  end
  if properties.life_amount == nil then
    properties.life_amount = 32 -- 8 hearts
  end
  if properties.stamina_amount == nil then
    properties.stamina_amount = 20
  end
  if properties.sound_effect == nil then
    properties.sound_effect = "chewing"
  end
  
  function item:on_created()
    self:set_shadow(properties.shadow)
    self:set_can_disappear(properties.disappear)
    self:set_assignable(properties.assignable)
    self:set_savegame_variable(properties.savegame_variable)
    self:set_amount_savegame_variable(properties.amount_variable)
    self:set_max_amount(properties.max_amount)
  end

  -- Obtaining some food.
  function item:on_obtaining(variant, savegame_variable)
    local game = self:get_game()
    self:add_amount(1) -- Overall counter first, then this specific variant.
    if game:get_value(item:get_name()) == nil then game:set_value(item:get_name(), 1) end
    local amount = game:get_value(item:get_name() .. "_" .. variant .. "_counter")
    if amount ~= nil then
      game:set_value(item:get_name() .. "_" .. variant .. "_counter", amount + 1)
    else
      game:set_value(item:get_name() .. "_" .. variant .. "_counter", 1)
    end
    game:set_value(item:get_name() .. "_" .. variant .. "_obtained", true)
  end

  function item:on_pickable_created(pickable)
    local game = self:get_game()
    local _, variant, _ = pickable:get_treasure()
    if game:get_value(item:get_name() .. "_" .. variant .. "_obtained") then self:set_brandish_when_picked(false) end
  end

  function item:on_amount_changed(amount)
    local item = self:get_name()
    local variant = self:get_variant() or 1
    local sprite = sol.sprite.create("entities/items")
    sprite:set_animation(item); sprite:set_direction(variant - 1)
    local text = sol.language.get_string("inventory.caption.item." .. item ..  "." .. variant)
    self:get_game():show_collectible(sprite, text, 100)
  end

  function item:on_using()
    local game = self:get_game()
    if self:get_amount() == 0 or game:get_max_stamina() == 0 then
      sol.audio.play_sound("wrong")
    else
      sol.audio.play_sound(properties.sound_effect)
      self:remove_amount(1)
      game:set_value(item:get_name() .. "_" .. variant .. "_counter", amount - 1)
      game:add_life(properties.life_amount)
      game:add_stamina(propertied.stamina_amount)
    end
    self:set_finished()
  end
end

return behavior