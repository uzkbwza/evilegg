local OptionsMenuToggle = require("obj.Menu.OptionsMenu.OptionsMenuItem"):extend("OptionsMenuToggle")

function OptionsMenuToggle:new(x, y, text)
    OptionsMenuToggle.super.new(self, x, y, text)
end

function OptionsMenuToggle:on_selected()
	OptionsMenuToggle.super.on_selected(self)
    self.set_value_func()
end

function OptionsMenuToggle:draw()
    OptionsMenuToggle.super.draw(self)
    local x, y, w, h = self:get_rect_local()
    local size = h - 2
    local fill = self.get_value_func()
	local size_offset = 0
    local xoffs = 0
	local yoffs = 0
    if fill then
        size_offset = 1
        xoffs = -1
        yoffs = -1
    end
	local rect_x = x + w - size + xoffs
	local rect_y = y + 1 + yoffs
	local rect_w = size + size_offset
    local rect_h = size + size_offset
    graphics.set_color(Color.black)
    graphics.rectangle(fill and "fill" or "line", rect_x+1, rect_y+1, rect_w, rect_h)
	graphics.set_color(Color.white)
	graphics.rectangle(fill and "fill" or "line", rect_x, rect_y, rect_w, rect_h)
end

return OptionsMenuToggle
