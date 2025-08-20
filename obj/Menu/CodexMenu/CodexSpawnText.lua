local CodexSpawnText = GameObject2D:extend("CodexSpawnText")

local LINE_WIDTH = 140

function CodexSpawnText:new(x, y, text, centered, color, delay, uppercase)
    CodexSpawnText.super.new(self, x, y)
    self.font = uppercase and fonts.depalettized.image_font2 or fonts.depalettized.image_neutralfont1
    self.text = uppercase and text:upper() or text
    self.uppercase = uppercase
    
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
		self.sequencer:wait(delay * 1 or 0)
		self:show()
		self:start_timer("show_text", 10)
	end)
end

function CodexSpawnText:draw()
	graphics.set_color(self.color)
    graphics.set_font(self.font)
	local line_height = self.font:getHeight(" ")
	local t = 1 - self:timer_progress("show_text")
	if self.centered then
        for i, line in ipairs(self.wrapped_text) do
            local text = utf8.sub(line, 1, t * utf8.len(line))
            if self.uppercase then
                graphics.print_centered(text, self.font, 0, line_height * (i - 1))
            else
                graphics.print_outline_centered(Color.black, text, self.font, 0, line_height * (i - 1))
            end
        end
    else
        t = self.elapsed / utf8.len(self.text) * 5
        if self.uppercase then
            graphics.printf_interpolated(self.text, self.font, -LINE_WIDTH / 2, 0, LINE_WIDTH, "left", t)
        else
            graphics.printf_interpolated_outline(Color.black, self.text, self.font, -LINE_WIDTH / 2, 0, LINE_WIDTH, "left", t)
        end
    end
end

return CodexSpawnText
