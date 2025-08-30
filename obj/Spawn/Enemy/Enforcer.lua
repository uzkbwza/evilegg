local Enforcer = BaseEnemy:extend("Enforcer")
local EnforcerBullet = BaseEnemy:extend("EnforcerBullet")
local RoyalGuard = Enforcer:extend("RoyalGuard")
local RoyalGuardBullet = EnforcerBullet:extend("RoyalGuardBullet")
local MiniShotgunner = BaseEnemy:extend("MiniShotgunner")
local MiniShotgunnerBullet = EnforcerBullet:extend("MiniShotgunnerBullet")
local HeavyPatrol = MiniShotgunner:extend("HeavyPatrol")
local HeavyPatrolBullet = RoyalGuardBullet:extend("HeavyPatrolBullet")

local HOMING_SPEED = 0.035

local SPAWNING_DRAG = 0.01
local NORMAL_DRAG = 0.02
local BULLET_SPEED = 1.3

local PLAYER_DISTANCE = 64
local WALK_SPEED = 0.075
local SPAWN_SPEED = 0.0125
local MAX_DIST = 200

Enforcer.max_hp = 2
RoyalGuard.max_hp = 5
MiniShotgunner.max_hp = 3
MiniShotgunnerBullet.max_hp = 2
HeavyPatrol.max_hp = 5
HeavyPatrolBullet.max_hp = 3

MiniShotgunner.spawn_cry = "enemy_patrol_spawn"
HeavyPatrol.spawn_cry = "enemy_heavy_patrol_spawn"

function Enforcer:new(x, y)
    self.body_height = 4

    Enforcer.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	
    self.drag = SPAWNING_DRAG

	self.sprite = textures.enemy_enforcer1
	self.declump_radius = 8
	self.declump_mass = 1
	self.declump_same_class_only = true
	self.self_declump_modifier = 1.5
	self.pdx, self.pdy = 0, 0
    self.player_distance = PLAYER_DISTANCE
	self.spawn_cry = "enemy_enforcer_emerge"
    self.spawn_cry_volume = 0.75
	self.spawn_sprite1 = textures.enemy_enforcer1
	self.spawn_sprite2 = textures.enemy_enforcer2
	self.walk_speed = WALK_SPEED
	self.normal_sprite = textures.enemy_enforcer3
    self.time_to_spawn = rng:randi(80, 180)
end

function Enforcer:state_Spawning_enter()
    local s = self.sequencer

end

function Enforcer:state_Spawning_update(dt)
    local player = self:get_closest_player()
    if player and not self.player then
		local s = self.sequencer
        s:start(function()
			s:wait(self.time_to_spawn)
			self:change_state("Normal")
        end)
		self.player = player
	end
    if player then
        local target_position_x, target_position_y = player.pos.x, player.pos.y
        local offset = sin(self.random_offset_ratio * 100 + self.elapsed)
        local offsx, offsy = 0, 0

		local pdx, pdy = vec2_direction_to(self.pos.x, self.pos.y, player.pos.x, player.pos.y)
		if vec2_distance(self.pos.x, self.pos.y, player.pos.x, player.pos.y) > MAX_DIST then
		
		else
			self:apply_force(-pdx * SPAWN_SPEED, -pdy * SPAWN_SPEED)
		end
    end
	self.sprite = self:tick_pulse(5) and self.spawn_sprite1 or self.spawn_sprite2
end

function Enforcer:state_Spawning_exit()
	self:play_sfx(self.enforcer_spawn_sfx or "enemy_enforcer_spawn", self.enforcer_spawn_sfx_volume or 0.75, 1.0)
end

function Enforcer:state_Normal_enter()
	self.sprite = self.normal_sprite
    self.drag = NORMAL_DRAG
end

-- function Enforcer:collide_with_terrain()
	
-- 	-- if vec2_distance(self.pos.x, self.pos.y, 0, 0) > MAX_DIST then
--     --     local clamped_x, clamped_y = vec2_clamp_magnitude(self.pos.x, self.pos.y, 0, MAX_DIST)
-- 	-- 	self:move_to(clamped_x, clamped_y)
-- 	-- 	return true
-- 	-- end
-- 	return false
-- end

