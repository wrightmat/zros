local entity = ...
local game = entity:get_game()
local hero = game:get_map():get_entity("hero")

-- A mayfly is an entity which darts around randomly
-- and and quickly, while avoiding the hero.

local function random_walk()
  local m = sol.movement.create("random_path")
  m:set_speed(80)
  m:start(entity)
  entity:get_sprite():set_animation("walking")
end

local function avoid_hero()
  sol.timer.start(entity, 500, function()
    local m = sol.movement.create("target")
    local hx, hy, _ = hero:get_position()
    if math.random(4) == 1 then hx = hx + 100
    elseif math.random(4) == 2 then hy = hy + 100
    elseif math.random(4) == 3 then hx = hx - 100
    elseif math.random(4) == 4 then hy = hy - 100 end
    m:set_target(hx, hy)
    m:set_ignore_obstacles(true)
    m:set_speed(96)
    m:start(entity)
    entity:get_sprite():set_animation("walking")
  end)
end

function entity:on_created()
  self.action_effect = "grab"
  self:set_drawn_in_y_order(true)
  sol.timer.start(entity, 500, function()
    local hx, hy, hl = hero:get_position()
    local ex, ey, el = entity:get_position()
    local distance_hero = math.abs((hx+hy)-(ex+ey))
    if distance_hero > 50 then
      random_walk()
    else
      avoid_hero()
    end
    return true
  end)
end

function entity:on_movement_changed(movement)
  local direction = movement:get_direction4()
  entity:get_sprite():set_direction(direction)
end

-- If the hero interacts with the butterfly, he collects it.
function entity:on_interaction()
  sol.audio.play_sound("picked_item")
  game:get_item("insect_mayfly"):on_obtaining(1)
  self:remove()
end