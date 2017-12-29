local enemy = ...
local map = enemy:get_map()
sol.main.load_file("entities/generic_animal")(enemy)

-- Dog

function enemy:on_created()
  self:set_life(3); self:set_damage(1)
  self:create_sprite("animals/dog")
  self:set_size(16, 16); self:set_origin(8, 13)
  self:on_generic_created()
end