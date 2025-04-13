local OptionsMenuScreen = CanvasLayer:extend("OptionsMenuScreen")

function OptionsMenuScreen:new()
	OptionsMenuScreen.super.new(self)
    self:add_signal("exit_menu_requested")
	self.blocks_input = true
    self.blocks_logic = true
	-- self.blocks_render = true
end

function OptionsMenuScreen:enter()
	self.clear_color = self.in_game and Color.transparent or Color.black
    self:ref("options_menu_world", self:add_world(Worlds.OptionsMenuWorld()))
	signal.chain_connect("exit_menu_requested", self.options_menu_world,  self)
end

function OptionsMenuScreen:update(dt)
	-- local input = self:get_input_table()
	-- if self.in_game and input.ui_cancel_pressed then
	-- 	self:emit_signal("exit_menu_requested")
	-- end
end

function OptionsMenuScreen:draw()
end

return OptionsMenuScreen