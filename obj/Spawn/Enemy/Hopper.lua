local Hopper = require("obj.Spawn.Enemy.BaseEnemy"):extend("Hopper")
local HopperBullet = require("obj.Spawn.Enemy.HopperBullet")

function Hopper:new(x, y)
    Hopper.super.new(self, x, y)
	self.drag = 0.05
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
	
    self.default_body_height = self.default_body_height or 4
	self:set_body_height(self.default_body_height)
    self.sprite = textures.enemy_hopper1
    
    self.number_hop_bullets = self.number_hop_bullets or 5
    self.bullet_speed = self.bullet_speed or 1
    self.hop_speed = self.hop_speed or 1
    self.min_wait_time = self.min_wait_time or 60
	self.max_start_time = self.max_start_time or 300
    self.max_wait_time = self.max_wait_time or 900
	self.body_height_mod = self.body_height_mod or 4
    self.hop_sfx = "enemy_hopper_hop"
	self.shoot_sfx = "enemy_hopper_shoot"
end

function Hopper:on_terrain_collision(normal_x, normal_y)
    self:terrain_collision_bounce(normal_x, normal_y)
end

function Hopper:get_palette()
    local offset = 0
	if idivmod_eq_zero(self.random_offset + self.world.tick, 15, 3) then
		offset = self.random_offset + self.world.tick / 3
	end
	return nil, offset
end

function Hopper:state_Waiting_enter()
	self:set_body_height(self.default_body_height)
	self.vel:mul_in_place(0.1)

    self.sprite = textures.enemy_hopper1
	local s = self.sequencer
	s:start(function()
		s:wait(rng.randi_range(self.min_wait_time, (not self.started) and self.max_start_time or self.max_wait_time))
		self.started = true
        self:change_state("Hopping")
	end)
end

function Hopper:state_Waiting_update(dt)
	self.sprite = idivmod_eq_zero(self.state_tick, 10, 2) and textures.enemy_hopper1 or textures.enemy_hopper2
end

function Hopper:state_Hopping_enter()
    self.sprite = textures.enemy_hopper3
    local hop_dir = Vec2(rng.random_8_way_direction())
    self:apply_impulse(hop_dir.x * self.hop_speed, hop_dir.y * self.hop_speed)
	self:play_sfx(self.hop_sfx, 1.0, 1.0)
end

function Hopper:state_Hopping_exit()
	if rng.percent(100) then
		self:play_sfx(self.shoot_sfx, 1.0, 1.0)
		for i = 1, self.number_hop_bullets do
			local angle = (tau / self.number_hop_bullets) * i + self.elapsed
			local bullet = self:spawn_object(HopperBullet(self.pos.x, self.pos.y))
			bullet:apply_impulse(cos(angle) * self.bullet_speed, sin(angle) * self.bullet_speed * 0.75)
			bullet.bullet_index = floor(i / self.number_hop_bullets)
		end
	end
end

function Hopper:state_Hopping_update(dt)
	local speed = self.vel:magnitude()
    self:set_body_height(splerp(self.body_height, self.default_body_height + speed * self.body_height_mod, 190, dt))
	if speed < 0.125 then
		self:change_state("Waiting")
	end
end

function Hopper:draw()
	Hopper.super.draw(self)
end

function Hopper:get_sprite()
    return self.sprite
end

AutoStateMachine(Hopper, "Waiting")

return Hopper
