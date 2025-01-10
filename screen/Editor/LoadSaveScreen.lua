local LoadSaveScreen = CanvasLayer:extend("LoadSaveScreen")
local TextInputBox = require "ui.text_input"

function LoadSaveScreen:new()
	LoadSaveScreen.super.new(self)
	self.blocks_render = true
	self.blocks_logic = true
	self.blocks_input = true
	self.text = ""
end

function LoadSaveScreen:enter()
	LoadSaveScreen.super.enter(self)
	self.text = self.below.load_save_text
	self.tile_data_input_box = self:add_object(TextInputBox(0, 16, self.viewport_size.x, self.viewport_size.y))
	self.tile_data_input_box.active = true
	self.tile_data_input_box.single_line = true
end

function LoadSaveScreen:update(dt) 
	local input = self:get_input_table()
	if input.keyboard_held["return"] then
	self.below:process_load_save_screen_text(string.strip_whitespace(self.tile_data_input_box.text))
		self:pop_from_parent()
	end
end

function LoadSaveScreen:draw()
	love.graphics.setColor(1, 1, 1, 1)
    -- love.graphics.rectangle("fill", 0, 0, self.viewport_size.x, self.viewport_size.y)
	if self.text then
		love.graphics.print(self.text, 0, 0)
	end
	graphics.push()
	graphics.translate(0, self.tile_data_input_box.pos.y)
	graphics.set_font(graphics.font["PixelOperator8"])
	self.tile_data_input_box:draw()
	graphics.pop()
end

return LoadSaveScreen
