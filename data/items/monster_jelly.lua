local item = ...
local game = item:get_game()

function item:on_created()
  self:set_shadow("small")
  self:set_can_disappear(true)
  self:set_assignable(true)
  self:set_savegame_variable("monster_jelly")
  self:set_amount_savegame_variable("monster_jelly_counter")
  self:set_max_amount(999)
end

function item:on_obtaining(variant, savegame_variable)
  self:add_amount(1) -- Overall counter first, then this specific variant.
  local amount = game:get_value("monster_jelly_" .. variant .. "_counter")
  if amount ~= nil then
    game:set_value("monster_jelly_" .. variant .. "_counter", amount + 1)
  else
    game:set_value("monster_jelly_" .. variant .. "_counter", 1)
  end
  game:set_value("monster_jelly_" .. variant .. "_obtained", true)
end

function item:on_pickable_created(pickable)
  local _, variant, _ = pickable:get_treasure()
  if game:get_value("monster_jelly_" .. variant .. "_obtained") then self:set_brandish_when_picked(false) end
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