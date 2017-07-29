local fire = ...
local game = fire:get_game()
local map = game:get_map()
local enemies_touched = { }
local sprite

function fire:on_created()
  local sprite = self:create_sprite("entities/fire_burns")
  self:set_size(16, 16); self:set_origin(8, 13)
  self:set_can_traverse("hero", true)
  self:set_traversable_by("hero", true)
  
  function sprite:on_animation_finished()
    fire:remove()
  end
  
  -- Create a really slow movement to the fire.
  local m = sol.movement.create("random_path")
  m:set_speed(2)
  m:start(fire)
end

-- Returns the sprite of a destrucible.
-- TODO remove this when the engine provides a function destructible:get_sprite()
local function get_destructible_sprite(destructible)
  return fire.get_sprite(destructible)
end

-- Returns whether a destructible is flammable.
local function is_flammable(destructible)
  local sprite = get_destructible_sprite(destructible)
  if sprite == nil then return false end
  local sprite_id = sprite:get_animation_set()
  return sprite_id == "entities/bush" or sprite_id:match("^entities/bush_") or sprite_id:match("^entities/wood_")
end

-- Traversable rules.
fire:set_can_traverse("crystal", true)
fire:set_can_traverse("crystal_block", true)
fire:set_can_traverse("hero", true)
fire:set_can_traverse("jumper", true)
fire:set_can_traverse("stairs", false)
fire:set_can_traverse("stream", true)
fire:set_can_traverse("switch", true)
fire:set_can_traverse("teletransporter", true)
fire:set_can_traverse_ground("deep_water", true)
fire:set_can_traverse_ground("shallow_water", true)
fire:set_can_traverse_ground("hole", true)
fire:set_can_traverse_ground("lava", true)
fire:set_can_traverse_ground("prickles", true)
fire:set_can_traverse_ground("low_wall", true)
fire:set_can_traverse("destructible", function(fire, destructible)
  return is_flammable(destructible)
end)

-- Burn flammable entities (e.g. bushes).
fire:add_collision_test("touching", function(fire, entity)
  if entity:get_type() == "destructible" then
    if not is_flammable(entity) then return end
    
    -- Possibly already being destroyed.
    if get_destructible_sprite(entity):get_animation() ~= "on_ground" then return end
    
    local ex, ey, el = entity:get_position()
    if math.random(10) >= 4 and not entity:overlaps(fire, "sprite") then -- 60% chance of the bush spreading the fire.
      sol.timer.start(map, math.random(10*100), function()
        map:create_custom_entity({ direction = 0, x = ex, y = ey, layer = el, width = 16, height = 16, model = "fire" })
      end)
    end
    sol.timer.start(map, 500, function() destroy_destructible(fire, entity) end)
  end
  
  function destroy_destructible(fire, entity)
    local entity_sprite = get_destructible_sprite(entity)
    local entity_sprite_id = entity_sprite:get_animation_set()
    local ex, ey, el = entity:get_position()
    
    local treasure = { entity:get_treasure() }
    if treasure ~= nil then
      local pickable = map:create_pickable({
        x = ex,
        y = ey,
        layer = el,
        treasure_name = treasure[1],
        treasure_variant = treasure[2],
        treasure_savegame_variable = treasure[3],
      })
    end
    
    sol.audio.play_sound(entity:get_destruction_sound())
    entity:remove()
    
    local entity_destroyed_sprite = fire:create_sprite(entity_sprite_id)
    local x, y = fire:get_position()
    entity_destroyed_sprite:set_xy(ex - x, ey - y)
    entity_destroyed_sprite:set_animation("destroy")
  end
end)

-- Hurt enemies.
fire:add_collision_test("sprite", function(fire, entity)
  if entity:get_type() == "enemy" then
    local enemy = entity
    -- If protected we don't want to play the sound repeatedly.
    if enemies_touched[enemy] then return end
    enemies_touched[enemy] = true
    local reaction = enemy:get_fire_reaction(enemy_sprite)
    enemy:receive_attack_consequence("fire", reaction)
  end
end)

function fire:on_obstacle_reached()
  sol.timer.start(fire, 350, function() fire:remove() end)
end