local FloorCanvasPush = Object:extend("FloorCanvasPush")

function FloorCanvasPush:floor_canvas_push()
    self.world:floor_canvas_push()
	graphics.translate(self.pos.x, self.pos.y)
end

function FloorCanvasPush:floor_canvas_pop()
    self.world:floor_canvas_pop()
end

return FloorCanvasPush
