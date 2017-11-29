local entity = ...
local game = entity:get_game()
local hour = game:get_value("hour_of_day")
local last_hour
sol.main.load_file("entities/generic_npc")(entity)

local dialogs = { "greetings.generic", "all_characters.jhoro_ethern", }
game:set_value(entity:get_name() .. "_dialogs", tableToString(dialogs))
game:set_value(entity:get_name() .. "_memory", 12) -- Number of dialogs this NPC can learn

-- Hylian Virgator/Landowner (name?)
-- Walks out of his house in the morning, then through town to
-- each of his farms throughout the day. Returns home in the evening.
--[[
function entity:determine_routine()
  if hour == 7 then
    follow_path(entity, "wp_npc_virgator_1", function()
      entity:get_movement():stop()
      entity:get_sprite():set_animation("stopped")
      entity:get_sprite():set_direction(2) -- Face to the left.
    end)
  elseif hour == 8 then
    follow_path(entity, "wp_npc_virgator_2/8")
  elseif hour == 9 then
    follow_path(entity, "wp_npc_virgator_3", function()
      entity:get_movement():stop()
      entity:get_sprite():set_animation("stopped")
      entity:get_sprite():set_direction(2) -- Face to the left.
    end)
  elseif hour == 10 then
    follow_path(entity, "wp_npc_virgator_4")
  elseif hour == 11 then
    follow_path(entity, "wp_npc_virgator_5", function()
      entity:get_movement():stop()
      entity:get_sprite():set_animation("stopped")
      entity:get_sprite():set_direction(2) -- Face to the left.
    end)
  elseif hour == 12 then
    follow_path(entity, "wp_npc_virgator_6")
  elseif hour == 13 then
    follow_path(entity, "from_shop")
  elseif hour == 14 then
    follow_path(entity, "wp_npc_virgator_7")
  elseif hour == 15 then
    follow_path(entity, "wp_npc_virgator_2/8")
  elseif hour == 16 then
    follow_path(entity, "from_virgator", function() entity:remove() end)
  end
end

function entity:on_created()
  entity:on_generic_created()

  if hour <= 6 then
    entity:remove() -- NPC is inside his house.
  elseif hour == 7 then
    entity:set_position(game:get_map():get_entity("from_virgator"):get_position())
  elseif hour == 8 then
    entity:set_position(game:get_map():get_entity("wp_npc_virgator_1"):get_position())
  elseif hour == 9 then
    entity:set_position(game:get_map():get_entity("wp_npc_virgator_2/8"):get_position())
  elseif hour == 10 then
    entity:set_position(game:get_map():get_entity("wp_npc_virgator_3"):get_position())
  elseif hour == 11 then
    entity:set_position(game:get_map():get_entity("wp_npc_virgator_4"):get_position())
  elseif hour == 12 then
    entity:set_position(game:get_map():get_entity("wp_npc_virgator_5"):get_position())
  elseif hour == 13 then
    entity:set_position(game:get_map():get_entity("wp_npc_virgator_6"):get_position())
  elseif hour == 14 then
    entity:set_position(game:get_map():get_entity("from_shop"):get_position())
  elseif hour == 15 then
    entity:set_position(game:get_map():get_entity("wp_npc_virgator_7"):get_position())
  elseif hour == 16 then
    entity:set_position(game:get_map():get_entity("wp_npc_virgator_2/8"):get_position())
  elseif hour >= 17 then
    entity:remove() -- NPC is inside his house.
  end

  self:determine_routine()
  sol.timer.start(self, 5000, function()
    hour = game:get_value("hour_of_day")
    if hour ~= last_hour then
      self:determine_routine()
    end
    last_hour = hour
    return true
  end)
end
--]]
function entity:on_interaction()
  entity:on_generic_interaction()
end