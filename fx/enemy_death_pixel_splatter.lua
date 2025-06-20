local DEATH_FX_POWER = 1.4
local DEATH_FX_DISTANCE = 3

local BASE_SIZE = 14
local MAX_SPEED = 20

local CENTER_SPEED = 1

local DRAG = 0.15

local DeathSplatter = Effect:extend("DeathSplatter")

DeathSplatter.is_death_flash = true

-- TODO: use quads instead of pixels
function DeathSplatter:new(x, y, flip, texture, texture_palette, palette_tick_length, vel_x, vel_y, hit_point_x, hit_point_y, center_speed_modifier)
	DeathSplatter.super.new(self, x, y)
	-- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
    self.duration = 20
	self.reversed = false	
    self.flip = flip or 1
	self.texture_palette = texture_palette
	self.palette_tick_length = palette_tick_length or 2
	local width, height = 0, 0
    local offset_x, offset_y = 0, 0

	vel_x = vel_x or 0
	vel_y = vel_y or 0
    self.vel_x, self.vel_y = vel_x, vel_y
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
	self.texture = texture
    local pixels = {}
    local c = 1
    local vel_dir_x, vel_dir_y = vec2_normalized(vel_x, vel_y)
	self.vel_dir_x, self.vel_dir_y = vel_dir_x, vel_dir_y
    local speed = vec2_magnitude(vel_x, vel_y)
	-- local center_x, center_y = width / 2, height / 2
	hit_point_x = hit_point_x or x
	hit_point_y = hit_point_y or y
    local dx, dy = vec2_sub(hit_point_x, hit_point_y, x, y)
	self.hit_point_local_x, self.hit_point_local_y = dx, dy
	dx = dx + width / 2
    dy = dy + height / 2


	self.random_start_tick = rng:randi(0, 999)

	local diagonal_size = vec2_magnitude(width, height)
	self.hit_angle = vec2_angle(vel_dir_x, vel_dir_y)

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
			local x2 = stepify(x_, 4)
            local y2 = stepify(y_, 4)

			
			local diff_x, diff_y = vec2_sub(x2, y2, dx, dy)
			local diff_mag = vec2_magnitude(diff_x, diff_y) / diagonal_size
			local diff_dir_x, diff_dir_y = vec2_normalized(diff_x, diff_y)

            local a_ = (1 + vec2_dot(vel_dir_x, vel_dir_y, diff_dir_x, diff_dir_y))
			local b_ = a_ * 0.5 * (1 - diff_mag) 
			local speed_scale = pow(abs(b_), 2.5)
			local pixel_vel_x, pixel_vel_y = vec2_mul_scalar(vel_dir_x, vel_dir_y, min(speed_scale * speed, MAX_SPEED))

			local center_dir_x, center_dir_y = vec2_direction_to(self.hit_point_local_x, self.hit_point_local_y, x2 - width / 2, y2 - height / 2)
            local center_vel_x, center_vel_y = vec2_mul_scalar(center_dir_x, center_dir_y, (CENTER_SPEED * (center_speed_modifier or 1)))
			
			pixel_vel_x = (pixel_vel_x + center_vel_x)
            pixel_vel_y = (pixel_vel_y + center_vel_y)
			
            -- if vec2_magnitude(speed_x, speed_y) < 0.5 then
            --     speed_x, speed_y = vec2_normalized(speed_x, speed_y)
			-- 	speed_x, speed_y = vec2_mul_scalar(speed_x, speed_y, 0.5)
			-- end

			pixels[c] = {
				r = r,
				g = g,
				b = b,
				a = a,

				start_x = x_ - width / 2,
                start_y = y_ - height / 2,
				x = 0,
				y = 0,

				-- vel_x = rng:randfn(speed_x, 0.005),
				-- vel_y = rng:randfn(speed_y, 0.005),
				vel_x = pixel_vel_x,
				vel_y = pixel_vel_y,
			}
			


			c = c + 1
			::continue::
		end
	end

    self.size_mod = max(width, height) / BASE_SIZE
    local true_width, true_height = true_end_x - true_start_x + 1, true_end_y - true_start_y + 1

	self.size_ratio = true_height / true_width

	self.pixels = pixels
	self.z_index = 0.05
	self:start_timer("z_index", 10, function()
		self.z_index = -100
	end)
