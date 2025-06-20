local TitleScreen = CanvasLayer:extend("TitleScreen")
-- local TitleScreenWorld = World:extend("TitleScreenWorld")

-- local NUM_STARS = 130
local NUM_STARS = 260
-- local NUM_STARS = 0
local NUM_LENS_FLARE_STARBURST_LINES = 20
local STAR_DISTANCE = 10

local TITLE_TEXT_Y_OFFSET = 50
-- local TITLE_TEXT_Y_OFFSET = 20

local TITLE_QUAD_WIDTH = 4

local STAR_FIELD_WIDTH = conf.viewport_size.x * 2
-- local STAR_FIELD_HEIGHT = conf.viewport_size.y
local STAR_FIELD_HEIGHT = conf.viewport_size.y * 2

local START_STARS_MOVE_SPEED = 10
-- local START_STARS_MOVE_SPEED = 0
local START_STARS_ROTATION_SPEED = 0.0
local END_STARS_MOVE_SPEED = 0.0
local END_STARS_ROTATION_SPEED = 0.00075
local MAX_BURSTS = 15

local STAR_H_SPEED = 1
local STAR_V_SPEED = 0.5

local LENS_FLARE_BURST_DIRECTION = Vec2(-1, 1):normalized()

local SCREENSHOT_MODE = false

if not debug.enabled then
	SCREENSHOT_MODE = false
end

local darkest_color = Color.darkblue
local dark_color = Color.purple
local light_color = Color.magenta
local lightest_color = Color.white
local flash_color = Color.purple
local press_start_color = Color.white


function TitleScreen:new()
	-- self.expand_viewport = false
    TitleScreen.super.new(self)
	-- self:add_world(TitleScreenWorld(), "world")
	self.clear_color = Color.black
    self:add_signal("start_main_menu_requested")
    self.state = "start"

    self.egg_pos = Vec2(0, 22)
	self.real_egg_pos = self.egg_pos:clone()
    self.sun_pos = Vec2(-0, -28)
    self.start_offset_amount = 0

	self.title_line_offset_amount = 1.0
	
    self.flash_amount = 1.0
	
    self.showing_title_text = false
	
    self.showing_lens_flare1 = true
    self.showing_lens_flare2 = false
	
	self.lens_flare1_start = Vec2(-1, 1)
	self.lens_flare1_end = Vec2(1, -1)

	self.showing_title_text_background = false

	self.title_bg_height_amount = 0

    self.title_lines = {}

    self.star_elapsed = 0
    self.stars_move_speed = 0
	self.show_stars_at_distance = 0.0
	self.moving_quads = false

	self.show_press_start = false

    self.star_rotation_elapsed = 0
	self.star_rotation_speed = 0.05

    self.stars = {}
	
	self.lens_flare_starburst_lines = {}

    self:generate_stars()
	
	self:generate_title_lines()
end

function TitleScreen:generate_title_lines()
    local texture = textures.title_title_text
    local data = graphics.texture_data[texture]

	local width = data:getWidth()
	local height = data:getHeight()

    for i = 1, height do
		local quad = graphics.new_quad((i - 1) * TITLE_QUAD_WIDTH, 0, TITLE_QUAD_WIDTH, height, width, height)
        local quad_table = graphics.get_quad_table(texture, quad, TITLE_QUAD_WIDTH, height)
        local line = {
            quad = quad_table,
            start_offset = (rng:randf(100, 200) + height) * rng:rand_sign(),
			-- speed = rng:randf(3, 7),
            speed = (rng:randf(2, 4)),
		}

        -- if SCREENSHOT_MODE then
        --     line.speed = line.speed * 1.4
        -- end
		
		-- if line.speed < 3 then
		-- 	line.speed = 3
		-- end

		table.insert(self.title_lines, line)
	end

    self.title_image_height = height
	self.title_image_width = width
    self.num_title_lines = #self.title_lines
	self.showing_title_text = false
