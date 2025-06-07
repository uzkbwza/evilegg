local PauseScreen = CanvasLayer:extend("PauseScreen")

function PauseScreen:new()
    PauseScreen.super.new(self)
    self:add_signal("resume_requested")
    self:add_signal("options_menu_requested")
	self:add_signal("quit_requested")
    self:add_signal("codex_menu_requested")
    self:ref("world", self:add_world(Worlds.PauseScreenWorld()))
end

function PauseScreen:update(dt)
    local input = self:get_input_table()
    if input.menu_pressed then
        self:emit_signal("resume_requested")
    end

end

function PauseScreen:draw()
end

function PauseScreen:destroy()
    PauseScreen.super.destroy(self)
end

return PauseScreen