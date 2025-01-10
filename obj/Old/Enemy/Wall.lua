local Wall = require("obj.Enemy.Enemy"):extend("WallEnemy")

local sheet = SpriteSheet("terrain_brick", 16, 16)

function Wall:new(x, y)
	Wall.super.new(self, x, y)
	self.collision_rect = Rect(0, 0, 18, 18)
	self.score = 50
	-- self.bullet_passthrough = true
    self.solid = true
	self.is_wall = true
    self:disable_bump_layer(PHYSICS_HAZARD)
	self:enable_bump_layer(PHYSICS_TERRAIN)
	self:init_health(6)
end

function Wall:get_texture()
	if self.health <= self.max_health / 2 then
		return sheet:get_frame(2)
	else
		return sheet:get_frame(1)
	end
end

return Wall
