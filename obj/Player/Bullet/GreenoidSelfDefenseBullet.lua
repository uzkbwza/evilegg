local GreenoidSelfDefenseBullet = require("obj.Player.Bullet.BasePlayerBullet"):extend("GreenoidSelfDefenseBullet")

function GreenoidSelfDefenseBullet:new(x, y)
	self.use_artefacts = true
    self.use_upgrades = true
	self.damage = 0.1
	self.hit_vel_multip = 10
	self.push_modifier = 0.35
    GreenoidSelfDefenseBullet.super.new(self, x, y)
end

function GreenoidSelfDefenseBullet:update(dt)
	GreenoidSelfDefenseBullet.super.update(self, dt)
end

function GreenoidSelfDefenseBullet:draw()
	graphics.drawp_centered(textures.ally_greenoid_bullet2, nil, idiv(self.tick, 3) + 1, vec2_mul_scalar(self.direction.x, self.direction.y, -8))
	graphics.drawp_centered(textures.ally_greenoid_bullet1, nil, idiv(self.tick, 3))
end

function GreenoidSelfDefenseBullet:die()
	self:queue_destroy()
end

return GreenoidSelfDefenseBullet
