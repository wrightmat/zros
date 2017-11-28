local entity = ...
local game = entity:get_game()
sol.main.load_file("entities/generic_animal")(entity)

-- Animal Description...

function entity:on_created()
  entity:on_generic_created()
end