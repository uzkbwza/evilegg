local Quark = require("obj.Spawn.Enemy.BaseEnemy"):extend("Quark")

local SPEED = 1
local MAX_SPEED = 1.5

local physics_limits = {
	max_speed = MAX_SPEED
}

function Quark:new(x, y)
    self.max_hp = 4
    self.hit_bubble_radius = 3
    self.hurt_bubble_radius = 5
    self.terrain_collision_radius = 5
    Quark.super.new(self, x, y)

    self:set_physics_limits(physics_limits)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self.bullet_push_modifier = 1.4
    self.drag = 0.0
    local angle = (tau / 8) + rng.randi_range(1, 4) * (tau / 4)
    self.vel.x, self.vel.y = cos(angle), sin(angle)
    self.vel:mul_in_place(SPEED)
    self.z_index = 1
end

function Quark:on_terrain_collision(normal_x, normal_y)
    self:terrain_collision_bounce(normal_x, normal_y)
	self:play_sfx("hazard_quark_bounce", 0.75, 1.0)
end

function Quark:enter()
	self:hazard_init()
end

function Quark:get_sprite()
	return textures.hazard_quark
end

function Quark:get_palette()
    local palette, offset = Quark.super.get_palette(self)
    if palette == nil then
		return nil, self.random_offset + idiv(self.tick, 5)
	end
end

return Quark
