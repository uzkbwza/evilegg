local Cultist = BaseEnemy:extend("Cultist")
local CultistBullet = BaseEnemy:extend("CultistBullet")
local CultistBulletFx = Effect:extend("CultistBulletFx")
local FloorParticle = GameObject2D:extend("FloorParticle")
local PullParticle = GameObject2D:extend("PullParticle")
local BiteParticle = Effect:extend("BiteParticle")
local PowerupParticle = Effect:extend("PowerupParticle")
local PULL_RADIUS = 90
local PULL_FORCE = 0.0355
local GRAB_SPEED = 3
local GRAB_TIME = 50
local GRAB_RADIUS = 12
local HURT_TIME = 49

Cultist.spawn_cry = "enemy_cultist_spawn"
Cultist.spawn_cry_volume = 0.8
Cultist.death_cry = "enemy_cultist_death"
Cultist.death_cry_volume = 0.8

function Cultist:new(x, y)
    self.body_height = 7
    self.max_hp = 9
	self.hit_bubble_radius = 4
    Cultist.super.new(self, x, y)
	self.walk_speed = 0.0475
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self.declump_radius = 9
    self.declump_mass = 1.0
	self.declump_force = (self.declump_force or 0.005)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
	
	self.pull_time = 0
	self.bullet_push_modifier = 1.0
	self.particles = {}
	self.nearby_rescues = {}
	self:ref_bongle("held_rescues")
	self.hold_positions = {}
end

function Cultist:enter()
	self:add_hurt_bubble(0, -4, 3, "main")
	self:add_hurt_bubble(0, 0, 5, "main2")
    self:add_hurt_bubble(0, 3, 5, "main3")
    self:ref("floor_particle", self:spawn_object(FloorParticle(0, 0, self)))
	self:ref("pull_particle", self:spawn_object(PullParticle(0, 0, self)))
    self:add_exit_function(function()
		if self.floor_particle then
            self.floor_particle:finish()
		end
	end)
end

function Cultist:get_sprite()
	return textures.enemy_cultist
end

function Cultist:entity_declump_filter(other)
	if table.is_empty(self.hold_positions) then
		return true
	end
	return false
end

function Cultist:walk_toward_target(dt)
	local closest = nil

	local closest_dist = math.huge
	local rescue_objects = self:get_objects_with_tag("rescue_object")
	if rescue_objects then
		for _, rescue in rescue_objects:ipairs() do
			local dist = self:body_distance_to(rescue)
			if rescue.grabbed_by_cultist then
				goto continue
			end
			if dist < closest_dist then
				closest_dist = dist
				closest = rescue
			end
			::continue::
		end
	end

	if not closest then
		closest = self:get_closest_player()
	end

	if closest then
		local bx, by = self:get_body_center()
		local cx, cy = closest:get_body_center()
		local dx, dy = cx - bx, cy - by
		local direction_x, direction_y = vec2_normalized(dx, dy)
		self:apply_force(direction_x * self.walk_speed, direction_y * self.walk_speed)
	end
end

