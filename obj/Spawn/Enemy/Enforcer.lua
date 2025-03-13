local Enforcer = require("obj.Spawn.Enemy.BaseEnemy"):extend("Enforcer")
local EnforcerBullet = require("obj.Spawn.Enemy.EnforcerBullet")

local SPAWNING_DRAG = 0.01
local NORMAL_DRAG = 0.02
local BULLET_SPEED = 0.8

local PLAYER_DISTANCE = 56
local WALK_SPEED = 0.025
local SPAWN_SPEED = 0.0125
local MAX_DIST = 200

function Enforcer:new(x, y)
	self.body_height = 4

    Enforcer.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AutoStateMachine, "Spawning")
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
end

function Enforcer:state_Spawning_enter()
    local s = self.sequencer

end

function Enforcer:state_Spawning_update(dt)
    local player = self:get_closest_player()
    if player and not self.player then
		local s = self.sequencer
		s:start(function()
			s:wait(rng.randi_range(120, 280))
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
	self.sprite = self:tick_pulse(5, 0) and textures.enemy_enforcer1 or textures.enemy_enforcer2
end

function Enforcer:state_Spawning_exit()
	self:play_sfx("enemy_enforcer_spawn", 0.75, 1.0)
end

function Enforcer:state_Normal_enter()
	self.sprite = textures.enemy_enforcer3
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
                if rng.chance((300 - distance) / 300) then
                    local dx, dy = vec2_direction_to(self.pos.x, self.pos.y, player.pos.x, player.pos.y)
                    dx, dy = vec2_snap_angle(dx, dy, 16)
                    self:shoot_bullet(dx, dy)
                end
            end
			-- if rng.percent(60) then
			-- 	self:start_tick_timer("shoot_delay", 10)
			-- else
				self:start_tick_timer("shoot_delay", clamp(rng.randfn(75, 10), 10, 100))
			-- end
        end
		
        if distance < self.player_distance  then
			pdx = -pdx
			pdy = -pdy
		end

		self.player_distance = self.player_distance - dt * 0.05
		
		self:apply_force(pdx * WALK_SPEED, pdy * WALK_SPEED)


    end
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

return Enforcer
