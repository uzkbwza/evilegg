local RollbackObject = Object:extend("RollbackObject")

RollbackObject.tracked_values = {

}

function RollbackObject:extend(name, tracked_values)
    local new_class = Object.extend(self, name)
    new_class.tracked_values = table.merge(new_class.tracked_values, tracked_values or {})

    return new_class
end

function RollbackObject:get_state()
	local state = {}
	for key, value in pairs(self.tracked_values) do
		state[key] = self[key]
	end
	return state
end



function RollbackObject:new(id)
	self.id = id
	for key, value in pairs(self.tracked_values) do
		self[key] = value
	end
end

return RollbackObject