local GenericMenuRoot = require("obj.Menu.MenuItem"):extend("GenericMenuRoot")

function GenericMenuRoot:new(x, y, w, h)
    GenericMenuRoot.super.new(self, x, y, w, h)
	self.focusable = false
	self.mouse_enabled = false
end

function GenericMenuRoot:update(dt)
	
end

return GenericMenuRoot
