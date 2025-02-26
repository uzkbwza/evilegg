local Bouncer = require("obj.Enemy.BaseEnemy"):extend("Bouncer")

local TRAIL_COLOR = Palette.rainbow:get_color(16):clone()
local trail_mod = 0.8
TRAIL_COLOR.r = TRAIL_COLOR.r * trail_mod
TRAIL_COLOR.g = TRAIL_COLOR.g * trail_mod
TRAIL_COLOR.b = TRAIL_COLOR.b * trail_mod

function Bouncer:new(x, y)
	self.max_hp = 1
    Bouncer.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self:lazy_mixin(Mixins.Behavior.Roamer)
	self:lazy_mixin(Mixins.Behavior.RandomOffsetPulse)
	-- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
	self.drag = 0.3
    self.bullet_push_modifier = 0.7
    self.terrain_collision_radius = 4
    self.hurt_bubble_radius = 6
	self.hit_bubble_radius = 5
    self.declump_radius = 8
	self.declump_mass = 10
	self.walk_speed = 0.3
	self.body_height = 4
end

function Bouncer:is_invulnerable()
    return true
end

function Bouncer:enter()
	self:hazard_init()
end

function Bouncer:get_sprite()
    return self:random_offset_pulse(30, 0) and textures.enemy_bouncer1 or textures.enemy_bouncer2
end


function Bouncer:floor_draw()
    graphics.set_color(Color.black)
    graphics.line(-5, 3, 6, 3)
    graphics.set_color(TRAIL_COLOR, 1)
	graphics.points(-5, 3, 6, 3)
end

return Bouncer
