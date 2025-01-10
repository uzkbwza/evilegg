local path = select(1, ...)

return {
	StateMachine = require(... .. ".statemachine")._create,
	State = require(... .. ".state")._create
}
