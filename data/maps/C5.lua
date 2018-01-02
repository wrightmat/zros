local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  self.properties = { "leaf", 1, "temperate", "mayfly", "plants" }
end