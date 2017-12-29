-- sand manager script.
-- Author: Diarandor (Solarus Team).
-- License: GPL v3-or-later.
-- Donations: solarus-games.org, diarandor at gmail dot com.

--[[   Instructions:
To add this script to your game, call from game_manager script:
    require("scripts/weather/sand_manager")

The functions here defined are:
    game:get_sand_mode()
    game:set_sand_mode(sand_mode)
    game:get_world_sand_mode(world)
    game:set_world_sand_mode(world, sand_mode)

sand modes: "sand", "sandstorm", nil (no sand).
--]]

local sand_manager = {}

local game_meta = sol.main.get_metatable("game")
local map_meta = sol.main.get_metatable("map")

-- Assets: sounds and sprites.
local grain_sprite = sol.sprite.create("weather/sand")

-- Default settings. Change these for testing.
local sand_speed, sandstorm_speed = 20, 60 -- In pixels per second.
local grain_min_distance, grain_max_distance = 40, 140
local grain_min_zigzag_distance, grain_max_zigzag_distance = 10, 150
local sand_grain_delay, sandstorm_grain_delay = 10, 5 -- In milliseconds.
local sand_darkness, sandstorm_darkness = 50, 90 -- Opacity during sandstorm.
local current_darkness = 0 -- Opacity (transparent = 0, opaque = 255).
local color_darkness = {220, 140, 0} -- Used for full darkness.
local max_num_grains_sand, max_num_grains_sandstorm = 50, 200
local grain_min_opacity, grain_max_opacity = 50, 255
local sx, sy = 0, 0 -- Scrolling shifts for grain positions.

-- Main variables.
local sand_surface, dark_surface, grain_surface
local grain_list, splash_list, timers, num_grains, num_splashes
local current_game, current_map, current_sand_mode, previous_sand_mode
local previous_world, current_world, is_scrolling

-- Get/set current sand mode in the current map.
function game_meta:get_sand_mode() return current_sand_mode end
function game_meta:set_sand_mode(sand_mode)
  previous_world = current_world
  sand_manager:start_sand_mode(sand_mode)
end
-- Get/set the sand mode for a given world.
function game_meta:get_world_sand_mode(world)
  return world and self:get_value("sand_mode_" .. world) or nil
end
function game_meta:set_world_sand_mode(world, sand_mode)
  self:set_value("sand_mode_" .. world, sand_mode)
  if current_world == world then self:set_sand_mode(sand_mode) end
end

-- Initialize sand manager.
game_meta:register_event("on_started", function(game)
  current_game = game
  sand_manager:on_created()
end)
-- Initialize sand on maps when necessary.
game_meta:register_event("on_map_changed", function(game)
  sand_manager:on_map_changed(game:get_map())
end)
-- Allow to draw surfaces (it uses the event "game.on_draw").
game_meta:register_event("on_draw", function(game, dst_surface)
  sand_manager:on_draw(dst_surface)
end)

-- Create sand and dark surfaces.
function sand_manager:on_created()
  -- Create surfaces.
  local w, h = sol.video.get_quest_size()
  sand_surface = sol.surface.create(w, h)
  dark_surface = sol.surface.create(w, h)
  sand_surface:set_blend_mode("add")
  dark_surface:set_blend_mode("add")
  grain_surface = sol.surface.create(8, 8)
  -- Initialize main variables.
  current_sand_mode, previous_sand_mode, previous_world = nil, nil, nil
  num_grains, num_splashes, current_darkness = 0, 0, 0
  grain_list, splash_list, timers = {}, {}, {}
  local num_slots = math.max(max_num_grains_sand, max_num_grains_sandstorm)
  for i = 0, num_slots - 1 do  
    grain_list[i] = {index = i}
    splash_list[i] = {index = i}
  end
  -- Add scrolling feature with teletransporters.
  self:initialize_scrolling_feature()
end

-- Update current_sand_mode and current_map variables.
function sand_manager:on_map_changed(map)
  local world = map:get_world()
  current_map = map
  previous_world = current_world
  current_world = world
  local sand_mode = current_game:get_world_sand_mode(world)
  self:start_sand_mode(sand_mode)
  if is_scrolling then self:finish_scrolling() end
end

-- Draw surfaces of the sand manager.
function sand_manager:on_draw(dst_surface)
  if current_sand_mode == nil then
    if previous_sand_mode == nil or previous_world ~= current_world then
      return
    end
  end
  -- Draw surfaces on the current map if necessary.
  if sand_surface and (num_grains > 0 or num_splashes > 0) then
    self:update_sand_surface()
    sand_surface:draw(dst_surface)
  end
  if dark_surface and current_darkness > 0 then
    dark_surface:draw(dst_surface)
  end
end

