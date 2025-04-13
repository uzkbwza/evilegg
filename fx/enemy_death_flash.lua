local DEATH_FX_POWER = 1.4
local DEATH_FX_DISTANCE = 3

local BASE_SIZE = 7

local DRAG = 0.15

local PIXEL_COUNT = 10
local SPEED = 5.0

local DeathFlash = Effect:extend("DeathFlash")

-- TODO: use quads instead of pixels
function DeathFlash:new(x, y, texture, size_mod, palette, palette_tick_length, use_grey_pixels)
	DeathFlash.super.new(self, x, y)
	-- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
    self.duration = 30
	self.reversed = false	

	local width, height = 0, 0
    local offset_x, offset_y = 0, 0

	if texture.__isquad then
		width, height = texture.width, texture.height
		offset_x, offset_y = texture.x, texture.y
		texture = texture.texture
	else
		width, height = texture:getPixelWidth(), texture:getPixelHeight()
		offset_x, offset_y = 0, 0
	end
	self.width = width
	self.height = height
	self.start_tick = gametime.tick
    local data = graphics.texture_data[texture]


    local true_start_x, true_start_y = math.huge, math.huge
    local true_end_x, true_end_y = 0, 0
	
	for y_ = 0, height - 1 do
		for x_ = 0, width - 1 do
            local r, g, b, a = data:getPixel(x_ + offset_x, y_ + offset_y)
            if a == 0 then goto continue end
            if x_ < true_start_x then true_start_x = x_ end
			if y_ < true_start_y then true_start_y = y_ end
			if x_ > true_end_x then true_end_x = x_ end
			if y_ > true_end_y then true_end_y = y_ end
			::continue::
		end
	end

    self.size_mod = (max(width, height) / BASE_SIZE) * (size_mod or 1)
    local true_width, true_height = true_end_x - true_start_x + 1, true_end_y - true_start_y + 1

	self.size_ratio = true_height / true_width

	local pixels = {}

    if use_grey_pixels == nil then
		use_grey_pixels = true
	end

	self.pixel_count = 0

    if use_grey_pixels then
		self.pixel_count = PIXEL_COUNT * self.size_mod

		for i = 1, self.pixel_count do
			local vel_x, vel_y = rng.random_vec2()
			vel_x = vel_x * SPEED * self.size_mod * rng.randfn(0.5, 0.15)
			vel_y = vel_y * SPEED * self.size_mod * rng.randfn(0.5, 0.15)
			

			local darkergrey = Color.darkergrey
			local alpha = clamp(rng.randfn(darkergrey.r, 0.25), 0.00, darkergrey.r)
			local pixel = {
				x = vel_x * 0.25,
				y = vel_y * 0.25,
				vel_x = vel_x,
				vel_y = vel_y,
				radius = rng.randfn(1, 0.5) / 2,
				color = Color(alpha, alpha, alpha)
			}
			pixels[i] = pixel
		end
	end

	self.pixels = pixels
    self.z_index = 0.1
	self:start_timer("z_index", 10, function()
		self.z_index = -100
	end)
	self.palette = palette
    self.palette_tick_length = palette_tick_length
	self.flash_duration = 1

end

function DeathFlash:update(dt)
	for i = 1, self.pixel_count do
        local pixel = self.pixels[i]
		pixel.x = pixel.x + pixel.vel_x * dt
		pixel.vel_x, pixel.vel_y = vec2_drag(pixel.vel_x, pixel.vel_y, DRAG, dt)
		pixel.y = pixel.y + pixel.vel_y * dt
	end
end

function DeathFlash:draw(elapsed, tick, t)
    if self.reversed then
        t = 1 - t
        elapsed = self.duration - elapsed
        tick = floor(elapsed)
    end

    t = elapsed / (self.duration)
    -- t = clamp01(t - (1 / self.duration) * 6)
	local t2 = ease("outExpo")(t)
    t = ease("outCubic")(t)
	
	if tick < 6 * self.flash_duration then
		local size = max(5 - ((tick) * 2.0) + 12 * self.size_mod, 1)
		graphics.push()
		-- graphics.rotate(tau / 8)
		graphics.scale(1.0, self.height / self.width)
		graphics.set_color((self.palette or Palette.cmy):tick_color(tick, self.start_tick, self.palette_tick_length))

		graphics.rectangle(tick <= 3 and "fill" or "line", -size / 2, -size / 2, size, size)
		graphics.pop()
	end

    if tick < 4 * self.flash_duration then
		local size = max(((t2 * self.duration) * 0.5) + 8 * self.size_mod, 1)
		graphics.push()
		-- graphics.rotate(tau / 8)
		graphics.scale(1.0, self.height / self.width)
		graphics.set_color((self.palette or Palette.cmy):tick_color(tick / 5, self.start_tick, self.palette_tick_length))

		graphics.rectangle("line", -size / 2, -size / 2, size, size)
		graphics.pop()
	end



    graphics.set_color(Color.darkergrey)
    for i = 1, self.pixel_count do
        local pixel = self.pixels[i]
        graphics.rectangle("fill", pixel.x - pixel.radius, pixel.y - pixel.radius, pixel.radius * 2, pixel.radius * 2)
    end
end

function DeathFlash:floor_draw()
    local elapsed = self.elapsed
    local tick = floor(elapsed)
	local t = elapsed / (self.duration)
	if self.tick == 1 then
	
		if self.reversed then
			t = 1 - t
			elapsed = self.duration - elapsed
			tick = floor(elapsed)
		end
	
		t = elapsed / (self.duration)
		t = clamp01(t - (1 / self.duration) * 6)
		t = ease("outCirc")(t)

	end


	if self.is_new_tick and self.tick == 3 then
		local size = max(4 - ((tick) * 2.0) + 4 * self.size_mod * 0.75, 1)

		graphics.push()
		-- graphics.rotate(tau / 8)
		graphics.scale(1.0, self.height / self.width)
		graphics.set_color(Color.black)

		graphics.rectangle("fill", -size / 2, -size / 2, size, size)
		graphics.set_color(Color.darkergrey)

		graphics.rectangle("line", -size / 2, -size / 2, size, size)
		graphics.pop()
		for i = 1, 10 do
			graphics.set_color(Color.black)
			graphics.rectangle_centered("fill", rng.randf(-size, size), rng.randf(-size, size), rng.randf(1, 10) * self.size_mod, rng.randf(1, 10) * self.size_mod)
		end
	end

	if self.tick < self.duration - 20 then
		return
	end

	
	for i = 1, self.pixel_count do
		local pixel = self.pixels[i]
		graphics.set_color(pixel.color)
		graphics.rectangle("fill", pixel.x - pixel.radius, pixel.y - pixel.radius, pixel.radius * 2, pixel.radius * 2)
	end

end

return DeathFlash