end

function TitleScreen:generate_stars()
    local used_positions = {}

    -- bench.start_bench("generate_stars")


    for i = 1, NUM_STARS do
        local valid = false
        local attempts = 0

        local new_pos = Vec2()

        while not valid and attempts < 100 do
            new_pos = Vec2(
                rng:randi(0, STAR_FIELD_WIDTH) - STAR_FIELD_WIDTH / 2,
                rng:randi(0, STAR_FIELD_HEIGHT) - STAR_FIELD_HEIGHT / 2
            )
            attempts = attempts + 1
            valid = true
            for _, pos in pairs(used_positions) do
                if new_pos:distance_squared(pos) < (STAR_DISTANCE * STAR_DISTANCE) then
                    valid = false
                    break
                end
                if vec2_distance_squared(new_pos.x, new_pos.y, pos.x - conf.viewport_size.x, pos.y) < (STAR_DISTANCE * STAR_DISTANCE) then
                    valid = false
                    break
                end
                if vec2_distance_squared(new_pos.x, new_pos.y, pos.x + conf.viewport_size.x, pos.y) < (STAR_DISTANCE * STAR_DISTANCE) then
                    valid = false
                    break
                end
                if vec2_distance_squared(new_pos.x, new_pos.y, pos.x, pos.y - conf.viewport_size.y) < (STAR_DISTANCE * STAR_DISTANCE) then
                    valid = false
                    break
                end
                if vec2_distance_squared(new_pos.x, new_pos.y, pos.x, pos.y + conf.viewport_size.y) < (STAR_DISTANCE * STAR_DISTANCE) then
                    valid = false
                    break
                end
            end
        end

        self.stars[i] = {
            pos = new_pos,
            sparkle_offset = rng:randi(),
            no_sparkle = rng:percent(80),
            sparkle_time_modifier = rng:randfn(1, 0.1),
            distance = stepify(rng:randf(0.2, 1), 0.2),
			flicker_offset = rng:randi()
        }

        if self.stars[i].distance < 0.4 then
            self.stars[i].color = darkest_color
        elseif self.stars[i].distance < 0.6 then
            self.stars[i].color = dark_color
        elseif self.stars[i].distance < 0.8 then
            self.stars[i].color = light_color
        else
            self.stars[i].color = lightest_color
        end


        table.insert(used_positions, self.stars[i].pos)
    end

    table.sort(self.stars, function(a, b)
        return a.distance < b.distance
    end)

    -- bench.end_bench("generate_stars")
end



