local PauseScreenButton = require("obj.Menu.MenuButton"):extend("PauseScreenButton")

local WIDTH = 50
local HEIGHT = 14

function PauseScreenButton:new(x, y, text)
    PauseScreenButton.super.new(self, x - WIDTH / 2, y - HEIGHT / 2, WIDTH, HEIGHT)

    self.text = text

    self.font = fonts.image_font2
	self.palette = PaletteStack(Color.black, Color.black, Color.green)

    self.text_width = self.font:getWidth(text)
    self.text_height = self.font:getHeight(text)
end

function PauseScreenButton:on_focused()
	self:play_sfx("ui_menu_button_focused1", 0.6)
end

function PauseScreenButton:on_selected()
	self:play_sfx("ui_menu_button_selected1", 0.6)
end

function PauseScreenButton:draw()
	graphics.set_color(self.focused and Color.green or Color.transparent)
	graphics.rectangle("fill", 0, 0, self.width, self.height)
    -- graphics.set_color(self.focused and Color.white or Color.black)
    graphics.set_font(self.font)
	self.palette:set_color(2, self.focused and Color.green or Color.black)
	self.palette:set_color(3, self.focused and Color.black or Color.green)
	graphics.printp_centered(self.text, self.font, self.palette, 0, self.width / 2, self.height / 2)
end

return PauseScreenButton


