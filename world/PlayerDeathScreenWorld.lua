local PlayerDeathScreenWorld = World:extend("PlayerDeathScreenWorld")
local YouDiedLetter = GameObject2D:extend("YouDiedLetter")
local BackgroundObject = GameObject2D:extend("BackgroundObject")
local StatDisplay = GameObject2D:extend("StatDisplay")
local ScoreGraph = GameObject2D:extend("ScoreGraph")
local GamerHealthTimer = require("obj.Menu.GamerHealthTimer")

local O = require("obj")

local YOU_DIED_TEXT = "GAME OVER"
local BEAM_TIME = 10

function PlayerDeathScreenWorld:new()
	PlayerDeathScreenWorld.super.new(self)
    self:add_signal("restart_requested")
	self:add_signal("quit_requested")
	self:add_signal("menu_item_selected")
	self:add_signal("leaderboard_requested")
	self:add_signal("covering_screen")
	self.blocks_render = true
	self.blocks_logic = true
	self.you_died_font = fonts.depalettized.image_bigfont1
	self.draw_sort = self.z_sort
end

function PlayerDeathScreenWorld:enter()
	
	local prev_high_score = savedata:get_category_highs(game_state.leaderboard_category) and savedata:get_category_highs(game_state.leaderboard_category).score or 0
	local prev_high_kills = savedata:get_category_highs(game_state.leaderboard_category) and savedata:get_category_highs(game_state.leaderboard_category).kills or 0
	local prev_high_level = savedata:get_category_highs(game_state.leaderboard_category) and savedata:get_category_highs(game_state.leaderboard_category).level or 0
	local prev_high_rescues = savedata:get_category_highs(game_state.leaderboard_category) and savedata:get_category_highs(game_state.leaderboard_category).rescues or 0
	
    local score_table = game_state:get_run_data_table()
	
	savedata:add_score(score_table)

    -- if debug.enabled then
    --     for i = 1, 100 do
    --         savedata.uid = tostring(i)
    --         local score_table = game_state:get_run_data_table()
    --         score_table.score = i * 100
    --         score_table.level = 1000 - i
    --         leaderboard.submit(score_table, game_state.leaderboard_category, true, function(ok, res) end)
    --     end
    -- end

    savedata.run_upload_queue[GAME_LEADERBOARD_VERSION] = savedata.run_upload_queue[GAME_LEADERBOARD_VERSION] or {}

    local run_upload_queue = savedata.run_upload_queue[GAME_LEADERBOARD_VERSION]

    run_upload_queue[score_table.run_key] = score_table



    leaderboard.submit_queued_runs()
	
    self:ref("menu_root", self:spawn_object(O.Menu.GenericMenuRoot(0, 0)))

	local text_center = self.you_died_font:getWidth(YOU_DIED_TEXT) / 2
	
	
	local global_x_offset = 0
	
	local s = self.sequencer
	
	s:start(function()
		
		s:wait(5)
		for i = 1, #YOU_DIED_TEXT do
			local x = self.you_died_font:getWidth(i > 1 and YOU_DIED_TEXT:sub(1, i - 1) or 0)
			x = x - text_center


			local char = YOU_DIED_TEXT:sub(i, i)

			if char == " " then goto continue end

			local letter = self:spawn_object(YouDiedLetter(x + global_x_offset, 0, char))
			letter.char_offset = i
			-- self:start_timer("start_music", BEAM_TIME, function() audio.play_music("music_death_song") end)
			s:wait(6)

			::continue::
		end

		s:wait(10)

		self:play_sfx("ui_death_background_grow2", 1.0)
		for _, object in self:get_objects_with_tag("game_over_letter"):ipairs() do
			s:start(function()
				-- s:wait(rng:randi(1, 30))
				s:tween(function(t) object:move_to(object.pos.x, t * -100) end, 0, 1, 30, "linear")
			end)
		end


		s:start(function()
			s:wait(20)
			self:ref("background_object", self:spawn_object(BackgroundObject(0, 0)))
			signal.chain_connect("covering_screen", self.background_object, self)
		end)

		s:wait(30)

		self:add_buttons()

		s:wait(5)

		local start_y = -55

		local start_x = 12

		self:ref("score_display", self:spawn_object(StatDisplay(start_x, start_y, tr.game_over_score_display, game_state.score, prev_high_score)))
		
		while not self.score_display.finished_yet do
			s:wait(1)
		end

		self:ref("rescue_display", self:spawn_object(StatDisplay(start_x, start_y + 21, tr.game_over_rescue_display, game_state.rescues_saved, prev_high_rescues)))

		while not self.rescue_display.finished_yet do
			s:wait(1)
		end

		self:ref("kill_display", self:spawn_object(StatDisplay(start_x, start_y + 43, tr.game_over_kill_display, game_state.enemies_killed, prev_high_kills)))
		
		while not self.kill_display.finished_yet do
			s:wait(1)
		end

		self:ref("level_display", self:spawn_object(StatDisplay(start_x, start_y + 65, tr.game_over_level_display, game_state.level, prev_high_level)))
		
		while not self.level_display.finished_yet do
			s:wait(1)
		end

		self:ref("time_display", self:spawn_object(StatDisplay(start_x, start_y + 87, tr.game_over_time_display, frames_to_seconds(game_state.game_time))))
		self.time_display.format_function = format_hhmmss
	end)
