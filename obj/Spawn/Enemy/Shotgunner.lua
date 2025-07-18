local Shotgunner = BaseEnemy:extend("Shotgunner")
local ShotgunnerBullet = BaseEnemy:extend("ShotgunnerBullet")
local ShotgunnerMuzzleFlash = Effect:extend("ShotgunnerMuzzleFlash")

ShotgunnerBullet.is_shotgun_bullet = true
ShotgunnerBullet.death_flash_size_mod = 0.15

Shotgunner.max_hp = 9

Shotgunner.spawn_cry = "enemy_shotgunner_spawn"
Shotgunner.spawn_cry_volume = 0.9

local BULLET_SPEED = 4.
local NUM_BULLETS = 10
local SPREAD = 50

function ShotgunnerBullet:new(x, y)
	self.max_hp = 3

    ShotgunnerBullet.super.new(self, x, y)
    self.drag = 0.04
    self.hit_bubble_radius = 2
	self.hurt_bubble_radius = 4
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self.bullet_push_modifier = 2.5
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self.z_index = 10
	self:add_time_stuff()
end

function ShotgunnerBullet:filter_melee_attack(bubble)
	if bubble.parent.is_shotgun_bullet then
		return false
	end
	return true
end

function ShotgunnerBullet:on_landed_melee_attack()
	-- self:normal_death_effect()
    self:die()
end

-- function ShotgunnerBullet:death_effect(hit_by)
-- 	-- self:flash_death_effect()
-- end

function ShotgunnerBullet:die()
    ShotgunnerBullet.super.die(self)
end



function ShotgunnerBullet:enter()
	-- local s = self.sequencer
	-- s:start(function()
    --     s:wait(rng:randi(2))
	-- 	self.melee_both_teams = true
	-- end)
end

function ShotgunnerBullet:on_damaged(amount)
    self.melee_both_teams = true
	-- self.hitbox_team = "player"
end

local bullet_sprites = {
	textures.enemy_shotgunner_bullet1,
	textures.enemy_shotgunner_bullet2,
	textures.enemy_shotgunner_bullet3,
}

function ShotgunnerBullet:get_sprite()
	return textures.enemy_shotgunner_bullet4
end

function ShotgunnerBullet:get_palette()
    local palette = Palette[textures.enemy_shotgunner_bullet1]
	local offset = idiv(self.tick + self.random_offset, 8)
	if self.hitbox_team == "player" then
		palette = Palette.cmy
		offset = idiv(self.tick + self.random_offset, 4)
	end
	return palette, offset
end

function ShotgunnerBullet:draw()
    local palette, offset = self:get_palette_shared()
	local index, rotation, y_scale = get_16_way_from_3_base_sprite(self.vel:angle())
	graphics.drawp_centered(bullet_sprites[index], palette, offset, 0, 0, rotation, 1, y_scale)
end

function ShotgunnerBullet:update(dt)
	if self.vel:magnitude() < 0.45 then
		self:die()
	end
end

function ShotgunnerMuzzleFlash:new(x, y)
	self.duration = 5
	self.z_index = 1.1
	ShotgunnerMuzzleFlash.super.new(self, x, y)
end

function ShotgunnerMuzzleFlash:draw(dt)
	graphics.rectangle_centered("fill", 0, 0, 10, 10)
end


function Shotgunner:new(x, y)
	self.body_height = 6
	self.hurt_bubble_radius = 6
	self.hit_bubble_radius = 4
    self.walk_toward_player_chance = 80
	-- self.follow_allies = true
    Shotgunner.super.new(self, x, y)
	self.roam_diagonals = true
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.Roamer)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.declump_radius = 12
    self.declump_mass = 2.0
	self.bullet_push_modifier = 1.0
	self.walk_frequency = 4
	self.roam_chance = 6
	self.walk_speed = self.walk_speed or 0.7
	self.aim_direction = Vec2(rng:random_vec2())
end

function Shotgunner:enter()
	self:start_tick_timer("shoot_timer", 70)
end

function Shotgunner:get_sprite()
    return iflicker(self.tick, 10, 2) and textures.enemy_shotgunner1 or textures.enemy_shotgunner2
end

local shotgun_sprites = {
	textures.enemy_shotgunner_shotgun1,
	textures.enemy_shotgunner_shotgun2,
	textures.enemy_shotgunner_shotgun3,
}

function Shotgunner:update(dt)
	local dist = self:get_body_distance_to_player()
	local dx, dy = self:get_body_direction_to_player()

	if dist < 60 then 
        self.is_roaming = false
		self:apply_force(dx * -0.15, dy * -0.15)
    else
		self.is_roaming = true
	end

    if self.is_new_tick and rng:percent(16) then
		dx, dy = vec2_snap_angle(dx, dy, 16, 0)
        self.aim_direction.x, self.aim_direction.y = dx, dy

		if rng:percent(15) and not self:is_tick_timer_running("shoot_timer") and dist < 220 then 
			self:start_tick_timer("shoot_timer", 155)
			self:shoot()
		end
	end
end

function Shotgunner:shoot()
	local bx, by = self:get_body_center()
	local offset_x, offset_y = vec2_mul_scalar(self.aim_direction.x, self.aim_direction.y, 24)
    self:spawn_object(ShotgunnerMuzzleFlash(bx + offset_x, by + offset_y))
    self:play_sfx("enemy_shotgunner_shoot")
    local s = self.sequencer
    s:start(function()
		s:wait(30)
		self:play_sfx("enemy_shotgunner_reload")
	end)
	for i=1, NUM_BULLETS do
		local bullet = self:spawn_object(ShotgunnerBullet(bx + offset_x, by + offset_y))
		local angle = deg2rad(rng:randf(-SPREAD, SPREAD)) + self.aim_direction:angle()
		local speed = rng:randfn(BULLET_SPEED, BULLET_SPEED * 0.15)
		bullet:apply_impulse(cos(angle) * speed, sin(angle) * speed)
	end
end

function Shotgunner:exit() 
end

function Shotgunner:draw()

	self:body_translate()

    if self.aim_direction.y < 0 then
		self:draw_shotgun()
	end

    self:draw_sprite()
	
	if self.aim_direction.y >= 0 then
		self:draw_shotgun()
	end
end

function Shotgunner:draw_shotgun()
	local shotgun_index, shotgun_rotation, y_scale = get_16_way_from_3_base_sprite(self.aim_direction:angle())
    local shotgun_sprite = shotgun_sprites[shotgun_index]
	local palette, palette_index = self:get_palette_shared()
	graphics.drawp_centered(shotgun_sprite, palette, palette_index, 0, 0, shotgun_rotation, 1, y_scale)
end



return Shotgunner
