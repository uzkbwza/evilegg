local PreTitleScreen = CanvasLayer:extend("PreTitleScreen")
local PhotosensitivityWarningScreen = CanvasLayer:extend("PhotosensitivityWarningScreen")
local ScoreResetWarningScreen = CanvasLayer:extend("ScoreResetWarningScreen")

function PreTitleScreen:enter()
    self.clear_color = Color.black
	self:add_signal("start_title_screen_requested")
    self.screens = {
		PhotosensitivityWarningScreen,
    }

    if savedata.was_old_leaderboard_version then
		table.insert(self.screens, ScoreResetWarningScreen)
	end

    self:start_sub_screen(self:get_next_screen()())
end

function PreTitleScreen:get_next_screen()
    return table.pop_front(self.screens)
end

function PreTitleScreen:start_sub_screen(screen)
	if self.current_sub_screen then
		self.current_sub_screen:queue_destroy()
	end
    self:push(screen)
	self:ref("current_sub_screen", screen)
end

function PreTitleScreen:update(dt)
    local input = self:get_input_table()
    
	if not (self.current_sub_screen and self.current_sub_screen.cant_progress) then
		if input.ui_title_screen_start_pressed or not self.current_sub_screen then
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
end

function PhotosensitivityWarningScreen:update(dt)
    if self.is_new_tick and self.tick >= 360 then
		self:queue_destroy()
	end
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
	self:start_destroy_timer(1200)
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



function ScoreResetWarningScreen:update(dt)
	
end


return PreTitleScreen
