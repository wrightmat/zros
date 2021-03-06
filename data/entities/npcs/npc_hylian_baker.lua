local entity = ...
local game = entity:get_game()
sol.main.load_file("entities/generic_npc")(entity)

local dialogs = { "greetings.weather", "all_characters.burlon", }
game:set_value(entity:get_name() .. "_dialogs", tableToString(dialogs))
game:set_value(entity:get_name() .. "_memory", 12) -- Number of dialogs this NPC can learn

local routine = { [0800]="to_shop", [1000]="remove", [1200]="from_shop", [1300]="to_mill" }

-- Hylian Baker - Burlon
-- Begins near the mill in the morning, then walks through town to
-- the shop, enters, exits, and then goes back home to the mill.

function entity:on_created()
  entity:on_generic_created()
  -- Creation event(s)
  -- For example, setting the starting position/routine of the NPC when the
  -- map loads (if it varies due to different routines) would go here.
  self:set_routine(self, routine)
  random_walk()
end

function entity:on_interaction()
  entity:on_generic_interaction()
end

function entity:on_movement_finished()
  random_walk()
end