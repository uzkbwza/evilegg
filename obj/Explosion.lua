local Explosion = GameObject2D:extend("Explosion")

local DEFAULT_PARAMS = {
    damage = 10,
    size = 30,
	draw_scale = 1.0,
	team = "enemy",
	melee_both_teams = false,
	particle_count_modifier = 1,
	explode_sfx = "explosion",
	explode_sfx_volume = 0.9,
    explode_vfx = nil,
	force_modifier = 1.0,
	ignore_explosion_force = {},
	no_effect = false,
}

function Explosion:new(x, y, params)
	params = params or DEFAULT_PARAMS
    Explosion.super.new(self, x, y)
	self:add_elapsed_ticks()
    self:add_sequencer()
	-- Internal particle systems
	self.smoke_puffs = batch_remove_list()
	self.smoke_trails = batch_remove_list()
	self._spawn_running = 0
	self._spawning_done = false
    self.z_index = 1
	self.particle_count_modifier = params.particle_count_modifier or DEFAULT_PARAMS.particle_count_modifier
    self.size = params.size or DEFAULT_PARAMS.size
    self.team = params.team or (self.team or "enemy")
	self.hit_bubble_damage = params.damage or DEFAULT_PARAMS.damage
	self.damage = self.hit_bubble_damage
	self.melee_both_teams = params.melee_both_teams or DEFAULT_PARAMS.melee_both_teams
	self.draw_scale = params.draw_scale or DEFAULT_PARAMS.draw_scale
    self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
	self.explode_vfx = params.explode_vfx or DEFAULT_PARAMS.explode_vfx
	self.explode_sfx = params.explode_sfx or DEFAULT_PARAMS.explode_sfx
    self.explode_sfx_volume = params.explode_sfx_volume or DEFAULT_PARAMS.explode_sfx_volume
	self.no_effect = params.no_effect or DEFAULT_PARAMS.no_effect
	self.force_modifier = params.force_modifier or DEFAULT_PARAMS.force_modifier
    self:ref_bongle("ignore_explosion_force")
	for _, obj in ipairs(params.ignore_explosion_force or DEFAULT_PARAMS.ignore_explosion_force) do
		self:ref_bongle_push("ignore_explosion_force", obj)
	end
end

function Explosion:get_death_particle_hit_velocity(target)
    local direction = self.pos:direction_to(target.pos):mul_in_place(self.size)
	return direction.x, direction.y
end

function Explosion:get_rect()
    return self.pos.x - self.size / 2, self.pos.y - self.size / 2, self.size, self.size
end

function Explosion.apply_explosion_force(obj, self)
    if obj.is_simple_physics_object and not obj.is_player and not self.ignore_explosion_force:has(obj) then
        local x, y = obj.pos.x, obj.pos.y
        while x == self.pos.x and y == self.pos.y do
            x, y = vec2_add(obj.pos.x, obj.pos.y, rng:randf(-1, 1), rng:randf(-1, 1))
        end
        local dist = vec2_distance_squared(self.pos.x, self.pos.y, x, y)
        if dist <= self.size * self.size then
            local dx, dy = vec2_direction_to(self.pos.x, self.pos.y, x, y)
            local force = ((self.size / sqrt(dist)) / 2) * self.force_modifier
            force = min(force, 2.0)
            obj:apply_impulse(dx * force, dy * force)
        end
    end
end

