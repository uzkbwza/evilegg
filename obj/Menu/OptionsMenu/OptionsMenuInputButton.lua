local OptionsMenuInputButton = require("obj.Menu.OptionsMenu.OptionsMenuItem"):extend("OptionsMenuInputButton")

function OptionsMenuInputButton:new(x, y, text, input_action)
    OptionsMenuInputButton.super.new(self, x, y, text)
    self.input_action = input_action
    self.is_button = false
    self.option_x = self.width
    self.width = self.width + 120
end

-- function OptionsMenuInputButton:resolve_remapping_table(action, input_type)
--     local mapping = input.mapping[action]
--     if usersettings.input_remapping[action] and usersettings.input_remapping[action][input_type] then
--         if usersettings.input_remapping[action][input_type].skip_input then return nil end
--         return usersettings.input_remapping[action][input_type]
--     end
--     return mapping and mapping[input_type]
-- end

function OptionsMenuInputButton:get_values()
    local mouse_value = nil
    local joystick_value = nil
    local keyboard_value = nil

    mouse_value = input:resolve_remapping_table(self.input_action, "mouse")

    joystick_value = input:resolve_remapping_table(self.input_action, "joystick", false)
    if not joystick_value or table.is_empty(joystick_value) then
        joystick_value = input:resolve_remapping_table(self.input_action, "joystick_axis", false)
        if joystick_value then
            joystick_value = { joystick_value.axis }
        end
    end

    if not joystick_value or joystick_value and joystick_value[1] == nil then
        joystick_value = input.mapping[self.input_action] and input.mapping[self.input_action].joystick
        if not joystick_value or table.is_empty(joystick_value) then
            joystick_value = input.mapping[self.input_action] and input.mapping[self.input_action].joystick_axis
            if joystick_value then
                joystick_value = { joystick_value.axis }
            end
        end
    end

    keyboard_value = input:resolve_remapping_table(self.input_action, "keyboard")

    return mouse_value, joystick_value, keyboard_value
    
end

function OptionsMenuInputButton:process_input_value(value)

    if value[1] == nil then return "" end
    
    local key = value[1]
    if remap_keys[key] then
        key = remap_keys[key]
    end

    if control_glyphs[key] then
        key = control_glyphs[key]
    end

    return key:upper()
end

function OptionsMenuInputButton:draw()
    OptionsMenuInputButton.super.draw(self)
    local x, y, w, h = self:get_rect_local()
    -- x = 0
    -- y = 0
    local mouse_value, joystick_value, keyboard_value = self:get_values()

    graphics.set_color(Color.white)

    if self.focused then
        graphics.set_color(Color.green)
    end
    
    graphics.set_font(self.font)
    
    if mouse_value then
        graphics.print(self:process_input_value(mouse_value), x + self.option_x, y + 1)
    end
    if joystick_value then
        graphics.print(self:process_input_value(joystick_value), x + self.option_x + 25, y + 1)
    end
    if keyboard_value and keyboard_value[1] then
        if type(keyboard_value[1]) == "table" then
            graphics.print(keyboard_value[1][1]:upper(), x + self.option_x + 50, y + 1)
        else
            graphics.print(keyboard_value[1]:upper(), x + self.option_x + 50, y + 1)
        end
    end

end

return OptionsMenuInputButton
