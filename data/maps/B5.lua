local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  self.properties = { "rain", 0.1, "temperate", "butterfly", "mushrooms" }
end

function map:on_update()
  if game.weather == "rain" then campfire:get_sprite():set_animation("out") end
end