function Cultist:update(dt)
    if self.held_rescues:length() == 0 then
        self:walk_toward_target(dt)
        self.bullet_push_modifier = 1.0
    else
        self.bullet_push_modifier = 0.25
        -- self.applying_forces = false
        -- self.vel:mul_in_place(0)
    end

    self.floor_particle:move_to(self:get_body_center())
    local bx, by = self:get_body_center()
    local x, y, w, h = bx - PULL_RADIUS, by - PULL_RADIUS, PULL_RADIUS * 2, PULL_RADIUS * 2

	if self.tick > 100 then
    	self.world.rescue_grid:each_self(x, y, w, h, self.gather_nearby_rescues, self)
	end

    local pulled = false
    local held = table.length(self.hold_positions) > 0

    for _, rescue in ipairs(self.nearby_rescues) do
        local dist = self:body_distance_to(rescue)
        if dist < GRAB_RADIUS and self.pull_time > 90 then
            if not self.hold_positions[rescue] then
                self:ref_bongle_push("held_rescues", rescue)
                -- self.nearby_rescues[rescue] = nil
                rescue.grabbed_by_cultist = true
                local rescue_pos = Vec2(self:to_local(rescue.pos.x, rescue.pos.y))
                rescue_pos.y = 0
				if rescue_pos.x == 0 then
					rescue_pos.x = rng:rand_sign()
				end
				rescue_pos:normalize_in_place():mul_in_place(GRAB_RADIUS)
                self.hold_positions[rescue] = rescue_pos

                local s = self.sequencer
                local co = s:start(function()
                    while rescue.hp > 1 do
                        self:spawn_object(BiteParticle(bx, by))
                        self:play_sfx("enemy_cultist_bite")

                        s:wait(HURT_TIME)
                        if not self.hold_positions[rescue] then
                            return
                        end
                        rescue:damage(1)
                        self:start_timer("heal_fx", 25)
                        self:heal(4, true)
                    end
                    self:spawn_object(BiteParticle(bx, by))
                    self:play_sfx("enemy_cultist_bite")

                    s:wait(HURT_TIME)
                    -- while rng:percent(80) do
                    s:wait(10)
                    -- end
                    if not self.hold_positions[rescue] then
                        return
                    end
                    rescue:damage(1)
                    self:heal(2, true)
                    self.powered_up = true
                    self:play_sfx("enemy_cultist_powerup")
                    local bx_, by_ = self:get_body_center()
                    self:spawn_object(PowerupParticle(bx_, by_))
                    self:spawn_rescue_projectile()
                end)
                signal.connect(rescue, "destroyed", self, "on_held_rescue_destroyed", function()
                    self.hold_positions[rescue] = nil
                    s:stop(co)
                end, true)
                -- else
            end
        else
            pulled = true
            local dx, dy = self:body_direction_to(rescue)
            rescue:apply_force(-dx * PULL_FORCE, -dy * PULL_FORCE)
            if self.is_new_tick and rng:percent(80) then
                for i = 1, rng:randi(1, 2) do
                    self.pull_particle:add_particle(rescue:get_body_center())
                end
            end
        end
    end
	
    if table.is_empty(self.nearby_rescues) then
        self:stop_sfx("enemy_cultist_grab")
    end
    table.clear(self.nearby_rescues)

    if held then
        self:play_sfx_if_stopped("enemy_cultist_drain", 0.8)
    elseif pulled then
        self:play_sfx_if_stopped("enemy_cultist_grab", 0.75)
    end

    if not held then
        self:stop_sfx("enemy_cultist_drain")
    end
    if not pulled then
        self:stop_sfx("enemy_cultist_grab")
    end

	if pulled then
		self.pull_time = self.pull_time + dt
    else
		self.pull_time = 0
	end

	if self.powered_up then
		self:play_sfx_if_stopped("enemy_cultist_powered_up")
	else
		self:stop_sfx("enemy_cultist_powered_up")
	end

    for _, rescue in self.held_rescues:ipairs() do
        local hold_pos = self.hold_positions[rescue]
        if hold_pos then
            rescue:move_to(self:to_global(hold_pos.x, hold_pos.y))
        end
    end
end

function BiteParticle:new(x, y)
    BiteParticle.super.new(self, x, y)
	self.duration = 30
end

function BiteParticle:draw(elapsed, tick, t)
    graphics.set_color(Palette.cultist_heal:tick_color(tick, 0, 2))
	local size = 50 * (ease("inOutCubic")(1 - t)) + 10
    graphics.rectangle_centered("line", 0, 0, size, size)
end

function PowerupParticle:new(x, y)
    PowerupParticle.super.new(self, x, y)
    self.duration = 40
end

function PowerupParticle:draw(elapsed, tick, t)
	graphics.set_line_width(1)
	local size = 200 * (ease("outCubic")(t)) + 10
	graphics.set_color(Palette.cultist_heal:tick_color(tick, 0, 2))
    graphics.rectangle_centered("line", 0, 0, size, size)
    if size - 10 > 0 then
        graphics.rectangle_centered("line", 0, 0, size - 10, size - 10)
		graphics.set_color(Palette.cultist_heal:tick_color(tick + 4, 0, 2))
    end
	if size - 20 > 0 then
		graphics.set_color(Palette.cultist_heal:tick_color(tick + 8, 0, 2))
		graphics.rectangle_centered("line", 0, 0, size - 20, size - 20)
	end
	if size - 30 > 0 then
		graphics.set_color(Palette.cultist_heal:tick_color(tick + 12, 0, 2))
		graphics.rectangle_centered("line", 0, 0, size - 30, size - 30)
	end
	