end

function PlayerDeathScreenWorld:add_buttons()
    savedata:on_death()

	local retry = self:spawn_object(O.PauseScreen.PauseScreenButton(-60, 90, tr.death_screen_retry_button, 50, 14, true, Color.white, true))
    self.menu_root:add_child(retry)

    retry:add_update_function(function(self, dt)
        self:set_enabled(not (usersettings.retry_cooldown and savedata:get_seconds_until_retry_cooldown_is_over() > 0))
        if not self.enabled and not self.gamer_health_timer then
            self:ref("gamer_health_timer", self:spawn_object(GamerHealthTimer(self.pos.x, self.pos.y, self.width, self.height)))
        end
    end)

	local leaderboard = self:spawn_object(O.PauseScreen.PauseScreenButton(0, 90, tr.death_screen_leaderboard_button, 50, 14, true, Color.white, true))
	self.menu_root:add_child(leaderboard)

    local quit = self:spawn_object(O.PauseScreen.PauseScreenButton(60, 90, tr.death_screen_quit_button, 50, 14, true, Color.white, true))
    self.menu_root:add_child(quit)

    quit:add_neighbor(leaderboard, "left")
	quit:add_neighbor(retry, "right")
    retry:add_neighbor(leaderboard, "right")
    retry:add_neighbor(quit, "left")
    leaderboard:add_neighbor(retry, "left")
    leaderboard:add_neighbor(quit, "right")

	signal.connect(leaderboard, "selected", self, "on_leaderboard_selected", function() self:on_button_pressed("leaderboard_requested") end)

    signal.connect(retry, "selected", self, "on_retry_selected",
        function() self:on_button_pressed("restart_requested") end)
    signal.connect(quit, "selected", self, "on_quit_selected", function() self:on_button_pressed("quit_requested") end)

    retry:focus()
end

function PlayerDeathScreenWorld:on_button_pressed(signal_name)
	self:emit_signal("menu_item_selected")

    local s = self.sequencer
    s:start(function()
		s:wait(1)
		self:emit_signal(signal_name)
	end)
end

function YouDiedLetter:new(x, y, char, y_offset, x_offset)
	YouDiedLetter.super.new(self, x, y)
	self.char = char
	self:add_time_stuff()
	self.beam_in_t = 0
	self.beaming_in = false
	self.drawing_letter = false
	self.beam_dir = rng:rand_sign()
end
 
function YouDiedLetter:enter()
	local s = self.sequencer

	
	self:add_tag("game_over_letter")

	s:start(function()
		self:play_sfx("ui_game_over_letter_beam")
		-- s:wait(rng:randi(1, 30))
		
		-- s:start(function()
		self.beaming_in = true
		s:tween_property(self, "beam_in_t", 0, 0.9, BEAM_TIME, "linear")
		self:stop_sfx("ui_game_over_letter_beam")
		self.beam_in_t = 1
		s:wait(1)
		self:play_sfx("ui_game_over_letter_land", 0.85)
		self.beaming_in = false
		s:wait(2)
		self.drawing_letter = true
		-- end)
		-- s:start(function()
			-- s:wait(8)
			-- self.drawing_letter = true
		-- end)
	end)
end

function YouDiedLetter:draw()
	local font = fonts.depalettized.image_bigfont1

	if self.beaming_in then
		local bt = self.beam_in_t
		-- local t1 = ease("inOutCubic")(bt)
		local t2 = ease("linear")(bt)
		-- local t1 = clamp01(bt - 0.1)
		-- local t2 = clamp01(bt + 0.1)
		-- local dist = 1000
		local width = font:getWidth(self.char)
		-- local scale = remap01(ease("inExpo")(bt), 0.5, 1.0)
		-- local scale = bt >= 0.9 and 1.0 or 0.25
		-- local rw = bt >= 0.9 and width or 0
		local rw = width
		local height = font:getHeight(self.char)
		-- local top = lerp(-dist, 0, t1)
		-- local bottom = lerp(-dist, height, t2)
		local top = 10 * (1 - t2)
		local bottom = height - 10 * (1 - t2)
		local rh = bottom - top
		graphics.set_color(bt < 0.9 and Palette.cmyk:tick_color(self.tick, 0, 2) or Color.white)
		graphics.rectangle(bt < 0.9 and "line" or "fill", width / 2 - (rw) / 2, top, rw, rh)
		
		-- top = lerp(dist - height, 0, t2)
		-- bottom = lerp(dist, height, t1)
		-- graphics.rectangle("fill", width / 2 - (rw) / 2, top, rw, rh)
	end

	if self.drawing_letter then
		graphics.set_font(font)
		graphics.set_color(iflicker(self.world.tick + self.char_offset, 8, 4) and Color.purple or Color.magenta)
		graphics.print(self.char, 0, 0)
	end
