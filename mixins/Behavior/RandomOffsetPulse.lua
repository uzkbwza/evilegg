local RandomOffsetPulse = Object:extend("RandomOffsetPulse")

function RandomOffsetPulse:random_offset_pulse(pulse_length)
	return floor(((self.tick + self.random_offset) / pulse_length) % 2) == 0
end

return RandomOffsetPulse
