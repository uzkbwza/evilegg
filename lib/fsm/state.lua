local State = Object:extend("State")

function State.dummy()
end

function State._create(...)
	return State(...)
end

function State:new(name, table, add_transition_function)

	for _, unimplemented in ipairs({
		"enter",
		"exit",
		"update",
		"step",
		"draw"
	}) do
		self[unimplemented] = State.dummy
	end

	self.name = name

	local go = nil
	if add_transition_function then
		go = function(to, ...) self:transition(to, ...) end
	end

    for k, v in pairs(table) do
        if type(v) == "function" then
			if go then
				self[k] = function(...) v(go, ...) end
			else
				self[k] = v
			end
        else
            self[k] = v
        end
    end
	
end

function State:transition(to, ...)
	error("no state machine!")
end

return State
