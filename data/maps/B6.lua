local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  self.properties = { "leaf", 1, "temperate", "dragonfly", "mushrooms" }
end

function deku_clearing:on_activating(direction4)
  if direction4 == 1 then --  North
    -- Change music to less "religious" version once both versions are made.
  elseif direction4 == 3 then -- South
    -- Change music to more "religious" version once both versions are made.
  end
end