local Hopper = BaseEnemy:extend("Hopper")
local FastHopper = Hopper:extend("FastHopper")
local BigHopper = Hopper:extend("BigHopper")
local HopperBullet = BaseEnemy:extend("HopperBullet")

function Hopper:new(x, y)
    Hopper.super.new(self, x, y)
	self.drag = self.drag or 0.05
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
	-- if rng.percent(100) then
		self:play_sfx(self.shoot_sfx, 1.0, 1.0)
		for i = 1, self.number_hop_bullets do
			local angle = (tau / self.number_hop_bullets) * i + self.elapsed
			local bullet = self:spawn_object(HopperBullet(self.pos.x, self.pos.y))
			bullet:apply_impulse(cos(angle) * self.bullet_speed, sin(angle) * self.bullet_speed * 0.75)
			bullet.bullet_index = floor(i / self.number_hop_bullets)
		end
	-- end
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

function FastHopper:new(x, y)
	self.max_hp = 2
	self.drag = 0.325
	self.hop_speed = 7.5
	self.number_hop_bullets = floor(rng.randfn(3, 0.15))
	self.min_wait_time = 20
	self.max_wait_time = 90
	self.max_start_time = 90
	-- self.hop_speed = 1.5
	self.bullet_speed = 1
    FastHopper.super.new(self, x, y)
end


function FastHopper:get_sprite()
    return self.sprite == textures.enemy_hopper1 and textures.enemy_fasthopper1
        or self.sprite == textures.enemy_hopper2 and textures.enemy_fasthopper2
		or self.sprite == textures.enemy_hopper3 and textures.enemy_fasthopper3
end


function BigHopper:new(x, y)
    self.default_body_height = 8
    self.number_hop_bullets = 30
    self.hop_speed = 1.0
    self.max_hp = 10
    self.min_wait_time = 120
    self.max_wait_time = 360
    self.drag = 0.05
    BigHopper.super.new(self, x, y)

    self.terrain_collision_radius = self.terrain_collision_radius * 2
    self.hurt_bubble_radius = self.hurt_bubble_radius * 2
    self.hit_bubble_radius = self.hit_bubble_radius * 2
    self.body_height_mod = 15
    self.hop_sfx = "enemy_big_hopper_hop"
    self.shoot_sfx = "enemy_big_hopper_shoot"
end



function BigHopper:state_Hopping_enter()
	BigHopper.super.state_Hopping_enter(self)
	self.drag = 0.025
end

function BigHopper:state_Hopping_exit()
	BigHopper.super.state_Hopping_exit(self)
    self.drag = 0.05

	local num_hoppers = rng.randi(5, 7)

	if not game_state.game_over then
		for i = 1, num_hoppers do
			local angle = (tau / num_hoppers) * i + self.elapsed + self.random_offset
			local hopper = self:spawn_object(Hopper(self.pos.x, self.pos.y))
			hopper:apply_impulse(vec2_from_polar(6, angle))
			hopper:make_required_kill_on_enter()
		end
	end
end

function BigHopper:update(dt)
	BigHopper.super.update(self, dt)
end

function BigHopper:get_sprite()
    return self.sprite == textures.enemy_hopper1 and textures.enemy_bighopper1
        or self.sprite == textures.enemy_hopper2 and textures.enemy_bighopper2
		or self.sprite == textures.enemy_hopper3 and textures.enemy_bighopper3
end

function HopperBullet:new(x, y)
	self.max_hp = 1

    HopperBullet.super.new(self, x, y)
    self.drag = 0.0
    self.hit_bubble_radius = 1
	self.hurt_bubble_radius = 3
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self.z_index = 10
end

function HopperBullet:get_sprite()
    return textures.enemy_hopper_bullet
end

function HopperBullet:get_palette()
	local palette, offset = HopperBullet.super.get_palette(self)

	offset = idiv(self.tick + self.bullet_index, 3)

	return palette, offset
end

function HopperBullet:update(dt)
end


AutoStateMachine(Hopper, "Waiting")
AutoStateMachine(FastHopper, "Waiting")
AutoStateMachine(BigHopper, "Waiting")
return {Hopper, FastHopper, BigHopper}
