local LeaderboardWorld = World:extend("LeaderboardWorld")
local O = (require "obj")
local PickupTable = require "obj.pickup_table"


local MENU_ITEM_H_PADDING = 12
local MENU_ITEM_V_PADDING = 6

local MENU_ITEM_SKEW = 0

local PAGE_LENGTH = 10

local RANKING_H_PADDING = 40
local RANKING_V_PADDING = 23
local RANKING_LINE_HEIGHT = 20
local LINE_WIDTH = 220
local LINE_Y = 20


local GreenoidTextPalette = Palette{Color.black, Color.black, Color.darkergreen, Color.darkgreen, Color.darkgreen, Color.green}
local LevelTextPalette = Palette{Color.black, Color.black, Color.darkblue, Color.darkblue, Color.darkblue, Color.white}

function LeaderboardWorld:new()
    LeaderboardWorld.super.new(self)
	self:add_signal("exit_menu_requested")
	self.draw_sort = self.z_sort
	self.waiting = false
	self.death_count = 0
	-- self.current_page = nil
	self.current_page_number = 1
	self.target_death_count = 0

	self.current_category = debug.enabled and leaderboard.default_category

	self.run_t_values = {}
	for i=1, PAGE_LENGTH do
		self.run_t_values[i] = 0
	end

    self.wait_function = function(ok, res)
		if self.is_destroyed then
			return
		end
		self.waiting = false
        if (not ok) or res and res.status == "err" then
            self.error = true
            return
        end
		self.error = false
		self:on_page_fetched(res)
	end

	self.palette_stack = Palette{Color.black, Color.white, Color.darkgrey}


    self.artefact_map = {}
	
	for k, v in pairs(PickupTable.artefacts) do
		self.artefact_map[v.key] = v
	end
end

function LeaderboardWorld:enter()
	self.camera:move(conf.viewport_size.x / 2, conf.viewport_size.y / 2)

	self:ref("menu_root", self:spawn_object(O.Menu.GenericMenuRoot(1, 1, 1, 1)))
	local start_x = 170
	
	self:ref("back_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(MENU_ITEM_H_PADDING, MENU_ITEM_V_PADDING, "⮌",
			10, 10, false, nil, false, false))):focus()


	self:ref("me_button",
		self:add_menu_item(O.PauseScreen.PauseScreenButton(start_x + MENU_ITEM_H_PADDING + 30, 4, tr.leaderboard_me_button,
			25, 15, false, Color.white, true, true)))

	self:ref("top_button",
		self:add_menu_item(O.PauseScreen.PauseScreenButton(start_x + MENU_ITEM_H_PADDING + 57, 4, tr.leaderboard_top_button,
            25, 15, false, Color.white, true, true)))
			
	self.back_button:add_neighbor(self.me_button, "right")
	self.back_button:add_neighbor(self.top_button, "left")
	self.me_button:add_neighbor(self.back_button, "left")
	self.me_button:add_neighbor(self.top_button, "right")
    self.top_button:add_neighbor(self.me_button, "left")
	self.top_button:add_neighbor(self.back_button, "right")


    signal.connect(self.back_button, "selected", self, "exit_menu_requested", function()
		local s = self.sequencer
        s:start(function()
			self.handling_input = false
			s:wait(1)
			self:emit_signal("exit_menu_requested")
		end)
    end)

	signal.connect(self.me_button, "selected", self, "fetch_user", function()
		self:fetch_user(savedata.uid)
	end)

	signal.connect(self.top_button, "selected", self, "fetch_page", function()
		self:fetch_page(1)
	end)

    -- self:ref("previous_page_button",
    --     self:add_menu_item(O.PauseScreen.PauseScreenButton(MENU_ITEM_H_PADDING, MENU_ITEM_V_PADDING + 12, "←",
	-- 		15, 10, false)))
		
    leaderboard.get_deaths(function(ok, res)
		if self.is_destroyed then
			return
		end
		if ok then
			self.death_count = res.deaths or 0
		end
		local high_score_run = savedata:get_high_score_run()
        if high_score_run then
            leaderboard.submit(high_score_run, function(ok, res)
                if not self.is_destroyed then
                    self:fetch_user(savedata.uid)
                end
            end)
        end
		self:death_count_update_loop()
	end)
end

