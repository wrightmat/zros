local enemy = ...
local behavior = require("enemies/generic/keese")

-- Keese (bat): Basic flying enemy.

local properties = {
  sprite = "enemies/keese",
  life = 1,
  damage = 2,
  normal_speed = 56,
  faster_speed = 64,
  treasure_variant = 0
}
behavior:create(enemy, properties)