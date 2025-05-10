local CodexEntryButton = require("obj.Menu.MenuButton"):extend("CodexEntryButton")

local ICON_SIZE = 22

function CodexEntryButton:new(x, y, sprite, spawn)
    CodexEntryButton.super.new(self, x, y, ICON_SIZE + 1, ICON_SIZE + 1)
    sprite = graphics.depalettized[sprite]
	local width, height = graphics.texture_data[sprite]:getDimensions()
    local middle_x, middle_y = floor(width / 2), floor(height / 2)
	local icon_width = min(ICON_SIZE, width)
	local icon_height = min(ICON_SIZE, height)
	local quad = graphics.new_quad(middle_x - icon_width / 2, middle_y - icon_height / 2, icon_width, icon_height, width, height)
    self.icon_quad = graphics.get_quad_table(sprite, quad, icon_width, icon_height)
	self.is_codex_entry_button = true
	self.spawn = spawn
end

function CodexEntryButton:draw()
    local x, y, w, h = self:get_rect_local()
	local focused = self.focused or self.mouse_hovered
	graphics.set_color(Color.black)
    graphics.rectangle("fill", x, y, w, h)
	graphics.set_color(focused and Color.green or Color.darkergrey)
	graphics.rectangle("line", x, y, w, h)
	graphics.set_color(Color.white)
    graphics.draw_centered(self.icon_quad, (ICON_SIZE / 2), (ICON_SIZE / 2), 0, 1, 1, 0, 0)
	if savedata:is_new_codex_item(self.spawn.codex_save_name) then
		graphics.set_color(Color.red)
		graphics.set_font(fonts.depalettized.image_font2)
		graphics.print("?", floor(x + w - 5), floor(y - 2) + sin(self.tick * 0.35) * 1, 0, 1, 1)
		graphics.set_color(Color.white)
	end
end

function CodexEntryButton:on_focused()
    self:play_sfx("ui_menu_button_focused1", 0.6)
end


return CodexEntryButton
