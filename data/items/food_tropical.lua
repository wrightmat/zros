local item = ...
local game = item:get_game()

function item:on_created()
  self:set_shadow("small")
  self:set_can_disappear(true)
  self:set_assignable(true)
  self:set_savegame_variable("food_tropical")
  self:set_amount_savegame_variable("food_tropical_counter")
  self:set_max_amount(99)
end

-- Obtaining some meat.
function item:on_obtaining(variant, savegame_variable)
  self:add_amount(1)
  self:get_game():set_value("food_tropical_obtained", true)
end

function item:on_pickable_created(pickable)
  if game:get_value("food_tropical_obtained") then self:set_brandish_when_picked(false) end
end

function item:on_using()
  if self:get_amount() == 0 or game:get_max_stamina() == 0 then
    sol.audio.play_sound("wrong")
  else
    sol.audio.play_sound("chewing")
    self:remove_amount(1)
    game:add_life(32) -- 8 hearts
    game:add_stamina(20)
  end
  self:set_finished()
end