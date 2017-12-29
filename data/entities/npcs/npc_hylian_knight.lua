local entity = ...
local game = entity:get_game()
sol.main.load_file("entities/generic_npc")(entity)

local dialogs = { "greetings.generic", "all_characters.meduhi", }
game:set_value(entity:get_name() .. "_dialogs", tableToString(dialogs))
game:set_value(entity:get_name() .. "_memory", 12) -- Number of dialogs this NPC can learn

local routine = { [0700]="from_inn", [0800]="from_farm_1", [0900]="from_virgator", [1000]="from_farm_2", [1100]="from_shop", [1200]="from_farm_3", [1300]="from_church", [1400]="from_link", [1500]="from_groundskeeper", [1600]="from_mill", [1700]="knight_waypoint", [1800]="from_manor", [1830]="remove" }

-- Hylian Knight - Meduhi
-- Begins by standing guard at the manor, but then proceeds to walk around
-- the entire settlement before returning to the manor.

function entity:on_created()
  entity:on_generic_created()
  -- Creation event(s)
  -- For example, setting the starting position/routine of the NPC when the
  -- map loads (if it varies do to different routines) would go here.
  self:set_routine(self, routine)
end

function entity:on_interaction()
  entity:on_generic_interaction()
end

function entity:on_movement_finished()
  self:get_sprite():set_direction(3)
end