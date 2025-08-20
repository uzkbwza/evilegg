local OptionsMenuCycle = require("obj.Menu.OptionsMenu.OptionsMenuButton"):extend("OptionsMenuCycle")

function OptionsMenuCycle:new(x, y, text)
	self.selectable = false
    OptionsMenuCycle.super.new(self, x, y, text)
    self.current_option = 1
    self.option_x = self.width - self.height
    self.width = self.width + 50
    self.is_button = false
end

function OptionsMenuCycle:set_options(options)
    self.options = options
    self.num_options = #options
	local current_value = self.get_value_func()
	for i, option in ipairs(options) do
		if option == current_value then
			self.current_option = i
			break
		end
	end
end

function OptionsMenuCycle:draw()
    OptionsMenuCycle.super.draw(self)
    local x, y, w, h = self:get_rect_local()
	local value = self.print_func and self.print_func(self.get_value_func()) or self.get_value_func()
	local translated_value = (self.translate_options and tr:has_key(value)) and tr[value] or value
    graphics.print(tostring(translated_value):upper(), x + self.option_x, y + 1)
end

function OptionsMenuCycle:focused_poll(dt)
    OptionsMenuCycle.super.focused_poll(self, dt)
    local input = self:get_input_table()
    if input.ui_nav_right_pressed then
        self:cycle(1)
    elseif input.ui_nav_left_pressed then
        self:cycle(-1)
	elseif input.ui_confirm_pressed then
		self:cycle(1)
	end
end

function OptionsMenuCycle:on_selected()
	OptionsMenuCycle.super.on_selected(self)
    self:cycle(1)
end

function OptionsMenuCycle:cycle(dir)
	self.current_option = self.current_option + dir
    if self.current_option < 1 then
        self.current_option = self.num_options
	elseif self.current_option > self.num_options then
		self.current_option = 1
	end
	OptionsMenuCycle.super.on_selected(self)
	self.set_value_func(self.options[self.current_option])
end

function OptionsMenuCycle:on_mouse_pressed(button)
	OptionsMenuCycle.super.on_mouse_pressed(self, button)

	if button == "lmb" then
		self:cycle(1)
	elseif button == "rmb" then
		self:cycle(-1)
	end
end

function OptionsMenuCycle:update(dt)
	OptionsMenuCycle.super.update(self, dt)
end

return OptionsMenuCycle
