local StatsScreen = CanvasLayer:extend("StatsScreen")

function StatsScreen:new()
    self:add_signal("exit_menu_requested")
    self.blocks_input = true

    StatsScreen.super.new(self)
    self.clear_color = Color.black
    self:add_world(Worlds.StatsWorld(), "world")
    signal.connect(self.world, "exit_menu_requested", self, "on_exit_menu_requested")
end

function StatsScreen:on_exit_menu_requested()
    self:emit_signal("exit_menu_requested")
    self.handling_input = false
end

return StatsScreen
