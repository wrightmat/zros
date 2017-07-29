local entity = ...
local game = entity:get_game()
sol.main.load_file("entities/generic_npc")(entity)

local dialogs = { "greetings.generic", "all_characters.zelda_amerghin", }
game:set_value(entity:get_name() .. "_dialogs", tableToString(dialogs))
game:set_value(entity:get_name() .. "_memory", 12) -- Number of dialogs this NPC can learn

-- NPC Description...

function entity:on_created()
  entity:on_generic_created()
  -- Creation event(s)
  -- For example, setting the starting position/routine of the NPC when the
  -- map loads (if it varies do to different routines) would go here.
  random_walk()
  if hour == 0 then

  elseif hour == 1 then

  elseif hour == 2 then

  elseif hour == 3 then

  elseif hour == 4 then

  elseif hour == 5 then

  elseif hour == 6 then

  elseif hour == 7 then

  elseif hour == 8 then

  elseif hour == 9 then

  elseif hour == 10 then

  elseif hour == 11 then

  end
end

function entity:on_interaction()
  entity:on_generic_interaction()
end