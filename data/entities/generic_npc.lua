local entity = ...

local game = entity:get_game()
local map = entity:get_game():get_map()
local hero = game:get_map():get_entity("hero")
local name_display = string.sub(entity:get_name(), 5):gsub("^%l", string.upper):gsub("_", " ")
local font, font_size = sol.language.get_dialog_font()
local path_x, path_y
local dialog = nil
local can_converse = true

-- Generic NPC script which prevents the hero from being stuck
-- behind non-traversable moving characters (primarily for intro).

function random_walk()
  local m = sol.movement.create("random_path")
  m:set_ignore_obstacles(false)
  m:set_speed(32)
  m:start(entity)
  entity:get_sprite():set_animation("walking")
end

function follow_hero()
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

function follow_path(entity, dest, callback)
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

function select_dialog(entity)
  -- Load all available dialog for this NPC (both known defaults and learned).
  local dialogs = stringToTable(game:get_value(entity:get_name() .. "_dialogs"))
  
  -- Select a particular dialog at random, then do checks as needed to see if it should display.
  dialog = dialogs[math.random(#dialogs)]
  
  if game:get_dialog_property("var_require", dialog) then
    -- If there's a dialog requirement and it's not met, select a new dialog
    if not game:get_value(game:get_dialog_property("var_require", dialog)) then select_dialog(entity) end
  end
  if game:get_dialog_property("var_exclude", dialog) then
    -- If there's a dialog exclusion and it IS met, select a new dialog
    if game:get_value(game:get_dialog_property("var_exclude", dialog)) then select_dialog(entity) end
  end
  return dialog
end

function entity:on_generic_created()
  self.action_effect = "speak"
  self:set_drawn_in_y_order(true)
  self:set_can_traverse("hero", false)
  self:set_traversable_by("hero", false)
  -- Don't allow NPC to traverse other NPCs when moving.
  self:set_traversable_by("npc", false)
  self:set_traversable_by("custom_entity", false)
  
  sol.timer.start(self, 1000, function()
    -- If too close to the hero (and moving), become traversable so as not to trap hero in a corner.
    if self:get_movement() ~= nil then
      local _, _, layer = self:get_position()
      local _, _, hero_layer = map:get_hero():get_position()
      local near_hero = layer == hero_layer and self:get_distance(hero) < 17
      if near_hero then
        self:set_traversable_by("hero", true)
      else
        self:set_traversable_by("hero", false)
      end
    end
    return true
  end)
end

function entity:on_generic_interaction()
  -- Have NPC face hero and speak. Also show name above dialog if it's known.
  if game:get_value(entity:get_name() .. "_known") then
    game:set_dialog_name(name_display)
  end 
  entity:get_sprite():set_direction(entity:get_direction4_to(hero))
  local dialog = select_dialog(entity)
  game:start_dialog(dialog)
    -- Make NPC known if the dialog allows it and they weren't before.
    if game:get_dialog_property("known") then
      if not game:get_value(entity:get_name() .. "_known") then game:set_value(entity:get_name() .. "_known", true) end
    end
    -- Change variable if needed (boolean true or increment integer).
    if game:get_dialog_property("var_boolean") then
      game:set_value(game:get_dialog_property("var_boolean"), true) end
    if game:get_dialog_property("var_integer") then
      game:set_value(game:get_dialog_property("var_integer"), game:get_dialog_property("var_integer") + 1) end
end

function entity:on_post_draw()
  -- Draw the NPC's name above the entity if it's known.
  if game:get_value(entity:get_name() .. "_known") then
    local name_surface = sol.text_surface.create({ font = font, font_size = 8, text = name_display })
    local x, y, l = entity:get_position()
    local w, h = entity:get_sprite():get_size()
    if self:get_distance(hero) < 100 then
      map:draw_visual(name_surface, x-(w/2), y-(h-4))
    end
  end
end

function entity:on_movement_changed(movement)
  local direction = movement:get_direction4()
  entity:get_sprite():set_direction(direction)
end

function entity:on_obstacle_reached(movement)
  entity:add_collision_test("touching", function(self, other)
    if can_converse and other:get_type() == "custom_entity" and string.sub(other:get_name(), 1, 4) == "npc_" then
      -- Stop each character, storing their movements to resume later.
      can_converse = false
      if entity:get_movement() then
        m1 = entity:get_movement(); m1:stop(); entity:get_sprite():set_animation("stopped") end
      if other:get_movement() then
        m2 = other:get_movement(); m2:stop(); other:get_sprite():set_animation("stopped") end
      
      -- Put a sprite above the characters to indicate they're conversing.
      local ex, ey, el = entity:get_position()
      local talking_sprite = map:create_npc( { layer = 1, x = ex-6, y = ey-24, sprite = "entities/quest_bubble", direction = 0, subtype = 0 } )
      -- Wait 4 seconds before starting this process because it finishes so quickly and the player can't tell anything happened!
      sol.timer.start(game, 4000, function()
        -- Parse other character's dialogs to see if there's something this NPC can learn (if he has memory left).
        local dialogs = game:get_value(entity:get_name() .. "_dialogs")
        if #stringToTable(dialogs) < game:get_value(entity:get_name() .. "_memory") then
          local other_dialogs = stringToTable(game:get_value(other:get_name() .. "_dialogs"))
          local unique_dialogs = {}
          for i = 1, #other_dialogs do
            if not string.match(dialogs, other_dialogs[i]) then
              local other_dialog = sol.language.get_dialog(other_dialogs[i])
              if other_dialog.inheritance and (other_dialog.inheritance + 0) >= 1 then
                table.insert(unique_dialogs, other_dialogs[i])
              end
            end
          end
          for i = 1, #unique_dialogs do
            local other_dialog = sol.language.get_dialog(unique_dialogs[i])
            if (other_dialog.importance + 0) == 5 then
              dialog_to_learn = unique_dialogs[i]
            elseif (other_dialog.importance + 0) == 4 and (not dialog_to_learn or sol.language.get_dialog(dialog_to_learn).importance < 4) then
              dialog_to_learn = unique_dialogs[i]
            elseif (other_dialog.importance + 0) <= 3 and not dialog_to_learn then
              dialog_to_learn = unique_dialogs[i]
            end
          end
          if dialog_to_learn ~= nil then
            game:set_value(entity:get_name() .. "_dialogs", dialogs .. dialog_to_learn .. ",")
          end
        else
          -- TODO:
          -- This entity has no memory: If other_entity has dialogs that are importance 4 or greater and are inheritable then
            -- Replace an inheritable dialog of this entity of lesser importance with one of greater importance from other_entity (5 more likely than 4)
        end
        
        -- After conversing, NPCs resume their normal routine (and can't talk for another 10 seconds to prevent pile ups).
        -- TODO: Figure out why the characters jump around when the movement is resumed - am I doing something wrong or an engine bug?
        talking_sprite:remove()
        m1:start(entity); entity:get_sprite():set_animation("walking")
        m2:start(other); other:get_sprite():set_animation("walking")
      end)
      sol.timer.start(game, 20000, function() can_converse = true end)
    end
  end)
end