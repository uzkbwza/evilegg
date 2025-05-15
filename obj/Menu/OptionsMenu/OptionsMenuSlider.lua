local OptionsMenuSlider = require("obj.Menu.OptionsMenu.OptionsMenuItem"):extend("OptionsMenuSlider")

local SLIDER_WIDTH = 60
local GRABBER_WIDTH = 3
local MOUSE_LENIENCE = 4

function OptionsMenuSlider:new(x, y, text, start, stop, granularity)
	self.selectable = false
    OptionsMenuSlider.super.new(self, x, y, text)
	self.start = start or 0
	self.stop = stop or 1
    self.granularity = granularity or 0.05
	self.mouse_granularity = self.granularity / 100

    self.width = self.width + SLIDER_WIDTH - (self.height - GRABBER_WIDTH / 2)
    self.slider_start = self.width - SLIDER_WIDTH
	self.slider_end = self.width
end

function OptionsMenuSlider:draw()
	OptionsMenuSlider.super.draw(self)
    local x, y, w, h = self:get_rect_local()
	local value = self.buffered_value or self.get_value_func()
	
	local interp = inverse_lerp(self.start, self.stop, value)
    local slider_x = x + self.slider_start + (self.slider_end - self.slider_start) * interp
    local slider_rect_x = x + self.slider_start - GRABBER_WIDTH / 2
	local slider_rect_y = y + h / 4
	local slider_rect_w = self.slider_end - self.slider_start + GRABBER_WIDTH
	local slider_rect_h = h / 2
	local grabber_x = slider_x - GRABBER_WIDTH / 2
	local grabber_y = y
	local grabber_w = GRABBER_WIDTH
	local grabber_h = h
    graphics.set_color(Color.black)
	graphics.rectangle("fill", slider_rect_x + 1, slider_rect_y + 1, slider_rect_w, slider_rect_h)
    graphics.rectangle("fill", grabber_x+1, grabber_y+1, grabber_w, grabber_h)

    graphics.set_color(Color.darkergrey)
    graphics.rectangle("fill", slider_rect_x, slider_rect_y, slider_rect_w, slider_rect_h)
	
	graphics.set_color(Color.white)
    graphics.rectangle("fill", grabber_x, grabber_y, grabber_w, grabber_h)
	graphics.set_font(self.font)

	local print_value = self.print_func and self.print_func(value) or value
	graphics.print(tostring(print_value):upper(), x + w + 5, y)
end

function OptionsMenuSlider:update(dt)
    if self.dragging_slider then
		local input = self:get_input_table()
		local x, y, w, h = self:get_rect()
		local slider_start_x = x + self.slider_start
		local slider_end_x = x + self.slider_end
		local mouse_pos_x, mouse_pos_y = self:get_mouse_position()
		local mouse_value = remap_clamp(mouse_pos_x, slider_start_x, slider_end_x, self.start, self.stop)
		self.buffered_value = stepify(mouse_value, self.mouse_granularity)
	end
end

function OptionsMenuSlider:focused_poll(dt)
	OptionsMenuSlider.super.focused_poll(self, dt)
    local input = self:get_input_table()
	local new_value = self.get_value_func()
    if input.ui_nav_left_pressed then
        new_value = stepify(clamp(new_value - self.granularity, self.start, self.stop), self.granularity)
		self.set_value_func(new_value)
		self:select()
	end
    if input.ui_nav_right_pressed then
        new_value = stepify(clamp(new_value + self.granularity, self.start, self.stop), self.granularity)
		self.set_value_func(new_value)
		self:select()
    end

end

function OptionsMenuSlider:on_mouse_pressed(button)
	local input = self:get_input_table()
    if button == "lmb" then
        local x, y, w, h = self:get_rect()
		local mouse_pos_x, mouse_pos_y = self:get_mouse_position()
		local slider_start_x = x + self.slider_start
		local slider_end_x = x + self.slider_end
		local mx, my = mouse_pos_x, mouse_pos_y
		if mx > slider_start_x - MOUSE_LENIENCE and mx < slider_end_x + MOUSE_LENIENCE and my > y - MOUSE_LENIENCE and my < y + h + MOUSE_LENIENCE then
			self.dragging_slider = true
		end
	end
end

function OptionsMenuSlider:on_mouse_released(button)
	if button == "lmb" then
        self.dragging_slider = false
		if self.buffered_value then
			self.set_value_func(self.buffered_value)
            self.buffered_value = nil
			self:select()
		end
	end
end

return OptionsMenuSlider
