local LeaderboardMenuCycle = require("obj.Menu.MenuButton"):extend("LeaderboardMenuCycle")

local WIDTH = 100
local HEIGHT = 12

function LeaderboardMenuCycle:new(x, y, text, width, height, center, color, center_text, outline, ...)
    if center == nil then
        center = true
    end

    if center then
        LeaderboardMenuCycle.super.new(self, x - (width or WIDTH) / 2, y - (height or HEIGHT) / 2, width or WIDTH, height or HEIGHT)
    else
        LeaderboardMenuCycle.super.new(self, x, y, width or WIDTH, height or HEIGHT)
    end
    
    self.text = text
    self.selectable = false
    self.current_option = 1
    self.option_x = 0
    self.translate_options = true

    -- Aesthetic parameters from PauseScreenButton
    self.font = fonts.image_font2
    self.palette = PaletteStack(Color.black, Color.black, Color.green)
    self.text_width = self.font:getWidth(text)
    self.text_height = self.font:getHeight(text)
    self.color = color
    self.center_text = center_text
    self.outline = outline
end

function LeaderboardMenuCycle:set_options(options)
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

function LeaderboardMenuCycle:cycle_to_value(value)
    for i, option in ipairs(self.options) do
        if option == value then
            self.current_option = i
            break
        end
    end
end

function LeaderboardMenuCycle:set_text(text)
    self.text = text
    self.text_width = self.font:getWidth(text)
    self.text_height = self.font:getHeight(text)
end

function LeaderboardMenuCycle:on_focused()
    self:play_sfx("ui_menu_button_focused1", 0.6)
end

function LeaderboardMenuCycle:on_selected()
    self:play_sfx("ui_menu_button_selected1", 0.6)
    self:cycle(1)
end

function LeaderboardMenuCycle:draw()
    local value = self.get_value_func()
    local translated_value = (self.translate_options and tr:has_key(value)) and tr[value] or value
    self:draw_text(tostring(translated_value):upper())
end

function LeaderboardMenuCycle:draw_text(text)
    local col = self.color or Color.green
    
    if self.outline and not self.focused then
        graphics.set_color(col)
        graphics.rectangle("line", 1, 1, self.width - 1, self.height - 1)
    end
    
    graphics.set_color(self.focused and col or Color.transparent)
    graphics.rectangle("fill", 0, 0, self.width, self.height)
    
    graphics.set_font(self.font)
    self.palette:set_color(2, self.focused and col or Color.black)
    self.palette:set_color(3, self.focused and Color.black or col)
    
    if self.center_text then
        graphics.printp_centered(text, self.font, self.palette, 0, self.width / 2, self.height / 2)
    else
        graphics.printp(text, self.font, self.palette, 0, 0, 0)
    end
end

function LeaderboardMenuCycle:focused_poll(dt)
    LeaderboardMenuCycle.super.focused_poll(self, dt)
    local input = self:get_input_table()
    if input.ui_confirm_pressed then
        self:cycle(1)
    end
end

function LeaderboardMenuCycle:cycle(dir)
    self.current_option = self.current_option + dir
    if self.current_option < 1 then
        self.current_option = self.num_options
    elseif self.current_option > self.num_options then
        self.current_option = 1
    end
    LeaderboardMenuCycle.super.on_selected(self)
    self.set_value_func(self.options[self.current_option])
end

function LeaderboardMenuCycle:quiet_cycle(dir)
    self.current_option = self.current_option + dir
    if self.current_option < 1 then
        self.current_option = self.num_options
    elseif self.current_option > self.num_options then
        self.current_option = 1
    end
    self.set_value_func(self.options[self.current_option])
end

function LeaderboardMenuCycle:on_mouse_pressed(button)
    LeaderboardMenuCycle.super.on_mouse_pressed(self, button)

    if button == "lmb" then
        self:cycle(1)
    elseif button == "rmb" then
        self:cycle(-1)
    end
end

function LeaderboardMenuCycle:update(dt)
    LeaderboardMenuCycle.super.update(self, dt)
end

return LeaderboardMenuCycle
