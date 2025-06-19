local PauseScreenButton = require("obj.Menu.MenuButton"):extend("PauseScreenButton")

local WIDTH = 100
local HEIGHT = 12

function PauseScreenButton:new(x, y, text, width, height, center, color, center_text, outline)
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
	self.color = color
    self.center_text = center_text
    self.outline = outline


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
	local col = self.color or Color.green
	
	
	if self.outline and not self.focused then
		graphics.set_color(col)
		graphics.rectangle("line", 1, 1, self.width - 1, self.height - 1)
	end
	
	graphics.set_color(self.focused and col or Color.transparent)
	graphics.rectangle("fill", 0, 0, self.width, self.height)
    -- graphics.set_color(self.focused and Color.white or Color.black)
    graphics.set_font(self.font)
	self.palette:set_color(2, self.focused and col or Color.black)
	self.palette:set_color(3, self.focused and Color.black or col)
	if self.center_text then
		graphics.printp_centered(text, self.font, self.palette, 0, self.width / 2, self.height / 2)
	else
		graphics.printp(text, self.font, self.palette, 0, 0, 0)
	end
end

return PauseScreenButton