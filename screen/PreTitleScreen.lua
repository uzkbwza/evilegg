local PreTitleScreen = CanvasLayer:extend("PreTitleScreen")
local PhotosensitivityWarningScreen = CanvasLayer:extend("PhotosensitivityWarningScreen")
local ScoreResetWarningScreen = CanvasLayer:extend("ScoreResetWarningScreen")
local PerformanceTestScreen = CanvasLayer:extend("PerformanceWarningScreen")
local ShaderPerformanceWarningScreen = CanvasLayer:extend("ShaderPerformanceWarningScreen")
local PauseScreenButton = require("obj.Menu.PauseScreen.PauseScreenButton")
local MenuRoot = require("obj.Menu.GenericMenuRoot")

PhotosensitivityWarningScreen.kill_time = 360
ScoreResetWarningScreen.kill_time = 360
PerformanceTestScreen.kill_time = 60

function PreTitleScreen:new(x, y)
    PreTitleScreen.super.new(self)
    self.screens = {
		PhotosensitivityWarningScreen,
    }

    if not savedata.done_shader_performance_test or debug.enabled then
        usersettings:set_setting("screen_shader_preset", "shader_preset_soft")
        table.insert(self.screens, 1, PerformanceTestScreen)
    end

    if savedata.was_old_leaderboard_version then
		table.insert(self.screens, ScoreResetWarningScreen)
	end
end

function PreTitleScreen:enter()
    self.clear_color = Color.black
	self:add_signal("start_title_screen_requested")


    self:start_sub_screen(self:get_next_screen()())
end

function PreTitleScreen:get_next_screen()
    if self.current_sub_screen and self.current_sub_screen.get_next_screen then
        local next_screen = self.current_sub_screen:get_next_screen()
        if next_screen then
            return next_screen
        end
    end
    return table.pop_front(self.screens)
end

function PreTitleScreen:start_sub_screen(screen)
	if self.current_sub_screen then
		self.current_sub_screen:queue_destroy()
	end
    self:push(screen)
	self:ref("current_sub_screen", screen)
    if screen.kill_time then
        self:start_timer("kill_timer", screen.kill_time, function()
            screen.cant_progress = false
            screen.ready_to_progress = true
        end)
    end
end

function PreTitleScreen:update(dt)
    local input = self:get_input_table()
    
	if not (self.current_sub_screen and self.current_sub_screen.cant_progress) then
		if input.ui_title_screen_start_pressed or self.current_sub_screen.ready_to_progress then
			if input.ui_title_screen_start_pressed then
				self:play_sfx("ui_menu_button_selected1", 0.6)
			end
			local next_screen = self:get_next_screen()
			if next_screen then
				self:start_sub_screen(next_screen())
			else
				self:emit_signal("start_title_screen_requested")
			end
		end
	end
end

function PhotosensitivityWarningScreen:enter()
    -- self.cant_progress = true
end

function PhotosensitivityWarningScreen:update(dt)
    -- if self.is_new_tick and self.tick >= 360 then
		-- self:queue_destroy()
	-- end
end

function PhotosensitivityWarningScreen:draw()
	if not (self.tick > 2 and self.tick < 340) then return end

    self:center_translate()
	local font = fonts.depalettized.image_font1
	local font2 = fonts.depalettized.image_neutralfont1

	graphics.set_font(font)
    graphics.set_color(Color.red)
    local width = conf.viewport_size.x - 20
    local height = font:getHeight()
	
	graphics.translate(0, -height / 2)

	graphics.print_centered(tr.photosensitivity_warning_title, font, 0, -8)
    graphics.set_color(Color.white)
	graphics.set_font(font2)
	graphics.printf(tr.photosensitivity_warning_text, font2, -width / 2, 8, width, "center")
end

function ScoreResetWarningScreen:enter()
    self.cant_progress = true
    self:start_tick_timer("progress_timer", 120, function()
		self.cant_progress = false
	end)
end

function ScoreResetWarningScreen:draw()

    self:center_translate()
    local font = fonts.depalettized.image_font1
	local font2 = fonts.depalettized.image_neutralfont1
	graphics.set_font(font)
    graphics.set_color(Color.red)
    local width = conf.viewport_size.x - 20
    local height = font:getHeight()
	
	graphics.translate(0, -30)
	
	if (not self.cant_progress) or not iflicker(self.tick + 10, 2, 5) then
		graphics.print_centered(tr.score_reset_warning_title, font, 0, -8)
	end
    graphics.set_color(Color.white)
	graphics.set_font(font2)
	graphics.printf(tr.score_reset_warning_text:format(savedata.old_leaderboard_version), font2, -width / 2, 8, width, "center")
	graphics.printf(tr.score_reset_warning_text2, font2, -width / 2, 40 + height, width, "center")
end

function PerformanceTestScreen:enter()
    self.cant_progress = true
end

function PerformanceTestScreen:draw()
    self:center_translate()
    -- local font = fonts.depalettized.image_font1
    local font2 = fonts.depalettized.image_neutralfont1
    graphics.set_font(font2)
    graphics.set_color(Color.white)
    local width = conf.viewport_size.x - 20
    local height = font2:getHeight()

    graphics.print_centered(tr.performance_test_text, font2, 0, -height / 2)
end

function PerformanceTestScreen:exit()
    savedata:set_save_data("done_shader_performance_test", true)
end

function PerformanceTestScreen:get_next_screen()
    -- if graphics.shader_test_average_time_taken > (debug.enabled and 0.0 or 0.002) then
    if graphics.shader_test_average_time_taken > 0.002 then
        return ShaderPerformanceWarningScreen
    end
end

function ShaderPerformanceWarningScreen:enter()
    self.cant_progress = true
    -- self:start_tick_timer("progress_timer", 120, function()
		-- self.cant_progress = false
    -- end)
    local world = World(0, 0)

    world.enter = function(tab)

        local ok_button = PauseScreenButton(-20, 40, tr.button_yes:upper(), 30, 12, true, Color.green, true)

        local no_button = PauseScreenButton(20, 40, tr.button_no:upper(), 30, 12, true, Color.green, true)

        tab:spawn_object(ok_button)
        tab:spawn_object(no_button)

        local root = MenuRoot()

        tab:spawn_object(root)

        root:add_child(ok_button)
        root:add_child(no_button)

        ok_button:add_neighbor(no_button, "right", true)

        ok_button:focus()

        signal.connect(ok_button, "pressed", self, "ok_button_pressed", function()
            usersettings:set_setting("screen_shader_preset", "shader_preset_none")
            self.cant_progress = false
            self.ready_to_progress = true
        end)

        signal.connect(no_button, "pressed", self, "no_button_pressed", function()
            self.cant_progress = false
            self.ready_to_progress = true
        end)
    end

    self:add_world(world, "world")
end

function ShaderPerformanceWarningScreen:draw()

    self:center_translate()
    local font = fonts.depalettized.image_font1
	local font2 = fonts.depalettized.image_neutralfont1
	graphics.set_font(font)
    graphics.set_color(Color.red)
    local width = conf.viewport_size.x - 20
    local height = font:getHeight()

    graphics.print_centered(tr.shader_performance_warning_title, font, 0, -24)
    graphics.set_color(Color.white)
	graphics.set_font(font2)
	graphics.printf(tr.shader_performance_warning_text, font2, -width / 2, -16, width, "center")
end


function ScoreResetWarningScreen:update(dt)
	
end


return PreTitleScreen
