local LeaderboardMenuA2Button = require("obj.Menu.MenuButton"):extend("LeaderboardMenuA2Button")

local WIDTH = 100
local HEIGHT = 12

function LeaderboardMenuA2Button:new(x, y, width, height, center, color, center_text, outline, right_line)
    if center == nil then
        center = true
    end

	if center then
    	LeaderboardMenuA2Button.super.new(self, x - (width or WIDTH) / 2, y - (height or HEIGHT) / 2, width or WIDTH, height or HEIGHT)
	else
		LeaderboardMenuA2Button.super.new(self, x, y, width or WIDTH, height or HEIGHT)
	end
    local text = "A2"
    self.text = text

    self.font = fonts.depalettized.image_neutralfont1
	-- self.palette = PaletteStack(Color.black, Color.green)

    self.text_width = self.font:getWidth(text)
	self.text_height = self.font:getHeight(text)
	self.color = color
    self.center_text = false
    self.outline = outline
    self.right_line = right_line


end

function LeaderboardMenuA2Button:set_text(text)
	self.text = text
	self.text_width = self.font:getWidth(text)
    self.text_height = self.font:getHeight(text)
end

function LeaderboardMenuA2Button:on_focused()
	self:play_sfx("ui_menu_button_focused1", 0.6)
end

function LeaderboardMenuA2Button:on_selected()
	self:play_sfx("ui_menu_button_selected1", 0.6)
end

function LeaderboardMenuA2Button:draw()
	self:draw_text(self.text)
end

local a_color = {0, 1, 0}
local b_color = {1, 0, 1}

local a2_text = {a_color, "a", b_color, "2"}

function LeaderboardMenuA2Button:draw_text(text)
	local col = self.color or Color.green
	
	
    if not self.focused then
        if self.outline then
            graphics.set_color(col)
            graphics.rectangle("line", 1, 1, self.width - 1, self.height - 1)
        elseif self.right_line then
            graphics.set_color(col)
            graphics.line(self.width, 0, self.width, self.height)
            graphics.line(self.width - 4, self.height, self.width, self.height)
            graphics.line(self.width - 4, 1, self.width, 1)
        end
    end

	graphics.set_color(self.focused and col or Color.transparent)
	graphics.rectangle("fill", 0, 0, self.width, self.height)
    -- graphics.set_color(self.focused and Color.white or Color.black)
    graphics.set_font(self.font)

    graphics.set_color(Color.white)

    graphics.print_outline((self.focused and Color.white or Color.darkergrey), "a2", 1, 0)
    graphics.print_outline((self.focused and Color.white or Color.darkergrey), "a2", 2, 0)
    graphics.print_multicolor(self.font, 2, 0, "a", Color.green, "2", Color.magenta)
    graphics.print_multicolor(self.font, 1, 0, "a", Color.green, "2", Color.magenta)

end

return LeaderboardMenuA2Button
