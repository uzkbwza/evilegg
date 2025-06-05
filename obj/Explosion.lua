local Explosion = GameObject2D:extend("Explosion")
local ExplosionSmoke = Effect:extend("ExplosionSmoke")
local ExplosionSmokeTrail = GameObject2D:extend("ExplosionSmokeTrail")

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
}

function Explosion:new(x, y, params)
	params = params or DEFAULT_PARAMS
    Explosion.super.new(self, x, y)
	self:add_elapsed_ticks()
    self:add_sequencer()
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
    self.world.game_object_grid:each(x, y, w, h, function(obj)
        if obj.is_simple_physics_object and not obj.is_player and not self.ignore_explosion_force:has(obj) then
            local x, y = obj.pos.x, obj.pos.y
			while x == self.pos.x and y == self.pos.y do
				x, y = vec2_add(obj.pos.x, obj.pos.y, rng:randf(-1, 1), rng:randf(-1, 1))
			end
			local dist = vec2_distance(self.pos.x, self.pos.y, x, y)
			local dx, dy = vec2_direction_to(self.pos.x, self.pos.y, x, y)
			local force = ((self.size / dist) / 2) * self.force_modifier
			obj:apply_force(dx * force, dy * force)
		end
	end)

	self:play_sfx(self.explode_sfx, self.explode_sfx_volume)

    if self.explode_vfx then
        self:spawn_object(self.explode_vfx)
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
	-- self:spawn_object(ExplosionSmoke(self.pos.x, self.pos.y, scale * 1.75, 0, 0, Vec2(0, 0)))
	s:start(function()
		for i = 1, number_of_puffs * self.particle_count_modifier do
			local dist = abs(rng:randfn(0, scale * 0.75))
			dist = min(dist, scale * 1.25)
			local dx, dy = rng:random_vec2_times(dist)
			local size1 = abs((1 - (dist / scale)) * 1)
            local size = abs(size1 * scale * rng:randfn(0.4, 1.25))
			size = abs(min(size, scale * 1))

			local duration = size * rng:randfn(1.0, 1.25) * 10
			local vel = Vec2(dx, dy):normalize_in_place():mul_in_place(rng:randf(0.5, 1) * dist * 0.15)
            self:spawn_object(ExplosionSmoke(self.pos.x + dx, self.pos.y + dy, size, duration, 0, vel))
            if rng:percent(10) then
				s:wait(1)
			end
		end
	end)
	s:start(function()
		for i = 1, number_of_smoke_trails * self.particle_count_modifier do
			local dist = rng:randf(scale * 0.25, scale * 0.8)
			local dx, dy = rng:random_vec2_times(dist)
            local size = abs((pow(1 - (dist / scale), 1)) * scale * rng:randfn(1.0, 0.25) * 0.35) * 1.5
			size = min(size, rng:randfn(3, 1))
			local dir_x, dir_y = vec2_normalized(dx, dy)
			local force = rng:randf(size * 0.05, size * 0.005)
			local h_force_x, h_force_y = dir_x * force, dir_y * force
            local v_force = rng:randf(force * 10.85, force * 2.25)
			h_force_x = h_force_x * 6.5
			h_force_y = h_force_y * 6.5
			local vel = Vec3(h_force_x, h_force_y, -v_force)
            self:spawn_object(ExplosionSmokeTrail(self.pos.x + dx, self.pos.y + dy, size, vel, rng(-1, -5)))
			if rng:percent(10) then
				s:wait(1)
			end
		end
	end)
	self:die()
end

function Explosion:draw()
	if self.explode_vfx then
		return
	end
    if self.tick < 5 then
		graphics.set_color(Palette.explosion:get_color_clamped(idiv(self.tick, 3)))
		local size = min(max(self.size - self.tick * 0.25, 2), self.tick * 20) * 2 * self.draw_scale
		graphics.rectangle("fill", -size / 2, -size/2, size, size)
		size = size + self.tick * 3
		graphics.rectangle("line", -size / 2, -size/2, size, size)
	end
end

function Explosion:die()
	self:start_destroy_timer(60)
end

function ExplosionSmoke:new(x, y, size, duration, y_offset, vel)
    self.y_offset = y_offset or 0
    self.size = size or 0
	self.z_index = 1
    self.duration = min(max(duration or 30, 30), 40)
    ExplosionSmoke.super.new(self, x, y)
	self.vel = vel or Vec2(0, 0)
    self.y_speed = max(rng:randfn(1, 0.5) - self.size * 0.01, 0)
	self.color_tick_speed = rng:randf(1, 0.15)
end


local DRAG = 0.04

function ExplosionSmoke:update(dt)
	self.y_offset = self.y_offset - dt * min(self.tick * 0.0025, 0.1) * self.y_speed
    self.pos = self.pos + self.vel * dt
	self.vel.x, self.vel.y = vec2_drag(self.vel.x, self.vel.y, DRAG, dt)
end

