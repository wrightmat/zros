local item = ...
local game = item:get_game()

function item:on_created()
  self:set_shadow("small")
  self:set_can_disappear(true)
  self:set_assignable(true)
  self:set_savegame_variable(item:get_name())
  self:set_amount_savegame_variable(item:get_name() .. "_counter")
  self:set_max_amount(99)
end

-- Obtaining a monster part.
function item:on_obtaining(variant, savegame_variable)
  self:add_amount(1) -- Overall counter first, then this specific variant.
  local amount = game:get_value(item:get_name() .. "_" .. variant .. "_counter")
  if amount ~= nil then
    game:set_value(item:get_name() .. "_" .. variant .. "_counter", amount + 1)
  else
    game:set_value(item:get_name() .. "_" .. variant .. "_counter", 1)
  end
  game:set_value(item:get_name() .. "_" .. variant .. "_obtained", true)
end

function item:on_pickable_created(pickable)
  local _, variant, _ = pickable:get_treasure()
  if game:get_value(item:get_name() .. "_" .. variant .. "_obtained") then self:set_brandish_when_picked(false) end
end

function item:on_using()
  if self:get_amount() == 0 or game:get_max_stamina() == 0 then
    sol.audio.play_sound("wrong")
  else
    -- What to do when "using" a monster part?
  end
  self:set_finished()
end