end

function Cultist:spawn_rescue_projectile()
    -- local projectile = self:spawn_object(CultistProjectile(x, y))
    -- projectile.target = self:get_closest_player()

    local s = self.sequencer
    local num_projectiles = rng:randi(2, 5)
    if rng:percent(10) then
		num_projectiles = num_projectiles + rng:randi(1, 3)
	end
	s:start(function()
        for i = 1, num_projectiles do
			local x, y = self:get_body_center()

			local projectile = self:spawn_object(CultistBullet(x, y))
			projectile:apply_impulse(rng:random_vec2_times(1.15))
			s:wait(15)
		end
    end)
	self:start_tick_timer("spawn_projectile", rng:randi(20, 50) * num_projectiles, function()
        if self.powered_up then
			self:spawn_rescue_projectile()
		end
	end)
end

function Cultist:exit()
	self:stop_sfx("enemy_cultist_drain")
	self:stop_sfx("enemy_cultist_grab")
	self:stop_sfx("enemy_cultist_powered_up")
	for _, rescue in self.held_rescues:ipairs() do
		rescue.grabbed_by_cultist = nil
	end
end

function Cultist:filter_melee_attack(bubble)
	if bubble.parent:has_tag("rescue_object") then
		return false
	end
	return true
end

function Cultist.gather_nearby_rescues(other, self)
    if other.grabbed_by_cultist then
        return
    end
    local dist = self:body_distance_to(other)

    if dist < PULL_RADIUS then
        table.insert(self.nearby_rescues, other)
    end
end

function Cultist:get_palette()
	local palette, offset = Cultist.super.get_palette(self)
	
	if palette == nil and offset == nil and (self.powered_up or self:is_timer_running("heal_fx")) then
        palette = Palette.cultist_heal
		offset = idiv(self.tick, 3)
	end

	return palette, offset
end

function Cultist:draw()
	self:body_translate()

	local palette, offset = self:get_palette_shared()

	graphics.drawp_centered(self:get_sprite(), palette, offset, 0, 0, 0, self.flip, 1)

	if debug.can_draw_bounds() then
		graphics.set_color(Color.green)
		graphics.circle("line", 0, 0, PULL_RADIUS)
	end
end

function PullParticle:new(x, y, parent)
    PullParticle.super.new(self, x, y)
	self:add_time_stuff()
	self.particles = {}
	self.z_index = 1
	self:ref("parent", parent)
end

function PullParticle:finish()
    self.done = true
end

function PullParticle:update(dt)
    if self.parent ~= nil then
        for particle, _ in pairs(self.particles) do
            local bx, by = self.parent:get_body_center()
            particle.end_x = bx
            particle.end_y = by
        end
    end
	for particle, _ in pairs(self.particles) do
		particle.elapsed = particle.elapsed + dt
	end
end

function PullParticle:add_particle(start_x, start_y)
	local particle = {}
	local bx, by = self.parent:get_body_center()
	local offset_x, offset_y = rng:random_vec2_times(rng:randf(10, 2))
	particle.start_x = start_x + offset_x
    particle.start_y = start_y + offset_y

	local end_offset_x, end_offset_y = rng:random_vec2_times(rng:randf(10, 2))
	particle.end_offset_x = end_offset_x
    particle.end_offset_y = end_offset_y
	
	particle.end_x = bx
	particle.end_y = by
    particle.t = 0
	particle.elapsed = 0
    particle.size = rng:randf(0.25, 1) * 4
	self.particles[particle] = true

	local s = self.sequencer
    s:start(function()
        s:tween_property(particle, "t", 0, 1, rng:randfn(20, 5), "inOutQuad")
		self.particles[particle] = nil
	end)
end

