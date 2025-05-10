local NameEntryCharacterButton = require("obj.Menu.MenuButton"):extend("NameEntryCharacterButton")

local WIDTH = 100
local HEIGHT = 12

function NameEntryCharacterButton:new(x, y, text, width, height, center)
    if center == nil then
        center = true
    end

	if center then
    	NameEntryCharacterButton.super.new(self, x - (width or WIDTH) / 2, y - (height or HEIGHT) / 2, width or WIDTH, height or HEIGHT)
	else
		NameEntryCharacterButton.super.new(self, x, y, width or WIDTH, height or HEIGHT)
	end
    self.text = text

    self.font = fonts.image_font2
	self.palette = PaletteStack(Color.black, Color.black, Color.green)

    self.text_width = self.font:getWidth(text)
    self.text_height = self.font:getHeight(text)
end

function NameEntryCharacterButton:set_text(text)
	self.text = text
	self.text_width = self.font:getWidth(text)
    self.text_height = self.font:getHeight(text)
end

function NameEntryCharacterButton:on_focused()
	self:play_sfx("ui_menu_button_focused1", 0.6)
end

function NameEntryCharacterButton:on_selected()
	self:play_sfx("ui_menu_button_selected1", 0.6)
end

function NameEntryCharacterButton:draw()
	self:draw_text(self.text)
end

function NameEntryCharacterButton:draw_text(text)
	local col = self.color or Palette.rainbow:tick_color(self.world.tick, 0, 10)
	graphics.set_color(self.focused and col or Color.transparent)
	graphics.rectangle("fill", 0, 0, self.width, self.height)
    -- graphics.set_color(self.focused and Color.white or Color.black)
    graphics.set_font(self.font)
	self.palette:set_color(2, self.focused and col or Color.black)
	self.palette:set_color(3, self.focused and Color.black or col)
	graphics.printp_centered(text, self.font, self.palette, 0, self.width / 2 - 1, self.height / 2)
end

return NameEntryCharacterButton


