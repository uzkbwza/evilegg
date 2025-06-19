local ExplosionRadiusWarning = GameObject2D:extend("ExplosionRadiusWarning")

function ExplosionRadiusWarning:new(x, y, radius, parent)
    ExplosionRadiusWarning.super.new(self, x, y)
    self.radius = radius
	self:ref("parent", parent)
	self.z_index = -1
	self:add_time_stuff()
	self.random_offset = rng:randi(0, 100)
end

function ExplosionRadiusWarning:update(dt)
    if self.parent then
        self:move_to(self.parent:get_body_center())
    else
		self:queue_destroy()
	end
end

function ExplosionRadiusWarning:draw()
	if not self.parent then return end
    graphics.rotate(self.elapsed * 0.05)
	-- if iflicker(gametime.tick + self.random_offset, 1, 3) then
		self:draw_circ((self.elapsed + self.random_offset) % self.radius, 2, "line")
		self:draw_circ(self.radius, 1, self.parent.about_to_explode and "fill" or "line")
		-- self:draw_circ(self.radius - 2, 1)
	-- end
end

function ExplosionRadiusWarning:draw_circ(radius, thickness, fill_type)
	if radius < 1 then return end
	graphics.set_line_width(thickness * 2)
    graphics.set_color(Color.black)
	graphics.ellipse(fill_type, 0, 0, radius, radius * 1, 10)
    graphics.set_line_width(thickness)
	if self.parent.about_to_explode then
		graphics.set_color(Color.yellow)
	else
		graphics.set_color(iflicker(gametime.tick + self.random_offset, 4, 2) and Color.orange or Color.red)
	end
	graphics.ellipse(fill_type, 0, 0, radius, radius * 1, 10)
end

return ExplosionRadiusWarning
