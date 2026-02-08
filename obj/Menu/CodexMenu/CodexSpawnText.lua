local CodexSpawnText = GameObject2D:extend("CodexSpawnText")

local LINE_WIDTH = 140

function CodexSpawnText:new(x, y, text, centered, color, delay, uppercase)
    CodexSpawnText.super.new(self, x, y)
    self.font = uppercase and fonts.depalettized.image_font2 or fonts.depalettized.image_neutralfont1
    self.uppercase = uppercase

    -- Support colored segments: text can be a table of {text, color} pairs
    if type(text) == "table" then
        self.segments = {}
        local full_text = ""
        for _, seg in ipairs(text) do
            local seg_text = uppercase and seg[1]:upper() or seg[1]
            table.insert(self.segments, {text = seg_text, color = seg[2]})
            full_text = full_text .. seg_text
        end
        self.text = full_text
    else
        self.text = uppercase and text:upper() or text
    end

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
    elseif self.segments then
        t = self.elapsed / utf8.len(self.text) * 5
        local total_chars = utf8.len(self.text)
        local reveal = math.max(0, math.min(total_chars, floor((t or 0) * total_chars)))
        local draw_x = -LINE_WIDTH / 2
        local chars_consumed = 0
        for _, seg in ipairs(self.segments) do
            local seg_len = utf8.len(seg.text)
            local seg_reveal = math.min(seg_len, math.max(0, reveal - chars_consumed))
            if seg_reveal > 0 then
                local draw_text = seg_reveal >= seg_len and seg.text or utf8.sub(seg.text, 1, seg_reveal)
                graphics.set_color(seg.color)
                graphics.print(draw_text, draw_x, 0)
            end
            draw_x = draw_x + self.font:getWidth(seg.text)
            chars_consumed = chars_consumed + seg_len
            if chars_consumed >= reveal then break end
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
