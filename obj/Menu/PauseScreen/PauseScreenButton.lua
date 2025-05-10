local PauseScreenButton = require("obj.Menu.MenuButton"):extend("PauseScreenButton")

local WIDTH = 100
local HEIGHT = 12

function PauseScreenButton:new(x, y, text, width, height, center)
    if center == nil then
        center = true
    end

	if center then
    	PauseScreenButton.super.new(self, x - (width or WIDTH) / 2, y - (height or HEIGHT) / 2, width or WIDTH, height or HEIGHT)
	else
		PauseScreenButton.super.new(self, x, y, width or WIDTH, height or HEIGHT)
	end
    self.text = text

    self.font = fonts.image_font2
	self.palette = PaletteStack(Color.black, Color.black, Color.green)

    self.text_width = self.font:getWidth(text)
    self.text_height = self.font:getHeight(text)
end

function PauseScreenButton:set_text(text)
	self.text = text
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
	self:draw_text(self.text)
end

function PauseScreenButton:draw_text(text)
	graphics.set_color(self.focused and Color.green or Color.transparent)
	graphics.rectangle("fill", 0, 0, self.width, self.height)
    -- graphics.set_color(self.focused and Color.white or Color.black)
    graphics.set_font(self.font)
	self.palette:set_color(2, self.focused and Color.green or Color.black)
	self.palette:set_color(3, self.focused and Color.black or Color.green)
	graphics.printp(text, self.font, self.palette, 0, 0, 0)
end

return PauseScreenButton


