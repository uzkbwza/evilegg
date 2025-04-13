local PauseScreenRoot = require("obj.Menu.MenuItem"):extend("PauseScreenRoot")

function PauseScreenRoot:new(x, y, w, h)
    PauseScreenRoot.super.new(self, x, y, w, h)
	self.focusable = false
	self.mouse_enabled = false
end

function PauseScreenRoot:update(dt)
	
end

return PauseScreenRoot
