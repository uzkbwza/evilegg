local Servitor = GameObject:extend("Servitor")
local DeathFx = require("fx.death_effect")

local sheet = SpriteSheet("player_servitor", 16, 16)

function Servitor:new(x, y, width, height)
	Servitor.super.new(self, x, y, width, height)
	self:add_elapsed_ticks()
	self:add_sequencer()
end

function Servitor:enter()
	local fx = DeathFx(self.pos.x, self.pos.y, self:get_texture(), 1)
	self:ref("fx", fx)
    fx.reversed = true
	fx.flash = false
	fx.duration = 60
	self:spawn_object(fx)
	self:set_visibility(false)
	local s = self.sequencer
	s:start(function()
		self:set_visibility(false)
		s:wait(59)
		self:set_visibility(true)
	end)
end

function Servitor:get_texture()
	return sheet:loop(self.tick, 13)
end

function Servitor:draw()
	graphics.draw_centered(self:get_texture())
end

return Servitor
