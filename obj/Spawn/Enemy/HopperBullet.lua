local HopperBullet = require("obj.Spawn.Enemy.BaseEnemy"):extend("HopperBullet")


function HopperBullet:new(x, y)
	self.max_hp = 1

    HopperBullet.super.new(self, x, y)
    self.drag = 0.0
    self.hit_bubble_radius = 1
	self.hurt_bubble_radius = 3
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
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


function HopperBullet:get_floor_sprite()

	return textures.enemy_enforcer_bullet_trail
end

function HopperBullet:update(dt)
end

return HopperBullet
