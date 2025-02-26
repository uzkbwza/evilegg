local TrackPreviousPosition2D = Object:extend("TrackPreviousPosition2D")

function TrackPreviousPosition2D:__mix_init()
    self.prev_pos = Vec2(self.pos.x, self.pos.y)
	local move_to = self.move_to
    self.move_to = function(self, x, y)
        self.prev_pos.x = self.pos.x
        self.prev_pos.y = self.pos.y
        move_to(self, x, y)
    end
end

return TrackPreviousPosition2D
