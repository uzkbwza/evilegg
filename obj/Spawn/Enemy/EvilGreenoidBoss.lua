local EvilGreenoidBoss = BaseEnemy:extend("EvilGreenoidBoss")

local ThrashProjectile = BaseEnemy:extend("ThrashProjectile")
local TargetedBullet = BaseEnemy:extend("TargetedBullet")
local CoilBullet = BaseEnemy:extend("CoilBullet")
local ThrashIndicator = Effect:extend("ThrashIndicator")

local GREENOID_ORBIT_RADIUS = 22
local ORBIT_SPEED = 0.05

function EvilGreenoidBoss:new()
    self.max_hp = 20
	self.terrain_collision_radius = 16
    self.hit_bubble_radius = 14
	self.hurt_bubble_radius = 16

    EvilGreenoidBoss.super.new(self, 0, 0)

	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self:lazy_mixin(Mixins.Behavior.TrackPreviousPosition2D)

    self.greenoid_health = 0
    self.greenoid_max_health = 80
    self.greenoid_damage = 0.0

    self.z_index = 0.1
	
	self.phase = 1
	
	self.greenoids = {}
end

function EvilGreenoidBoss:update(dt)
    EvilGreenoidBoss.super.update(self, dt)
    for i, greenoid in ipairs(self.greenoids) do
        self:update_greenoid(greenoid, dt)
    end

	if self.finished_spawning and self.phase == 1 and self.greenoid_health < self.greenoid_max_health * 0.75 then
		self.phase = 2
	end
end


function EvilGreenoidBoss:try_start_targeted_bullet_burst()
	if game_state.egg_rooms_cleared > 0 and self.is_new_tick and not self:is_tick_timer_running("targeted_bullet_burst") and self.greenoid_health < self.greenoid_max_health * 0.4 then
		self:start_tick_timer("targeted_bullet_burst", 90 * rng:randi(1, 3))
		self:targeted_bullet_burst()
	end
end

function EvilGreenoidBoss:get_sprite()
    return textures.enemy_evil_greenoid_core
end

function EvilGreenoidBoss:damage(amount)
	
	if self.greenoid_health > 0 then
        self.greenoid_damage = self.greenoid_damage + amount * (self.greenoid_max_health / 250)
        while self.greenoid_damage >= 1 and self.greenoid_health > 0 do
			self:take_greenoid_damage()
		end
	else
		self:set_hp(self.hp - amount)
	end
end

function EvilGreenoidBoss:take_greenoid_damage()
    self.greenoid_health = self.greenoid_health - 1
    self.greenoid_damage = self.greenoid_damage - 1
	self:kill_greenoid()
end

function EvilGreenoidBoss:state_Spawning_enter()
    self.melee_attacking = false
    self.intangible = true
    self:start_tick_timer("spawn_sound", 10, function()
		self:play_sfx("enemy_yolk_spawn")
	end)
end

function EvilGreenoidBoss:state_Spawning_update(dt)
    if self.is_new_tick and not self.finished_spawning then
		for i = 1, 3 do
            self.greenoid_health = self.greenoid_health + 1
            self:add_greenoid()
            if self.greenoid_health >= self.greenoid_max_health then
                self.finished_spawning = true
                self:start_tick_timer("finished_spawning", 60, function()
					self.intangible = false
					self.melee_attacking = true
					self:change_state("Idle")
				end)
            end
        end
    end

end

function EvilGreenoidBoss:update_greenoid(greenoid, dt)
    greenoid.elapsed = greenoid.elapsed + dt
    greenoid.tick = floor(greenoid.elapsed)
	greenoid.x, greenoid.y = splerp_vec(greenoid.x, greenoid.y, self.pos.x, self.pos.y, greenoid.follow_speed, dt)
end

function EvilGreenoidBoss:add_greenoid()
    local greenoid = {
        elapsed = 0,
		palette_offset = rng:randi(0, 500),
        angle = rng:random_angle(),
        orbit_width = clamp01(rng:randfn(0.5, 0.25)),
		orbit_modifier = rng:randfn(1, 0.1),
        orbit_direction = rng:rand_sign(),
		follow_speed = pow(rng:randf(0, 1), 4) * 300,
        orbit_phase = rng:randf(0, 1),
		x = self.pos.x,
        y = self.pos.y,
    }

    if rng:percent(4) then
		greenoid.follow_speed = greenoid.follow_speed * (1 + abs(rng:randfn(0, 5)))
	end
	greenoid.tick = floor(greenoid.elapsed)
    table.insert(self.greenoids, greenoid)
end