function ExplosionSmoke:draw()
    local size = min(max(self.size - self.tick * 0.25, 2), min(self.tick * 60, self.size))
    -- if self.outline then
    -- graphics.set_color(Color.black)
    -- graphics.rectangle("fill", -size / 2 - 1, -size/2 + self.y_offset - 1, size + 2, size + 2)
    -- else
    graphics.set_color((self.from_trail and Palette.explosion_smoke or Palette.explosion):get_color_clamped(idiv(
    self.tick * self.color_tick_speed, 2)))
    graphics.rectangle(self.tick > 10 and "line" or "fill", -size / 2, -size / 2 + self.y_offset, size, size)
    -- end
end

function ExplosionSmoke:floor_draw()
	if self.tick <= 10 then return end
    local size = min(max(self.size - self.tick * 0.25, 2), self.tick * 6)
	
	if not self.is_new_tick then return end
	if not rng:percent(5) then return end

	graphics.set_color(self.tick % 2 == 0 and Color.darkergrey or Color.black)
	graphics.rectangle(self.from_trail and "line" or self.tick > 10 and "line" or "fill", -size / 2, -size / 2, size, size)
end

function ExplosionSmoke:get_draw_offset()
	local x, y = Explosion.super.get_draw_offset(self)
	return x, y + self.y_offset
end

function ExplosionSmokeTrail:new(x, y, size, vel, y_offset)
    ExplosionSmokeTrail.super.new(self, x, y)
	self:add_elapsed_ticks()
    self.y_offset = y_offset or 0
    self.size = size or 0
    self.vel = vel or Vec3(0, 0, 0)
    self.positions = {}
	self.fill_time = rng:randf(30, 8)
	-- self.z_index = -1
end

local TRAIL_DRAG = 0.015

function ExplosionSmokeTrail:update(dt)
    self.y_offset = self.y_offset + self.vel.z * dt
	self.vel.z = self.vel.z + dt * 0.06
	self.vel.x, self.vel.y = vec2_drag(self.vel.x, self.vel.y, TRAIL_DRAG, dt)
    self.pos = self.pos + self.vel * dt
    self.size = max(self.size - dt * (0.001  + (self.tick * 0.001)), 1)
    -- TODO: just track your route (make a mixin? and draw the trail)
	if self.vel:magnitude() < 0.1 then
		if  #self.positions == 0 then
			self:queue_destroy()
		end
    elseif self.is_new_tick then
        -- local smoke = self:spawn_object(ExplosionSmoke(self.pos.x, self.pos.y, self.size * 0.9, self.size, self.y_offset))
        -- smoke.from_trail = true
        if rng:percent(66) then
            local size = self.size * 0.9 * rng:randfn(1.0, 0.25)
            table.insert(self.positions, {
                pos = self.pos:clone(),
                size = size,
                tick = 0,
                y_offset = self.y_offset,
                duration = size * rng:randfn(1.0, 1.25) * 7,
                palette_tick_length = rng:randfn(1.0, 0.25),
            })
        end
        if self.size <= 1 and rng:percent(1) then
			self:queue_destroy()
		end
    end


	for i, v in ipairs(self.positions) do
		v.tick = v.tick + 1
		v.size = v.size - dt * 0.1
		v.y_offset = v.y_offset - dt * 0.15

	end
	table.fast_remove(self.positions, function(t, i, j)
		local v = t[i]
		return v.tick < v.duration and v.size > 1
	end)

	if self.y_offset > 0 then
        self.y_offset = 0
		self.vel.z = -self.vel.z * 0.9
		self.vel:mul_in_place(0.5)
	end

end
function ExplosionSmokeTrail:draw()
	if self.tick > 20 and idivmod_eq_zero(gametime.tick, 1, 2) then
        return
	end

    local size = self.size
    -- if self.outline then
    -- graphics.set_color(Color.black)
    -- graphics.rectangle("fill", -size / 2 - 1, -size/2 + self.y_offset - 1, size + 2, size + 2)
    -- else
    graphics.set_color((Palette.explosion):get_color_clamped(idiv(
		self.tick, 9)))
    graphics.rectangle(self.tick < self.fill_time and "fill" or "line", -size / 2, -size / 2 + self.y_offset, size, size)
	for i, v in ipairs(self.positions) do
		local pos_x, pos_y = self:to_local(v.pos.x, v.pos.y)
        local size = min(max(v.size - v.tick * 0.125, 0.5), v.tick * 6)
		local color = (Palette.explosion_smoke):get_color_clamped(idiv(
			v.tick * v.palette_tick_length + 1, 2))
		graphics.set_color(color)
        graphics.rectangle("line", pos_x - size / 2, pos_y - size / 2 + v.y_offset, size, size)
	end
end

function ExplosionSmokeTrail:floor_draw()
    if not self.is_new_tick then return end
	if self.y_offset < -4 then return end
	-- if not idivmod_eq_zero(self.tick, 1, 3) then return end
    local size = self.size * 0.64
	size = max(size + self.y_offset * 0.02, 1)
    -- if self.outline then
    -- graphics.set_color(Color.black)
    -- graphics.rectangle("fill", -size / 2 - 1, -size/2 + self.y_offset - 1, size + 2, size + 2)
    -- else
    graphics.set_color(rng:percent(50) and Color.darkergrey or Color.black)
	if rng:percent(3) then
		graphics.set_color(Color.grey)
	end
    graphics.rectangle("line", -size / 2, -size / 2, size, size)
end


return Explosion
