local OptionsMenuButton = require("obj.Menu.OptionsMenu.OptionsMenuItem"):extend("OptionsMenuButton")

function OptionsMenuButton:new(x, y, text)
    OptionsMenuButton.super.new(self, x, y, text)
end

function OptionsMenuButton:on_focused()
	OptionsMenuButton.super.on_focused(self)
end

function OptionsMenuButton:on_selected()
	OptionsMenuButton.super.on_selected(self)
end

function OptionsMenuButton:draw()
	OptionsMenuButton.super.draw(self)
end

return OptionsMenuButton
