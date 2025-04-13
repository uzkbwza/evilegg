local TextInputBox = GameObject2D:extend("TextInputBox")

local PADDING = 2
local CHARWIDTH = 8
local CHARHEIGHT = 8

local WORD_SEPARATORS = {
	" ",
	"\n",
    "\t",
}

function TextInputBox:new(x, y, w, h)
    TextInputBox.super.new(self, x, y)
    self.w = w
    self.h = h
    self.text = ""
    self.cursor = 1
    self.active = false
	self.single_line = false

    signal.connect(input, "text_input", self, "on_text_input")
    signal.connect(input, "key_pressed", self, "on_key_pressed")

end

function TextInputBox:on_text_input(key)
    if not self.active then
        return
    end
	
	local text = self.text

	
    self.text = text:sub(1, self.cursor) .. key .. text:sub(self.cursor + 1)
	self:move_cursor(1)
end

function TextInputBox:on_key_pressed(key)
    if not self.active then
        return
    end

    local text = self.text

	local ctrl = input.keyboard_held["lctrl"] or input.keyboard_held["rctrl"]

    if key == "up" then

        self:move_cursor_to(self:move_up(self.cursor))
    elseif key == "down" then
        self:move_cursor_to(self:move_down(self.cursor))
    elseif key == "left" then
		if ctrl then
			self:move_cursor_to(self:previous_word(self.cursor))
		else
			self:move_cursor(-1)
		end
    elseif key == "right" then
		if ctrl then
			self:move_cursor_to(self:next_word(self.cursor))
		else
        	self:move_cursor(1)
		end
    elseif key == "backspace" and self.cursor > 0 then
        if ctrl then
            local start = self:previous_word(self.cursor)
            self.text = text:sub(1, start) .. text:sub(self.cursor + 1)
            self:move_cursor_to(start)
			
		else
			self.text = text:sub(1, self.cursor - 1) .. text:sub(self.cursor + 1)
			self:move_cursor(-1)
		end

    elseif key == "return" and not self.single_line then
        self:add_at_cursor("\n")
    end

	dbg("text_cursor", self.cursor)
end

function TextInputBox:move_down(location)
	local x = self:get_x(self.cursor)
	local l = self.cursor
	local new_line = false
    while true do
        l = l + 1
        if self:get_char(l) == "\n" then
            if new_line then break end
            new_line = true
        end
        if new_line and self:get_x(l) == x then
            break
        end
        if self:get_char(l) == "" then
            break
        end
    end
	return l
end

function TextInputBox:move_up(location)
	local x = self:get_x(self.cursor)
	local l = self.cursor
	local new_line = false
	while true do
		l = l - 1
		if self:get_char(l) == "\n" then
			if new_line then break end
			new_line = true
		end
		if new_line and self:get_x(l) == x then
			break
		end
		if self:get_char(l) == "" then
			break
		end
	end
	return l
end


function TextInputBox:next_word(location)
    local l = location
	local encountered_separator = false
    while true do
		l = l + 1
		local char = self:get_char(l)
        if table.list_has(WORD_SEPARATORS, char) then
            encountered_separator = true
        elseif encountered_separator then
            return l - 1
		elseif char == "" then
			return l - 1
		end
	end
end

function TextInputBox:previous_word(location)
	local l = location
	local encountered_separator = false
	while true do
		local char = self:get_char(l)
		if table.list_has(WORD_SEPARATORS, char) then
			encountered_separator = true
		elseif encountered_separator then
			return l
		elseif char == "" then
			return l
		end
		l = l - 1
	end
end

function TextInputBox:move_cursor_to(location)
	self.cursor = clamp(location, 0, #self.text)
end

function TextInputBox:move_cursor(dir)
	self:move_cursor_to(self.cursor + dir)
end

function TextInputBox:on_click(x, y)
	self:move_cursor_to(self:xy_to_location(x, y))
end

function TextInputBox:add_at_cursor(str)
	if self.cursor == 0 then self:move_cursor_to(1) end
	local text = self.text
	self.text = text:sub(1, self.cursor) .. str .. text:sub(self.cursor + 1)
    self.cursor = self.cursor + #str
end

function TextInputBox:get_char(location)
	return self.text:sub(location, location)
end


function TextInputBox:get_x(location)
    local l = location

    while true do
        local char = self:get_char(l)
		l = l - 1
        if l < 0 or char == "\n" then
            return location - l
        end
    end
end

function TextInputBox:get_y(location)
	local y = 1
	local l = location
	while true do
		l = l - 1
		if l <= 0 then
			return y
		end
		if self:get_char(l) == "\n" then
			y = y + 1
		end
	end
end

function TextInputBox:xy_to_location(x, y)
    local cx = max(ceil(((x - self.pos.x) / CHARWIDTH) - PADDING) + 1, 0)
    local cy = max(round(((y - self.pos.y) / CHARHEIGHT) - PADDING) + 2, 1)
	-- print(cx, cy)
	local l = 0
	local x_ = 0
	local y_ = 1
    while true do
		l = l + 1

		if x_ == cx and y_ == cy then
			return l - 1
		end
		if self:get_char(l) == "\n" then
			y_ = y_ + 1
            x_ = 0
		elseif l > 0 and self:get_char(l) == "" then
			return l
		else
			x_ = x_ + 1
		end
	end
end

function TextInputBox:get_line(location)
	-- lol
    local y = 1
    local l = location
    while true do
        l = l - 1
        
		if self:get_char(l) == "\n" then y = y + 1 end
		
        if l <= 0 then
            return y
        end
	end
end

function TextInputBox:draw()
    local text = self.text

	graphics.set_color(Color.black, 0.5)
	graphics.rectangle("fill", 0, 0, self.w, self.h)

    graphics.set_color(Color.white)
	
	local len = #text
    if len == 0 or self.cursor == 0 then
		self:draw_cursor(1, 1)
	end
	
	local y = 1
	local x = 1
    for i = 1, len do
        local c = self:get_char(i)
        graphics.print(c, PADDING + (x - 1) * CHARWIDTH, PADDING + (y - 1) * CHARHEIGHT)

		x = x + 1
        if c == "\n" then
            x = 1
            y = y + 1
        end
	        
        if i == self.cursor then
			self:draw_cursor(x, y)
        end
	end
end

function TextInputBox:draw_cursor(x, y)
    local x_ = PADDING + (x - 1) * CHARWIDTH
	local y_ = PADDING + (y) * CHARHEIGHT
	graphics.line(x_, y_ - CHARHEIGHT, x_, y_)
end

return TextInputBox
