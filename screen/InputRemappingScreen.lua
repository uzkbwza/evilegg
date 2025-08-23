local InputRemappingScreen = CanvasLayer:extend("InputRemappingScreen")

function InputRemappingScreen:new(input_name)
    self.blocks_input = true
    self.blocks_logic = true

    InputRemappingScreen.super.new(self)
    self.clear_color = Color.black
    self.input_name = input_name
    self.cancel_time = 0
end

function InputRemappingScreen:on_input_remapped()
	-- self:emit_signal("input_remapped", name)
	self.handling_input = false
    local s = self.sequencer
    self.finished = true
    
    self:play_sfx("ui_menu_button_selected1", 0.6)
	s:start(function()
		s:wait(5)
		self:queue_destroy()
	end)
end


local joystick_buttons = {
    "a",
    "b",
    "x",
    "y",
    "back",
    "leftstick",
    "rightstick",
    "leftshoulder",
    "rightshoulder",
    "dpup",
    "dpdown",
    "dpleft",
    "dpright",
}

local triggers = {
    "triggerleft",
    "triggerright",
}

local mouse = {
    "lmb",
    "rmb",
    "mmb",
}

function InputRemappingScreen:update(dt)
    if self.finished then return end

    if self.tick < 2 then return end

    if input.keyboard_held["escape"] or input:any_joystick_held("start") then
        self.cancel_time = self.cancel_time + dt
    else
        self.cancel_time = 0
    end

    if input.keyboard_released["escape"] or input:any_joystick_released("start") then
        usersettings:remove_remapping(self.input_name, "joystick")
        usersettings:remove_remapping(self.input_name, "mouse")
        usersettings:remove_remapping(self.input_name, "keyboard")
        usersettings:remove_remapping(self.input_name, "joystick_axis")
        self:on_input_remapped()
        return
    end

    if self.cancel_time >= 60 then
        usersettings:add_remapping(self.input_name, "joystick", {})
        usersettings:add_remapping(self.input_name, "mouse", {})
        usersettings:add_remapping(self.input_name, "keyboard", {})
        usersettings:add_remapping(self.input_name, "joystick_axis", {})
        self:on_input_remapped()
        return
    end

    -- joystick buttons
    for _, button in ipairs(joystick_buttons) do
        if input:any_joystick_pressed(button) then
            self:add_remapping(button, "joystick")
            break
        end
    end

    -- triggers
    for _, trigger in ipairs(triggers) do
        for joystick, _ in pairs(input.joysticks) do
            if joystick:getGamepadAxis(trigger) > TRIGGER_DEADZONE then
                self:add_remapping({ axis = trigger, dir = 1, deadzone = TRIGGER_DEADZONE }, "joystick_axis")
                break
            end
        end
    end

    -- mouse
    for _, button in ipairs(mouse) do
        if input.mouse_pressed[button] then
            self:add_remapping(button, "mouse")
            break
        end
    end

    -- keyboard
    for key, _ in pairs(input.keyboard_pressed) do
        if input.keyboard_pressed[key] and key ~= "escape" then
            self:add_remapping(key, "keyboard")
            break
        end
    end

end

function InputRemappingScreen:add_remapping(button, input_type)

    if input.mapping[self.input_name] and input.mapping[self.input_name].allow_inclusive_remap then
        if input.mapping[self.input_name][input_type] then
            local temp = button
            button = table.deepcopy(input.mapping[self.input_name][input_type])
            table.insert(button, 1, temp)
        end
    else
        if input_type == "joystick" then
            usersettings:add_remapping(self.input_name, "joystick_axis", {})
        elseif input_type == "joystick_axis" then
            usersettings:add_remapping(self.input_name, "joystick", {})
        end
    end
    usersettings:add_remapping(self.input_name, input_type, button)
    self:on_input_remapped()
end

function InputRemappingScreen:draw()
    self:center_translate()
    local font = fonts.depalettized.image_font1
    graphics.set_font(font)
    graphics.set_color(Color.white)
    local width = 128
    local glyph = input.last_input_device == "gamepad" and control_glyphs.start or control_glyphs.esc
    graphics.printf(
    string.format(tr.input_remap_prompt, tr["options_input_map_" .. self.input_name], glyph, glyph):upper(), -width,
        -font:getHeight(""), width * 2, "center")
    if self.cancel_time > 20 then
        graphics.set_color(Color.red)
        graphics.printf(tr.input_remap_prompt_clear:upper(), -width, font:getHeight("") * 2, width * 2, "center")
    end
end

return InputRemappingScreen
