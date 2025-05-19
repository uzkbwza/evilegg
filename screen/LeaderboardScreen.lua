local LeaderboardScreen = CanvasLayer:extend("LeaderboardScreen")

function LeaderboardScreen:new()
    self:add_signal("exit_menu_requested")
	self.blocks_input = true
    self.blocks_logic = true
	
	LeaderboardScreen.super.new(self)
	self.clear_color = Color.black
    self:add_world(Worlds.LeaderboardWorld(), "world")
    signal.connect(self.world, "exit_menu_requested", self, "on_exit_menu_requested")
end

function LeaderboardScreen:enter()
end

function LeaderboardScreen:on_exit_menu_requested()
    self:emit_signal("exit_menu_requested")
    self.handling_input = false
end

function LeaderboardScreen:exit()
end

return LeaderboardScreen