function TitleScreen:enter()

	audio.stop_music()
    local s = self.sequencer
    s:start(function()
        self.started = true
		local start_time = 102
		local pre_wait_time = 20


		s:start(function()
            -- s:wait(10)
			s:wait(1)
			s:tween_property(self, "show_stars_at_distance", 0.0, 1.0, 85, "linear")
		end)

		self.stars_move_speed = START_STARS_MOVE_SPEED
		self.star_rotation_speed = START_STARS_ROTATION_SPEED
						
		s:start(function()
            -- s:wait(10)
			s:tween_property(self, "stars_move_speed", self.stars_move_speed, END_STARS_MOVE_SPEED, 300, "outExpo")
        end)

		s:start(function()
			s:tween_property(self, "star_rotation_speed", self.star_rotation_speed, END_STARS_ROTATION_SPEED, 300, "outExpo")
		end)
	
        s:wait(pre_wait_time)
	
		s:start(function()
			s:wait(start_time - 52)
			if audio.playing_music ~= audio.get_music("music_title") then
				audio.play_music("music_title", 1.0)
			end
		end)

		self.moving_quads = true
		


        local easing = "inSine"

		s:start(function()
			local wait_time = start_time * 0.85
            s:wait(wait_time - 3)
			for i=1, 10 do 
				self:generate_lens_flare_starburst_line()
			end
            s:wait(3)
            self.lens_flare2_scale = 0.5
            s:start(function()
				s:wait(6)
				self.showing_lens_flare2 = true	
			end)
			s:tween_property(self, "lens_flare2_scale", self.lens_flare2_scale, 2, 10, "linear")
			s:tween_property(self, "lens_flare2_scale", self.lens_flare2_scale, 1.5, 1.25, "linear")
			s:tween_property(self, "lens_flare2_scale", 2.5, 2.0, 45, "linear")
		end)

        s:start(function()
            s:tween_property(self.egg_pos, "x", self.egg_pos.x, -17, start_time, easing)
		end)
		
		s:start(function()
			s:tween_property(self.sun_pos, "x", self.sun_pos.x, 20, start_time, easing)
        end)
		
        s:start(function()
			s:tween_property(self, "start_offset_amount", 0, 1, start_time, easing)
		end)

		s:start(function()
            -- s:wait(10)
			self.showing_title_text = true
			s:tween_property(self, "title_line_offset_amount", 1, 0, 120, "outSine")
        end)


        s:wait(start_time)

		s:start(function()
			s:tween_property(self, "title_bg_height_amount", 0.1, 1, 90, "outSine")
		end)
		
        s:start(function()

			if SCREENSHOT_MODE then
            --     return	
				s:wait(50)
			end

            self.showing_lens_flare1 = true
			local flash_color = flash_color:clone()
            self.clear_color = flash_color
            s:wait(3)
            self.clear_color = Color.black
			self.showing_title_text_background = true
            s:wait(3)
            self.clear_color = flash_color

            for _, prop in ipairs({ "r", "g", "b" }) do
				s:start(function()
					s:tween_property(self.clear_color, prop, self.clear_color[prop], 0, 32, "linear", 0.125)
					self.clear_color = Color.black
				end)
			end
			-- s:tween_property(self.clear_color, "g", self.clear_color.g, 0, 32, "linear", 0.125)
        end)
		
		s:start(function()
			s:wait(100)
			self.show_press_start = true
		end)
	end)
end

function TitleScreen:update_stars(dt)
end

function TitleScreen:update(dt)
    self.real_egg_pos.x = self.egg_pos.x
    self.real_egg_pos.y = floor(self.egg_pos.y + sin(self.tick * 0.025) * 2)

    local input = self:get_input_table()

    if input.ui_title_screen_start_pressed then
        self:emit_signal("start_main_menu_requested")
    end

    -- if self.is_new_tick then
    -- 	for i=1, #self.stars do
    --         local star = self.stars[i]
    -- 		if rng:percent(5) then
    -- 			star.color = rng:percent(70) and Color.white or (rng:percent(50) and Color.green or (rng:percent(20) and Color.yellow or Color.darkgreen))
    -- 		end
    -- 	end
    -- end

    if self.moving_quads then
        for i = 1, self.num_title_lines do
            local line = self.title_lines[i]
            line.start_offset = approach(line.start_offset, 0, line.speed * dt)
        end
    end

    self.star_elapsed = self.star_elapsed + dt * self.stars_move_speed


    if self.showing_lens_flare2 and self.is_new_tick and rng:percent(35) then
		for i=1, rng:randi(0, 3) do
			self:generate_lens_flare_starburst_line()
		end
    end

	self.star_rotation_elapsed = self.star_rotation_elapsed + dt * self.star_rotation_speed
end


