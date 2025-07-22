local CodexEntryButton = require("obj.Menu.MenuButton"):extend("CodexEntryButton")

local ICON_SIZE = 22

function CodexEntryButton:new(x, y, sprite, spawn, text, width, text_color)
    local height = ICON_SIZE + 1
    if text then
        height = 13
        width = width or 100
        self.text = text
        self.text_color = text_color
    else
        width = ICON_SIZE + 1
    end
    CodexEntryButton.super.new(self, x, y, width, height)
    sprite = graphics.depalettized[sprite] or sprite
    local img_data = graphics.texture_data[sprite]
	if img_data ~= nil then
		-- error(string.format("%s %s", table.length(graphics.texture_paths), graphics.texture_paths[sprite]))
        local width, height = img_data:getDimensions()
        local middle_x, middle_y = floor(width / 2), floor(height / 2)
        local icon_width = min(ICON_SIZE, width)
        local icon_height = min(ICON_SIZE, height)
        local quad = graphics.new_quad(middle_x - icon_width / 2, middle_y - icon_height / 2, icon_width, icon_height, width, height)
        self.icon_quad = graphics.get_quad_table(sprite, quad, icon_width, icon_height)
	end
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
    if self.text then
        graphics.set_color(self.text_color)
        graphics.set_font(fonts.depalettized.image_font2)
        graphics.print(self.text, x + 2, y + 2)
    end
    graphics.set_color(Color.white)
    
    if self.icon_quad then
        graphics.draw_centered(self.icon_quad, floor(self.width / 2), floor(self.height / 2), 0, 1, 1, 0, 0)
    end
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
