local CodexSpawnText = GameObject2D:extend("CodexSpawnText")

local LINE_WIDTH = 120

function CodexSpawnText:new(x, y, text, centered, color, delay, uppercase)
    CodexSpawnText.super.new(self, x, y)
    self.font = uppercase and fonts.depalettized.image_font2 or fonts.depalettized.image_neutralfont1
    self.text = uppercase and text:upper() or text
    
	if centered == nil then
        centered = true
    end
    
	if color == nil then
        color = Color.white
    end

	self.centered = centered
	self.color = color
    self.wrapped_width, self.wrapped_text = self.font:getWrap(self.text, LINE_WIDTH)
	local line_height = self.font:getHeight(" ")
	self.text_height = line_height * #self.wrapped_text
	self:add_time_stuff()
	self:hide()

	self.sequencer:start(function()
		self.sequencer:wait(delay or 0)
		self:show()
		self:start_timer("show_text", 10)
	end)
end

function CodexSpawnText:draw()
	graphics.set_color(self.color)
    graphics.set_font(self.font)
	local line_height = self.font:getHeight(" ")
    for i, line in ipairs(self.wrapped_text) do
        local text = line
		text = line:sub(1, (1 - self:timer_time_left_ratio("show_text")) * #line)

		if self.centered then
			graphics.print_centered(text, self.font, 0, line_height * (i - 1))
		else
			graphics.print(text, -LINE_WIDTH / 2, line_height * (i - 1))
		end
	end
end

return CodexSpawnText