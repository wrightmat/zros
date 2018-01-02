local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by("hero", false)
  self:set_traversable_by("npc", false)
  if game.weather ~= "rain" and game.weather ~= "snow" then
    self.action_effect = "look"
  end
end

function entity:on_interaction()
  if game.weather ~= "rain" and game.weather ~= "snow" then
    game.cooking_enabled = true
    game:set_value("pause_last_submenu", 2)
    game:set_paused(true)
  end
end