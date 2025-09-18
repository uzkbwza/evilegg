local PlayerHitscanBullet = require("obj.Player.Bullet.BasePlayerBullet"):extend("PlayerHitscanBullet")

function PlayerHitscanBullet:new(x, y)
    self.force_speed_stack = 200
    self.force_speed_stack_push_modifier = 1.
    self.force_speed_stack_hit_vel_multip = 1.2
    PlayerHitscanBullet.super.new(self, x, y)

end

return PlayerHitscanBullet
