local LevelCompleteTile = GameObject:extend("LevelCompleteTile")

function LevelCompleteTile:new(x, y)
	LevelCompleteTile.super.new(self, x, y)
	self.collision_rect = Rect(0, 0, 16, 16)
	self:implement(Mixins.Behavior.BumpCollision)
	self:enable_bump_layer(PHYSICS_OBJECT)
    self.level_complete_tile = true
end

function LevelCompleteTile:draw()
	if debug.can_draw() then
		graphics.draw_centered(textures.friendly_placeholder1, 0, 0)
	end 
end

return LevelCompleteTile
