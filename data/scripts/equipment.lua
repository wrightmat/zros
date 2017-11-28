local equipment = {}

local game_meta = sol.main.get_metatable("game")

-- Returns whether a small key counter exists on the current map.
game_meta:register_event("are_small_keys_enabled", function(game)
  return game:get_small_keys_savegame_variable() ~= nil
end)

-- Returns the name of the integer variable that stores the number
-- of small keys for the current map, or nil.
game_meta:register_event("get_small_keys_savegame_variable", function(game)
  local map = game:get_map()
  if map ~= nil then
    -- Does the map explicitly define a small key counter?
    if map.small_keys_savegame_variable ~= nil then
      return map.small_keys_savegame_variable
    end
    -- Are we in a dungeon?
    local dungeon_index = game:get_dungeon_index()
    if dungeon_index ~= nil then
      return "dungeon_" .. dungeon_index .. "_small_keys"
    end
  end

  -- No small keys on this map.
  return nil
end)

-- Returns whether the player has at least one small key.
-- Raises an error if small keys are not enabled in the current map.
game_meta:register_event("has_small_key", function(game)
  return game:get_num_small_keys() > 0
end)

-- Returns the number of small keys of the player.
-- Raises an error is small keys are not enabled in the current map.
game_meta:register_event("get_num_small_keys", function(game)
  if not game:are_small_keys_enabled() then
    error("Small keys are not enabled in the current map")
  end
  local savegame_variable = game:get_small_keys_savegame_variable()
  return game:get_value(savegame_variable) or 0
end)

-- Adds a small key to the player.
-- Raises an error is small keys are not enabled in the current map.
game_meta:register_event("add_small_key", function(game)
  if not game:are_small_keys_enabled() then
    error("Small keys are not enabled in the current map")
  end
  local savegame_variable = game:get_small_keys_savegame_variable()
  game:set_value(savegame_variable, game:get_num_small_keys() + 1)
end)

-- Removes a small key from the player.
-- Raises an error is small keys are not enabled in the current map
-- or if the player has no small keys.
game_meta:register_event("remove_small_key", function(game)
  if not game:has_small_key() then
    error("The player has no small key")
  end
  local savegame_variable = game:get_small_keys_savegame_variable()
  game:set_value(savegame_variable, game:get_num_small_keys() - 1)
end)

-- Returns a bottle with the specified content, or nil.
game_meta:register_event("get_first_bottle_with", function(game, variant)
  for i = 1, 4 do
    local item = game:get_item("bottle_" .. i)
    if item:get_variant() == variant then return item end
  end
  return nil
end)

game_meta:register_event("get_first_empty_bottle", function(game)
  return game:get_first_bottle_with(1)
end)

game_meta:register_event("has_bottle", function(game)
  for i = 1, 4 do
    if game:has_item("bottle_" .. i) then return true end
  end
  return false
end)

game_meta:register_event("has_bottle_with", function(game, variant)
  return game:get_first_bottle_with(variant) ~= nil
end)

return equipment