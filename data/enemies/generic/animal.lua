local entity = ...

local game = entity:get_game()
local map = entity:get_map()
local angry = false
local num_times_hurt = 0

-- Generic animal script that wanders around the map, but gets
-- angry and attacks after enough abuse or threat from the hero.

function entity:random_walk()
  local m = sol.movement.create("random_path")
  m:set_ignore_obstacles(false)
  m:set_speed(32)
  m:start(entity)
  entity:get_sprite():set_animation("walking")
end

function entity:follow_hero()
  sol.timer.start(entity, 1000, function()
    local hero_x, hero_y, hero_layer = hero:get_position()
    local npc_x, npc_y, npc_layer = entity:get_position()
    local distance_hero = math.abs((hero_x+hero_y)-(npc_x+npc_y))
    local m = sol.movement.create("target")
    m:set_ignore_obstacles(false)
    m:set_speed(40)
    m:start(entity)
    entity:get_sprite():set_animation("walking")
  end)
end

function entity:follow_path(entity, dest, callback)
  path_x, path_y = entity:get_position()
  local dest_entity = map:get_entity(dest)
  local m = sol.movement.create("path_finding")
  m:set_ignore_obstacles(false)
  m:set_speed(40)
  m:set_target(dest_entity)
  m:start(entity, function() return true end)
  entity:get_sprite():set_animation("walking")
  
  function m:on_obstacle_reached()
    if entity:get_distance(dest_entity) <= 50 then
      return callback(dest)
    end
  end
end

function entity:on_generic_created()
  self:set_drawn_in_y_order(true)
  self:set_can_traverse("hero", false)
  self:set_traversable_by("hero", false)
  -- Don't allow NPC to traverse other NPCs when moving.
  self:set_traversable_by("npc", false)
  self:set_traversable_by("custom_entity", false)
  self:random_walk()
end

function entity:on_movement_changed(movement)
  local direction4 = movement:get_direction4()
  self:get_sprite():set_direction(direction4)
end

function entity:on_obstacle_reached(movement)
  if not angry then
    self:go_random()
  else
    self:go_angry()
  end
end

function entity:on_restarted()
  if angry then
    self:go_angry()
  else
    self:go_random()
  end
end

function entity:go_random()
  angry = false
  local movement = sol.movement.create("random")
  movement:set_speed(32)
  movement:start(self)
  --self:set_can_attack(false)
end

function entity:go_angry()
  angry = true
  going_hero = true
  --sol.audio.play_sound("animal")
  local movement = sol.movement.create("target")
  movement:set_speed(96)
  movement:start(self)
  --self:get_sprite():set_animation("angry")
  --self:set_can_attack(true)
end

function entity:on_hurt()
  --sol.audio.play_sound("animal")
  num_times_hurt = num_times_hurt + 1
  if num_times_hurt == 3 and not angry then
    self:go_angry()
  end
end