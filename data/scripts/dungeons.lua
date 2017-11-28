-- Define the existing dungeons and their floors for the minimap menu.

local dungeons = {
  [1] = {
    floor_width = 2256,
    floor_height = 2256,
    lowest_floor = -1,
    highest_floor = 0,
    maps = { "201", "202" },
    boss = {
      floor = 0,
      x = 2032,
      y = 536,
      savegame_variable = "b1046",
    },
  },
  [2] = {
    floor_width = 2032,
    floor_height = 1760,
    lowest_floor = 0,
    highest_floor = 0,
    maps = { "203" },
    boss = {
      floor = 0,
      x = 1130,
      y = 30,
      savegame_variable = "b1058",
    },
  },
  [3] = {
    floor_width = 2032,
    floor_height = 1760,
    lowest_floor = 0,
    highest_floor = 0,
    maps = { "204" },
    boss = {
      floor = 0,
      x = 824,
      y = 1024,
      savegame_variable = "b1079",
    },
  },
  [4] = {
    floor_width = 1696,
    floor_height = 1760,
    lowest_floor = 0,
    highest_floor = 0,
    maps = { "205" },
    boss = {
      floor = 0,
      x = 1528,
      y = 160,
      savegame_variable = "b1110",
    },
  },
  [5] = {
    floor_width = 2032,
    floor_height = 1600,
    lowest_floor = -1,
    highest_floor = 0,
    maps = { "206", "207" },
    boss = {
      floor = -1,
      x = 416,
      y = 1192,
      savegame_variable = "b1131",
    },
  },
  [6] = {
    floor_width = 1024,
    floor_height = 1760,
    lowest_floor = -2,
    highest_floor = -1,
    maps = { "208", "209" },
    boss = {
      floor = -2,
      x = 232,
      y = 312,
      savegame_variable = "b1147",
    },
  },
  [7] = {
    floor_width = 912,
    floor_height = 800,
    lowest_floor = 0,
    highest_floor = 7,
    maps = { "210", "211", "212", "213", "214", "215", "216", "217" },
    boss = {
      floor = 7,
      x = 448,
      y = 184,
      savegame_variable = "b1110",
    },
  },
  [8] = {
    floor_width = 2032,
    floor_height = 1760,
    lowest_floor = -1,
    highest_floor = 0,
    maps = { "218", "219" },
    boss = {
      floor = 0,
      x = 880,
      y = 180,
      savegame_variable = "b1191",
    },
  },
}
local game_meta = sol.main.get_metatable("game")

-- Returns the index of the current dungeon if any, or nil.
game_meta:register_event("get_dungeon_index", function(game)
  local map = game:get_map()
  local world = map:get_world()
  local index = tonumber(world:match("^dungeon_([0-9]+)$"))
  -- Special case for Sacred Grove Temple since it's indoor and outdoor - return to world map when dungeon is complete.
  if game:is_dungeon_finished(2) and (map:get_id() == "20" or map:get_id() == "21" or map:get_id() == "22") then
    return nil
  else
    return index
  end
end)

-- Returns the current dungeon if any, or nil.
game_meta:register_event("get_dungeon", function(game)
  local index = game:get_dungeon_index()
  return dungeons[index]
end)

game_meta:register_event("is_dungeon_finished", function(game, dungeon_index)
  return game:get_value("dungeon_" .. dungeon_index .. "_finished")
end)

game_meta:register_event("set_dungeon_finished", function(game, dungeon_index, finished)
  if finished == nil then finished = true end
  game:set_value("dungeon_" .. dungeon_index .. "_finished", finished)
end)

game_meta:register_event("has_dungeon_map", function(game, dungeon_index)
  dungeon_index = dungeon_index or game:get_dungeon_index()
  return game:get_value("dungeon_" .. dungeon_index .. "_map")
end)

game_meta:register_event("has_dungeon_compass", function(game, dungeon_index)
  dungeon_index = dungeon_index or game:get_dungeon_index()
  return game:get_value("dungeon_" .. dungeon_index .. "_compass")
end)

game_meta:register_event("has_dungeon_big_key", function(game, dungeon_index)
  dungeon_index = dungeon_index or game:get_dungeon_index()
  return game:get_value("dungeon_" .. dungeon_index .. "_big_key")
end)

game_meta:register_event("has_dungeon_boss_key", function(game, dungeon_index)
  dungeon_index = dungeon_index or game:get_dungeon_index()
  return game:get_value("dungeon_" .. dungeon_index .. "_boss_key")
end)

-- Returns the name of the boolean variable that stores the exploration of dungeon room, or nil.
game_meta:register_event("get_explored_dungeon_room_variable", function(game, dungeon_index, floor, room)
  dungeon_index = dungeon_index or game:get_dungeon_index()
  room = room or 1

  if floor == nil then
    if game:get_map() ~= nil then
      floor = game:get_map():get_floor()
    else
      floor = 0
    end
  end

  local room_name
  if floor >= 0 then
    room_name = tostring(floor + 1) .. "f_" .. room
  else
    room_name = math.abs(floor) .. "b_" .. room
  end

  return "dungeon_" .. dungeon_index .. "_explored_" .. room_name
end)

-- Returns whether a dungeon room has been explored.
game_meta:register_event("has_explored_dungeon_room", function(game, dungeon_index, floor, room)
  return game:get_value(
    game:get_explored_dungeon_room_variable(dungeon_index, floor, room)
  )
end)

-- Changes the exploration state of a dungeon room.
game_meta:register_event("set_explored_dungeon_room", function(game, dungeon_index, floor, room, explored)
  if explored == nil then explored = true end
  game:set_value(
    game:get_explored_dungeon_room_variable(dungeon_index, floor, room), explored
  )
end)

-- Returns whether the current map is in a dungeon.
game_meta:register_event("is_in_dungeon", function(game)
  return game:get_dungeon() ~= nil
end)