function TitleScreen:generate_lens_flare_starburst_line()

	if table.length(self.lens_flare_starburst_lines) >= MAX_BURSTS then
		return
	end

	local r = rng:randfn(1, 0.1)
	local theta = rng:random_angle()

	local dx, dy = vec2_from_angle(theta)

    local dotted1 = -(vec2_dot(LENS_FLARE_BURST_DIRECTION.x, LENS_FLARE_BURST_DIRECTION.y, dx, dy))
	local dotted2 = abs(vec2_dot(dx, dy, vec2_rotated(LENS_FLARE_BURST_DIRECTION.x, LENS_FLARE_BURST_DIRECTION.y, tau / 4)))
	local dotted = max(abs(dotted1), dotted2)
	local extra = rng:randf(0, (dotted) ^ 5)


	r = r + extra


	local d = 0.95

    if (dotted) > d then
		local new = remap_pow(1 - dotted, 0.0, 1 - d, 0.0, 3.0, 3)
        r = r * rng:randf(1.5, new)
	end
	
    if dotted1 < 0 then
        if rng:percent(25) then
			return self:generate_lens_flare_starburst_line()
		end
		r = r * 0.75
	end
	
	local vx, vy = vec2_from_polar(r, theta)
	local line = {
		r = r,
		theta = theta,
		vx = vx,
		vy = vy,
		speed = clamp(rng:randfn(1, 0.24), 0.1, 10.0),
        random_offset = rng:randi(1, 100),
		opacity = 0,
		width = max(abs(rng:randfn(1, 2)), 2)
	}

    self.lens_flare_starburst_lines[line] = true
	
	local s = self.sequencer
    s:start(function()
        s:tween(function(t)
            line.opacity = math.bump(t)
        end, 0, 1, rng:randfn(120, 20) * r, "linear")
		self.lens_flare_starburst_lines[line] = nil
		
	end)
end


function TitleScreen:exit()
	audio.stop_music("music_title")
end

local steps = {
    Color.transparent,
	darkest_color,
	dark_color,
	light_color,
	lightest_color,
}