end

function DeathSplatter:update(dt)
	if self.tick <= 2 then return end
    for _, pixel in ipairs(self.pixels) do
        pixel.vel_x, pixel.vel_y = vec2_drag(pixel.vel_x, pixel.vel_y, DRAG, dt)
        pixel.x = pixel.x + pixel.vel_x * dt
        pixel.y = pixel.y + pixel.vel_y * dt
    end
end

function DeathSplatter:draw(elapsed, tick, t)
    if self.reversed then
        t = 1 - t
        elapsed = self.duration - elapsed
        tick = floor(elapsed)
    end

    t = elapsed / (self.duration)
    t = clamp01(t - (1 / self.duration) * 6)
    t = ease("outCirc")(t)


    graphics.push("all")

    for _, pixel in ipairs(self.pixels) do
        if pixel.a == 0 then goto continue end

        local r, g, b

        local color_mod = 1

        if self.color then
            graphics.set_color(self.color)
        else
            if tick >= 5 and tick <= self.duration - 10 then
                r, g, b = pixel.r * color_mod, pixel.g * color_mod, pixel.b * color_mod
            else
                local pixel_color = self.texture_palette:get_swapped_color_unpacked(pixel.r, pixel.g, pixel.b,
                    self.texture_palette, floor((self.random_start_tick + tick) / self.palette_tick_length))
                r, g, b = pixel_color.r * color_mod, pixel_color.g * color_mod, pixel_color.b * color_mod
            end
            -- graphics.set_color(pixel_color.r, pixel_color.g, pixel_color.b, pixel.a)
            -- graphics.set_color(pixel.r, pixel.g, pixel.b, pixel.a)
        end
        -- graphics.set_color(r * 0.5, g * 0.5, b * 0.5, pixel.a)
        -- graphics.points(
        -- 	floor(pixel.start_x + pixel.x * 1.5),
        -- 	floor(pixel.start_y + pixel.y * 1.5)
        -- )

		pixel.new_r = r
		pixel.new_g = g
		pixel.new_b = b

		graphics.set_color(r, g, b, pixel.a)



        graphics.points(
            floor(pixel.start_x + pixel.x),
            floor(pixel.start_y + pixel.y)
        )

        -- if tick > self.duration - 10 then
        --     self:floor_canvas_pop()
        -- end
        -- if self.tick == self.duration then
        -- 	self:floor_canvas_push()

        -- 	local ground_color_index = self.texture_palette:get_color_index_unpacked(pixel.r, pixel.g, pixel.b)
        -- 	local ground_color_r, ground_color_g, ground_color_b = Palette.rainbow:get_color_unpacked(self.start_tick + floor(tick / self.palette_tick_length) + ground_color_index * 3)
        -- 	graphics.set_color(ground_color_r * 0.05, ground_color_g * 0.05, ground_color_b * 0.05, pixel.a)
        -- 	graphics.points(
        -- 		floor(pixel.start_x + pixel.x),
        -- 		floor(pixel.start_y + pixel.y)
        -- 	)
        -- 	self:floor_canvas_pop()
        -- end
        ::continue::
    end
    graphics.pop()
end

local PIXEL_MOD = 1.0

function DeathSplatter:floor_draw()
    if self.tick < self.duration - 5 then
        return
    end
	
	for _, pixel in ipairs(self.pixels) do
		graphics.set_color(pixel.new_r * PIXEL_MOD, pixel.new_g * PIXEL_MOD, pixel.new_b * PIXEL_MOD, pixel.a)
		graphics.points(	
			floor(pixel.start_x + pixel.x),
			floor(pixel.start_y + pixel.y)
		)
	end
end

return DeathSplatter