function Enforcer:state_Normal_update(dt)
    local player = self:get_closest_player()
    if player then
        local target_position_x, target_position_y = player.pos.x, player.pos.y


        local pdx, pdy = vec2_direction_to(self.pos.x, self.pos.y, target_position_x, target_position_y)
        pdx, pdy = vec2_snap_angle(pdx, pdy, 3, deg2rad(self.random_offset_ratio * 360))
        self.pdx, self.pdy = pdx, pdy
		local distance = vec2_distance(self.pos.x, self.pos.y, player.pos.x, player.pos.y)

        if self.state_tick > 100 and not self:is_tick_timer_running("shoot_delay") then
            if distance < 300 then
                if rng:chance(((300 - distance) / 300) * self:shoot_chance_modifier()) then
                    local dx, dy = vec2_direction_to(self.pos.x, self.pos.y, player.pos.x, player.pos.y)
                    dx, dy = vec2_snap_angle(dx, dy, 16)
                    self:shoot_bullet(dx, dy)
                end
            end
			-- if rng:percent(60) then
			-- 	self:start_tick_timer("shoot_delay", 10)
			-- else
				self:start_tick_timer("shoot_delay", clamp(rng:randfn(45, 10), 10, 100))
			-- end
        end
		
        if distance < self.player_distance  then
			pdx = -pdx
			pdy = -pdy
		end

		self.player_distance = self.player_distance - dt * 0.05
		
		self:apply_force(pdx * self.walk_speed, pdy * self.walk_speed)


    end
end

function Enforcer:shoot_chance_modifier()
	return 1.0
end

function Enforcer:shoot_bullet(dx, dy)
    local bullet = self:spawn_object(EnforcerBullet(self.pos.x, self.pos.y))
	bullet:move(dx * 3, dy * 3)
    bullet:apply_impulse(dx * BULLET_SPEED + self.vel.x, dy * BULLET_SPEED + self.vel.y)
	self:play_sfx("enemy_enforcer_shoot", 1, 1.0)
end

function Enforcer:state_Normal_exit()

end

function Enforcer:get_sprite()
    return self.sprite
end

function Enforcer:draw()
	if self.tick > 1 and floor(self.random_offset + gametime.tick / 2) % 2 == 0 and self.state == "Spawning" then return end
	Enforcer.super.draw(self)
end

function Enforcer:debug_draw()
    -- Enforcer.super.debug_draw(self)
    graphics.setColor(1, 0, 0)
    graphics.line(0, 0, self.pdx * 10, self.pdy * 10)
    graphics.setColor(1, 1, 1)
end

function RoyalGuard:new(x, y)
	self.walk_speed = WALK_SPEED * 0.5
    RoyalGuard.super.new(self, x, y)
	self.spawn_cry = "enemy_royalguard_emerge"
    self.enforcer_spawn_sfx = "enemy_royalguard_spawn"
    self.spawn_cry_volume = 1
	self.enforcer_spawn_sfx_volume = 1
	self.spawn_sprite1 = textures.enemy_royalguard1
	self.spawn_sprite2 = textures.enemy_royalguard2
    self.normal_sprite = textures.enemy_royalguard3
	-- self.bullet_push_modifier = 0.5
end

function RoyalGuard:enter()
	self:add_tag("royalguard")
end

function RoyalGuard:shoot_bullet(dx, dy)
	if rng:coin_flip() then
		for i = -1, 1 do
			local dx_, dy_ = vec2_rotated(dx, dy, i * tau / 16)		
			local bullet = self:spawn_object(RoyalGuardBullet(self.pos.x, self.pos.y))
			bullet:move(dx_ * 3, dy_ * 3)
			bullet:apply_impulse(dx_ * BULLET_SPEED + self.vel.x, dy_ * BULLET_SPEED + self.vel.y)
		end
		self:play_sfx("enemy_royalguard_shoot", 1, 1.0)
	else
		local s = self.sequencer
        s:start(function()
			for i=1, 5 do 		
				local bullet = self:spawn_object(RoyalGuardBullet(self.pos.x, self.pos.y))
				bullet:move(dx * 3, dy * 3)
				bullet:apply_impulse(dx * BULLET_SPEED + self.vel.x, dy * BULLET_SPEED + self.vel.y)
				self:play_sfx("enemy_royalguard_shoot", 1, 1.0)
				s:wait(5)
			end
		end)
	end
end

