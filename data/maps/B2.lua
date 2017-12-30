local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  -- Desert is cool at night and warm during the day, sand kicks up during the day too.
  if game:get_time_of_day() == "night" then
    self.properties = { nil, 0, "cool", "butterfly", "mushrooms" }
  else
    self.properties = { "sand", 0.4, "warm", "butterfly", "mushrooms" }
  end
end