local Pausescreen = CanvasLayer:extend("Pausescreen")

function Pausescreen:new()
	Pausescreen.super.new(self)
    self.blocks_render = false
	self.blocks_input = true
	self.blocks_logic = true
end

function Pausescreen:update(dt)
	if self.input.menu_pressed then
		self:pop_from_parent()
	end
end

function Pausescreen:draw()
	Pausescreen.super.draw(self)

	graphics.print("PAUSED", 0, 0)
end

function Pausescreen:enter()
end

return Pausescreen
