local Heart = GameObject2D:extend("Heart")
local DeathFlash = require("fx.enemy_death_flash")
local DeathSplatter = require("fx.enemy_death_pixel_splatter")
function Heart:new(x, y, index)
    Heart.super.new(self, x, y)
	self.filled = false
    self.index = index
	self:add_time_stuff()
    self:update_fill(game_state.hearts)
    self.flashing = false
end

function Heart:draw()
	if self.flashing and iflicker(self.tick, 3, 2) then
		return
	end
	local texture = self.filled and textures.pickup_heart_icon2 or textures.pickup_empty_heart_icon
    graphics.drawp_centered(texture, nil, 0, 0, 0)
end

function Heart:update_fill(hearts)
    if not self.filled and self.index <= hearts then
        self:fill()
    elseif self.index > hearts then
        self:empty()
    end
end

function Heart:flash()
	local s = self.sequencer
	s:start(function()
		self.flashing = true
		s:wait(30)
		self.flashing = false
	end)
end

function Heart:empty_animation()
	-- self:spawn_object(Heart(self.pos.x + 10, self.pos.y))
    -- self:spawn_object(Heart(self.pos.x - 10, self.pos.y))
	self:spawn_object(DeathFlash(self.pos.x, self.pos.y, textures.pickup_heart_icon2, 0.5, nil, nil, false))
	self:spawn_object(DeathSplatter(self.pos.x + 1, self.pos.y + 2, 1, textures.pickup_heart_icon2, Palette[textures.pickup_heart_icon2], 2, 0, 0, nil, nil, 3))
end

function Heart:fill()
    self.filled = true
end

function Heart:empty()
    self.filled = false

end

return Heart
