local enemy = ...
local map = enemy:get_map()
sol.main.load_file("enemies/generic_animal")(entity)

-- Cucco (Hylian Chicken)

function enemy:on_created()
  self:set_life(4); self:set_damage(1)
  self:create_sprite("enemies/cucco")
  self:set_size(16, 16); self:set_origin(8, 13)
  self:on_generic_created()
end

function enemy:on_restarted()
  if angry then
    enemy:go_angry()
  else
    enemy:go_random()  
    sol.timer.start(enemy, 100, function()
      if map.angry_cuccos and not angry then
        enemy:go_angry()
        return false
      end
      return true  -- Repeat the timer.
    end)
  end
end

function enemy:go_angry()
  angry = true
  map.angry_cuccos = true
  going_hero = true
  sol.audio.play_sound("cucco")
  local movement = sol.movement.create("target")
  movement:set_speed(96)
  movement:start(enemy)
  enemy:get_sprite():set_animation("angry")
  enemy:set_can_attack(true)
end

function enemy:on_hurt()
  sol.audio.play_sound("cucco")
  num_times_hurt = num_times_hurt + 1
  if num_times_hurt == 3 and not map.angry_cuccos then
    -- Make all cuccos of the map attack the hero.
    map.angry_cuccos = true
  end
end