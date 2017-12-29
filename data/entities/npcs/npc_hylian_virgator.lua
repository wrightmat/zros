local entity = ...
local game = entity:get_game()
sol.main.load_file("entities/generic_npc")(entity)

local dialogs = { "greetings.generic", "all_characters.jhoro_ethern", }
game:set_value(entity:get_name() .. "_dialogs", tableToString(dialogs))
game:set_value(entity:get_name() .. "_memory", 12) -- Number of dialogs this NPC can learn

local routine = { [0900]="from_farm_1", [1100]="from_farm_2", [1300]="from_farm_3", [1500]="from_manor", [1700]="from_virgator", [1730]="remove" }

-- Hylian Virgator/Landowner - Jhoro Ethern
-- Walks out of his house in the morning, then through town to
-- each of his farms throughout the day. Returns home in the evening.

function entity:on_created()
  entity:on_generic_created()
  -- Creation event(s)
  -- For example, setting the starting position/routine of the NPC when the
  -- map loads (if it varies due to different routines) would go here.
  self:set_routine(self, routine)
end

function entity:on_interaction()
  entity:on_generic_interaction()
end

function entity:on_movement_finished()
  random_walk()
end