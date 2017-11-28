local pause_menu = {}

local inventory_builder = require("scripts/menus/pause_inventory")
local collection_builder = require("scripts/menus/pause_collection")
local quest_status_builder = require("scripts/menus/pause_quest_status")
local map_builder = require("scripts/menus/pause_map")
local options_builder = require("scripts/menus/pause_options")
local game_meta = sol.main.get_metatable("game")

game_meta:register_event("start_pause_menu", function(game)
  game.pause_submenus = {
    inventory_builder:new(game),
    collection_builder:new(game),
    quest_status_builder:new(game),
    map_builder:new(game),
    options_builder:new(game),
  }
  
  local submenu_index = game:get_value("pause_last_submenu") or 1
  if submenu_index <= 0 or submenu_index > #game.pause_submenus then
    submenu_index = 1
  end
  game:set_value("pause_last_submenu", submenu_index)
   
  sol.audio.play_sound("pause_open")
  sol.menu.start(game, game.pause_submenus[submenu_index], true)
  game.hud:set_enabled(false)
  game.hud:set_enabled(true)  -- Refresh the HUD so it stays on top of the menu.
end)

game_meta:register_event("stop_pause_menu", function(game)
  sol.audio.play_sound("pause_closed")
  local submenu_index = game:get_value("pause_last_submenu")
  sol.menu.stop(game.pause_submenus[submenu_index])
  game.pause_submenus = {}
  game:set_custom_command_effect("action", nil)
  game:set_custom_command_effect("attack", nil)
end)

return pause_menu