function RoyalGuard:shoot_chance_modifier()
	return 0.75
end

function RoyalGuard:get_palette()
    if self.state == "Spawning" then
        return nil, self.tick / 3
    end
    return self.super.get_palette(self)
end

function RoyalGuard:draw()
    graphics.push("all")
    self:body_translate()
    if self.state == "Spawning" and gametime.tick % 2 ~= 0 then
        local t = (self.elapsed / self.time_to_spawn)
        graphics.set_color(Palette[self:get_sprite()]:tick_color(self.tick / 2))
        local scale = min(self.elapsed * 2, 12 + (1 - ease("inCubic")(t)) * 6)
        -- graphics.rotate(ease("inCubic")(t) * tau * 0.5 * (self.random_offset % 2 == 0 and 1 or -1))
        graphics.rectangle_centered("line", 0, 0, scale, scale)
    end
    graphics.pop()
    self.super.draw(self)
end


function EnforcerBullet:new(x, y)
	self.max_hp = 1
    EnforcerBullet.super.new(self, x, y)
    self.drag = 0.014
    self.hit_bubble_radius = 3
	self.hurt_bubble_radius = 2
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    -- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.z_index = 10
	self.floor_draw_color = Palette.rainbow:get_random_color()
    self.homing = true
end

function EnforcerBullet:get_sprite()
    return self:tick_pulse(3) and textures.enemy_enforcer_bullet1 or textures.enemy_enforcer_bullet2
end

-- function EnforcerBullet:collide_with_terrain()
-- 	return false
-- end

function EnforcerBullet:get_floor_sprite()
	-- local i = floor(self.tick / 3) % 4
    -- if i == 0 then
	-- 	return textures.enemy_enforcer_bullet1
	-- elseif i == 1 then
	-- 	return textures.enemy_enforcer_bullet2
	-- elseif i == 2 then
	-- 	return textures.enemy_enforcer_bullet3
	-- elseif i == 3 then
	-- 	return textures.enemy_enforcer_bullet4
	-- end
	return textures.enemy_enforcer_bullet_trail
end

function EnforcerBullet:update(dt)
    if vec2_magnitude(self.vel.x, self.vel.y) < 0.05 then
        self:die()
    end

	local player = self:get_closest_player()
	if player and self.tick < 120 and self.homing then
        local pdx, pdy = vec2_direction_to(self.pos.x, self.pos.y, player.pos.x, player.pos.y)
		local homing_speed = HOMING_SPEED * (1.0 - self.tick / 120)
		self:apply_force(pdx * homing_speed, pdy * homing_speed)
	end
end

local COLOR_MOD = 0.9

function EnforcerBullet:floor_draw()
    local scale = pow(1.0 - self.tick / 600, 1.5)
    local color_mod = (self.floor_trail_color_mod or 1.0)
    graphics.set_color(scale * COLOR_MOD * color_mod, 0, (1.0 - scale * COLOR_MOD) * color_mod, 1)
    if self.is_new_tick and self.tick % 4 == 0 and scale > 0.1 then
		local palette, offset = self:get_palette()
        local sprite = self:get_floor_sprite()
		
		graphics.scale(scale, scale)
		graphics.drawp_centered(sprite, palette, offset, 0, 0)
	end
end

function RoyalGuardBullet:new(x, y)
    RoyalGuardBullet.super.new(self, x, y)
end

function RoyalGuardBullet:get_sprite()
    return self:tick_pulse(3) and textures.enemy_royalguard_bullet1 or textures.enemy_royalguard_bullet2
end

function RoyalGuardBullet:get_palette()
    return nil, idiv(self.tick, 2)
end


MiniShotgunner.bullet_class = MiniShotgunnerBullet
HeavyPatrol.bullet_class = HeavyPatrolBullet

function MiniShotgunner:new(x, y)
	self.body_height = 3
	self.hurt_bubble_radius = 5
	self.hit_bubble_radius = 2
    self.walk_toward_player_chance = 80
    MiniShotgunner.super.new(self, x, y)

	self.follow_allies = true
	-- self.roam_diagonals = true
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.Roamer)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.declump_radius = 8
    self.declump_mass = 1.5
    self.back_away = true
	self.bullet_push_modifier = 1.5
	self.walk_frequency = 4
    self.roam_chance = 12
    self.shoot_chance = 1
    self.walk_speed = 0.4
    self.back_away_distance = 60
    self.aim_direction = Vec2(rng:random_vec2())
    self:start_tick_timer("shoot_delay", rng:randf(40, 60))
    self.bullet_speed = 1.1
    self.shoot_cooldown = 100