-- Draw sandgrain or splash on a surface with its properties (Opacity = 0 means transparent).
function sand_manager:draw_grain(dst_surface, x, y, grain, animation)
  grain_sprite:set_animation(animation)
  grain_sprite:set_direction(grain.direction or 0)
  grain_sprite:set_frame(grain.frame or 0)
  grain_surface:clear()
  grain_sprite:draw(grain_surface)
  grain_surface:set_opacity(grain.opacity)
  grain_surface:draw(dst_surface, x, y)
end

-- Update sand surface.
function sand_manager:update_sand_surface()
  if current_sand_mode == nil and previous_sand_mode == nil then
    return
  end
  sand_surface:clear()
  local camera = current_map:get_camera()
  local cx, cy, cw, ch = camera:get_bounding_box()
  -- Draw grains on surface.
  for _, grain in pairs(grain_list) do
    if grain.exists then
      local x = (grain.init_x + grain.x - cx + sx) % cw
      local y = (grain.init_y + grain.y - cy + sy) % ch
      self:draw_grain(sand_surface, x, y, grain, "grain")
    end
  end
  -- Draw splashes on surface.
  for _, splash in pairs(splash_list) do
    if splash.exists then
      local x = (splash.x - cx + sx) % cw
      local y = (splash.y - cy + sy) % ch
      self:draw_grain(sand_surface, x, y, splash, "grain_splash")
    end
  end
end

-- Create properties list for a new water grain at random position.
function sand_manager:create_grain(deviation)
  -- Prepare next slot.
  local max_num_grains = max_num_grains_sand
  if current_sand_mode == "sandstorm" then max_num_grains = max_num_grains_sandstorm end
  local index, grain = 0, grain_list[0]
  while index < max_num_grains and grain.exists do
    index = index + 1
    grain = grain_list[index]
  end
  if grain == nil or grain.exists then return end
  -- Set properties for new grain.
  local map = current_map
  local cx, cy, cw, ch = map:get_camera():get_bounding_box()
  grain.init_x = cx + cw * math.random()
  grain.init_y = cy + ch * math.random()
  grain.x, grain.y, grain.frame = 0, 0, 0
  grain.speed = (current_sand_mode == "sand") and sand_speed or sandstorm_speed
  local num_dir = grain_sprite:get_num_directions("grain")
  grain.direction = math.random(0, num_dir - 1) -- Sprite direction.
  local inverted_angle = (math.random(0,1) == 1)
  grain.angle = 7 * math.pi / 5 + (deviation or 0)
  if inverted_angle then grain.angle = math.pi - grain.angle end
  grain.max_distance = math.random(grain_min_distance, grain_max_distance)
  grain.zigzag_dist = math.random(grain_min_zigzag_distance, grain_max_zigzag_distance)
  grain.opacity = 255
  grain.target_opacity = math.random(grain_min_opacity, grain_max_opacity)
  num_grains = num_grains + 1
  grain.exists = true
end

-- Create splash effect and put it in the list.
function sand_manager:create_splash(index)
  -- Diable associated grain.
  local grain = grain_list[index]
  num_grains = num_grains - 1
  -- Do nothing if there is no space for a new splash.
  local splash = splash_list[index]
  if splash.exists then return end
  -- Create splash.
  splash.x = grain.init_x + grain.x
  splash.y = grain.init_y + grain.y
  splash.opacity = grain.opacity
  num_splashes = num_splashes + 1
  splash.exists = true
end

-- Destroy the timers whose names appear in the list.
function sand_manager:stop_timers(timers_list)
  for _, key  in pairs(timers_list) do
    local t = timers[key]
    if t then t:stop() end
    timers[key] = nil
  end
end

