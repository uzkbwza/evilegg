local CollisionBubble = require("obj.collision_bubble")

local HitBubble = CollisionBubble:extend("HitBubble")

function HitBubble:new(parent, x, y, parent_x, parent_y, radius, x1, x2, damage)
    HitBubble.super.new(self, parent, x, y, parent_x, parent_y, radius, x1, x2)
    self.damage = damage or 1
end

return HitBubble
