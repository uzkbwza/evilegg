local AutoStateMachine = Object:extend("AutoStateMachine")

function AutoStateMachine.__global_mix_init()
	
end

function AutoStateMachine:__mix_init(start_state)
	assert(start_state, "starting state is required")

	self.state = start_state

	local states = {}
	local callback_names = bonglewunch {
		"enter",
		"exit",
		"update",
		"step",
		"draw"
	}

	local methods = {}
    local tab = self
	while tab and tab.get_methods do
		methods = table.merged(methods, tab:get_methods())
		tab = getmetatable(tab)
	end
	for k, v in pairs(methods) do
		if string.startswith(k, "state_") then
			local name = string.split(string.sub(k, 6), "_")[1]
			if not states[name] then
				states[name] = {

				}
			end
			for _, callback_name in (callback_names):ipairs() do
				if string.endswith(k, callback_name) then
					states[name][callback_name] = function(...) v(self, ...) end
					break
				end
			end
		end
	end
	self.state_machine = StateMachine()
	if not states[self.state] then
		states[self.state] = {}
	end
	self.state_machine:add_state(State(self.state, states[self.state]))
	states[self.state] = nil

	for k, v in pairs(states) do
		self.state_machine:add_state(State(k, v, false))
	end

	self.state_elapsed = 1
	self.state_tick = 1

	local old_update = self.update
	local old_draw = self.draw

	self.update = function(self, dt)
		old_update(self, dt)
		self.state_machine.update(dt)
		self.state_elapsed = self.state_elapsed + dt
		self.state_tick = floor(self.state_elapsed)
	end

    self.draw = function(self)
        old_draw(self)
        self.state_machine.draw()
    end
	
	self:add_enter_function(function(self)
		self:change_state(self.state)
	end)
end

function AutoStateMachine:change_state(to)
	self.state_machine:change_state(to)
	self.state = to
	self.state_elapsed = 1
	self.state_tick = 1
end

return AutoStateMachine