function LeaderboardWorld:death_count_update_loop()
	self:start_timer("death_count_update_loop", rng.randi_range(30, 120), function()
		leaderboard.get_deaths(function(ok, res)
            if ok then
                if self.death_count == 0 then
                    self.death_count = res.deaths or 0
                else
                    self.target_death_count = res.deaths or 0
                end
            end
			if not self.is_destroyed then
				self:death_count_update_loop()
			end
		end)
	end)
end

function LeaderboardWorld:fetch_user(uid)
	self.waiting = true
	self.error = false
    leaderboard.lookup(uid, PAGE_LENGTH, self.current_category, function(ok, res)
		if self.is_destroyed then
			return
		end
		self.waiting = false
		if (not ok) or res and res.status == "err" then
			self:fetch_page(1)
			self.error = true
			return
		end
		self.error = false
		self:on_page_fetched(res)
	end)
end

function LeaderboardWorld:fetch_page(page)
	self.waiting = true
	self.error = false
	leaderboard.fetch(page, PAGE_LENGTH, self.current_category, self.wait_function)
end

function LeaderboardWorld:on_page_fetched(page)
	self.waiting = false
    self.current_page = page
	self.current_category = page.category
    self.current_page_number = page.page
	
	self.run_t_values = {}
	for i=1, PAGE_LENGTH do
        self.run_t_values[i] = 0
	end
    local s = self.sequencer
	
    self.fetch_sequences = self.fetch_sequences or {}
	
	for _, sequence in ipairs(self.fetch_sequences) do
		s:stop(sequence)
	end

	self.fetch_sequences = {}
	self:play_sfx("ui_ranking_tick", 0.35)

	local sequence = s:start(function()
        for i = 1, PAGE_LENGTH do
			local sequence2 = s:start(function()
                s:tween_property(self.run_t_values, i, 0, 1, 9)
				self.run_t_values[i] = 1
            end)
			table.insert(self.fetch_sequences, sequence2)
			if i % 2 == 0 then
				-- self:play_sfx("ui_ranking_tick2", 0.25)
			end
            s:wait(1)

		end
	end)
	table.insert(self.fetch_sequences, sequence)
end

function LeaderboardWorld:on_menu_item_selected(menu_item, func)
	self:emit_signal("menu_item_selected")
	menu_item:focus()
	local s = self.sequencer
    s:start(function()
        for _, item in ipairs(self.menu_items) do
            if item ~= menu_item then
                item:disappear_animation()
            end
        end
		s:wait(2)
		func()
	end)
end

function LeaderboardWorld:update(dt)
	LeaderboardWorld.super.update(self, dt)
    if not self:is_timer_running("death_count") and self.death_count < self.target_death_count then
        self.death_count = self.death_count + 1
        self:start_timer("death_count_flash", 30)
		self:start_timer("death_count", max(1, abs(rng.randfn(15, 5))))
	end
	if input.ui_cancel_pressed then
		self.back_button:select()
	end
end

function LeaderboardWorld:draw()
    local font = fonts.depalettized.image_bigfont1
    local font2 = fonts.depalettized.image_font2
    graphics.set_font(font)
    graphics.print(tr.main_menu_leaderboard_button, font, 28, MENU_ITEM_V_PADDING - 3, 0, 1, 1)
    LeaderboardWorld.super.draw(self)
    graphics.set_font(font2)

    -- local hi_score_text = (tr.leaderboard_hi_score .. ": "):upper()

    -- graphics.push("all")
    -- graphics.translate(0, 0)
    -- graphics.set_color(Color.green)
    -- graphics.print(hi_score_text, font2, 0, 0)

    -- local hi_score_run = savedata:get_high_score_run(self.current_category)

    -- graphics.set_color(Color.white)
    -- graphics.print(comma_sep(hi_score_run and hi_score_run.score or 0), font2, font2:getWidth(hi_score_text), 0)
    -- graphics.pop()

    if self.waiting or self.error or self.current_page == nil then
        graphics.set_color(Color.white)
        graphics.print_centered((self.error and tr.leaderboard_error or tr.leaderboard_loading):upper(), font2,
            conf.viewport_size.x / 2, conf.viewport_size.y / 2)
    else
        graphics.push("all")
        self:draw_leaderboard()
        graphics.pop()
        if self.death_count > 0 then
            local color = Color.white
            if self:is_timer_running("death_count_flash") then
                color = idivmod_eq_zero(self.tick, 5, 2) and Color.red or Color.darkred
            end
            graphics.set_color(color)
            graphics.print_centered(tr.leaderboard_deaths:upper() .. ": " .. comma_sep(self.death_count), font2,
                conf.viewport_size.x / 2, conf.viewport_size.y - font2:getHeight())
        end
    end
