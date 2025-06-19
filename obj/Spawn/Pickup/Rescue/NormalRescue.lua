local NormalRescue = require("obj.Spawn.Pickup.Rescue.BaseRescue"):extend("NormalRescue")

function NormalRescue:new(x, y)
	self.walk_speed = self.walk_speed or 0.2
	-- self.team = "player"
    -- self.body_height = 4
    -- self.max_hp = self.max_hp or 3
    -- self.hurt_bubble_radius = self.hurt_bubble_radius or 3
    -- self.declump_radius = self.declump_radius or 20
	-- self.self_declump_modifier = self.self_declump_modifier or 0.3
    NormalRescue.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.Roamer)


end

return NormalRescue
