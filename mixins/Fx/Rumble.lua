local Rumble = Object:extend("Rumble")

function Rumble:_init()
    self:add_sequencer()

    local old_get_draw_offset = self.get_draw_offset
	
    self.get_draw_offset = function()
        local x, y = old_get_draw_offset()
		if self.rumble_amount <= 0 then return x, y end
        local rumble_x, rumble_y = self:get_rumble_vec()
		return x + rumble_x, y + rumble_y
	end

	self.rumble_amount = 0
end

function Rumble:get_rumble_vec()
	local dx, dy = rng.random_vec2()
	return (dx * rng.randf(self.rumble_amount*0.5, self.rumble_amount)), (dy * rng.randf(self.rumble_amount*0.5, self.rumble_amount))
end

function Rumble:start_rumble(amount, duration, easing_function)
	local s = self.world.sequencer
	s:stop(self.rumble_coroutine)
    easing_function = easing_function or ease("outQuad")
    self.rumble_coroutine = s:start(function()
        s:tween_property(self, "rumble_amount", amount, 0, duration, easing_function)
        self.rumble_coroutine = nil
		self.rumble_amount = 0
    end)
end

function Rumble:set_rumble_directly(amount)
	self.rumble_amount = amount
end

function Rumble:stop_rumble()
	local s = self.world.sequencer
	s:stop(self.rumble_coroutine)
	self.rumble_amount = 0
end

function Rumble:frame_rumble(intensity)
	self:start_rumble(intensity, 1, "constant0")
end

return Rumble
