local CodexTextMenuItem = require("obj.Menu.MenuButton"):extend("CodexTextMenuItem")

local WIDTH = 160
local HEIGHT = 9

function CodexTextMenuItem:new(x, y, text)
    CodexTextMenuItem.super.new(self, x, y, WIDTH, HEIGHT)
    self.font = fonts.depalettized.image_font2
    self.text = text
	-- self.focus_on_hover = false
end

function CodexTextMenuItem:on_focused()
    self:play_sfx("ui_menu_button_focused1", 0.6)
end

function CodexTextMenuItem:on_selected()
    self:play_sfx("ui_menu_button_selected1", 0.6)
end

function CodexTextMenuItem:draw()
	graphics.set_color(Color.white)
	local x, y, w, h = self:get_rect_local()
    if self.focused then
        graphics.rectangle("fill", x - 6, y + 2, 4, 4)
    end
	graphics.set_font(self.font)
	graphics.print(self.text, 0, 0)

end

return CodexTextMenuItem