function PullParticle:draw()
	for particle, _ in pairs(self.particles) do
        local x, y = self:to_local(vec2_lerp(particle.start_x, particle.start_y, particle.end_x + particle.end_offset_x, particle.end_y + particle.end_offset_y,
        particle.t))
		
		local color = Color.red
        if iflicker(particle.elapsed, 6, 2) then
            color = Color.blue
        end
		if iflicker(particle.elapsed, 1, 3) then
            color = Color.black
		end
		if iflicker(particle.elapsed, 1, 7) then
            color = Color.white
		end
        graphics.set_color(color)
        local size = particle.size * remap01_lower(particle.t, 0.5)
		local fill_ = "fill"
		if iflicker(particle.elapsed, 3, 2) then
            size = size * 1.3
			fill_ = "line"
		end
		graphics.rectangle_centered(fill_, x, y, size, size)
	end
end

function FloorParticle:new(x, y, parent)
    FloorParticle.super.new(self, x, y)
    self:add_time_stuff()
    self.particles = {}
    self.z_index = -1
	self:ref("parent", parent)
end

function FloorParticle:finish()
	self.done = true
	for particle, _ in pairs(self.particles) do
		particle.outward_speed = abs(rng:randfn(2, 0.5))
	end
end

function FloorParticle:update(dt)
	if self.parent ~= nil then
		if self.is_new_tick and not self.done and rng:percent(40 * (1 + (self.parent.hp - 4) / 3)) then
			local particle = {}
			particle.dist = rng:randf(12, 64) * (1 + (self.parent.hp - 4) / 6)
			particle.start_angle = rng:randf(0, tau)
			particle.t = 0
			particle.visible = rng:percent(25)
			particle.angle_offset = 0
			particle.elapsed = 0
			particle.outward_offset = 0
			particle.outward_speed = 0
			particle.final_offset = rng:randf(-1, 1) * tau
			particle.size = rng:randf(0.25, 1) * 4 * (1 + (self.parent.hp - 4) / 8)
			particle.offset = rng:randf(0, tau)
			self.particles[particle] = true
		end
	end

    if self.done and table.is_empty(self.particles) then
        self:queue_destroy()
    end
    for particle, _ in pairs(self.particles) do
        particle.elapsed = particle.elapsed + dt
		particle.t = particle.elapsed / 190
        particle.angle_offset = particle.angle_offset + dt * (1 / 190) * (self.done and 0.15 or 1)
        if particle.t >= 1 then
            self.particles[particle] = nil
        end
        particle.outward_offset = particle.outward_offset + particle.outward_speed * dt
		particle.outward_speed = drag(particle.outward_speed, 0.1, dt)
	end
end

function FloorParticle:get_particle_position(particle)
    local dist = particle.dist * (1 - particle.angle_offset)
	dist = remap_lower(dist, 0, particle.dist, 10)
	local angle = particle.start_angle + particle.offset + particle.angle_offset * particle.final_offset
	local vx, vy = polar_to_cartesian(dist + particle.outward_offset, angle)
	return vx, vy
end

function FloorParticle:draw()
	if true then return end

	-- graphics.set_color(1, 1, 1, 1)
    for particle, _ in pairs(self.particles) do
		if not particle.visible then goto continue end

        local size = particle.size * (particle.angle_offset)

		local vx, vy = self:get_particle_position(particle)
		local color = Color.red
		if iflicker(particle.elapsed, 6, 2) then
			color = Color.blue
		end
        graphics.set_color(color)
		-- if size >= 0.1 then
		graphics.rectangle_centered("fill", vx, vy, size, size)
        -- elseif iflicker(particle.elapsed, 1, max(1, floor(10 - particle.elapsed / 4))) then
			-- graphics.points(vx, vy)
		-- end
		::continue::
    end
end