end

local function spell_out(text, t, max_length)
	local len = utf8.len(text)
    local t = round(t * max_length)
	if t > len then
		return text
	end
	return utf8.sub(text, 1, t)
end

function LeaderboardWorld:draw_leaderboard()
    local font = fonts.image_font1
	

    graphics.translate(RANKING_H_PADDING, RANKING_V_PADDING)
	local width = conf.viewport_size.x - RANKING_H_PADDING * 2
    local center_x = conf.viewport_size.x / 2 - RANKING_H_PADDING
	
	graphics.push("all")
	local dont_draw_next_top_line = false
    for i = 1, PAGE_LENGTH do
        local t = self.run_t_values[i]
		if t == 0 then
			break
		end
        local run = self.current_page.entries[i]
        if run then
			local is_self = run.uid == savedata.uid
			local line_color = Color.darkergrey
			
			if is_self and self:tick_pulse(5, 1) then
				graphics.set_color(Color.nearblack)
				dont_draw_next_top_line = true
				-- line_color = Color.darkpurple

				local y = LINE_Y - RANKING_LINE_HEIGHT
				graphics.rectangle("fill", center_x - LINE_WIDTH / 2, y, LINE_WIDTH, RANKING_LINE_HEIGHT - 1)

            end
			
			-- local line_color = Palette.rainbow:tick_color(self.tick, i, 13)
            -- local color_mod = 0.5
            -- local r, g, b = line_color.r, line_color.g, line_color.b
            -- r = r * color_mod
            -- g = g * color_mod
            -- b = b * color_mod



            -- graphics.set_color(r, g, b)
            graphics.set_color(line_color)

            -- if idivmod_eq_zero(self.tick, 1, 2) then
			if not (dont_draw_next_top_line and not is_self) then
                graphics.line(center_x - LINE_WIDTH / 2, LINE_Y - RANKING_LINE_HEIGHT, center_x + LINE_WIDTH / 2,
                    LINE_Y - RANKING_LINE_HEIGHT)
			elseif not is_self then
				dont_draw_next_top_line = false
			end
            graphics.line(center_x - LINE_WIDTH / 2, LINE_Y, center_x - LINE_WIDTH / 2, LINE_Y - 6)
            -- if i == PAGE_LENGTH then
			graphics.line(center_x - LINE_WIDTH / 2, LINE_Y, center_x + LINE_WIDTH / 2, LINE_Y)
            -- end
		
						
            -- local ending_image = run.good_ending and textures.ui_leaderboard_good_ending or textures.ui_leaderboard_bad_ending

            graphics.push("all")
			local line_width = 7
            graphics.set_line_width(line_width - 2)
			graphics.set_color(Color.nearblack)
            graphics.line(center_x - LINE_WIDTH / 2, line_width / 2, LINE_WIDTH - 28, line_width / 2)
            graphics.set_line_width(11)
			local end_x = LINE_WIDTH - 41 - (GlobalGameState.max_artefacts - 1) * 13
			graphics.dashline(1 + center_x - LINE_WIDTH / 2, line_width / 2 + 9, end_x, line_width / 2 + 9, 1, 1)
			
            graphics.pop()
			



			
            graphics.set_color(Color.darkergrey)
			graphics.push("all")
			graphics.translate(LINE_WIDTH - 18, RANKING_LINE_HEIGHT / 2)
			graphics.rectangle_centered("line", 0, 0, RANKING_LINE_HEIGHT - 4, RANKING_LINE_HEIGHT - 4)
			graphics.pop()

			graphics.set_color(Color.white)

			
            for j = 1, GlobalGameState.max_artefacts do
				graphics.push("all")
				graphics.translate(LINE_WIDTH - 41 - (j - 1) * 13, RANKING_LINE_HEIGHT - 14)
				
				graphics.draw(textures.hud_artefact_slot1, 0, 0, 0, 1, 1)
				local artefact = self.artefact_map[run.artefacts[j]]
                if artefact and j <= t * GlobalGameState.max_artefacts then
                    graphics.drawp(artefact.icon, nil, 0, 0, 0, 0, 1, 1)
				end
				graphics.pop()
			end


        else
            break
        end 
		graphics.translate(0, RANKING_LINE_HEIGHT)
	end
	graphics.pop()

    for i = 1, PAGE_LENGTH do
		local t = self.run_t_values[i]
		if t == 0 then
			break
		end
		local run = self.current_page.entries[i]
        if run then
			local is_self = run.uid == savedata.uid
			local name = run.name
            local score = run.score


			
            local secondary_weapon = run.secondary_weapon

			local secondary_weapon_sprite = nil

            if secondary_weapon and self.artefact_map[secondary_weapon] then
                local artefact = self.artefact_map[secondary_weapon]
                secondary_weapon_sprite = artefact.sprite or artefact.icon
            end
            if secondary_weapon_sprite then
                graphics.push("all")
                graphics.translate(LINE_WIDTH - 18, RANKING_LINE_HEIGHT / 2)
                -- graphics.points(0, 0)
                graphics.drawp_centered(secondary_weapon_sprite, nil, 0, 0)
                graphics.pop()
            end
		

			local palette_stack = self.palette_stack



            if is_self then
                palette_stack:set_color(3, Color.magenta)
                palette_stack:set_color(2, Color.blue)

			else
                palette_stack:set_color(3, Color.white)
                palette_stack:set_color(2, Color.blue)
            end
            graphics.set_color(Color.white)
			
			local ending_image = run.good_ending and textures.ui_leaderboard_good_ending or textures.ui_leaderboard_bad_ending
			-- local ending_image = run.score > 40000 and textures.ui_leaderboard_good_ending or textures.ui_leaderboard_bad_ending

			graphics.push("all")
			do
            	graphics.translate(-18, -6)
				graphics.draw(ending_image, 0, 0, 0, 1, 1)
			end
			graphics.pop()


			-- graphics.set_color(Color.green)
            graphics.set_font(font)
			graphics.push("all")
            local rank = i + (self.current_page_number - 1) * PAGE_LENGTH
			local is_special = false
            if rank == 1 then
				is_special = true
				palette_stack:set_color(3, Palette.high_score_rank_1:tick_color(self.tick, i, 1))
                palette_stack:set_color(2, Palette.high_score_rank_1_border:tick_color(self.tick, i, 1))
			elseif rank == 2 then
				is_special = true
				palette_stack:set_color(3, Palette.high_score_rank_2:tick_color(self.tick, i, 2.1))
                palette_stack:set_color(2, Palette.high_score_rank_2_border:tick_color(self.tick, i, 1))
			elseif rank == 3 then
				is_special = true
				palette_stack:set_color(3, Palette.high_score_rank_3:tick_color(self.tick, i, 1))
                palette_stack:set_color(2, Palette.high_score_rank_3_border:tick_color(self.tick, i, 2.75))
			end
			graphics.pop()
			
			graphics.printp(spell_out(comma_sep(rank * 1) .. ". " ..name, t, 30), font, palette_stack, 0, -12, 0)
            if not is_special then
                palette_stack:set_color(3, Palette.rainbow:tick_color(self.tick, -i, 2))
                palette_stack:set_color(2, Color.purple)
            end
			
            graphics.push("all")
			graphics.translate(0, 9)

			graphics.printp(spell_out(comma_sep(score), t, 18), font, palette_stack, 0, -6, 0)
            graphics.pop()

			graphics.push("all")
			do
				local greenoid_palette = GreenoidTextPalette
                local greenoid_end_x = floor(center_x - LINE_WIDTH / 2 + LINE_WIDTH - 18)
                graphics.set_font(fonts.greenoid)
				
				-- dbg("width1", fonts.greenoid:getWidth("G" .. tostring(1)))
				-- dbg("width2", fonts.greenoid:getWidth("G" .. tostring(10)))

				local greenoid_text = "G" .. tostring((run.rescues or 0))

                local level_text = "L" .. tostring(run.level or 0)



				local t2 = remap_clamp(t, 0, 0.4, 0, 1)

				graphics.printp_right_aligned(greenoid_text, fonts.greenoid, greenoid_palette, 0, greenoid_end_x, 0)
				graphics.printp_right_aligned(level_text, fonts.greenoid, LevelTextPalette, 0, greenoid_end_x - fonts.greenoid:getWidth(greenoid_text) - 1, 0)
			end
			graphics.pop()

        else
			break
		end
        graphics.translate(0, RANKING_LINE_HEIGHT)
	end
end


function LeaderboardWorld:add_menu_item(item)
    self.menu_root:add_child(self:spawn_object(item))
    return item
end
 

return LeaderboardWorld
