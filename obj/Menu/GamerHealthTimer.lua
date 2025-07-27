local GamerHealthTimer = GameObject2D:extend("GamerHealthTimer")

function GamerHealthTimer:new(x, y, width, height)
    GamerHealthTimer.super.new(self, x, y)
    self.width = width
    self.height = height
    self.z_index = 1000
end

function GamerHealthTimer:draw()
    graphics.set_font(fonts.depalettized.image_font2)
    graphics.set_color(Color.black)
    graphics.rectangle_centered("fill", self.width / 2, ceil(self.height / 2), self.width + 2, 4)
    graphics.set_color(Color.magenta)
    graphics.rectangle_centered("fill", self.width / 2, ceil(self.height / 2), self.width, 2)
    graphics.set_color(Color.magenta)
    graphics.print_centered(tostring(savedata:get_seconds_until_retry_cooldown_is_over()), fonts.depalettized.image_font2, self.width / 2, self.height / 2)
end

function GamerHealthTimer:update(dt)
    if savedata:get_seconds_until_retry_cooldown_is_over() <= 0 then
        self:queue_destroy()
    end
end

return GamerHealthTimer
