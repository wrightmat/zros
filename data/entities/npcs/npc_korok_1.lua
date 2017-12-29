local entity = ...
local game = entity:get_game()
sol.main.load_file("entities/generic_npc")(entity)

local dialogs = { "greetings.korok", "korok_woods.1", }
game:set_value(entity:get_name() .. "_dialogs", tableToString(dialogs))
game:set_value(entity:get_name() .. "_memory", 8) -- Number of dialogs this NPC can learn

local routine = { }

-- Korok

function entity:on_created()
  entity:on_generic_created()
  -- Creation event(s)
  -- For example, setting the starting position/routine of the NPC when the
  -- map loads (if it varies due to different routines) would go here.
  --self:set_routine(self, routine)
  random_walk()
end

function entity:on_interaction()
  entity:on_generic_interaction()
end

function entity:on_movement_finished()
  random_walk()
end