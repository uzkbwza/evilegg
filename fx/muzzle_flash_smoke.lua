local MuzzleFlashSmoke = Effect:extend("MuzzleFlashSmoke")

function MuzzleFlashSmoke:new(x, y, duration, size, palette, speed, dir_x, dir_y, offset_distance)
	MuzzleFlashSmoke.super.new(self, x, y)
	self.duration = duration * rng:randfn(1.0, 0.15)
	self.size = size
	self.z_index = 0.5
	self.speed = speed or 0.5
	self.palette = palette or Palette.muzzle_flash_smoke
	self.offset = rng:randi()
	self.offset_x, self.offset_y = rng:randfn(0, size / 8), rng:randfn(0, size / 8)
	self.dir_x, self.dir_y = vec2_rotated(dir_x or 0, dir_y or 0, angle_diff(vec2_angle(self.offset_x, self.offset_y), vec2_angle(dir_x, dir_y)) * 0.25)
	self.offset_distance = offset_distance or 0
end

function MuzzleFlashSmoke:draw(elapsed, tick, t)
	local scale = lerp(self.size, 0, t)
	graphics.set_color(self.palette:interpolate_clamped(t))
	local t2 = ease("outQuad")(t)
	local offset_x = self.offset_x + self.dir_x * lerp(0, self.offset_distance, t2)
	local offset_y = self.offset_y + self.dir_y * lerp(0, self.offset_distance, t2)
	-- if self.rotated then
	-- 	graphics.rotate(tau/8)
	-- end
	graphics.rectangle_centered(t < 0.75 and "fill" or "line", offset_x, -elapsed * self.speed + offset_y, scale, scale)
	graphics.set_color(self.palette:get_color_clamped(self.palette:interpolate_index(t) + 1))
	-- if t < 0.75 then
	graphics.rectangle_centered("fill", offset_x, -elapsed * self.speed + offset_y + scale / 2 - scale / 8, scale, scale / 4)
	-- end
end

return MuzzleFlashSmoke
