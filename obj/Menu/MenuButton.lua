local MenuButton = require("obj.Menu.MenuItem"):extend("MenuButton")

function MenuButton:new(x, y, w, h)
    MenuButton.super.new(self, x, y, w, h)
	self:add_signal("pressed")
    self:add_signal("released")
	self:add_signal("selected")

	if self.press_mode == nil then
		self.press_mode = "press" -- | "release"
	end
	
	if self.pressed == nil then
		self.pressed = false
	end

	if self.pressed_by_mouse == nil then
		self.pressed_by_mouse = false
	end

	if self.selectable == nil then
		self.selectable = true
	end
end

function MenuButton:update_shared(dt)
	MenuButton.super.update_shared(self, dt)
    local input = self:get_input_table()

    if self.pressed then
        self:try_release(input)
    else
        self:try_press(input)
    end
end

function MenuButton:try_press(input)
	
	local gamepad_nav_only = self.world.gamepad_nav_only and input.last_input_device ~= "gamepad"
		
	
	if self.focused and ((input.ui_confirm_pressed and not gamepad_nav_only) or self.mouse_held.lmb) then
        self.pressed = true
        
		self.pressed_by_mouse = self.mouse_held.lmb and not input.ui_confirm_pressed
		
		self:emit_signal("pressed")
        self:on_pressed()
		if self.press_mode == "press" and self.selectable then
			self:select()
		end
	end
end

function MenuButton:try_release(input)
    if self.focused and (not input.ui_confirm_held and not self.mouse_held.lmb) then
        self.pressed = false
        self:emit_signal("released")
        self:on_released()
        if self.press_mode == "release" and self.selectable then
			self:select()
        end
    end
end

function MenuButton:select()
	self:defer(function()
	self:on_selected()
	self:emit_signal("selected")
	end)
end

function MenuButton:on_pressed()
end

function MenuButton:on_released()
end

function MenuButton:on_selected()
end

function MenuButton:draw()
	local x, y, w, h = self:get_rect_local()
	
	graphics.set_color(self.pressed and Color.darkergrey or Color.black)
    love.graphics.rectangle("fill", x, y, w, h)
	graphics.set_color(Color.white)
	love.graphics.rectangle("line", x, y, w, h)
end

return MenuButton