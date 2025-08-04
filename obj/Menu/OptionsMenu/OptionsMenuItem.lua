local OptionsMenuItem = require("obj.Menu.MenuButton"):extend("OptionsMenuItem")

local WIDTH = 160
local HEIGHT = 10

function OptionsMenuItem:new(x, y, text)
    OptionsMenuItem.super.new(self, x, y, WIDTH, HEIGHT)
    self.font = fonts.depalettized.image_font1
    self.text = text
	-- self.focus_on_hover = false
end

function OptionsMenuItem:on_focused()
    self:play_sfx("ui_menu_button_focused1", 0.6)
end

function OptionsMenuItem:on_selected()
    self:play_sfx("ui_menu_button_selected1", 0.6)
end

function OptionsMenuItem:draw()

    
    
    -- graphics.set_color(self.enabled and Color.white or Color.darkgrey)
    local x, y, w, h = self:get_rect_local()
    -- graphics.set_color(self.focused and Color.darkergrey or Color.black)
    -- graphics.rectangle("fill", 0, 0, WIDTH-HEIGHT, HEIGHT)
    
    



    local end_x = WIDTH - HEIGHT - 1
    local end_y = h
    graphics.set_color(self.focused and Color.green or Color.darkergrey)
    -- graphics.set_color(self.focused and Color.darkergrey or Color.darkgrey)
    -- graphics.line(0, end_y, 0, 0)
    -- graphics.rectangle_centered("fill", x - 3, end_y / 2 + 1, 4, 5)
    if self.focused then
        local line_h = end_y / 2 + 1
        -- graphics.line(0, line_h, -2, line_h)
        -- graphics.line(0, line_h + 2, -2, line_h + 2)
        -- graphics.line(0, line_h - 2, -2, line_h - 2)
        graphics.rectangle_centered("fill", -1, line_h, 3, 3)
        -- graphics.line(end_x, end_y, end_x, 0)
        -- graphics.line(-1, 0, end_x, 0)
        -- graphics.line(-1, end_y, end_x, end_y)
        if not self.is_button then
            graphics.line(self.font:getWidth(self.text) + 2, line_h, end_x, line_h)
        end
    end

    graphics.set_color(Color.white)

	if self.focused then
		graphics.set_color(Color.green)
	end
	graphics.set_font(self.font)
	graphics.print(self.text, 1, 1)

end

return OptionsMenuItem
