local CodexScreen = CanvasLayer:extend("CodexScreen")

function CodexScreen:new()
    self:add_signal("exit_menu_requested")
	self.blocks_input = true
    self.blocks_logic = true
	
	CodexScreen.super.new(self)
	self.clear_color = Color.black
    self:add_world(Worlds.CodexWorld(), "world")
	signal.connect(self.world, "exit_menu_requested", self, "on_exit_menu_requested")
end

function CodexScreen:on_exit_menu_requested()
	self:emit_signal("exit_menu_requested")
	self.handling_input = false
end

return CodexScreen