-- Start a sand mode in the current map.
function sand_manager:start_sand_mode(sand_mode)
  -- Update sand modes.
  previous_sand_mode = current_sand_mode
  current_sand_mode = sand_mode
  -- Stop creating grains (timer delays differ on each mode).
  self:stop_timers({"grain_creation_timer"})
  -- Update darkness (fade-out effects included).
  self:update_darkness()
  -- Nothing more to do if there is no sand.
  if sand_mode == nil then return end
  --Initialize grain parameters (used by "sand_manager.create_grain").
  local game = current_game
  local current_grain_delay
  if sand_mode == "sand" then current_grain_delay = sand_grain_delay
  elseif sand_mode == "sandstorm" then current_grain_delay = sandstorm_grain_delay
  elseif sand_mode ~= nil then error("Invalid sand mode.") end
  -- Initialize grain creation timer.
  timers["grain_creation_timer"] = sol.timer.start(game, current_grain_delay, function()
    -- Random angle deviation in case of sandstorm.
    local grain_deviation = 0
    if sand_mode == "sandstorm" then
      grain_deviation = math.random(-1, 1) * math.random() * math.pi / 8
    end
    sand_manager:create_grain(grain_deviation)
    return true -- Repeat loop.
  end)
  -- Initialize grain position timer.
  if timers["grain_position_timer"] == nil then
    local dt = 10 -- Timer delay.
    timers["grain_position_timer"] = sol.timer.start(game, dt, function()
      for index, grain in pairs(grain_list) do
        if grain.exists then
          local distance_increment = grain.speed * (dt / 1000)
          grain.x = grain.x + distance_increment * math.cos(grain.angle)
          grain.y = grain.y + distance_increment * math.sin(grain.angle) * (-1)
          local distance = math.sqrt((grain.x)^2 + (grain.y)^2)
          if distance > grain.zigzag_dist then
            local d = math.random(grain_min_zigzag_distance, grain_max_zigzag_distance)
            grain.zigzag_dist = grain.zigzag_dist + d
            grain.angle = math.pi - grain.angle -- Reflected angle.
          end      
          if distance >= grain.max_distance then
            -- Disable grain and create grain splash.
            grain.exists = false
            sand_manager:create_splash(index)
          end
        end
      end
      return true
    end)
  end
  -- Update sand frames for all grains at once.
  if timers["grain_frame_timer"] == nil then
    timers["grain_frame_timer"] = sol.timer.start(game, 250, function()
      for _, grain in pairs(grain_list) do
        if grain.exists then
          grain.frame = (grain.frame + 1) % 4
        end
      end
      return true
    end)
  end
  -- Update splash frames for all splashes at once.
  if timers["grain_opacity_timer"] == nil then
    timers["grain_opacity_timer"] = sol.timer.start(game, 10, function()
      for _, grain in pairs(grain_list) do
        if grain.exists then
          -- Modify opacity towards the target opacity.
          if grain.opacity == grain.target_opacity then
            grain.target_opacity = math.random(grain_min_opacity, grain_max_opacity)
          else
            local d = (grain.opacity < grain.target_opacity) and 1 or -1
            grain.opacity = grain.opacity + d
          end
        end
      end
      for _, splash in pairs(splash_list) do
        if splash.exists then
          -- Disable splash when transparent.
          splash.opacity = math.max(0, splash.opacity - 1)
          if splash.opacity == 0 then
            splash.exists = false
            num_splashes = num_splashes - 1
          end
        end
      end
      return true
    end)
  end
  -- Do not suspend sand when paused.
  timers["grain_creation_timer"]:set_suspended_with_map(false)
  timers["grain_position_timer"]:set_suspended_with_map(false)
  timers["grain_frame_timer"]:set_suspended_with_map(false)
  timers["grain_opacity_timer"]:set_suspended_with_map(false)
end

-- Fade in/out dark surface for sandstorm mode. Parameter (opacity) is optional.
function sand_manager:update_darkness()
  -- Define next darkness value.
  local darkness = 0
  if current_sand_mode == "sand" then
    darkness = sand_darkness
  elseif current_sand_mode == "sandstorm" then
    darkness = sandstorm_darkness
  end
  local d = 0 -- Increment/decrement for opacity.
  if darkness > current_darkness then d = 1
  elseif darkness < current_darkness then d = -1 end
  self:stop_timers({"darkness_timer"}) -- Destroy old timer.
  -- Start modifying darkness towards the next value.
  timers["darkness_timer"] = sol.timer.start(current_game, 40, function()
    if dark_surface == nil then return end
    current_darkness = current_darkness + d
    local r = math.floor(color_darkness[1] * (current_darkness / 255))
    local g = math.floor(color_darkness[2] * (current_darkness / 255))
    local b = math.floor(color_darkness[3] * (current_darkness / 255))
    dark_surface:clear()
    dark_surface:fill_color({r, g, b})
    if darkness == current_darkness then -- Darkness reached.
      return false
    end
    return true -- Keep modifying darkness value.
  end)
  timers["darkness_timer"]:set_suspended_with_map(false)
end

-- Add scrolling features to teletransporters.
function sand_manager:initialize_scrolling_feature()
  local tele_meta = sol.main.get_metatable("teletransporter")
  tele_meta:register_event("on_activated", function(tele)
    local dir = tele:get_scrolling_direction()
    if dir then sand_manager:start_scrolling(dir) end
  end)
end

-- Start scrolling feature: shift 5 pixels each 10 milliseconds (like the engine).
function sand_manager:start_scrolling(direction)
  is_scrolling = true
  local dx = {[0] = -1, [1] = 0, [2] = 1, [3] = 0}
  local dy = {[0] = 0, [1] = -1, [2] = 0, [3] = 1}
  dx, dy = dx[direction], dy[direction]
  self:stop_timers({"scrolling"}) -- Needed in case of consecutive teleportation.
  timers["scrolling"] = sol.timer.start(current_game, 10, function()
    sx, sy = sx + 5 * dx, sy - 5 * dy
    if is_scrolling then return true
    else timers["scrolling"] = nil end
  end)
  timers["scrolling"]:set_suspended_with_map(false)
end
-- Stop scrolling feature.
function sand_manager:finish_scrolling()
  local map = current_map
  map:register_event("on_opening_transition_finished", function(map)
    is_scrolling = false
  end)
end

-- Return sand manager.
return sand_manager