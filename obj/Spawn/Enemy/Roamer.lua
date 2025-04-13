local Roamer = BaseEnemy:extend("Roamer")
local Roamsploder = Roamer:extend("Roamsploder")
local Explosion = require("obj.Explosion")
local ExplosionRadiusWarning = require("obj.ExplosionRadiusWarning")

Roamsploder:implement(Mixins.Behavior.ExploderEnemy)

-- local ROAMER_SHEET = SpriteSheet(textures.enemy_roamer, 10, 14)

Roamer.palette = Palette[textures.enemy_roamer1]:clone()

-- Roamer.spawn_cry = "enemy_roamer_spawn"
-- Roamer.spawn_cry_volume = 0.9
-- Roamer.death_cry = "enemy_roamer_death"
-- Roamer.death_cry_volume = 0.9

function Roamer:new(x, y)
	self.max_hp = self.max_hp or 1
    Roamer.super.new(self, x, y)
	-- self.drag = 0.6
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self:lazy_mixin(Mixins.Behavior.Roamer)
	self.declump_radius = 5
	self.walk_toward_player_chance = 60
	self.follow_allies = rng.percent(20)
    self.walk_frequency = 6
	self.body_height = 5
	self.declump_mass = 2.5
	
end

function Roamer:update(dt)
    if self.is_new_tick and self.tick % self.walk_frequency == 0 and rng.percent(10) then
		self:play_sfx("enemy_roamer_walk", 0.25, 1.0)
	end
end

function Roamer:get_palette()
	local palette = self.palette
	if self.world then
		palette:set_color(3, Palette.roamer:tick_color(self.world.tick / 2))
	end
	return palette, 0
end

function Roamer:get_sprite()
	-- return ROAMER_SHEET:loop(self.tick, 10, 0)
	return (self:tick_pulse(self.walk_frequency) and textures.enemy_roamer1 or textures.enemy_roamer2)
end

function Roamer:draw()
	Roamer.super.draw(self)
	-- graphics.line(0, 0, self.roam_direction.x * 100, self.roam_direction.y * 100)
end

function Roamer:floor_draw()
    if self.is_new_tick and self.tick % self.walk_frequency == 0 then
        local dx
        if idivmod_eq_zero(self.tick, self.walk_frequency, 2) then
            dx = -3
        else
            dx = 3
        end
        local length = 1

        local shade = 0.5
        graphics.set_color(shade, shade, shade)
        graphics.line(dx - length * 0.5, 0, dx + length * 0.5, 0)
    end
end

-- function Roamsploder:new(x, y)
-- 	Roamsploder.super.new(self, x, y)
-- 	self.max_hp = 2
-- 	self.walk_toward_player_chance = 100
-- 	self.follow_allies = 0
-- 	self.walk_frequency = 3
-- 	self.body_height = 5
-- 	self.declump_radius = 5
-- end

local EXPLOSION_RADIUS = 20

function Roamsploder:new(x, y)
    self.max_hp = 2
	self.hit_bubble_damage = 10
    self.bullet_push_modifier = 3.5
    self.walk_speed = 0.75
    Roamsploder.super.new(self, x, y)
	self:mix_init(Mixins.Behavior.ExploderEnemy)
end

function Roamsploder:enter()
	local bx, by = self:get_body_center()
	self:spawn_object(ExplosionRadiusWarning(bx, by, EXPLOSION_RADIUS, self))
end

function Roamsploder:get_sprite()
    -- return ROAMER_SHEET:loop(self.tick, 10, 0)
    return (self:tick_pulse(self.walk_frequency) and textures.enemy_roamsploder1 or textures.enemy_roamsploder2)
end

function Roamsploder:on_landed_melee_attack()
	self:die()
end


function Roamsploder:get_palette()

    if self.world then
        return nil, floor(self.world.tick / 3)
    end
	return nil, 0
end

function Roamsploder:die(...)
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
    Roamsploder.super.die(self, ...)
end

return { Roamer, Roamsploder }
