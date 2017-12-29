local collectibles = {
  collectible_display_count = 0
}

function collectibles:new(game)
  local object = {}
  setmetatable(object, self)
  self.__index = self
  
  self.game = game
  
  -- Display an item that was just collected
  function game:show_collectible(sprite, text, seconds)
    sol.menu.start(self, collectibles, false)
    collectibles:display_collectible(sprite, text, seconds)
  end
  
  return object
end

function collectibles:display_collectible(sprite, text, seconds)
  self.surface = sol.surface.create(120, 15)
  self.surface:fill_color({0, 0, 0, 230})
  self.surface:set_xy(100, 15*self.collectible_display_count)
  self.collectible_display_count = self.collectible_display_count + 1
  
  local i = 0
  local language = sol.language.get_language()
  local font = language == "jp" and "wqy-zenhei" or "minecraftia"
  local size = language == "jp" and 12 or 8
  
  self.text = sol.text_surface.create({
    vertical_alignement = "middle",
    horizontal_alignement = "left",
    font = font,
    font_size = size,
  })
  
  -- Format the text.
  for line in text:gmatch("[^$]+") do
    i = i + 1
    if i > 1 then self.text:set_font_size(6) end
    self.text:set_text(line)
    self.text:draw(self.surface, 20, 7 + ((i - 1) * 8))
  end
  
  if sprite ~= nil then
    sprite:draw(self.surface, 8, 14 + ((i - 1) * 8))
  end
  
  self.surface:fade_in(5)
  local movement = sol.movement.create("straight")
  movement:set_angle(2 * math.pi / 2)
  movement:set_speed(400)
  movement:set_max_distance(110)
  movement:start(self.surface, function()
    sol.timer.start(seconds, function()
      if self.surface ~= nil then
        self.surface:fade_out(seconds/2, function()
          self.text:set_text(nil)
          self.surface = nil
        end)
      end
    end)
  end)
  sol.timer.start(seconds*20, function()
    if self.collectible_display_count > 0 then
      self.collectible_display_count = self.collectible_display_count - 1
    end
  end)
end

function collectibles:on_draw(dst)
  if not self.game:is_paused() and self.surface ~= nil then
    self.surface:draw(dst, 210, 60)
  end
end

return collectibles