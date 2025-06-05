local XpPickup = GameObject2D:extend("XpPickup")

local SMALL_SIZE = 0.05
local BIG_SIZE = 0.25
local HUGE_SIZE = 0.75
local REALLY_HUGE_SIZE = 20.0
local ACCEL = 0.5
local DRAG = 0.02
local HOME_SPEED = 0.015
local HISTORY_LENGTH = 1

local XP_SPRITESHEET = SpriteSheet(textures.pickup_xp, 6, 6)

local textures = {
	pickup_xp_really_huge = {XP_SPRITESHEET:get_frame(1), XP_SPRITESHEET:get_frame(2), XP_SPRITESHEET:get_frame(3)},
	pickup_xp_huge = {XP_SPRITESHEET:get_frame(1), XP_SPRITESHEET:get_frame(2), XP_SPRITESHEET:get_frame(3)},
	pickup_xp_big = {XP_SPRITESHEET:get_frame(4), XP_SPRITESHEET:get_frame(5), XP_SPRITESHEET:get_frame(6)},
	pickup_xp_small = {XP_SPRITESHEET:get_frame(7), XP_SPRITESHEET:get_frame(8), XP_SPRITESHEET:get_frame(9)},
}

function XpPickup:new(x, y, xp)
	-- xp = 10
    XpPickup.super.new(self, x, y)
    self.persist = true
    self:add_time_stuff()

    self.particles = bonglewunch()
    self.particles_to_remove = {}
    self.z_index = -0.9
	local particles = self.particles

    local speed = min(4 + xp * 0.05, 10)


    local xp_left = xp
    -- local big_pickup_size_threshold = min(xp / 1.5, SMALL_SIZE * 20)
	-- local huge_pickup_size_threshold = min(xp / 4, BIG_SIZE * 10)
    while xp_left > 0 do
        local texture = "pickup_xp_small"
		local xp_to_add = min(SMALL_SIZE, xp_left)

        if xp_left >= SMALL_SIZE * 5 then
			if xp_left >= REALLY_HUGE_SIZE and rng:percent(60) then
				texture = "pickup_xp_really_huge"
				xp_to_add = REALLY_HUGE_SIZE
			elseif xp_left >= HUGE_SIZE and rng:percent(60) then
				texture = "pickup_xp_huge"
				xp_to_add = HUGE_SIZE
			elseif xp_left >= BIG_SIZE and rng:percent(60) then
				texture = "pickup_xp_big"
				xp_to_add = BIG_SIZE
			end
        end

        local p = {
            elapsed = 0,
            -- lerp_t = 0,
            home_speed = max(rng:randfn(1, 0.5), 0.5),
			start_vertical = rng:coin_flip(),
            texture = texture,
        }

		
        p.vel_x, p.vel_y = rng:random_vec2_times(rng:randfn(speed, speed * 0.1))
		
        p.history = { { x, y, 0 } }
		
		
		p.random_offset = rng:randi()
		p.x = x + rng:randf_range(0, 10) * sign(p.vel_x)
        p.y = y + rng:randf_range(0, 10) * sign(p.vel_y)
		
		
        p.xp = xp_to_add

        xp_left = xp_left - xp_to_add

        particles:push(p)
    end
end

function XpPickup:enter()
	self:add_tag("xp_pickup")
end

function XpPickup:update(dt)
	if self.particles:is_empty() then
        self:queue_destroy()
		return
	end

    for _, particle in (self.particles:ipairs()) do
        self:update_particle(particle, dt)
	end

	local picked_up = false
    for _, particle in ipairs(self.particles_to_remove) do
        self.particles:remove(particle)
		if not particle.no_pickup then
			picked_up = true
		end
    end
	if picked_up then
		self:play_sfx("xp_pickup", 0.115)
	end
    table.clear(self.particles_to_remove)
	
end

function XpPickup:update_particle(particle, dt)

    if game_state.game_over then
		table.insert(self.particles_to_remove, particle)
		return
	end

    particle.elapsed = particle.elapsed + dt / self.world.object_time_scale
	
	table.insert(particle.history, {particle.x, particle.y, particle.elapsed})
	
	-- print(#particle.history)
	while particle.elapsed - particle.history[1][3] > HISTORY_LENGTH do
		table.remove(particle.history, 1)
	end
	
	local vel_x = (particle.vel_x)
    local vel_y = (particle.vel_y)
    local move_x, move_y = 0, 0

    move_x = move_x + vel_x * dt
    move_y = move_y + vel_y * dt


    particle.vel_x, particle.vel_y = vec2_drag(particle.vel_x, particle.vel_y, DRAG, dt)
    local closest_player = self.world:get_closest_object_with_tag("player", particle.x, particle.y)
    local all_directions = false
	local long_enough = self.world.state == "RoomClear" or particle.elapsed > seconds_to_frames(5)

    if closest_player and particle.elapsed > seconds_to_frames(0.125) then
        local px, py = closest_player:get_body_center()
        local dx, dy = vec2_direction_to(particle.x, particle.y, px, py)
        local dist = vec2_distance(particle.x, particle.y, px, py)
        if dist < 15 or long_enough then
            if dist < (long_enough and 10 or 5) then
                game_state:gain_xp(particle.xp)
                table.insert(self.particles_to_remove, particle)
                return
                -- else
            end
            -- 	particle.vel_x, particle.vel_y = vec2_drag(particle.vel_x, particle.vel_y, 0.6, dt)
            -- else
			if dist < 15 then
				-- all_directions = true
			end
        end
        local speed = min(particle.elapsed * (ACCEL) * particle.home_speed * dt, dist)

		speed = long_enough and max(10.0 * dt, speed) or speed

        move_x, move_y = vec2_add(move_x, move_y, dx * speed, dy * speed)
    end


    -- move_x = abs(move_x) > abs(move_y) and move_x or 0
    -- move_y = abs(move_y) > abs(move_x) and move_y or 0

    if not all_directions then
        local first = idivmod_eq_zero(particle.elapsed, max(20 * particle.home_speed - particle.elapsed * 0.08, 2), 2)
        if first and particle.start_vertical or (not first and not particle.start_vertical) then
            move_x = move_x * 0.025
        else
            move_y = move_y * 0.025
        end
    end

    particle.x = particle.x + move_x
    particle.y = particle.y + move_y
		
	-- if particle.elapsed > seconds_to_frames(8) then
	-- 	game_state:gain_xp(particle.xp)
	-- 	table.insert(self.particles_to_remove, particle)
    -- end
    if particle.elapsed > seconds_to_frames(30) then
        table.insert(self.particles_to_remove, particle)
		particle.no_pickup = true
		return
	end
end

function XpPickup:draw()

    for i, particle in (self.particles:ipairs()) do
        local x1, y1 = self:to_local(particle.x, particle.y)
		local last = particle.history[1]
		local x2, y2 = self:to_local(last[1], last[2])
		local dist = vec2_distance(x1, y1, x2, y2)
		local texture = textures[particle.texture]
		local max = clamp(floor(dist), 1, 20)
		for j=1, max do
			local x, y = vec2_lerp(x1, y1, x2, y2, j/dist)
			graphics.draw_centered(texture[(idiv(gametime.time * particle.home_speed, 2) + particle.random_offset) % #texture + 1], x, y)
		end
		-- print(i)
	end
end

return XpPickup
