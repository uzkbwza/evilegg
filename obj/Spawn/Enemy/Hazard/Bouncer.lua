local Bouncer = BaseEnemy:extend("Bouncer")
local FastBouncer = Bouncer:extend("FastBouncer")
local TRAIL_COLOR = Palette.rainbow:get_color(16):clone()
local TRAIL_COLOR_FAST1 = Color.blue:clone()
local TRAIL_COLOR_FAST2 = Color.skyblue:clone()
local trail_mod = 0.8
TRAIL_COLOR.r = TRAIL_COLOR.r * trail_mod
TRAIL_COLOR.g = TRAIL_COLOR.g * trail_mod
TRAIL_COLOR.b = TRAIL_COLOR.b * trail_mod
TRAIL_COLOR_FAST1.r = TRAIL_COLOR_FAST1.r * trail_mod
TRAIL_COLOR_FAST1.g = TRAIL_COLOR_FAST1.g * trail_mod
TRAIL_COLOR_FAST1.b = TRAIL_COLOR_FAST1.b * trail_mod
TRAIL_COLOR_FAST2.r = TRAIL_COLOR_FAST2.r * trail_mod
TRAIL_COLOR_FAST2.g = TRAIL_COLOR_FAST2.g * trail_mod
TRAIL_COLOR_FAST2.b = TRAIL_COLOR_FAST2.b * trail_mod

function Bouncer:new(x, y)
	self.max_hp = 1
    Bouncer.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self:lazy_mixin(Mixins.Behavior.Roamer)
	self:lazy_mixin(Mixins.Behavior.RandomOffsetPulse)
	-- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
	self.drag = 0.3
    self.bullet_push_modifier = 2.7
    self.terrain_collision_radius = 4
    self.hurt_bubble_radius = 6
	
	self.hit_bubble_radius = 5
    self.declump_radius = 8
	self.declump_mass = 10
	self.walk_speed = 0.3
	self.body_height = 4
    self.no_damage_flash = true
    self.hurt_sfx = "enemy_hurt"
	self.hurt_sfx_volume = 0.0
end

function Bouncer:is_invulnerable()
    return true
end

function Bouncer:enter()
	self:hazard_init()
end

function Bouncer:get_trail_color()
    return TRAIL_COLOR
end

function Bouncer:get_sprite()
    return self:random_offset_pulse(30, 0) and textures.enemy_bouncer1 or textures.enemy_bouncer2
end

function FastBouncer:new(x, y)
    FastBouncer.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.walk_speed = 0.6
    self.drag = 0.025
    self.walk_toward_player_chance = 99
    self.bullet_push_modifier = 2.5
end

function FastBouncer:enter()
    FastBouncer.super.enter(self)
	-- self:add_tag("fast_bouncer")
end


function FastBouncer:get_sprite()
    return self:random_offset_pulse(20, 0) and textures.enemy_fast_bouncer1 or textures.enemy_fast_bouncer2
end

function FastBouncer:get_palette()
	if idivmod_eq_zero(self.tick, 6, 5) then
		return nil, idiv(self.tick, 3)
	end
	return nil, nil
end

function FastBouncer:get_trail_color()

    return self:tick_pulse(16) and TRAIL_COLOR_FAST1 or TRAIL_COLOR_FAST2
end

function Bouncer:floor_draw()
    graphics.set_color(Color.black)
    graphics.line(-3, 3, 4, 3)
    graphics.set_color(self:get_trail_color(), 1)
	graphics.points(-3, 3, 4, 3)
end

return {Bouncer, FastBouncer}
