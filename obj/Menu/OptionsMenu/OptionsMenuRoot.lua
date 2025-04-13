local OptionsMenuRoot = require("obj.Menu.MenuItem"):extend("OptionsMenuRoot")

function OptionsMenuRoot:new(x, y, w, h)
    OptionsMenuRoot.super.new(self, x, y, w, h)
	self.focusable = false
	self.mouse_enabled = false
end

function OptionsMenuRoot:update(dt)
	
end

return OptionsMenuRoot
