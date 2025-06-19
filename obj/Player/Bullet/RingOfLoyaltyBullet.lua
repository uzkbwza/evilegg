local RingOfLoyaltyBullet = require("obj.Player.Bullet.BasePlayerBullet"):extend("RingOfLoyaltyBullet")

function RingOfLoyaltyBullet:new(x, y)
	local extra_bullet = true
	self.use_artefacts = true
    self.use_upgrades = true
    -- self.die_on_hit = false
    self.lifetime = 10
    self.damage = 7.5
	self.push_modifier = 10.0
    RingOfLoyaltyBullet.super.new(self, x, y, extra_bullet)
	-- print(self:get_damage())
end


return RingOfLoyaltyBullet
