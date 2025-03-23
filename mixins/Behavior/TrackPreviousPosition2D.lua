local TrackPreviousPosition2D = Object:extend("TrackPreviousPosition2D")

function TrackPreviousPosition2D:__mix_init()
    self.prev_pos = Vec2(self.pos.x, self.pos.y)
	local move_to = self.move_to
    self.move_to = function(self, x, y, ...)
		local old_x, old_y = self.pos.x, self.pos.y
        move_to(self, x, y, ...)
		if old_x ~= self.pos.x or old_y ~= self.pos.y then
			self.prev_pos.x = old_x
			self.prev_pos.y = old_y
		end
    end
end

return TrackPreviousPosition2D
