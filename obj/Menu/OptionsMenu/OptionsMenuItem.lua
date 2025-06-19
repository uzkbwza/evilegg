local OptionsMenuItem = require("obj.Menu.MenuButton"):extend("OptionsMenuItem")

local WIDTH = 160
local HEIGHT = 7

function OptionsMenuItem:new(x, y, text)
    OptionsMenuItem.super.new(self, x, y, WIDTH, HEIGHT)
    self.font = fonts.depalettized.image_font1
    self.text = text
	-- self.focus_on_hover = false
end

function OptionsMenuItem:on_focused()
    self:play_sfx("ui_menu_button_focused1", 0.6)
end

function OptionsMenuItem:on_selected()
    self:play_sfx("ui_menu_button_selected1", 0.6)
end

function OptionsMenuItem:draw()
    graphics.set_color(Color.white)
	local x, y, w, h = self:get_rect_local()

	if self.focused then
		graphics.set_color(Color.green)
		graphics.rectangle("fill", x - 6, y + 2, 4, 4)
	end
	graphics.set_font(self.font)
	graphics.print(self.text, 0, 0)

end

return OptionsMenuItem