function EvilGreenoidBoss:kill_greenoid()
    table.remove(self.greenoids)
end


function EvilGreenoidBoss:is_greenoid_behind(greenoid)
	return cos(greenoid.elapsed * ORBIT_SPEED + greenoid.orbit_phase * tau) < 0
end

function EvilGreenoidBoss:get_greenoid_pos(greenoid)

	local radius = GREENOID_ORBIT_RADIUS * greenoid.orbit_modifier

	local extra_radius_ratio = ease("inCubic")(remap_clamp(greenoid.elapsed, 0, 60, 1, 0))

	local extra_radius = 400

	local x = sin(greenoid.elapsed * ORBIT_SPEED + greenoid.orbit_phase * tau * greenoid.orbit_direction) * (radius + extra_radius_ratio * extra_radius)
    local y = cos(greenoid.elapsed * ORBIT_SPEED + greenoid.orbit_phase * tau) * lerp(greenoid.orbit_width, 1, extra_radius_ratio) * (radius + extra_radius_ratio * extra_radius)
	

	local gx, gy = self:to_local(greenoid.x, greenoid.y)

    x, y = vec2_rotated(x, y, greenoid.angle)
	x = x + gx
	y = y + gy

	return x, y
end

function EvilGreenoidBoss:state_Idle_enter()
    local s = self.sequencer
    s:start(function()
        s:wait(rng:randi(1, max(2 - game_state.egg_rooms_cleared, 1)) * 30)
		self:change_state(self:get_next_attack())
	end)
end

function EvilGreenoidBoss:state_Idle_update(dt)
	self:try_start_targeted_bullet_burst()
end

function EvilGreenoidBoss:get_next_attack()

    local attack = nil
	local dict = {}

	if self.phase == 1 then
		dict = {
			-- Thrash = 4,
			CoilBullets = 20 * self:spawning_bullets_weight(),
            CoilBullets2 = 20 * self:spawning_bullets_weight(),
			Idle = 1,
		}
	else
		dict = {
			Thrash = 60,
			CoilBullets = 20 * self:spawning_bullets_weight(),
			CoilBullets2 = 20 * self:spawning_bullets_weight(),
			Idle = 1,
		}
	end

    if self.last_attack then
		dict[self.last_attack] = dict[self.last_attack] * 0.3
	end

	attack = rng:weighted_choice_dict(dict)

	self.last_attack = attack

	return attack
end

function EvilGreenoidBoss:spawning_bullets_weight()
	return self.spawning_bullets and 0 or 1
end


function EvilGreenoidBoss:state_Thrash_enter(dt)
    self:play_sfx("enemy_yolk_start_thrash", 1, 1.0)
    if rng:percent(25) then
        local new_x, new_y = rng:random_4_way_direction()

        while new_x == self.thrash_x and new_y == self.thrash_y do
            new_x, new_y = rng:random_4_way_direction()
        end
        self.thrash_x, self.thrash_y = new_x, new_y
    elseif rng:percent(60) then
        local pbx, pby = self:to_local(self:closest_last_player_body_pos())
        self.thrash_x, self.thrash_y = vec2_to_cardinal(pbx, pby)
    else
        local pbx, pby = self:to_local(self:closest_last_player_body_pos())
        self.thrash_x, self.thrash_y = vec2_normalized(pbx, pby)
    end
	local s = self.sequencer
	-- s:start(function()
		-- s:wait(2)
		self:spawn_object(ThrashIndicator(self.pos.x, self.pos.y, self.thrash_x, self.thrash_y))
	-- end)
    self.thrash_started = false
    -- self:try_start_targeted_bullet_burst()
end


function EvilGreenoidBoss:state_Thrash_update(dt)
    if not self.thrash_started then
        self:apply_force(vec2_mul_scalar(self.thrash_x, self.thrash_y, -0.2))
        if self.is_new_tick and self.state_tick >= 25 then
            self.thrash_started = true

        end
    else
        self:apply_force(vec2_mul_scalar(self.thrash_x, self.thrash_y, 1.0))
        self:play_sfx_if_stopped("enemy_yolk_start_thrash_movement", 1)
    end

    if self.state_tick >= 35 then
		self.can_wall_slam = true
	end

    if self.state_tick >= 120 then
        self:change_state("Idle")
        return
    end
	self:try_start_targeted_bullet_burst()

end

function EvilGreenoidBoss:state_Thrash_exit()
    self:stop_sfx("enemy_yolk_start_thrash_movement")
    self.can_wall_slam = false
end