function Explosion:enter()

	self.active = true
    local s = self.sequencer

    s:start(function()
		s:wait(1)
		self:add_hit_bubble(0, 0, self.size, "main", self.hit_bubble_damage)
        s:wait(2)
		self.active = false
		self:remove_hit_bubble("main")
    end)
	
	local x, y, w, h = self:get_rect()
    self.world.game_object_grid:each_self(x, y, w, h, self.apply_explosion_force, self)

	self:play_sfx(self.explode_sfx, self.explode_sfx_volume)

	if self.no_effect then
		return
	end

    if self.explode_vfx then
        self.explode_vfx = self:spawn_object(self.explode_vfx(self.pos.x, self.pos.y))
		if self.explode_vfx.process_explosion then
			self.explode_vfx:process_explosion(self)
		end
		self.explode_vfx = true
        return
    end


    self.size = self.size * 1.25
	local scale = self.size * self.draw_scale
	local number_of_puffs = (scale / 3) + 5
	number_of_puffs = rng:randf(number_of_puffs * 0.8, number_of_puffs * 1.2)
	local number_of_smoke_trails = (scale / 4) + 4
    number_of_smoke_trails = rng:randf(number_of_smoke_trails * 0.8, number_of_smoke_trails * 1.2)
	-- Spawn internal smoke puffs over a few ticks
	self._spawn_running = self._spawn_running + 1
	s:start(function()
		for i = 1, number_of_puffs * self.particle_count_modifier do
			local dist = abs(rng:randfn(0, scale * 0.75))
			dist = min(dist, scale * 1.25)
			local dx, dy = rng:random_vec2_times(dist)
			local size1 = abs((1 - (dist / scale)) * 1)
			local size = abs(size1 * scale * rng:randfn(0.4, 1.25))
			size = abs(min(size, scale * 1))

			local duration = size * rng:randfn(1.0, 1.25) * 10
			local dir_x, dir_y = vec2_normalized(dx, dy)
			local speed = rng:randf(0.5, 1) * dist * 0.15
			self:_add_smoke_puff(self.pos.x + dx, self.pos.y + dy, size, duration, 0, dir_x * speed, dir_y * speed, false)
			if rng:percent(10) then
				s:wait(1)
			end
		end
		self._spawn_running = self._spawn_running - 1
		if self._spawn_running == 0 then self._spawning_done = true end
	end)

	-- Spawn internal smoke trails over a few ticks
	self._spawn_running = self._spawn_running + 1
	s:start(function()
		for i = 1, number_of_smoke_trails * self.particle_count_modifier do
			local dist = rng:randf(scale * 0.25, scale * 0.8)
			local dx, dy = rng:random_vec2_times(dist)
			local size = abs((pow(1 - (dist / scale), 1)) * scale * rng:randfn(1.0, 0.25) * 0.35) * 1.5
			size = min(size, rng:randfn(3, 1))
			local dir_x, dir_y = vec2_normalized(dx, dy)
			local force = rng:randf(size * 0.05, size * 0.005)
			local h_force_x, h_force_y = dir_x * force * 6.5, dir_y * force * 6.5
			local v_force = rng:randf(force * 10.85, force * 2.25)
			self:_add_smoke_trail(self.pos.x + dx, self.pos.y + dy, size, h_force_x, h_force_y, -v_force, rng(-1, -5))
			if rng:percent(10) then
				s:wait(1)
			end
		end
		self._spawn_running = self._spawn_running - 1
		if self._spawn_running == 0 then self._spawning_done = true end
	end)
	self:die()
end

function Explosion:draw()
    if self.explode_vfx then
        return
    end
	if self.no_effect then
		return
	end

    if self.tick < 5 then
		graphics.set_color(Palette.explosion:get_color_clamped(idiv(self.tick, 3)))
		local size = min(max(self.size - self.tick * 0.25, 2), self.tick * 20) * 2 * self.draw_scale
		graphics.rectangle("fill", -size / 2, -size/2, size, size)
		size = size + self.tick * 3
		graphics.rectangle("line", -size / 2, -size/2, size, size)
	end

	-- Draw internal smoke puffs
	for _, puff in self.smoke_puffs:ipairs() do
		local size = min(max(puff.size - puff.tick * 0.25, 2), min(puff.tick * 60, puff.size))
		graphics.set_color((puff.from_trail and Palette.explosion_smoke or Palette.explosion):get_color_clamped(idiv(puff.tick * puff.color_tick_speed, 2)))
		local x, y = self:to_local(puff.x, puff.y)
		graphics.rectangle(puff.tick > 10 and "line" or "fill", x - size / 2, y - size / 2 + puff.y_offset, size, size)
	end

	-- Draw internal smoke trails (main blob + marks)
	for _, trail in self.smoke_trails:ipairs() do
		if not (trail.tick > 20 and iflicker(gametime.tick, 1, 2)) then
			local size = trail.size
			graphics.set_color((Palette.explosion):get_color_clamped(idiv(trail.tick, 9)))
			local x, y = self:to_local(trail.x, trail.y)
			graphics.rectangle(trail.tick < trail.fill_time and "fill" or "line", x - size / 2, y - size / 2 + trail.y_offset, size, size)
		end
		for i, v in ipairs(trail.positions) do
			local pos_x, pos_y = self:to_local(v.pos_x, v.pos_y)
			local size = min(max(v.size - v.tick * 0.125, 0.5), v.tick * 6)
			local color = (Palette.explosion_smoke):get_color_clamped(idiv(v.tick * v.palette_tick_length + 1, 2))
			graphics.set_color(color)
			graphics.rectangle("line", pos_x - size / 2, pos_y - size / 2 + v.y_offset, size, size)
		end
	end
end

function Explosion:die()
	-- Defer actual destruction until particles have finished
	self._spawning_done = true
end

-- ===============================
-- Internal particle system helpers and updates
-- ===============================

local DRAG = 0.04
local TRAIL_DRAG = 0.015

function Explosion:_add_smoke_puff(x, y, size, duration, y_offset, vel_x, vel_y, from_trail)
	local puff = {
		x = x,
		y = y,
		size = size or 0,
		duration = min(max(duration or 30, 30), 40),
		y_offset = y_offset or 0,
		vel_x = vel_x or 0,
		vel_y = vel_y or 0,
		y_speed = max(rng:randfn(1, 0.5) - (size or 0) * 0.01, 0),
		color_tick_speed = rng:randf(1, 0.15),
		elapsed = 0,
		tick = 0,
		from_trail = from_trail or false,
	}
	self.smoke_puffs:push(puff)
