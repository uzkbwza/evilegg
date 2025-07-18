local AutoStateMachine = {}

local callback_names = {
	"enter",
	"exit",
	"update",
	"step",
	"draw"
}


function AutoStateMachine.get_state_methods(class, methods)
    local m = methods or {}
    
	local super = class.super

    if super then
        m = table.merged(m, AutoStateMachine.get_state_methods(super, m), true)
    end

    for k, v in pairs(class) do
        if type(v) == "function" then
			if string.startswith(k, "state_") then
            	m[k] = v
			end
        end
    end

	
	return m
end

function AutoStateMachine.set_up_class(class, start_state)
    class.state_methods = {}
    -- if class == require("obj.Spawn.Enemy.BigHopper") then
    --     print("BigHopper")
    -- end
	local state_methods = AutoStateMachine.get_state_methods(class)

    for k, v in pairs(state_methods) do
        if type(v) == "function" then
			local name = string.split(string.sub(k, 6), "_")[1]
			local callback = nil
			for _, callback_name in ipairs(callback_names) do
				if string.endswith(k, callback_name) then
					callback = callback_name
				end
			end
			class.state_methods[name] = class.state_methods[name] or {}
			table.insert(class.state_methods[name], { func = v, callback_name = callback })
        end
    end
    class.start_state = start_state
	class.auto_state_machine = true
    class.change_state = AutoStateMachine.change_state
	class.init_state_machine = AutoStateMachine.init_state_machine
end

function AutoStateMachine:init_state_machine()

	assert(self.start_state, "starting state is required")

	self.state = self.start_state

	local states = {}

	local methods = self.state_methods
	
	for state_name, state_data in pairs(methods) do
        if not states[state_name] then
            states[state_name] = {
            }
        end
		
		for _, callback in ipairs(state_data) do
			states[state_name][callback.callback_name] = function(...) callback.func(self, ...) end
		end
	end

	local state_machine = StateMachine()
	if not states[self.state] then
		states[self.state] = {}
	end
	state_machine:add_state(State(self.state, states[self.state]))
	states[self.state] = nil

	for k, v in pairs(states) do
		state_machine:add_state(State(k, v, false))
	end

	self.state_elapsed = 1
	self.state_tick = 1

	local old_update = self.update or dummy_function
	local old_draw = self.draw or dummy_function

	self.update = function(self, dt)
		old_update(self, dt)
		state_machine.update(dt)
		self.state_elapsed = self.state_elapsed + dt
		self.state_tick = floor(self.state_elapsed)
	end

    self.draw = function(self)
        old_draw(self)
        state_machine.draw()
    end
	
	self:add_enter_function(function(self)
		self:change_state(self.state)
	end)

	self.state_machine = state_machine
end

function AutoStateMachine:change_state(to, ...)
	self.state_machine:change_state(to, ...)
	self.state = to
	self.state_elapsed = 1
	self.state_tick = 1
end

return AutoStateMachine.set_up_class
