local MainScreen = CanvasLayer:extend("MainScreen")
local TopLayer = CanvasLayer:extend("TopLayer")

-- local debug_start = "game"
-- local debug_start = "codex_menu"
-- local debug_start = "options_menu"
-- local debug_start = "main_menu"
local debug_start = "leaderboard_menu"
-- local debug_start = "title_screen"
-- local debug_start = "pre_title_screen"

function MainScreen:new()
    MainScreen.super.new(self)
end

function MainScreen:enter()
    if debug.enabled then
        self["start_" .. debug_start](self)
    else
        self:start_pre_title_screen()
    end

    self:ref("top_layer", self:insert_layer(TopLayer, 1))
    self.top_layer:ref("main_screen", self)
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

function MainScreen:connect_codex_menu(screen)
    signal.connect(screen, "codex_menu_requested", self, "start_codex_menu")
end

function MainScreen:connect_leaderboard_menu(screen)
    signal.connect(screen, "leaderboard_menu_requested", self, "start_leaderboard_menu")
end

function MainScreen:start_game()
	self:defer(function()
		global_state:reset_game_state()
		self:set_current_screen(Screens.GameScreen)
		self:connect_restart(self.current_screen)
		self:connect_quit_to_main_menu(self.current_screen)
		self:connect_leaderboard_menu(self.current_screen)
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

function MainScreen:start_pre_title_screen()
    self:defer(function()
        self:set_current_screen(Screens.PreTitleScreen)
		self:connect_start_title_screen(self.current_screen)
    end)
end

function MainScreen:start_title_screen()
	self:defer(function()
        self:set_current_screen(Screens.TitleScreen)
		signal.connect(self.current_screen, "start_main_menu_requested", self, "start_main_menu", function()
			self:start_main_menu(true)
		end)
	end)
end

function MainScreen:start_main_menu(from_title_screen)
    self:defer(function()
		local screen = Screens.MainMenuScreen()
		screen.started_from_title_screen = from_title_screen
		self:set_current_screen(screen)
		self:connect_start_game(self.current_screen)
        self:connect_options_menu(self.current_screen)
		self:connect_start_title_screen(self.current_screen)
        self:connect_codex_menu(self.current_screen)
        self:connect_leaderboard_menu(self.current_screen)
	end)
end

function MainScreen:start_options_menu()
    self:defer(function()
        self:set_current_screen(Screens.OptionsMenuScreen)
        self:connect_exit_menu(self.current_screen, self.start_main_menu)
    end)
end

function MainScreen:start_codex_menu()
    self:defer(function()
        self:set_current_screen(Screens.CodexScreen)
        self:connect_exit_menu(self.current_screen, self.start_main_menu)
    end)
end

function MainScreen:start_leaderboard_menu()
    self:defer(function()
        self:set_current_screen(Screens.LeaderboardScreen)
        self:connect_exit_menu(self.current_screen, self.start_main_menu)
    end)
end
function MainScreen:set_current_screen(screen)
    if self.current_screen then
        self.current_screen:destroy()
    end
    
    self:ref("current_screen", self:insert_layer(screen, 1))
    modloader:call("on_screen_changed", self.current_screen)
end

function MainScreen:get_mouse_mode()
	local visible, relative, confine = self.current_screen:get_mouse_mode()
	return visible, relative, confine
end

function MainScreen:update(dt)
	local visible, relative, confine = true, false, false
    if self.current_screen and self.current_screen.get_mouse_mode then
        visible, relative, confine = self.current_screen:get_mouse_mode()
    end

    if game_state and game_state.cutscene_no_cursor then
        visible = false
    end

    if game_state and game_state.force_cursor then
        visible = true
    end

    self.drawing_cursor = visible
    self.clear_color = self:get_clear_color()
    -- love.mouse.set_visible(visible)
    love.mouse.set_visible(false)
    -- If it goes from relative to non-relative, center the cursor on the screen

    -- Track previous relative mode
    self._prev_relative = self._prev_relative or false

    if self._prev_relative and not (relative and not usersettings.use_absolute_aim) then
        -- We are switching from relative to non-relative
        local w, h = love.graphics.getDimensions()
        love.mouse.setPosition(w / 2, h / 2)
    end

    
    self.top_layer.show_cursor = (visible)
    self._prev_relative = (relative and not usersettings.use_absolute_aim)

    love.mouse.set_relative_mode(relative and not usersettings.use_absolute_aim)

    if usersettings.confine_mouse == "when_aiming" then
        love.mouse.set_grabbed(confine)
    elseif usersettings.confine_mouse == "always" then
        love.mouse.set_grabbed(true)
    elseif usersettings.confine_mouse == "never" then
        love.mouse.set_grabbed(false)
    end
end

function TopLayer:draw()
    -- if self.drawing_cursor then
    graphics.set_font(fonts.depalettized.image_neutralfont1)

    graphics.set_color(Color.white)

    local mouse_x, mouse_y = input.mouse.pos.x, input.mouse.pos.y
    if self.show_cursor and not (self.main_screen.current_screen.draw_cursor and self.main_screen.current_screen:draw_cursor(mouse_x, mouse_y)) and (input.last_input_device ~= "gamepad" or usersettings.gamepad_plus_mouse) then
        graphics.drawp(textures.ui_cursor, nil, 0, mouse_x, mouse_y)
    end

    local time_warning = time_checker:should_warn()
    local time_leaderboard_warning = not time_checker:is_valid_game_speed_for_leaderboard()
    
    -- if debug.enabled then
        -- time_warning = true
        -- time_leaderboard_warning = true
    -- end
    
    graphics.set_color(Color.orange)
    
    if time_leaderboard_warning then
        graphics.set_color(Color.red)
    end
    
    if time_leaderboard_warning or iflicker(floor(seconds_to_frames(gametime.love_time)), 10, 2) then
        if game_state then
            if game_state.game_over then 
                time_warning = false
            end
            if game_state.stopped_updating then
                time_warning = false
                time_leaderboard_warning = false
            end
        end
        
        if time_warning then
            graphics.print("⏲", self.viewport_size.x - 9, 0, 0, 1, 1)
            if not time_leaderboard_warning then
                graphics.print("‼", self.viewport_size.x - 9, 9, 0, 1, 1)
            end
        end
    end

    graphics.set_color(Color.white)
        
    if usersettings.show_fps then

        local fps = love.timer.getFPS()

        graphics.set_color(Color.darkergrey)

        if fps < 120 then
            graphics.set_color(Color.yellow)
        end

        if fps < 90 then
            graphics.set_color(Color.orange)
        end

        if fps < 60 then
            graphics.set_color(Color.red)
        end

        if usersettings.cap_framerate then
            fps = min(fps, usersettings.fps_cap)
        end

        if self.viewport_size.x <= conf.viewport_size.x + 14 and self.viewport_size.y <= conf.viewport_size.y + 17 then
            graphics.print_outline(Color.black, fps, 9, 0, deg2rad(90), 1, 1)
        else
            graphics.print_outline(Color.black, fps, 1, 1, 0, 1, 1)
        end
    end
end

return MainScreen
