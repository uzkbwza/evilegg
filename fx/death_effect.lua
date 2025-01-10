local DEATH_FX_POWER = 1.4
local DEATH_FX_DISTANCE = 12

local DeathFx = Effect:extend("DeathFx")

function DeathFx:new(x, y, texture, flip)
	DeathFx.super.new(self, x, y)
    self.duration = 30
	self.reversed = false
	self.flip = flip or 1
	local width, height = 0, 0
    local offset_x, offset_y = 0, 0
    self.flash = true
	self.color_flash = nil
	self.size_mod = 1
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
	local data = graphics.texture_data[texture]
	self.texture = texture
	local pixels = {}
	for y_ = 0, height - 1 do
		for x_ = 0, width - 1 do
			
            local r, g, b, a = data:getPixel(x_ + offset_x, y_ + offset_y)
			local x2 = stepify(x_, 2)
			local y2 = stepify(y_, 2)
            -- local x2 = x_ + 0.5
            -- local y2 = y_ + 0.5
			
			local x_dist = x2 - width / 2 
            local y_dist = y2 - height / 2

            if abs(x_dist) > abs(y_dist) then
				-- y_dist = y_dist * 0.75
			else
				-- x_dist = x_dist * 0.65
			end

            local direction_from_center_x = abs(x_dist) >= abs(y_dist) and sign(x_dist)	or 0
            local direction_from_center_y = abs(y_dist) >= abs(x_dist) and sign(y_dist) or 0
			-- local direction_from_center_x, direction_from_center_y = vec2_direction_to(x2, y2, width / 2, height / 2)

            local dist = max(abs(x_dist), abs(y_dist))
			-- local dist = vec2_distance_to(x2, y2, width / 2, height / 2)
            dist = pow(dist / max(width, height), DEATH_FX_POWER)
			-- dist = max(dist, 1)
			-- local valid_pixel = true
			-- if abs(dist) < 0.0001 then valid_pixel = false end
            -- if a <= 0.0
            -- then
                -- valid_pixel = false
				
			-- end
			


			pixels[x_ + y_ * width] = {
				r = r,
				g = g,
				b = b,
				a = a,
				dist = dist,
				direction_from_center_x = direction_from_center_x,
				direction_from_center_y = direction_from_center_y,
				x = x_ - width / 2,
				y = y_ - height / 2
				}

		end
	end
	self.pixels = pixels
end

function DeathFx:draw(elapsed, tick, t)
	if self.reversed then
        t = 1 - t
		elapsed = self.duration - elapsed
		tick = floor(elapsed)
	end

	t = elapsed / (self.duration)
	t = clamp(t - (1/self.duration) * 6, 0, 1)
	t = ease("linear")(t) 
    -- t = lerp(t, stepify(t, 0.1), 0.5)
	if tick >= self.duration - 12 and (floor(tick/1)) % 2 == 0 then
		return
	end
	
	graphics.push("all")
	for _, pixel in ipairs(self.pixels) do
		if self.color_flash then
			graphics.set_color(graphics.color_flash(self.color_flash[1], self.color_flash[2]))
		elseif self.color then
			graphics.set_color(self.color)
		else
			graphics.set_color(pixel.r, pixel.g, pixel.b, pixel.a)
		end
		graphics.points(
			floor(pixel.x + pixel.dist * (t) * DEATH_FX_DISTANCE * self.width  * pixel.direction_from_center_x * self.flip) * self.size_mod + 1,
			floor(pixel.y + pixel.dist * (t) * DEATH_FX_DISTANCE * self.height * pixel.direction_from_center_y) * self.size_mod + 1
		)
	end
    graphics.pop()
    if (tick == 1 or tick == 4)and self.flash then
		if self.color_flash then
			graphics.set_color(graphics.color_flash(self.color_flash[1], self.color_flash[2]))
		elseif self.color then
			graphics.set_color(self.color)
		else
		graphics.set_color(1, 1, 1, 1)
		end
        graphics.circle("fill", 0, 0, 5 - floor(tick) + 12 * self.size_mod)
    end
end

return DeathFx
