local CodexMenuCycle = require("obj.Menu.PauseScreen.PauseScreenButton"):extend("CodexMenuCycle")

function CodexMenuCycle:new(x, y, text, ...)
	self.selectable = false
    CodexMenuCycle.super.new(self, x, y, text, ...)
    self.current_option = 1
    self.option_x = 0
	self.translate_options = true

end

function CodexMenuCycle:set_options(options)
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


function CodexMenuCycle:draw()
    -- CodexMenuCycle.super.draw(self)
    -- local x, y, w, h = self:get_rect_local()
    local value = self.get_value_func()
	local translated_value = (self.translate_options and tr:has_key(value)) and tr[value] or value
    self:draw_text(tostring(translated_value):upper())
end

function CodexMenuCycle:focused_poll(dt)
    CodexMenuCycle.super.focused_poll(self, dt)
    local input = self:get_input_table()
    -- if input.ui_nav_right_pressed then
    --     self:cycle(1)
    -- elseif input.ui_nav_left_pressed then
    --     self:cycle(-1)
	 if input.ui_confirm_pressed then
		self:cycle(1)
	end
end

function CodexMenuCycle:on_selected()
	CodexMenuCycle.super.on_selected(self)
    self:cycle(1)
end

function CodexMenuCycle:cycle(dir)
	self.current_option = self.current_option + dir
    if self.current_option < 1 then
        self.current_option = self.num_options
	elseif self.current_option > self.num_options then
		self.current_option = 1
	end
	CodexMenuCycle.super.on_selected(self)
	self.set_value_func(self.options[self.current_option])
end

function CodexMenuCycle:quiet_cycle(dir)
	self.current_option = self.current_option + dir
    if self.current_option < 1 then
        self.current_option = self.num_options
	elseif self.current_option > self.num_options then
		self.current_option = 1
	end
	self.set_value_func(self.options[self.current_option])
end

function CodexMenuCycle:on_mouse_pressed(button)
	CodexMenuCycle.super.on_mouse_pressed(self, button)

	if button == "lmb" then
		self:cycle(1)
	elseif button == "rmb" then
		self:cycle(-1)
	end
end

function CodexMenuCycle:update(dt)
	CodexMenuCycle.super.update(self, dt)
end

return CodexMenuCycle
