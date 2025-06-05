local Walker = BaseEnemy:extend("Walker")

local Walksploder = Walker:extend("Walksploder")
local ExplosionRadiusWarning = require("obj.ExplosionRadiusWarning")
local Explosion = require("obj.Explosion")
local FastWalker = Walker:extend("FastWalker")
local BigWalker = Walker:extend("BigWalker")
local BigWalkerBullet = BaseEnemy:extend("BigWalkerBullet")


Walksploder:implement(Mixins.Behavior.ExploderEnemy)

-- FastWalker.spawn_cry = "enemy_fast_walker_spawn"
-- FastWalker.spawn_cry_volume = 0.9


-- Walker.spawn_cry = "enemy_walker_spawn"
-- Walker.spawn_cry_volume = 0.9
-- Walker.death_cry = "enemy_walker_death"
-- Walker.death_cry_volume = 0.9

function Walker:new(x, y)
	self.max_hp = self.max_hp or 1

    self.walk_speed = 0.0525
    self.hurt_bubble_radius = 5
    self.hit_bubble_radius = 3
    self.body_height = 5
    Walker.super.new(self, x, y)
	self.follow_allies = rng:percent(5)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.WalkTowardPlayer)
    self.bullet_push_modifier = self.bullet_push_modifier or 1.0
    self.declump_radius = self.declump_radius or 7
    self.walk_snap_angle = self.walk_snap_angle or 8
end

function Walker:update(dt)
    self:set_flip(idivmod_eq_zero(self.tick, 5, 2) and 1 or -1)
end

local EXPLOSION_RADIUS = 14

function Walksploder:new(x, y)
    self.max_hp = 1.5
	self.hit_bubble_damage = 10

    -- self.bullet_push_modifier = 2.0
    -- self.walk_speed = 0.5
    Walksploder.super.new(self, x, y)
	self.walk_speed = 0.075
	self:mix_init(Mixins.Behavior.ExploderEnemy)
end

function Walksploder:get_palette()
    if self.world then
        return nil, floor(self.world.tick / 3)
    end
	return nil, 0
end

function Walksploder:enter()
	local bx, by = self:get_body_center()
	self:spawn_object(ExplosionRadiusWarning(bx, by, EXPLOSION_RADIUS, self))
end

function Walksploder:get_sprite()
    -- return ROAMER_SHEET:loop(self.tick, 10, 0)
    return (textures.enemy_walksploder)
end

function Walksploder:on_landed_melee_attack()
	self:die()
end

function Walksploder:die(...)
	local bx, by = self:get_body_center()
    local params = {
		size = EXPLOSION_RADIUS,	
		damage = 10,
		team = "enemy",
		melee_both_teams = true,
		particle_count_modifier = 0.85,
		explode_sfx = "explosion3",
	}
    self:spawn_object(Explosion(bx, by, params))
    Walksploder.super.die(self, ...)
end


function FastWalker:new(x, y)
	self.max_hp = 2
    FastWalker.super.new(self, x, y)
    self.walk_speed = 0.1
	self.bullet_push_modifier = 1.5
end

function FastWalker:get_sprite()
    return textures.enemy_fastwalker
end

function BigWalker:new(x, y)
    self.max_hp = 3
    BigWalker.super.new(self, x, y)
    self.walk_speed = 0.08
    self.bullet_push_modifier = 0.1
	self.hurt_bubble_radius = 7
	self.terrain_collision_radius = 4
	self.declump_radius = 7
	self.declump_mass = 2
	self.hit_bubble_radius = 5
    self.body_height = 7
	self.shoot_offset = round(rng:randfn(0, 15))
end


function BigWalker:enter()
	self.start_tick = self.world.timescaled.tick
end


function BigWalker:get_sprite()
    return textures.enemy_bigwalker
end

BigWalker.bullet_speed = 2.5

function BigWalker:update(dt)
	
	BigWalker.super.update(self, dt)
	if self.is_new_tick and self.tick > 60 and (self.tick + self.start_tick + self.shoot_offset) % 130 == 0 and not self:is_tick_timer_running("shoot_cooldown") then
		local bx, by = self:get_body_center()
		local pbx, pby = self:closest_last_player_body_pos()
        local dx, dy = vec2_direction_to(bx, by, pbx, pby)
		dx, dy = vec2_mul_scalar(dx, dy, BigWalker.bullet_speed)
        self:spawn_object(BigWalkerBullet(bx, by)):apply_impulse(dx, dy)
        self:play_sfx("enemy_bigwalker_shoot")
        self.shoot_offset = round(rng:randfn(0, 15))
		self:start_tick_timer("shoot_cooldown", 45)
	end
end


function BigWalkerBullet:new(x, y)
	self.max_hp = 2

    BigWalkerBullet.super.new(self, x, y)
    self.drag = 0.0
    self.hit_bubble_radius = 4
	self.hurt_bubble_radius = 5
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self.bullet_push_modifier = 0.85
    self.z_index = 10
end

function BigWalkerBullet:get_sprite()
    return self:tick_pulse(3) and textures.enemy_bigwalker_bullet1 or textures.enemy_bigwalker_bullet2
end

-- function BigWalkerBullet:get_palette()
-- 	local palette, offset = BigWalkerBullet.super.get_palette(self)

-- 	offset = idiv(self.tick, 3)

-- 	return palette, offset
-- end

function BigWalkerBullet:update(dt)	
end

return{ Walker, Walksploder, FastWalker, BigWalker }
