local StateMachine = {}

local mt = {
	__index = function(table, key) 
		if rawget(table, key) ~= nil then
			return rawget(table, key) 
		end
		if rawget(table, "current_state") ~= nil then
			local v = rawget(table, "current_state")[key]
			if v ~= nil then
				return v
			end
		end
		return StateMachine[key]
	end
}

function StateMachine._create(obj)
	obj = obj or {
		current_state = nil,
		states = {},
		update = function() end
	}

	obj.state_transition = function(state, to, ...) obj:change_state(to, ...) end
	setmetatable(obj, mt)

	return obj
end

function StateMachine:add_state(state)
	self.update = nil
	self.states[state.name] = state
	if self.current_state == nil then
		self:change_state(state.name)
	end
	state.transition = self.state_transition
end

function StateMachine:add_states(states)
	for _, v in ipairs(states) do
		self:add_state(v)
	end
end

function StateMachine:change_state(to, ...)
    if self.current_state then
        self.current_state:exit()
    end

    self.current_state = self.states[to]
    if self.current_state == nil then error("state doesn't exist: " .. tostring(to)) end

    self.current_state.enter(...)
end

return StateMachine
