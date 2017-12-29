local generic = {}

-- Generic properties and methods of a collectible entity.

function generic:create(entity, properties)
  local name_display = string.sub(entity:get_name(), 0):gsub("^%l", string.upper):gsub("_", " ")
  local font, font_size = sol.language.get_dialog_font()
  local game = entity:get_game()
  
  -- Set effect based on collectible name.
  if string.match(entity:get_name(), "magical") then properties.effect = "restore_magic"; properties.variant = 17
  elseif string.match(entity:get_name(), "energizing") then properties.effect = "restore_stamina"; properties.variant = 16
  elseif string.match(entity:get_name(), "healing") then properties.effect = "restore_life"; properties.variant = 15
  elseif string.match(entity:get_name(), "hasty") or string.match(entity:get_name(), "swift") then properties.effect = "increase_speed"; properties.variant = 14
  elseif string.match(entity:get_name(), "holy") then properties.effect = "cure_cursed"; properties.variant = 13
  elseif string.match(entity:get_name(), "clear") then properties.effect = "cure_confusion"; properties.variant = 12
  elseif string.match(entity:get_name(), "pure") then properties.effect = "cure_poison"; properties.variant = 11
  elseif string.match(entity:get_name(), "electric") then properties.effect = "cure_shocking"; properties.variant = 10
  elseif string.match(entity:get_name(), "spicy") or string.match(entity:get_name(), "warm") then properties.effect = "cure_freezing"
  elseif string.match(entity:get_name(), "chilly") or string.match(entity:get_name(), "cool") then properties.effect = "cure_burning"
  elseif string.match(entity:get_name(), "brave") then properties.effect = "increase_magic"
  elseif string.match(entity:get_name(), "enduring") then properties.effect = "increase_stamina"
  elseif string.match(entity:get_name(), "hearty") then properties.effect = "increase_life"
  elseif string.match(entity:get_name(), "wise") then properties.effect = "boost_magic"
  elseif string.match(entity:get_name(), "courageous") then properties.effect = "boost_stamina"
  elseif string.match(entity:get_name(), "powerful") then properties.effect = "boost_life"
  end
  
  -- Set default properties.
  if properties.effect == nil then
    properties.effect = "none"
  end
  if properties.power == nil then
    properties.power = 1
  end
  if properties.action_effect == nil then
    properties.action_effect = "look"  -- May change to "lift" (pick up).
  end
  if properties.variant == nil then
    properties.variant = 1
  end
  
  function entity:on_created()
    self:set_shadow("small")
    self:set_can_disappear(true)
    self:set_assignable(true)
    self:set_savegame_variable(entity:get_name())
    self:set_amount_savegame_variable(entity:get_name() .. "_counter")
    self:set_max_amount(99)
    self:set_variant(properties.variant)
  end
  
  function entity:on_interaction()
    -- TODO: Collect the item? Or do this in the non-generic script?
  end

  function entity:on_post_draw()
    -- Draw the item's name above the entity if it's known.
    if game:get_value(entity:get_name() .. "_known") then
      local name_surface = sol.text_surface.create({ font = font, font_size = 8, text = name_display })
      local x, y, l = entity:get_position()
      local w, h = entity:get_sprite():get_size()
      if self:get_distance(game:get_hero()) < 100 then game:get_map():draw_visual(name_surface, x-(w/2), y-(h-4)) end
    end
  end
end

return generic