function EvilGreenoidBoss:spawn_thrash_projectiles()
	local start_angle = rng:random_angle()
	local num_spawns = 11
	local num_bullets_per_spawn = 6
    local min_speed = 1.6
    local max_speed = 2.6
    local s = self.sequencer
	local x, y = self.pos.x, self.pos.y

	s:start(function()
		for i = 1, num_spawns do
			for j = 1, num_bullets_per_spawn do
				local ang_offset = (tau / (num_bullets_per_spawn))
				local angle = start_angle + j * (tau / num_bullets_per_spawn) + rng:randf(-ang_offset, ang_offset)
                local _speed = lerp(max_speed, min_speed, (i - 1) / num_spawns)
				
				local projectile = self.world:spawn_object(ThrashProjectile(x, y))
				local impulse_x, impulse_y = vec2_from_polar(_speed, angle)
				projectile:apply_impulse(impulse_x, impulse_y)
			end
			s:wait(1)
		end
	end)
end


function EvilGreenoidBoss:state_CoilBullets_enter()
    -- self:spawn_thrash_projectiles()
	local s = self.sequencer
	s:start(function()
        s:wait(20)
		local num_bursts = rng:randi(2, 6)
        self:spawn_coil_bullets(num_bursts)
		s:wait(floor(45 / 3) * num_bursts)
		self:change_state("Idle")
	end)
end

function EvilGreenoidBoss:state_CoilBullets2_enter()
    -- self:spawn_thrash_projectiles()
	local s = self.sequencer
	s:start(function()
        s:wait(20)
        self:spawn_coil_bullets2()
        s:wait(50)
		self:change_state("Idle")
	end)
end

function EvilGreenoidBoss:state_CoilBullets_update(dt)
	self:try_start_targeted_bullet_burst()
end

function EvilGreenoidBoss:spawn_coil_bullets2()
	local s = self.sequencer
	
	
    s:start(function()
        while self:get_stopwatch("coil_bullets") do
            s:wait(1)
        end
		
		self:start_stopwatch("coil_bullets")

        self.spawning_bullets = true
	

        local num_waves = 5
		local burst_length = 3
		local added_angle = deg2rad(30)
		-- self.coil_spin_dir = self.coil_spin_dir or rng:rand_sign()
		-- self.coil_spin_dir = self.coil_spin_dir * -1

		local width = 5
		local speed = 3.8
		
		for i = 1, num_waves do
			local stopwatch = self:get_stopwatch("coil_bullets")
			local dx, dy = self:get_body_direction_to_player()

            s:start(function()
				local angle_offset = added_angle * (num_waves - i)
				-- local shot_type = rng:randi(1, 3)
				local shot_type = 1
				for j = 1, burst_length do

					self:play_sfx("enemy_yolk_shoot2", 1, 1.0)
                    if i == num_waves or (i - 2) % 3 == 0 then
						if shot_type == 1 or shot_type == 3 then
							local bullet1 = self.world:spawn_object(CoilBullet(self.pos.x, self.pos.y, 0,
								dx, dy, width, speed))
						end
						if shot_type == 1 or shot_type == 2 then
							local bullet2 = self.world:spawn_object(CoilBullet(self.pos.x, self.pos.y, pi,
								dx, dy, width, speed))
						end
					end
					if i < num_waves then
						for k = -1, 1, 2 do
							local dx2, dy2 = vec2_rotated(dx, dy, k * angle_offset)
							if shot_type == 1 or shot_type == 3 then
								local bullet1 = self.world:spawn_object(CoilBullet(self.pos.x, self.pos.y, 0,
									dx2, dy2, width, speed))
							end
							if shot_type == 1 or shot_type == 2 then
								local bullet2 = self.world:spawn_object(CoilBullet(self.pos.x, self.pos.y, pi,
									dx2, dy2, width, speed))
							end
						end
					end
					s:wait(4)
				end
            end)
			s:wait(15)
		end
		-- s:wait(20)

        self.spawning_bullets = false
		if self:get_stopwatch("coil_bullets") then
			self:stop_stopwatch("coil_bullets")
		end
    end)