end

function BackgroundObject:new(x, y)
	BackgroundObject.super.new(self, x, y)
	self:add_time_stuff()
	self.height = 0
	self.width = 0
	self.z_index = -1000
	self:add_signal("covering_screen")
end

function BackgroundObject:enter()
	local s = self.sequencer
	s:start(function()
		s:start(function()
			s:wait(2)
			self:play_sfx("ui_death_background_grow1", 0.7)
		end)
		s:tween_property(self, "height", 0, conf.room_size.y + 1, 5)
		self:play_sfx("ui_game_over_letter_moveup", 0.7)
		s:tween_property(self, "width", 0, conf.room_size.x + 1, 10)
		self:emit_signal("covering_screen")
		game_state.game_over_screen_force_hud = true
	end)
end

function BackgroundObject:draw()
	local border_color = Palette.game_over_border:tick_color(self.tick, 0, 1)

	if self.width == 0 then
		graphics.set_color(border_color)
		graphics.line(0, -self.height / 2 - 2, 0, self.height / 2 - 2)
	else
		graphics.set_color(Color.black)
		graphics.rectangle_centered("fill", 0, -2, self.width, self.height)
		graphics.set_color(border_color)
		graphics.rectangle_centered("line", 0, -2, self.width, self.height)
	end
end

function StatDisplay:new(x, y, label, value, prev_high_value)
	StatDisplay.super.new(self, x, y)
	self:add_time_stuff()
	self:add_signal("finished")
	self.label = label
	self.value = value
	self.prev_high_value = prev_high_value
	self.print_value = 0
	self._print_value = 0
	self.finished_yet = false
end

function StatDisplay:enter()
	self:play_sfx("ui_game_over_stat_display_tick")
	local s = self.sequencer
	s:start(function()
		s:tween(function(t)
			self._print_value = (round(self.value * t))
		end, 0, 1, 20, "linear")
		self.finished_yet = true
		-- self:play_sfx("ui_game_over_stat_display_tick")
	end)
end

 
function StatDisplay:update(dt)
	if self.is_new_tick and self.tick % 2 == 0 then
		local old_print_value = self.print_value
		self.print_value = self._print_value
		if old_print_value ~= self.print_value then
			if self.prev_high_value and self.print_value > self.prev_high_value and old_print_value <= self.prev_high_value then
				-- self:start_timer("high_score_flash", 10)
				self.high_score = true
			end
			self:play_sfx("ui_game_over_stat_display_tick")
		end
	end
end

function StatDisplay:format_value(value)
	return self.format_function and self.format_function(value) or (tostring(type(value) == "number" and comma_sep(value) or value))
end

function StatDisplay:draw()
	local font = fonts.depalettized.image_font2
	graphics.set_font(font)
	graphics.translate(font:getWidth(" "), 0)
	graphics.set_color(Color.green)
	graphics.print_right_aligned(self.label:upper() .. ": ", font, 0, 0)

	local value_color = Color.white
	-- if self:is_timer_running("high_score_flash") then
	if self.high_score then
		value_color = Palette.high_score_stat_display:tick_color(self.tick, 0, 3)
	end

	graphics.set_color(value_color)
	graphics.print(self:format_value(self.print_value), font, 0, 0)

	if self.prev_high_value then
		graphics.set_color(Color.darkgrey)
		graphics.print_right_aligned(tr.stat_display_prev_high:upper() .. ": ", font, 0, 11)
		graphics.print(self:format_value(max(self.prev_high_value, self.print_value)), font, 0, 11)
	end
end

function ScoreGraph:new(x, y, width, height, values)
	ScoreGraph.super.new(self, x, y)
	self:add_time_stuff()
	self.values = values
	self.z_index = -1
	self.max_value = 0
	for i = 2, #self.values do
		self.max_value = max(self.max_value, self.values[i] - self.values[i - 1])
	end
	self.start_index = 1
	self.interp_t = 0.0
	self.width = width
	self.height = height

end

function ScoreGraph:draw()

	-- graphics.set_color(Color.white)

	graphics.translate(-self.width / 2, -self.height / 2)
	-- graphics.line(0, 0, 0, self.height + 1)
	-- graphics.line(0, self.height + 1, self.width, self.height + 1)
	graphics.set_color(iflicker(self.tick, 1, 2) and Color.darkblue or Color.darkergrey)

	local len = #self.values

	for i = 1, len - 1 do
		local x_start = (i - 1) * (self.width / (len - 1))
		local x_end = i * (self.width / (len - 1))
		local t = 1
		if i == self.start_index then
			t = self.interp_t
		elseif i >= self.start_index + 1 then
			break
		end
		local y_start = self.height - max((self.values[i + 1] - self.values[i]) * t * self.height / self.max_value, 1)
		local y_end = self.height

		graphics.rectangle("fill", x_start, y_start, x_end - x_start - (idiv(self.width, len) > 2 and 1 or 0), y_end - y_start)
	end

end




return PlayerDeathScreenWorld

