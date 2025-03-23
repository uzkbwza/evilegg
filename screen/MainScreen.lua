local MainScreen = CanvasLayer:extend("MainScreen")

function MainScreen:new()
	MainScreen.super.new(self)
end

function MainScreen:enter()
	self:start_game()
	-- self:start_menu()
	-- self:push(Screens.TestPaletteCyclingScreen)
end

function MainScreen:start_game()
    global_state:reset_game_state()
    self:set_current_screen(Screens.GameScreen)
    signal.connect(self.current_screen, "player_died", self, "start_game")
end

function MainScreen:get_clear_color()
	if self.current_screen then
		if self.current_screen.get_clear_color then
			return self.current_screen:get_clear_color()
		end
	end
	return Color.transparent
end

function MainScreen:start_menu()
	self:set_current_screen(Screens.MainMenuScreen)
end

function MainScreen:set_current_screen(screen)
	if self.current_screen then
		self.current_screen:queue_destroy()
	end
	self:ref("current_screen", self:push(screen))
end

function MainScreen:get_mouse_mode()
	local visible, relative = self.current_screen:get_mouse_mode()
	return visible, relative
end

function MainScreen:update(dt)
	local visible, relative = true, false
	if self.current_screen and self.current_screen.get_mouse_mode then
		visible, relative = self.current_screen:get_mouse_mode()
	end
	love.mouse.set_visible(visible)
	love.mouse.set_relative_mode(relative)
end

function MainScreen:draw()
end

return MainScreen
