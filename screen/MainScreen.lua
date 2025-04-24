local MainScreen = CanvasLayer:extend("MainScreen")


local debug_start = "game"

function MainScreen:new()
    MainScreen.super.new(self)
end

function MainScreen:enter()
	if debug.enabled then
		self["start_" .. debug_start](self)
	else
		self:start_title_screen()
	end
end

function MainScreen:connect_restart(screen)
	signal.connect(screen, "restart_requested", self, "start_game")
end

function MainScreen:connect_options_menu(screen)
    signal.connect(screen, "options_menu_requested", self, "start_options_menu")
end

function MainScreen:connect_exit_menu(screen, func)
    signal.connect(screen, "exit_menu_requested", self, "on_exit_menu_requested", function() func(self) end)
end

function MainScreen:connect_quit_to_main_menu(screen)
    signal.connect(screen, "quit_requested", self, "start_main_menu")
end

function MainScreen:connect_start_game(screen)
    signal.connect(screen, "start_game_requested", self, "start_game")
end

function MainScreen:connect_start_main_menu(screen)
    signal.connect(screen, "start_main_menu_requested", self, "start_main_menu")
end

function MainScreen:connect_start_title_screen(screen)
    signal.connect(screen, "start_title_screen_requested", self, "start_title_screen")
end

function MainScreen:start_game()
	self:defer(function()
		global_state:reset_game_state()
		self:set_current_screen(Screens.GameScreen)
		self:connect_restart(self.current_screen)
		self:connect_quit_to_main_menu(self.current_screen)
	end)
end

function MainScreen:get_clear_color()
    if self.current_screen then
        if self.current_screen.get_clear_color then
            return self.current_screen:get_clear_color()
        end
    end
    return Color.transparent
end

function MainScreen:start_title_screen()
	self:defer(function()
        self:set_current_screen(Screens.TitleScreen)
		self:connect_start_main_menu(self.current_screen)
	end)
end

function MainScreen:start_main_menu()
	self:defer(function()
		self:set_current_screen(Screens.MainMenuScreen)
		self:connect_start_game(self.current_screen)
        self:connect_options_menu(self.current_screen)
		self:connect_start_title_screen(self.current_screen)
	end)
end

function MainScreen:start_options_menu()
	self:defer(function()
		self:set_current_screen(Screens.OptionsMenuScreen)
		self:connect_exit_menu(self.current_screen, self.start_main_menu)
	end)
end

function MainScreen:set_current_screen(screen)
	if self.current_screen then
		self.current_screen:destroy()
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
	love.mouse.set_relative_mode(relative and not usersettings.use_absolute_aim)
end

function MainScreen:draw()
end

return MainScreen
