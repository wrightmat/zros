local enemy = ...
local vulnerable = false
local timers = {}
local ex, ey, el

-- Wizzrobe: Ice magic enemy which shoots beams at the hero.

function enemy:on_created()
  self:set_life(8); self:set_damage(12)
  self:create_sprite("enemies/wizzrobe_ice")
  self:set_size(16, 24); self:set_origin(8, 17)
  self:get_sprite():set_animation("immobilized")
end

function enemy:on_restarted()
  vulnerable = false
  for _, t in ipairs(timers) do t:stop() end
  self:get_sprite():fade_out()
  timers[#timers + 1] = sol.timer.start(self, 700, function() self:hide() end)
end

function enemy:on_movement_changed(movement)
  local direction4 = movement:get_direction4()
  self:get_sprite():set_direction(direction4)
end

function enemy:hide()
  vulnerable = false
  self:get_sprite():set_animation("immobilized")
  ex, ey, el = self:get_position()
  self:set_position(-100, -100)
  sol.timer.start(self:get_map(), math.random(10)*100, function() self:unhide() end)
end

function enemy:unhide()
  vulnerable = true
  self:set_position(ex, ey)
  self:get_sprite():fade_in()
  self:get_sprite():set_animation("walking")
  local m = sol.movement.create("path_finding")
  m:set_speed(56)
  m:start(self)
  timers[#timers + 1] = sol.timer.start(self, 1000, function() self:fire() end)
end

function enemy:fire()
  vulnerable = true
  self:get_sprite():set_animation("shaking")
  local beam = self:create_enemy({ breed = "projectiles/wizzrobe_beam", direction = self:get_sprite():get_direction(), name = "ice" })
  self:restart()
end