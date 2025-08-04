local OptionsMenuHeader = GameObject2D:extend("OptionsMenuHeader")

function OptionsMenuHeader:new(x, y, text)
	OptionsMenuHeader.super.new(self, x, y)
	self.text = text
end

function OptionsMenuHeader:draw()
    if self.text == "" then
        return
    end
    graphics.set_color(Color.green)
    local font = fonts.depalettized.image_font2
	graphics.set_font(font)
    graphics.print(self.text, -1, 0)
    graphics.set_color(Color.darkgreen)
    graphics.line(-1, 10, font:getWidth(self.text), 10)
end

return OptionsMenuHeader
