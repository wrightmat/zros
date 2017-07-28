local enemy = ...
local behavior = require("enemies/generic/lizalfos")

-- Lizalfos (Red, fire).

local properties = {
  main_sprite = "enemies/lizalfos_red",
  life = 8,
  damage = 8,
  normal_speed = 48,
  faster_speed = 72,
  treasure_variant = 2
}

behavior:create(enemy, properties)