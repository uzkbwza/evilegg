local DEATH_FX_POWER = 1.4
local DEATH_FX_DISTANCE = 3

local BASE_SIZE = 10

local DRAG = 0.15

local PIXEL_COUNT = 8
local SPEED = 3.0

local LifeFlash = Effect:extend("LifeFlash")

-- TODO: use quads instead of pixels
function LifeFlash:new(x, y, splatter_x, splatter_y, texture, size_mod)
	LifeFlash.super.new(self, x, y)
	-- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
    self.duration = 20
	self.reversed = false
	self.splatter_x = splatter_x - x
	self.splatter_y = splatter_y - y

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

    for i = 1, PIXEL_COUNT * self.size_mod do
        local vel_x, vel_y = rng.random_vec2()
		vel_x = vel_x * SPEED * self.size_mod * rng.randfn(0.5, 0.15)
        vel_y = vel_y * SPEED * self.size_mod * rng.randfn(0.5, 0.15)
		
        local pixel = {
            x = vel_x * 0.25,
            y = vel_y * 0.25,
			vel_x = vel_x,
            vel_y = vel_y,
			radius = rng.randfn(1, 0.5) / 2
        }
		pixels[i] = pixel
    end

	self.pixels = pixels
    self.z_index = 11
	self:start_timer("z_index", 10, function()
		self.z_index = -100
	end)

end

local COLOR_MOD = 0.3

function LifeFlash:update(dt)
	for i = 1, PIXEL_COUNT * self.size_mod do
        local pixel = self.pixels[i]
		pixel.vel_x, pixel.vel_y = vec2_drag(pixel.vel_x, pixel.vel_y, DRAG, dt)
		pixel.x = pixel.x + pixel.vel_x * dt
		pixel.y = pixel.y + pixel.vel_y * dt
	end
end

function LifeFlash:draw(elapsed, tick, t)
    if self.reversed then
        t = 1 - t
        elapsed = self.duration - elapsed
        tick = floor(elapsed)
    end

    t = elapsed / (self.duration)
    t = clamp01(t - (1 / self.duration) * 6)
    t = ease("inCirc")(t)

    if (tick < 4) then
        local size = max(- 2 + ((tick) * 2.0) + 12 * self.size_mod, 1)

        if tick < 6 then
            graphics.push()
			
            -- graphics.rotate(tau / 8)
            -- graphics.scale(1.0, self.height / self.width)
			graphics.rotate(tau / 8)
            graphics.set_color(Palette.enemy_spawn_flash:tick_color(tick, self.start_tick, self.palette_tick_length))

            graphics.rectangle(tick <= 3 and "fill" or "line", -size / 2, -size / 2, size, size)
            graphics.pop()
        end
    end


	local color = Color.white
    graphics.set_color(color.r * COLOR_MOD, color.g * COLOR_MOD, color.b * COLOR_MOD, color.a)
	graphics.translate(self.splatter_x, self.splatter_y)
    for i = 1, PIXEL_COUNT * self.size_mod do
		local pixel = self.pixels[i]
        graphics.rectangle("fill", pixel.x - pixel.radius, pixel.y - pixel.radius, pixel.radius * 2, pixel.radius * 2)
    end
end

function LifeFlash:floor_draw()
	if self.tick < self.duration - 10 then
		return
	end
	local color = Color.white
    graphics.set_color(color.r * COLOR_MOD, color.g * COLOR_MOD, color.b * COLOR_MOD, color.a)
	graphics.translate(self.splatter_x, self.splatter_y)
	
	for i = 1, PIXEL_COUNT * self.size_mod do
		local pixel = self.pixels[i]
		graphics.rectangle("fill", pixel.x - pixel.radius, pixel.y - pixel.radius, pixel.radius * 2, pixel.radius * 2)
	end
end

return LifeFlash
