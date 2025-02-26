local BulletPushable = Object:extend("BulletPushable")

function BulletPushable:__mix_init()
	self.bullet_pushable = true
	self.bullet_push_modifier = self.bullet_push_modifier or 1
end

function BulletPushable:get_pushed_by_bullet(vec_x, vec_y)
	self:apply_impulse(vec_x * self.bullet_push_modifier, vec_y * self.bullet_push_modifier)
end

return BulletPushable
