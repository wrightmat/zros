local game = ...

-- This script handles global properties of a particular savegame.

-- Include the various game features.
require("scripts/multi_events")
local warp_menu = require("scripts/menus/warp")
local pause_menu = require("scripts/menus/pause")
local credits_menu = require("scripts/menus/credits")
local game_over_menu = require("scripts/menus/game_over")
local dialog_box = require("scripts/menus/dialog_box")
local hud_manager = require("scripts/hud_manager")
local camera_manager = require("scripts/camera_manager")
local condition_manager = require("scripts/condition_manager")
game.save_between_maps = require("scripts/save_between_maps")
require("scripts/weather/weather_manager.lua")
require("scripts/tone_manager")(game)
require("scripts/common_functions")
require("scripts/equipment")
require("scripts/dungeons")
game.independent_entities = {}

game:register_event("on_started", function(game)
  game.hud = hud_manager:initialize(game)
end)

game:register_event("on_finished", function(game)
  game.hud:quit()
  -- Ensure the hero always has a sword when they start a new game (possible to lost it permanantly if cursed).
  if (game:get_ability("sword") == 0 and game:get_value("i1821")) then
    game:set_ability("sword", game:get_value("i1821"))
  end
end)

-- This event is called when a new map has just become active.
game:register_event("on_map_changed", function(game)
  local map = game:get_map()
  -- Notify the hud.
  game.hud:on_map_changed(map)
  game.save_between_maps:load_map(map) -- Create saved and carried entities.
end)

function game:on_paused()
  game.hud:on_paused()
  game:start_pause_menu()
end

function game:on_unpaused()
  game:stop_pause_menu()
  game.hud:on_unpaused()
end

function game:get_player_name()
  return self:get_value("player_name")
end

function game:set_player_name(player_name)
  self:set_value("player_name", player_name)
end

-- Returns whether the current map is in the inside world.
function game:is_in_inside_world()
  return self:get_map():get_world() == "inside_world"
end

-- Returns whether the current map is in the outside world.
function game:is_in_outside_world()
  if self:get_map() ~= nil then
    return self:get_map():get_world() == "outside_world" or
         self:get_map():get_world() == "outside_north" or
         self:get_map():get_world() == "outside_subrosia"
  else
    return false
  end
end

function game:calculate_percent_complete()
  game:set_value("percent_complete", percent_complete)
  
  return percent_complete
end

-- Run the game.
sol.main.game = game
game:start()