end

function Explosion:_add_smoke_trail(x, y, size, vel_x, vel_y, vel_z, y_offset)
	local trail = {
		x = x, y = y,
		size = size or 0,
		vel_x = vel_x or 0, vel_y = vel_y or 0, vel_z = vel_z or 0,
		y_offset = y_offset or 0,
		positions = {},
		fill_time = rng:randf(30, 8),
		elapsed = 0,
		tick = 0,
	}
	self.smoke_trails:push(trail)
end

function Explosion:update(dt)
	-- Update smoke puffs
	for _, puff in self.smoke_puffs:ipairs() do
		puff.elapsed = puff.elapsed + dt
		if self.is_new_tick then puff.tick = puff.tick + 1 end
		puff.y_offset = puff.y_offset - dt * min(puff.tick * 0.0025, 0.1) * puff.y_speed
		puff.x = puff.x + puff.vel_x * dt
		puff.y = puff.y + puff.vel_y * dt
		puff.vel_x, puff.vel_y = vec2_drag(puff.vel_x, puff.vel_y, DRAG, dt)
		if puff.tick >= puff.duration then
			self.smoke_puffs:queue_remove(puff)
		end
	end

	-- Update smoke trails
	for _, trail in self.smoke_trails:ipairs() do
		trail.elapsed = trail.elapsed + dt
		if self.is_new_tick then trail.tick = trail.tick + 1 end
		trail.y_offset = trail.y_offset + trail.vel_z * dt
		trail.vel_z = trail.vel_z + dt * 0.06
		trail.vel_x, trail.vel_y = vec2_drag(trail.vel_x, trail.vel_y, TRAIL_DRAG, dt)
		trail.x = trail.x + trail.vel_x * dt
		trail.y = trail.y + trail.vel_y * dt
		trail.size = max(trail.size - dt * (0.001  + (trail.tick * 0.001)), 1)

		local vel_mag_sq = trail.vel_x * trail.vel_x + trail.vel_y * trail.vel_y + trail.vel_z * trail.vel_z
		if vel_mag_sq < 0.01 then
			if #trail.positions == 0 then
				self.smoke_trails:queue_remove(trail)
			end
		elseif self.is_new_tick then
			if rng:percent(66) then
				local size = trail.size * 0.9 * rng:randfn(1.0, 0.25)
				table.insert(trail.positions, {
					pos_x = trail.x,
					pos_y = trail.y,
					size = size,
					tick = 0,
					y_offset = trail.y_offset,
					duration = size * rng:randfn(1.0, 1.25) * 7,
					palette_tick_length = rng:randfn(1.0, 0.25),
				})
			end
			if trail.size <= 1 and rng:percent(1) then
				self.smoke_trails:queue_remove(trail)
			end
		end

		for i, v in ipairs(trail.positions) do
			v.tick = v.tick + 1
			v.size = v.size - dt * 0.1
			v.y_offset = v.y_offset - dt * 0.15
		end
		table.fast_remove(trail.positions, function(t, i, j)
			local v = t[i]
			return v.tick < v.duration and v.size > 1
		end)

		if trail.y_offset > 0 then
			trail.y_offset = 0
			trail.vel_z = -trail.vel_z * 0.9
			trail.vel_x = trail.vel_x * 0.5
			trail.vel_y = trail.vel_y * 0.5
		end
	end

	self.smoke_puffs:apply_removals()
	self.smoke_trails:apply_removals()

	if self._spawning_done and self.smoke_puffs:is_empty() and self.smoke_trails:is_empty() then
		self:queue_destroy()
	end
end

function Explosion:floor_draw()
	if self.no_effect or not self.is_new_tick then return end
	-- Floor for smoke puffs
	for _, puff in self.smoke_puffs:ipairs() do
		if puff.tick > 10 and rng:percent(5) then
			local size = min(max(puff.size - puff.tick * 0.25, 2), puff.tick * 6)
			local x, y = self:to_local(puff.x, puff.y)
			graphics.set_color(puff.tick % 2 == 0 and Color.darkergrey or Color.black)
			graphics.rectangle(puff.from_trail and "line" or puff.tick > 10 and "line" or "fill", x - size / 2, y - size / 2, size, size)
		end
	end
	-- Floor for smoke trails
	for _, trail in self.smoke_trails:ipairs() do
		if trail.y_offset < -4 then goto continue end
		local size = max(trail.size * 0.64 + trail.y_offset * 0.02, 1)
		local x, y = self:to_local(trail.x, trail.y)
		graphics.set_color(rng:percent(50) and Color.darkergrey or Color.black)
		if rng:percent(3) then graphics.set_color(Color.grey) end
		graphics.rectangle("line", x - size / 2, y - size / 2, size, size)
		::continue::
	end
end

return Explosion
