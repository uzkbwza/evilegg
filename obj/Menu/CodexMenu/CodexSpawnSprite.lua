local CodexSpawnSprite = GameObject2D:extend("CodexSpawnSprite")

function CodexSpawnSprite:new(x, y, sprite, delay)
    CodexSpawnSprite.super.new(self, x, y)
    self.sprite = graphics.depalettized[sprite]
	self:hide()
	self:add_time_stuff()
	self.sequencer:start(function()
        self.sequencer:wait(delay)
		self:show()
	end)
end

function CodexSpawnSprite:draw()
    graphics.draw_centered(self.sprite, 0, 0)
end

return CodexSpawnSprite