end

function MiniShotgunner:update(dt)
    if self.is_new_tick and rng:percent(self.shoot_chance) and not self:is_tick_timer_running("shoot_delay") then
        self:shoot_bullets()
        self:start_tick_timer("shoot_delay", self.shoot_cooldown)
    end
end


function MiniShotgunner:shoot_bullets()
    local player = self:get_closest_ally()
    if player then
        local dx, dy = vec2_direction_to(self.pos.x, self.pos.y, player.pos.x, player.pos.y)
        self.aim_direction.x, self.aim_direction.y = vec2_snap_angle(dx, dy, 16)
        self:shoot_bullet(self.bullet_speed, self.aim_direction.x, self.aim_direction.y)
        self:shoot_bullet(self.bullet_speed, vec2_rotated(self.aim_direction.x, self.aim_direction.y, tau / 20))
        self:shoot_bullet(self.bullet_speed, vec2_rotated(self.aim_direction.x, self.aim_direction.y, -tau / 20))
        self:shoot_bullet(self.bullet_speed, vec2_rotated(self.aim_direction.x, self.aim_direction.y, tau / 10))
        self:shoot_bullet(self.bullet_speed, vec2_rotated(self.aim_direction.x, self.aim_direction.y, -tau / 10))
        self:play_sfx("enemy_mini_shotgunner_shoot", 0.7, 1.0)
    end
end

function MiniShotgunner:shoot_bullet(speed, dx, dy)
    local bx, by = self:get_body_center()
    local bullet = self:spawn_object(self.bullet_class(bx, by))
	bullet:move(dx * 8, dy * 8)
    bullet:apply_impulse(dx * speed + self.vel.x, dy * speed + self.vel.y)
	self:play_sfx("enemy_mini_shotgunner_shoot", 1, 1.0)
end

function MiniShotgunner:get_sprite()
    return iflicker(self.tick, 10, 2) and textures.enemy_mini_shotgunner1 or textures.enemy_mini_shotgunner2
end

function HeavyPatrol:new(x, y)
    HeavyPatrol.super.new(self, x, y)
    self.walk_speed = 0.4
    self.back_away_distance = 32
    self.bullet_speed = 1.6
    self.shoot_chance = 1.0
    self.shoot_cooldown = 120
    self:start_tick_timer("shoot_delay", rng:randf(40, 240))
end

function HeavyPatrol:shoot_bullets()
    local s = self.sequencer
    s:start(function()
        for i=1, 5 do
            local player = self:get_closest_ally()
            if player then
                local dx, dy = vec2_direction_to(self.pos.x, self.pos.y, player.pos.x, player.pos.y)
                self.aim_direction.x, self.aim_direction.y = vec2_snap_angle(dx, dy, 16)
                for j = 1, 2 do
                    local dx, dy = vec2_rotated(self.aim_direction.x, self.aim_direction.y, rng:randf(-tau / 15, tau / 15))
                    self:shoot_bullet(self.bullet_speed, dx, dy)
                end

                self:play_sfx("enemy_mini_shotgunner_shoot", 1.0, 1.0)
            end
            s:wait(4)
        end
    end)
end

MiniShotgunnerBullet.floor_trail_color_mod = 0.25
HeavyPatrolBullet.floor_trail_color_mod = 0.25

function MiniShotgunnerBullet:new(x, y)
    MiniShotgunnerBullet.super.new(self, x, y)
    self.drag = 0.0
    self.homing = false
end


function HeavyPatrolBullet:new(x, y)
    HeavyPatrolBullet.super.new(self, x, y)
    self.drag = 0.0
    self.homing = false
end

function HeavyPatrol:get_sprite()
    return iflicker(self.tick, 10, 2) and textures.enemy_heavy_patrol1 or textures.enemy_heavy_patrol2
end


AutoStateMachine(Enforcer, "Spawning")
AutoStateMachine(RoyalGuard, "Spawning")

return {Enforcer, RoyalGuard, MiniShotgunner, HeavyPatrol}