end
function EvilGreenoidBoss:spawn_coil_bullets(bursts)
	local s = self.sequencer
	
	
    s:start(function()
        while self:get_stopwatch("coil_bullets") do
            s:wait(1)
        end
		
		self:start_stopwatch("coil_bullets")

        self.spawning_bullets = true
		
		for burst=1, bursts do
			local num_bullets = 3
			local num_waves = 4
			local random_angle = rng:random_angle()
			local angle_offset = tau / num_bullets
			-- self.coil_spin_dir = self.coil_spin_dir or rng:rand_sign()
			-- self.coil_spin_dir = self.coil_spin_dir * -1
			local turn_direction = rng:rand_sign()
			
			for i = 1, num_waves do
				local stopwatch = self:get_stopwatch("coil_bullets")
				self:play_sfx("enemy_yolk_shoot2", 1, 1.0)
				for j = 1, num_bullets do
                    local angle = j * angle_offset + random_angle + turn_direction * 0.016 * stopwatch.elapsed
					if not (self.state == "Thrash" and self.thrash_started) then
						local bullet1 = self.world:spawn_object(CoilBullet(self.pos.x, self.pos.y, 0, vec2_from_angle(angle)))
						local bullet2 = self.world:spawn_object(CoilBullet(self.pos.x, self.pos.y, pi, vec2_from_angle(angle)))
					end
				end
				s:wait(5)
			end
			s:wait(10)
		end
        self.spawning_bullets = false
		if self:get_stopwatch("coil_bullets") then
			self:stop_stopwatch("coil_bullets")
		end
    end)
end

function EvilGreenoidBoss:exit()
	self:stop_sfx("enemy_yolk_start_thrash_movement")
end


function EvilGreenoidBoss:on_terrain_collision(normal_x, normal_y)
    if self.state == "Thrash" then
        self:terrain_collision_bounce(normal_x, normal_y)
		if self.thrash_started and self.can_wall_slam then
            self:change_state("Idle")
			-- print("here")
		end
    else
        self:normal_terrain_collision(normal_x, normal_y)
    end
end

function EvilGreenoidBoss:on_terrain_collision_bounce()
	if self.state == "Thrash" and self.thrash_started and self.can_wall_slam then
		if abs(self.vel.x) > 0.3 or abs(self.vel.y) > 0.3 then
			self.world.camera:start_rumble(5, 15, ease("linear"), self.thrash_x ~= 0, self.thrash_y ~= 0)
            self:play_sfx("enemy_yolk_wall_slam", 1, 1.0)
			self:spawn_thrash_projectiles()
		end
	end
end

function EvilGreenoidBoss:get_palette()
	return nil, idiv(self.tick, 3)
end

function EvilGreenoidBoss:draw()
    for i, greenoid in ipairs(self.greenoids) do
		if self:is_greenoid_behind(greenoid) then
			self:draw_greenoid(greenoid)
		end
	end

    graphics.push()
	graphics.translate(0, sin(self.elapsed * 0.03) * 2)
    if not (self.state == "Spawning" and gametime.tick % 2 == 0) then
        EvilGreenoidBoss.super.draw(self)
    end
	graphics.pop()
	
    for i, greenoid in ipairs(self.greenoids) do
		if not self:is_greenoid_behind(greenoid) then
			self:draw_greenoid(greenoid)
		end
	end
end

function EvilGreenoidBoss:floor_draw()
	if self.state == "Thrash" and self.thrash_started then
		local prev_x, prev_y = self.prev_pos.x, self.prev_pos.y
        local SIZE = 32
        for x, y in bresenham_line_iter(prev_x, prev_y, self.pos.x, self.pos.y) do
            local bx, by = self:get_body_center_local()
            local px, py = self:to_local(bx + x, by + y)
            graphics.push()
			graphics.translate(px, py)
			-- graphics.rotate(tau / 8)
            graphics.set_color(Color.darkpurple)
            -- graphics.rectangle_centered("line", 0, 0, SIZE + 1, SIZE + 1)
			graphics.circle("line", 0, 0, SIZE/2)
            graphics.set_color(Color.black)
            -- graphics.rectangle_centered("fill", 0, 0, SIZE, SIZE)
			graphics.circle("fill", -self.thrash_x, -self.thrash_y, SIZE/2 - 0.5)
			graphics.pop()
        end
	end
end

function EvilGreenoidBoss:draw_greenoid(greenoid)
	local x, y = self:get_greenoid_pos(greenoid)
    graphics.drawp_centered(
        iflicker(greenoid.tick, 2, 2) and textures.enemy_evil_greenoid1 or textures.enemy_evil_greenoid2, nil, idiv(greenoid.tick + greenoid.palette_offset, 3), x, y)
end


function EvilGreenoidBoss:targeted_bullet_burst()
    local s = self.sequencer
	local speed = 5.0
	s:start(function()
        for i = 1, 8 do
            local pbx, pby = self:to_local(self:closest_last_player_body_pos())
            local angle = vec2_angle(pbx, pby)
			
            local bullet = self.world:spawn_object(TargetedBullet(self.pos.x, self.pos.y))
			bullet:apply_impulse(vec2_from_polar(speed, angle))
			self:play_sfx("enemy_yolk_shoot1", 0.8, 1.0)
			s:wait(3)
		end
	end)
