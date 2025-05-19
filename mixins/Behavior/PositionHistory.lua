local PositionHistory = Object:extend("PositionHistory")

function PositionHistory:__mix_init(position_history_size)
	self.position_history_size = position_history_size or self.position_history_size
	self.position_history = {}
	self:add_update_function(self._position_history_update)
end

function PositionHistory:_position_history_update(dt)
	if self.is_new_tick then
		self.position_history[#self.position_history + 1] = self:get_position_for_history()
		while #self.position_history > self.position_history_size do
			table.remove(self.position_history, 1)
		end
	end
end

function PositionHistory:get_position_for_history()
	return self.pos:clone()
end

return PositionHistory
