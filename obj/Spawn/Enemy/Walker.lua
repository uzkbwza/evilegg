local Walker = require("obj.Spawn.Enemy.BaseEnemy"):extend("Walker")

function Walker:new(x, y)
	self.max_hp = self.max_hp or 1

    self.walk_speed = 0.0525
    self.hurt_bubble_radius = 5
    self.hit_bubble_radius = 3
    self.body_height = 5
    Walker.super.new(self, x, y)
	self.follow_allies = rng.percent(5)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.WalkTowardPlayer)
    self.bullet_push_modifier = 1.0
    self.declump_radius = 7
    self.walk_snap_angle = 8
end

function Walker:update(dt)
	self:set_flip(idivmod_eq_zero(self.tick, 5, 2) and 1 or -1)
end

return Walker
