local OptionsMenuHeader = GameObject2D:extend("OptionsMenuHeader")

function OptionsMenuHeader:new(x, y, text)
	OptionsMenuHeader.super.new(self, x, y)
	self.text = text
end

function OptionsMenuHeader:draw()
    graphics.set_color(Color.green)
	graphics.set_font(fonts.depalettized.image_font2)
	graphics.print(self.text, self.x, self.y)
end

return OptionsMenuHeader
