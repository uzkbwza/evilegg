local MainMenuRoot = require("obj.Menu.MenuItem"):extend("MainMenuRoot")

function MainMenuRoot:new(x, y, w, h)
    MainMenuRoot.super.new(self, x, y, w, h)
	self.focusable = false
	self.mouse_enabled = false
end

function MainMenuRoot:update(dt)
	
end

return MainMenuRoot
