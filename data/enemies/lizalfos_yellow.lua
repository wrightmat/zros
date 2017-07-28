local enemy = ...
local behavior = require("enemies/generic/lizalfos")

-- Lizalfos (Yellow, electric).

local properties = {
  main_sprite = "enemies/lizalfos_yellow",
  life = 10,
  damage = 8,
  normal_speed = 48,
  faster_speed = 72,
  treasure_variant = 4
}

behavior:create(enemy, properties)