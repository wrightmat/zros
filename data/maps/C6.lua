local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  self.properties = { "leaf", 0.2, "temperate", "beetle", "fruits" }
end