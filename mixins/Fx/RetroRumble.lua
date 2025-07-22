local RetroRumble = Object:extend("RetroRumble")

function RetroRumble:__mix_init()
    self:add_sequencer()
	self:add_elapsed_ticks()

    local old_get_draw_offset = self.get_draw_offset
	
    self.get_draw_offset = function()
        local x, y = old_get_draw_offset()
		if self.rumble_amount_x <= 0 and self.rumble_amount_y <= 0 then return x, y end
        local rumble_x, rumble_y = self:get_rumble_vec()
		return x + rumble_x, y + rumble_y
	end

	self.rumble_amount_x = 0
	self.rumble_amount_y = 0
end

function RetroRumble:get_rumble_vec()
	local dx, dy = self.rumble_amount_x * (floor(gametime.tick / 2) % 2 == 0 and 1 or -1) * 0.5, self.rumble_amount_y * ((floor((gametime.tick + 1) / 2)) % 2 == 0 and 1 or -1) * 0.5
	return dx, dy
end

function RetroRumble:start_rumble(amount, duration, easing_function, x_axis, y_axis)
	if x_axis == nil then x_axis = true end
	if y_axis == nil then y_axis = false end
	local s = self.world.sequencer
	s:stop(self.rumble_coroutine)
    easing_function = easing_function or ease("outQuad")
	local func = function()

		s:tween(function(amount)
			self.rumble_amount_x = x_axis and amount or 0
			self.rumble_amount_y = y_axis and amount or 0
		end, amount, 0, duration, easing_function)

        self.rumble_coroutine = nil
		self.rumble_amount_x = 0
		self.rumble_amount_y = 0
    end
    self.rumble_coroutine = s:start(func)
end

function RetroRumble:set_rumble_directly(amount)
	self.rumble_amount_x = amount
	self.rumble_amount_y = amount
end

function RetroRumble:stop_rumble()
	local s = self.world.sequencer
	s:stop(self.rumble_coroutine)
	self.rumble_amount_x = 0
	self.rumble_amount_y = 0
end

function RetroRumble:frame_rumble(intensity)

end

return RetroRumble