function TitleScreen:draw()
	if not self.started then return end
    graphics.translate(self.viewport_size.x / 2, self.viewport_size.y / 2)
	
    local vertical_repeats = idiv(self.viewport_size.y, STAR_FIELD_HEIGHT)
	local horizontal_repeats = idiv(self.viewport_size.x, STAR_FIELD_WIDTH)

	graphics.translate(0, -12)

    -- bench.start_bench("draw_stars")
    -- local line_cache = {
	-- 	bresenham_line(-self.stars_move_speed * STAR_H_SPEED, -self.stars_move_speed * STAR_V_SPEED, 0, 0),
	-- 	bresenham_line(-self.stars_move_speed * STAR_H_SPEED * 0.8, -self.stars_move_speed * STAR_V_SPEED * 0.8, 0, 0),
	-- 	bresenham_line(-self.stars_move_speed * STAR_H_SPEED * 0.6, -self.stars_move_speed * STAR_V_SPEED * 0.6, 0, 0),
	-- 	bresenham_line(-self.stars_move_speed * STAR_H_SPEED * 0.4, -self.stars_move_speed * STAR_V_SPEED * 0.4, 0, 0),
	-- }


	for i=1, #self.stars do
        local star = self.stars[i]
        local x, y = star.pos.x, star.pos.y

        local flicker_mod = 5 + round((star.distance) * 2)
		
        if iflicker(star.flicker_offset + self.tick, 2, flicker_mod) then
			goto continue
		end

        if self.show_stars_at_distance < 1 then
            local step = stepify(self.show_stars_at_distance * 4 * star.distance, 1)
			local color = steps[step + 1]
			graphics.set_color(color)
		else
			graphics.set_color(star.color)
		end

		local sparkle_length = floor(520 * star.sparkle_time_modifier)
        local sparkle_offset = idivmod(star.sparkle_offset + self.tick, 1, sparkle_length)

		local h_speed = STAR_H_SPEED * star.distance
        local v_speed = STAR_V_SPEED * star.distance
		
		x = (x + (self.star_elapsed * h_speed)) % STAR_FIELD_WIDTH - STAR_FIELD_WIDTH / 2
		y = (y + (self.star_elapsed * v_speed)) % STAR_FIELD_HEIGHT - STAR_FIELD_HEIGHT / 2

		x, y = vec2_rotated(x, y, self.star_rotation_elapsed * star.distance)

        -- for yoffs = -vertical_repeats * 2, vertical_repeats * 2 do
        --     for xoffs = -horizontal_repeats * 2, horizontal_repeats * 2 do
				
		-- 		local x = x + xoffs * conf.viewport_size.x
        --         local y = y + yoffs * conf.viewport_size.y


				if vec2_magnitude_squared(h_speed * self.stars_move_speed, v_speed * self.stars_move_speed) > 1 then
					graphics.line(x - h_speed * self.stars_move_speed, y - v_speed * self.stars_move_speed, x, y)
				end
				
				if star.no_sparkle or sparkle_offset < sparkle_length - 10 then
					graphics.points(x, y)
				elseif sparkle_offset < sparkle_length - 5 then
					graphics.points(x, y - 1, x, y + 1, x + 1, y, x - 1, y)
				elseif sparkle_offset < sparkle_length - 2 then
					graphics.points(x, y - 1, x, y + 1, x + 1, y, x - 1, y)
					graphics.points(x, y - 2, x, y + 2, x + 2, y, x - 2, y)
				else
					graphics.points(x, y - 2, x, y + 2, x + 2, y, x - 2, y)
				end

				-- if vec2_magnitude_squared(h_speed * self.stars_move_speed, v_speed * self.stars_move_speed) > 1 then
				-- 	-- for x2, y2 in bresenham_line_iter(x - h_speed * self.stars_move_speed, y - v_speed * self.stars_move_speed, x, y) do
				-- 		-- graphics.points(x2, y2)
                --     -- end
				-- 	local step = stepify(clamp(1 + (star.distance * 4), 1, 4), 1)
				-- 	-- graphics.push("all")
                --     for _, vec in ipairs(line_cache[step]) do
				-- 		graphics.set_color(Color.red)
				-- 		graphics.points(x + vec.x - 1, y + vec.y - 1)
				-- 	end
				-- 	-- graphics.pop()
				-- end
		-- 	end
		-- end

		::continue::
	end

	graphics.set_color(Color.white)

	-- bench.end_bench("draw_stars")


	graphics.set_font(fonts.depalettized.image_font1)

	graphics.drawp_centered(textures.title_egg2, nil, 0, self.real_egg_pos.x * 0.9, self.real_egg_pos.y + self.start_offset_amount * -3)
	graphics.drawp_centered(textures.title_sun1, nil, 0, self.sun_pos.x, self.sun_pos.y)
	graphics.drawp_centered(textures.title_egg3, nil, 0, self.real_egg_pos.x * 0.9, self.real_egg_pos.y + self.start_offset_amount * -3)
	
	local egg2_scale = stepify(1 - self.start_offset_amount * 0.05, 0.01)
	graphics.drawp_centered(textures.title_egg2, nil, 0, self.real_egg_pos.x, self.real_egg_pos.y, 0, egg2_scale, egg2_scale)
	
	-- if self.showing_lens_flare2 then
		-- graphics.drawp_centered(textures.title_sun2, nil, 0, self.sun_pos.x, self.sun_pos.y)
	-- end
	-- if self.showing_title_text then
		-- graphics.drawp_centered(textures.title_title_text, nil, 0, 0, 50)
    -- end
	
	local flare_center_x, flare_center_y = self.sun_pos.x + 5, self.sun_pos.y - 7

    if self.showing_lens_flare1 then

    end
	
    if self.showing_lens_flare2 then
        graphics.push("all")
		graphics.set_color(lightest_color)
		graphics.translate(flare_center_x, flare_center_y)
		local flare_scale = 6 * self.lens_flare2_scale
        -- if iflicker(gametime.tick, 1, 2) then
			-- local scale1 = 0.618 * (1 + (3 * self.lens_flare2_scale) + sin(self.elapsed * 0.02) * 1)
		local scale2 = (3 + (4 * self.lens_flare2_scale) + sin(self.elapsed * 0.02) * 2)
			-- local scale3 = 0.618 * (1 + (3 * self.lens_flare2_scale) + sin(self.elapsed * 0.02) * 1)
        -- graphics.rectangle_centered("fill", -7, -4, scale1, scale1)
		graphics.push()
		graphics.rotate(deg2rad(45))
        graphics.rectangle_centered("fill", 0, 0, scale2, scale2)
		graphics.pop()
        	-- graphics.rectangle_centered("fill", 5, 8, scale3, scale3)
		-- end
        for line in pairs(self.lens_flare_starburst_lines) do
            -- graphics.set_line_width()
            local width = (line.width * line.opacity)
			
            local mod_tick = (max(floor((1 - (line.opacity)) * 10), 1))
			-- print(mod_tick)
			if SCREENSHOT_MODE or iflicker(line.random_offset + self.tick, 2, mod_tick) then
				local line_scale = flare_scale * 2 * (1 + sin(line.random_offset * 2.5 + self.tick * 0.025 * line.speed) * 0.1) * remap01(line.opacity, 0.5, 1.0)

				local start_x, start_y = 0, 0
                local end_x, end_y = line.vx * line_scale, line.vy * line_scale
				local dx, dy = vec2_normalized(end_x - start_x, end_y - start_y)
                -- graphics.line(start_x, start_y, end_x, end_y)
				local base_x1, base_y1 = vec2_rotated(dx, dy, tau / 4)
				local base_x2, base_y2 = vec2_rotated(dx, dy, -tau / 4)

				graphics.polygon("fill", start_x + base_x1 * width, start_y + base_y1 * width, start_x + base_x2 * width, start_y + base_y2 * width, end_x, end_y)
				
				
				
				-- graphics.rectangle_centered("fill", end_x, end_y, line.width, line.width)
			end
		end
		-- end
		graphics.pop()
	end

	-- if SCREENSHOT_MODE then return end

	
    if self.showing_title_text then
		local title_offset_multiplier = (1 + self.title_line_offset_amount * 0.85)
		if self.showing_title_text_background then
			-- graphics.set_color(Color.white)
			graphics.set_color(Color.black)
			graphics.rectangle_centered("fill",0, TITLE_TEXT_Y_OFFSET - 2, 234 * (1 + (title_offset_multiplier - 1) * 4), 54 * (self.title_bg_height_amount))
		end
		
		graphics.set_color(Color.white)
		for i=1, self.num_title_lines do
			local line = self.title_lines[i]
			local quad = line.quad
			local offset = line.start_offset
			local y = offset + sin(i * 0.55 + self.elapsed * 0.015) * 0
            local x = ((i - (self.title_image_width / 2) / TITLE_QUAD_WIDTH) * TITLE_QUAD_WIDTH) * stepify(title_offset_multiplier, 0.0125)
            -- x = x * 0.95 + x * sin01(self.elapsed * 0.015) * 0.05
			x = floor(x)
			y = floor(y)
			graphics.draw_centered(quad, x, y + TITLE_TEXT_Y_OFFSET)
		end
	end

	if not SCREENSHOT_MODE and self.show_press_start and not iflicker(self.tick, 16, 3) then
	-- if not SCREENSHOT_MODE and self.show_press_start then
        graphics.set_color(press_start_color)
        -- graphics.set_color(Palette.title_screen_press_start_flash:tick_color(self.tick, 0, 2))
		local font = fonts.depalettized.image_font2
		graphics.set_font(font)
		graphics.printp_centered("PRESS " .. (input.last_input_device == "gamepad" and control_glyphs.start or control_glyphs.lmb), font, nil, 0, 0, TITLE_TEXT_Y_OFFSET + 28)
	end

	if SCREENSHOT_MODE then
		-- graphics.draw_centered(textures.capsule_shot2, 0, 0)
	end
end

return TitleScreen