function FloorParticle:floor_draw()
    if not self.is_new_tick then
        return
    end

	if not self.done then
		graphics.set_color(0, 0, 0, 1)
		
		for i = 1, rng:randi(1, 3) do
			local size = rng:randf(2, 5)
			local vx, vy = rng:random_vec2_times(rng:randfn(0, 3))
			graphics.rectangle_centered("fill", vx, vy, size, size)
		end
	end
	
    for particle, _ in pairs(self.particles) do

		if rng:percent(60) then goto continue end
		local alpha = abs(rng:randfn(0.35, 0.055)) * particle.angle_offset
		graphics.set_color(alpha * 1, alpha * 0.1, 0)
		local size = particle.size * (particle.angle_offset)
		local vx, vy = self:get_particle_position(particle)
		graphics.rectangle_centered("fill", vx, vy, size, size)
		::continue::
	end
end


local BULLET_HOMING_SPEED = 0.17

CultistBullet.enemy_bullet_can_touch_walls = true
CultistBullet.home_time = 48
CultistBullet.death_sfx = "enemy_cultist_bullet_die"

local MAX_SPEED = 4.5

local bullet_physics_limits = {
	max_speed = MAX_SPEED
}


function CultistBullet:new(x, y)
	self.max_hp = 1
    CultistBullet.super.new(self, x, y)
    self.drag = 0.0001
    self.hit_bubble_radius = 3
	self.hurt_bubble_radius = 6
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    -- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.z_index = 10
	self.floor_draw_color = Palette.rainbow:get_random_color()
	self:set_physics_limits(bullet_physics_limits)
end

function CultistBullet:enter()
	self:play_sfx("enemy_cultist_bullet_spawn")
end

function CultistBullet:on_terrain_collision(normal_x, normal_y)
    if self.tick < self.home_time then
        self:terrain_collision_bounce(normal_x, normal_y)
        return
    end
	self:die()
end

function CultistBullet:get_sprite()
    -- return self:tick_pulse(3) and textures.enemy_enforcer_bullet1 or textures.enemy_enforcer_bullet2
	return textures.enemy_cultist_bullet
end

-- function CultistBullet:collide_with_terrain()
-- 	return false
-- end

function CultistBullet:get_palette()
	local palette, offset = CultistBullet.super.get_palette(self)

	return palette, offset or self.tick / 2
end

function CultistBullet:update(dt)
    if vec2_magnitude(self.vel.x, self.vel.y) < 0.05 then
        self:die()
    end

	local player = self:get_closest_player()
    if player and self.tick > self.home_time and self.tick < 400 then
        local pdx, pdy = vec2_direction_to(self.pos.x, self.pos.y, player.pos.x, player.pos.y)
        local homing_speed = BULLET_HOMING_SPEED * (1.0 - self.tick / 400)
        self:apply_force(pdx * homing_speed, pdy * homing_speed)
    end
    if self.is_new_tick then 
		local bx, by = self:get_body_center()
		self:spawn_object(CultistBulletFx(vec2_add(bx, by, rng:random_vec2_times(rng:randf(0, 2)))))
        if self.tick == self.home_time then
			self:play_sfx("enemy_cultist_bullet_home")
		end
	end
end

function CultistBulletFx:new(x, y)
    CultistBulletFx.super.new(self, x, y)
	self.duration = 10
    -- self.z_index = 10
end

function CultistBulletFx:draw(elapsed, tick, t)
    graphics.set_color(Palette[textures.enemy_cultist_bullet]:tick_color((self.world.tick + tick) * 0.25))
    if self.tick == 2 then
		graphics.set_color(Color.black)
	end
    local size = 6
	size = remap_lower(size * (1 - t), 0, 12, 5)
	graphics.rectangle_centered("line", 0, 0, size, size)
end




-- local COLOR_MOD = 0.9

-- function CultistBullet:floor_draw()
--     local scale = pow(1.0 - self.tick / 600, 1.5)
--     graphics.set_color(scale * COLOR_MOD, 0, 1.0 - scale * COLOR_MOD, 1)
--     if self.is_new_tick and self.tick % 4 == 0 and scale > 0.1 then
-- 		local palette, offset = self:get_palette()
--         local sprite = self:get_floor_sprite()
		
-- 		graphics.scale(scale, scale)
-- 		graphics.drawp_centered(sprite, palette, offset, 0, 0)
-- 	end
-- end

AutoStateMachine(Cultist, "Waiting")

return Cultist