end

function ThrashProjectile:new(x, y)
    self.max_hp = 3
    self.terrain_collision_radius = 1
    self.hit_bubble_radius = 1
    self.hurt_bubble_radius = 4
	-- self.bullet_passthrough = true
    ThrashProjectile.super.new(self, x, y)
	self.z_index = 1
    self.drag = 0.0005
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self.bullet_push_modifier = 0.85
	-- self:add_elapsed_ticks()
end

function ThrashProjectile:get_sprite()
    return iflicker(self.tick + self.random_offset, 2, 2) and textures.enemy_yolk_thrash_bullet1 or
        textures.enemy_yolk_thrash_bullet2
end

function ThrashProjectile:get_palette()
    return nil, idiv(self.tick + self.random_offset, 3)
end

function ThrashProjectile:update(dt)
	if self.vel:magnitude() < 0.25 then
		self:queue_destroy()
	end
end

function TargetedBullet:new(x, y)
    self.max_hp = 12
    self.terrain_collision_radius = 1
    self.hit_bubble_radius = 4
    self.hurt_bubble_radius = 6
	self.bullet_passthrough = true
    TargetedBullet.super.new(self, x, y)
	self.z_index = 2
    self.drag = 0.0
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self.bullet_push_modifier = 2.25
	self:add_elapsed_ticks()
	-- self:add_elapsed_ticks()
end

function TargetedBullet:get_sprite()
    return iflicker(self.tick + self.random_offset, 2, 2) and textures.enemy_yolk_targeted_bullet1 or
        textures.enemy_yolk_targeted_bullet2
end

function TargetedBullet:get_palette()
    return nil, idiv(self.tick + self.random_offset, 3)
end

function TargetedBullet:update(dt)
	if self.tick > 77 or self.vel:magnitude() < 0.5 then
		self:queue_destroy()
	end
end

function CoilBullet:new(x, y, phase, direction_x, direction_y, width, speed)
    self.max_hp = 8
    self.terrain_collision_radius = 1
    self.hit_bubble_radius = 2
    self.hurt_bubble_radius = 4
    self.bullet_passthrough = true
	self.speed = speed or 2.1
	CoilBullet.super.new(self, x, y)
	self.z_index = 1
    self.drag = 0.0
	self.phase = phase
	self.start_x, self.start_y = x, y
	self.direction_x, self.direction_y = direction_x, direction_y
	self.width = width
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
	self:add_time_stuff()
end

function CoilBullet:update(dt)
    local distance = self.elapsed * self.speed
    local offset = sin(self.phase + self.elapsed * 0.16) * (self.width or 9)
    local wiggle_x, wiggle_y = vec2_rotated(self.direction_x, self.direction_y, tau / 4)
	wiggle_x, wiggle_y = vec2_mul_scalar(wiggle_x, wiggle_y, offset)
	local end_x, end_y = vec2_mul_scalar(self.direction_x, self.direction_y, distance)
	self:move_to(self.start_x + end_x + wiggle_x, self.start_y + end_y + wiggle_y)
end
function CoilBullet:get_sprite()
    return iflicker(self.tick + self.random_offset, 2, 2) and textures.enemy_yolk_coil_bullet1 or
        textures.enemy_yolk_coil_bullet2
end

function CoilBullet:get_palette()
    return nil, idiv(self.tick, 3)
end


function ThrashIndicator:new(x, y, thrash_x, thrash_y)
	self.duration = 10
	ThrashIndicator.super.new(self, x, y)
    self.thrash_x, self.thrash_y = vec2_mul_scalar(thrash_x, thrash_y, 200)
	self.z_index = 10
end

function ThrashIndicator:draw(elapsed, tick, t, color)
    local t2 = ease("outCubic")(t)
	-- local t3 = ease("linear")(t)
    local line_width = (1 - t2) * 4
	graphics.push("all")
	graphics.set_line_width(line_width)
	graphics.set_color(color or (iflicker(gametime.tick, 2, 2) and Color.magenta or Color.cyan))
	graphics.line(0, 0, self.thrash_x * t2, self.thrash_y * t2)
    -- graphics.set_line_width(1)
	graphics.pop()
end

function ThrashIndicator:floor_draw()
	self:draw(self.elapsed, self.tick, self.elapsed / self.duration, Color.darkred)
end



AutoStateMachine(EvilGreenoidBoss, "Spawning")

return EvilGreenoidBoss
