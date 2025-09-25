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
local KillsTextPalette = Palette{Color.black, Color.black, Color.red, Color.red, Color.orange, Color.yellow}
local LevelTextPalette = Palette{Color.black, Color.black, Color.darkblue, Color.darkblue, Color.darkblue, Color.white}

local LEADERBOARD_CATEGORIES = {
    "score",
    "depth",
    "speed",
    "score20",
}

function LeaderboardWorld:new()
    LeaderboardWorld.super.new(self)
	self:add_signal("exit_menu_requested")
	self.draw_sort = self.z_sort
	self.waiting = false
	self.death_count = 0
	-- self.current_page = nil
	self.current_page_number = 1
    self.previous_page_number = 1
	self.target_death_count = 0
	self.current_category = leaderboard.cat(self.current_category)

    self.sort_by = savedata.leaderboard_sort or "score"
    self.period = savedata.leaderboard_period or "daily"
    self.wep_filter = savedata.leaderboard_wep_filter or "all"

	self.run_t_values = {}
    for i = 1, PAGE_LENGTH do
        self.run_t_values[i] = 0
    end
    self.run_tables = {}
    for i = 1, PAGE_LENGTH do
        self.run_tables[i] = {
            hatch_particles = batch_remove_list(),
        }
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
    local LEADERBOARD_PERIODS = {
        all_time = tr.leaderboard_period_all_time,
        daily = tr.leaderboard_period_daily,
        monthly = tr.leaderboard_period_monthly,
    }

    local LEADERBOARD_SORT_OPTIONS = {
        score = tr.leaderboard_sort_score,
        depth = tr.leaderboard_sort_depth,
        speed = tr.leaderboard_sort_speed,
        score20 = tr.leaderboard_sort_score20,
    }

    local LEADERBOARD_WEAPON_FILTER = {
        all = "",
        sword = "",
        railgun = "",
        big_laser = "",
        none = "",
    }


    self.camera:move(conf.viewport_size.x / 2, conf.viewport_size.y / 2)

    self:ref("menu_root", self:spawn_object(O.Menu.GenericMenuRoot(1, 1, 1, 1)))
    local start_x = 170

    self:ref("back_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(MENU_ITEM_H_PADDING, MENU_ITEM_V_PADDING, "⮌",
            10, 10, false, nil, false, false))):focus()

    self:ref("period_button",
        self:add_menu_item(O.LeaderboardMenu.LeaderboardMenuCycle(start_x + MENU_ITEM_H_PADDING - 14, 12,
            LEADERBOARD_PERIODS[self.period] and LEADERBOARD_PERIODS[self.period] or "all_time",
            30, 9, false, Color.green, true, false)))

    self:ref("sort_button",
        self:add_menu_item(O.LeaderboardMenu.LeaderboardMenuCycle(start_x + MENU_ITEM_H_PADDING - 54, 12,
            LEADERBOARD_SORT_OPTIONS[self.sort_by] and LEADERBOARD_SORT_OPTIONS[self.sort_by] or "score",
            30, 9, false, Color.green, true, false)))

    self:ref("wep_button",
        self:add_menu_item(O.LeaderboardMenu.LeaderboardMenuCycle(start_x + MENU_ITEM_H_PADDING + 25, 12,
        "",
            26, 9, false, Color.green, true, false)))

    self:ref("me_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(start_x + MENU_ITEM_H_PADDING + 53, 12,
            tr.leaderboard_me_button,
            20, 9, false, Color.green, true, false)))

    self:ref("top_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(start_x + MENU_ITEM_H_PADDING + 53, 3,
            tr.leaderboard_top_button,
            20, 9, false, Color.green, true, false)))


    self.sort_button.get_value_func = function()
        return self.sort_button.text
    end

    self.sort_button:set_options({ "score", "depth", "speed", "score20" })


    self.sort_button.set_value_func = function(value)
        self.sort_button:set_text(LEADERBOARD_SORT_OPTIONS[value])
        self.sort_by = value
        self:fetch_page(1)
    end


    self.period_button.get_value_func = function()
        return self.period_button.text
    end

    self.period_button:set_options({ "all_time", "daily", "monthly" })

    self.period_button.set_value_func = function(value)
        self.period_button:set_text(LEADERBOARD_PERIODS[value])
        self.period = value
        self:fetch_page(1)
    end

    local function set_wep_filter_texture(value)
        if value == "all" then
            self.wep_filter_texture = textures.pickup_allweapons
        elseif value == "big_laser" then
            self.wep_filter_texture = textures.pickup_weapon_big_laser_icon
        elseif value == "railgun" then
            self.wep_filter_texture = textures.pickup_weapon_railgun_icon_leaderboard_filter
        elseif value == "sword" then
            self.wep_filter_texture = textures.pickup_weapon_sword_icon
        elseif value == "none" then
            self.wep_filter_texture = textures.pickup_noweapon
        end
    end

    self.wep_button.set_value_func = function(value)
        self.wep_button:set_text(LEADERBOARD_WEAPON_FILTER[value])
        self.wep_filter = value
        self.wep_filter_texture = nil
        set_wep_filter_texture(value)
        self:fetch_page(1)
    end

    set_wep_filter_texture(self.wep_filter)

    self.wep_button.get_value_func = function()
        return self.wep_button.text
    end

    self.wep_button:set_options({ "all", "sword", "railgun", "big_laser", "none" })


    self.wep_button:cycle_to_value(self.wep_filter)

    self.period_button:cycle_to_value(self.period)
    self.sort_button:cycle_to_value(self.sort_by)

    local page_buttons_y = 22

    local page_buttons_height = 201
    local page_buttons_width = 12


    local start = conf.viewport_size.x / 2 - LINE_WIDTH / 2
    local dist = 6

    self:ref("page_left_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(start - page_buttons_width - dist - 1, page_buttons_y, "←",
            page_buttons_width, page_buttons_height, false, Color.green, true, false)))

    self:ref("page_right_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(start + LINE_WIDTH + dist, page_buttons_y, "→",
            page_buttons_width, page_buttons_height, false, Color.green, true, false)))

    self.page_left_button.z_index = -1
    self.page_right_button.z_index = -1


    self.page_left_button:add_neighbor(self.page_right_button, "right", true)
    self.page_left_button:add_neighbor(self.back_button, "up", true)
    -- self.page_right_button:add_neighbor(self.me_button, "up", true)



    self.me_button:add_neighbor(self.top_button, "up", true)
    self.period_button:add_neighbor(self.page_right_button, "down")
    self.sort_button:add_neighbor(self.page_right_button, "down")
    self.wep_button:add_neighbor(self.page_right_button, "down")
    self.me_button:add_neighbor(self.page_right_button, "down")


    self.back_button:add_neighbor(self.sort_button, "right", true)
    self.sort_button:add_neighbor(self.period_button, "right", true)
    self.period_button:add_neighbor(self.wep_button, "right", true)
    self.wep_button:add_neighbor(self.me_button, "right", true)
    self.wep_button:add_neighbor(self.top_button, "right", true)
    self.top_button:add_neighbor(self.back_button, "right", true)
    self.me_button:add_neighbor(self.back_button, "right")


    signal.connect(self.back_button, "selected", self, "exit_menu_requested", function()
        local s = self.sequencer
        s:start(function()
            self.handling_input = false
            s:wait(1)
            self:emit_signal("exit_menu_requested")
        end)
    end)

    signal.connect(self.me_button, "selected", self, "fetch_user", function()
        self:fetch_user(savedata:get_uid())
    end)

    signal.connect(self.top_button, "selected", self, "fetch_page", function()
        self:fetch_page(1)
    end)

    signal.connect(self.page_left_button, "selected", self, "fetch_page", function()
        self.changing_page_number = true
        self:fetch_page(self.current_page_number - 1)
    end)

    signal.connect(self.page_right_button, "selected", self, "fetch_page", function()
        self.changing_page_number = true
        self:fetch_page(self.current_page_number + 1)
    end)

    signal.connect(self.sort_button, "selected", self, "on_sort_selected", function()
        self.sort_index = self.sort_index + 1
        if self.sort_index > #self.sort_options then
            self.sort_index = 1
        end
    end)
    -- self:ref("previous_page_button",
    --     self:add_menu_item(O.PauseScreen.PauseScreenButton(MENU_ITEM_H_PADDING, MENU_ITEM_V_PADDING + 12, "←",
    --         15, 10, false)))

    leaderboard.get_deaths(function(ok, res)
        if self.is_destroyed then
            return
        end
        if ok then
            self.death_count = res.deaths or 0
        end
        leaderboard.submit_queued_runs(function(ok, res)
            if not self.is_destroyed then
                self:fetch_user(savedata:get_uid())
            end
        end)

        self:death_count_update_loop()
    end)
end

function LeaderboardWorld:exit()
    savedata:set_save_data("leaderboard_period", self.period)
    savedata:set_save_data("leaderboard_sort", self.sort_by)
    savedata:set_save_data("leaderboard_wep_filter", self.wep_filter)
end

function LeaderboardWorld:death_count_update_loop()
	self:start_timer("death_count_update_loop", rng:randi(30, 120), function()
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

	leaderboard.lookup(uid, PAGE_LENGTH, self.current_category, self.wep_filter, self.sort_by, self:get_period(), false, function(ok, res)
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
    if page < 1 then
        page = 1
    end
	self.waiting = true
	self.error = false
	leaderboard.fetch(page, PAGE_LENGTH, self.current_category, self.wep_filter, self.sort_by, self:get_period(), false, self.wait_function)
end

function LeaderboardWorld:get_period()
    if self.period == "all_time" then
        return nil
    end
    return self.period
end

function LeaderboardWorld:sanitize_run(run)
    if type(run) ~= "table" then
        run = {}
    end
    
    if run.artefacts == nil or type(run.artefacts) ~= "table" then
        run.artefacts = {}
    else
        for j = 1, GlobalGameState.max_artefacts do
            if run.artefacts[j] ~= nil and type(run.artefacts[j]) ~= "string" then
                run.artefacts[j] = nil
            end
        end
    end
    
    if type(run.rescues) ~= "number" then
        run.rescues = 0
    end
    
    if type(run.level) ~= "number" then
        run.level = 0
    end
    
    if type(run.kills) ~= "number" then
        run.kills = 0
    end
    
    if type(run.score) ~= "number" then
        run.score = 0
    end
    
    if type(run.game_time) ~= "number" then
        run.game_time = 0
    end
    
    if type(run.name) ~= "string" then
        run.name = "ERROR"
    end
    
    if type(run.uid) ~= "string" then
        run.uid = ""
    end
    
    if type(run.secondary_weapon) ~= "string" and run.secondary_weapon ~= nil then
        run.secondary_weapon = nil
    end
    
    if run.good_ending ~= nil and type(run.good_ending) ~= "number" then
        run.good_ending = nil
    elseif run.good_ending ~= nil then
        if run.good_ending ~= 0 and run.good_ending ~= 1 and run.good_ending ~= 2 then
            run.good_ending = nil
        end
    end
    
    run.rescues = math.max(0, math.min(run.rescues, 999999999))
    run.level = math.max(0, math.min(run.level, 999999999))
    run.kills = math.max(0, math.min(run.kills, 999999999))
    run.score = math.max(0, math.min(run.score, 999999999999999))
    run.game_time = math.max(0, math.min(run.game_time, 999999999))

    return run
end

function LeaderboardWorld:on_page_fetched(page)
    -- Validate page structure
    if type(page) ~= "table" then
        self.error = true
        return
    end
    
    if type(page.entries) ~= "table" then
        page.entries = {}
    end
    
    if #page.entries == 0 and self.changing_page_number then
        self:fetch_page(self.current_page_number)
        return
    end
    
    self.changing_page_number = false

	self.waiting = false
    self.current_page = page
	self.current_category = page.category
    self.current_page_number = page.page
	
	self.run_t_values = {}
	for i=1, PAGE_LENGTH do
        self.run_t_values[i] = 0
	end
    self.run_tables = {}
    for i = 1, PAGE_LENGTH do
        self.run_tables[i] = {
            hatch_particles = nil,
            random_offset = rng:randi()
        }
    end

    for i = 1, PAGE_LENGTH do
        -- local run = self.current_page.entries[i]
        local run = self.current_page.entries[i]
        if run then
            run = self:sanitize_run(run)
            
            for j = 1, GlobalGameState.max_artefacts do
                local artefact_key = run.artefacts and run.artefacts[j]
                local artefact = artefact_key and self.artefact_map[artefact_key]
                if artefact and type(artefact) == "table" and artefact.name == "HatchedTwinArtefact" then
                    self.run_tables[i].hatch_particles = batch_remove_list()
                    break
                end
            end

        end
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
		self:start_timer("death_count", max(1, abs(rng:randfn(15, 5))))
	end
    if input.ui_cancel_pressed then
        self.back_button:select()
    end

    for i = 1, PAGE_LENGTH do
        local run_table = self.run_tables[i]
        if run_table.hatch_particles then
            if self.is_new_tick and rng:percent(20) and self.run_t_values[i] > 0 then
                local particle = {
                    position = Vec2(rng:random_vec2_times(rng:randf(0, 6))),
                    velocity = Vec2(0, -rng:randf(0.05, 0.15)),
                    size = rng:randf(1, 3),
                    color = Color.white,
                    lifetime = rng:randf(20, 90),
                    elapsed = 0,
                }
                particle.position.x = particle.position.x * 0.8
                run_table.hatch_particles:push(particle)
            end
            for _, particle in (run_table.hatch_particles):ipairs() do
                particle.position:add_in_place(particle.velocity.x * dt, particle.velocity.y * dt)
                particle.elapsed = particle.elapsed + dt
                if particle.elapsed > particle.lifetime then
                    run_table.hatch_particles:queue_remove(particle)
                end
            end
            run_table.hatch_particles:apply_removals()
        end
    end
end

function LeaderboardWorld:draw()
    local font = fonts.depalettized.image_bigfont1
    local font2 = fonts.depalettized.image_font2
    graphics.set_font(font)
    graphics.print(tr.main_menu_leaderboard_button, font, 26, MENU_ITEM_V_PADDING - 3, 0, 1, 1)
    graphics.set_font(font2)
    graphics.set_color(Color.white)
    graphics.print(tr.leaderboard_period_button, 170 + MENU_ITEM_H_PADDING - 16, 3)
    graphics.print(tr.leaderboard_sort_button, 170 + MENU_ITEM_H_PADDING - 54, 3)
    LeaderboardWorld.super.draw(self)
    graphics.print(tr.leaderboard_wep_button, 170 + MENU_ITEM_H_PADDING + 28, 3)

    graphics.push"all"

    graphics.set_stencil_mode("draw", 1)

    local start_x = 170

    graphics.rectangle("fill", start_x + MENU_ITEM_H_PADDING + 25, 12, 26, 9)
    graphics.set_stencil_mode("test", 1)

    graphics.draw_centered(self.wep_filter_texture, 170 + MENU_ITEM_H_PADDING + 38, 18)

    graphics.pop()

    -- local hi_score_text = (tr.leaderboard_hi_score .. ": "):upper()

    -- graphics.push("all")
    -- graphics.translate(0, 0)
    -- graphics.set_color(Color.green)
    -- graphics.print(hi_score_text, font2, 0, 0)

    -- local hi_score_run = savedata:get_high_score_run(self.current_category)

    -- graphics.set_color(Color.white)
    -- graphics.print(comma_sep(hi_score_run and hi_score_run.score or 0), font2, font2:getWidth(hi_score_text), 0)
    -- graphics.pop()

    if self.waiting or self.error or self.current_page == nil or type(self.current_page) ~= "table" or type(self.current_page.entries) ~= "table" then
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
                color = iflicker(self.tick, 5, 2) and Color.red or Color.darkred
            end
            graphics.set_color(color)
            graphics.print(tr.leaderboard_deaths:upper() .. ": " .. comma_sep(self.death_count), font2,
            MENU_ITEM_H_PADDING - 1, conf.viewport_size.y - font2:getHeight() - 7)

        end
    end
    graphics.set_color(Color.darkgrey)

    graphics.print_right_aligned(GAME_LEADERBOARD_VERSION, font2,
        conf.viewport_size.x - MENU_ITEM_H_PADDING, conf.viewport_size.y - font2:getHeight() - 7)
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
    local y_tracker = 0
    local me_y = 0
    local me_found = false
	graphics.push("all")
	local dont_draw_next_top_line = false
    for i = 1, PAGE_LENGTH do
        local t = self.run_t_values[i]
        if t == 0 then
            break
        end
        local run_table = self.run_tables[i]
        local run = self.current_page.entries[i]
        if run then

            run = self:sanitize_run(run)
            
            local is_self = run.uid == savedata:get_uid()
            local line_color = Color.darkergrey


            if is_self then
                me_y = y_tracker
                me_found = true
            end

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

            -- if iflicker(self.tick, 1, 2) then
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
            graphics.dashline(1 + center_x - LINE_WIDTH / 2, line_width / 2 + 9, end_x, line_width / 2 + 9, 1, 1, t * 10)

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
                local artefact_key = run.artefacts and run.artefacts[j]
                local artefact = artefact_key and self.artefact_map[artefact_key]
                if artefact and type(artefact) == "table" and artefact ~= "none" and j <= t * GlobalGameState.max_artefacts then
                    local palette, offset = nil, 0
                    if artefact.name == "HatchedTwinArtefact" then
                        -- palette = Palette.rankings_hatched_twin
                        -- palette = nil
                        -- offset = idiv(self.tick, 2)
                        -- offset = 0
                        graphics.set_color(Color.cyan)
                        local size1 = 3 + sin(run_table.random_offset + self.elapsed * 0.05) * 2
                        graphics.rectangle_centered("fill", 7, 7, size1, size1)
                        for _, particle in (run_table.hatch_particles):ipairs() do
                            local size2 = particle.size * (1 - (particle.elapsed / particle.lifetime))
                            graphics.rectangle_centered("fill", particle.position.x + 7, particle.position.y + 5, size2, size2)
                        end
                        graphics.set_color(Color.white)
                        -- graphics.drawp(iflicker(gametime.tick, 20, 2) and textures.pickup_artefact_hatched_twin1 or textures.pickup_artefact_hatched_twin2, palette, offset, 0, 0, 0, 1, 1)
                        graphics.drawp(artefact.icon, palette, offset, 0, 0, 0, 1, 1)
                    else
                        graphics.drawp(artefact.icon, palette, offset, 0, 0, 0, 1, 1)
                    end
                end
                graphics.pop()
            end
        else
            break
        end
        graphics.translate(0, RANKING_LINE_HEIGHT)
        y_tracker = y_tracker + RANKING_LINE_HEIGHT
    end
    
	graphics.pop()

    if me_found then
        graphics.push("all")

        local extra = 1
        local line_width = 1
        graphics.set_line_width(line_width)
        graphics.translate(-10 -extra - 1, me_y - extra)
        graphics.set_color(Palette.leaderboard_me_rect:tick_color(self.tick, 0, 1))
        graphics.dashrect(0, 0, LINE_WIDTH + extra * 2 - (line_width - 1) + 2, RANKING_LINE_HEIGHT + extra * 2 - (line_width - 1), 2, 2, -self.elapsed * 0.08)
        -- graphics.set_color(Color.darkergrey)
        -- graphics.dashrect(1, 1, LINE_WIDTH + extra, RANKING_LINE_HEIGHT - 2, 4, 4, -self.elapsed * 0.06)
        graphics.pop()
    end

    graphics.push()

    graphics.set_color(Color.white)

    for i = 1, PAGE_LENGTH do
        local t = self.run_t_values[i]
        if t == 0 then
            break
        end
        -- local run = {}
        local run = self.current_page.entries[i]
        if run then
            run = self:sanitize_run(run)
            
            local is_self = run.uid == savedata:get_uid()
            local name = run.name or ""
            local score = run.score or 0



            local secondary_weapon = run.secondary_weapon

            local secondary_weapon_sprite = nil

            if secondary_weapon and self.artefact_map[secondary_weapon] then
                local artefact = self.artefact_map[secondary_weapon]
                if artefact and type(artefact) == "table" then
                    secondary_weapon_sprite = artefact.sprite or artefact.icon
                end
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

            local ending_image = textures.ui_leaderboard_bad_ending
            if run.good_ending == 1 then
                ending_image = textures.ui_leaderboard_good_ending
            elseif run.good_ending == 2 then
                ending_image = textures.ui_leaderboard_best_ending
            end

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

            local score_text = ""

            
            if self.sort_by == "speed" then
                score_text = format_hhmmssms(run.game_time or 0)
            else
                score_text = comma_sep(score)
            end

            graphics.printp(spell_out(comma_sep(rank * 1) .. ". " .. name, t, 30), font, palette_stack, 0, -12, 0)
            if not is_special then
                palette_stack:set_color(3, Palette.rainbow:tick_color(self.tick, -i, 2))
                palette_stack:set_color(2, Color.purple)
            end

            graphics.push("all")
            graphics.translate(0, 9)

            graphics.printp(spell_out(score_text, t, 18), font, palette_stack, 0, -6, 0)
            graphics.pop()

            graphics.push("all")
            do
                local greenoid_palette = GreenoidTextPalette
                local kills_palette = KillsTextPalette
                local greenoid_end_x = floor(center_x - LINE_WIDTH / 2 + LINE_WIDTH - 18) - 1
                graphics.set_font(fonts.greenoid)

                -- dbg("width1", fonts.greenoid:getWidth("G" .. tostring(1)))
                -- dbg("width2", fonts.greenoid:getWidth("G" .. tostring(10)))

                local greenoid_text = "G" .. tostring(comma_sep(run.rescues or 0))

                local level_text = "L" .. tostring(comma_sep(run.level or 0))

                local kills_text = "K" .. tostring(comma_sep(run.kills or 0))

                -- local pts_text = tostring(comma_sep(score) or 0) .. "P"

                local t2 = remap_clamp(t, 0, 0.4, 0, 1)

                graphics.push()
                graphics.translate(greenoid_end_x, 0)
                if self.sort_by == "depth" then
                    graphics.printp_right_aligned(kills_text, fonts.greenoid, kills_palette, 0, 0, 0)
                    graphics.translate(-fonts.greenoid:getWidth(kills_text) - 1, 0)
                else
                    graphics.printp_right_aligned(greenoid_text, fonts.greenoid, greenoid_palette, 0, 0, 0)
                    graphics.translate(-fonts.greenoid:getWidth(greenoid_text) - 1, 0)
                end

                graphics.printp_right_aligned(level_text, fonts.greenoid, LevelTextPalette, 0, 0, 0)
                    -- graphics.translate(-fonts.greenoid:getWidth(greenoid_text) - 1, 0)
                    -- graphics.printp_right_aligned(pts_text, fonts.greenoid, LevelTextPalette, 0, 0, 0)
                
                graphics.pop()
            end
            graphics.pop()
        else
            break
        end
        graphics.translate(0, RANKING_LINE_HEIGHT)
        y_tracker = y_tracker + RANKING_LINE_HEIGHT
    end
    graphics.pop()

end


function LeaderboardWorld:add_menu_item(item)
    self.menu_root:add_child(self:spawn_object(item))
    return item
end
 

return LeaderboardWorld
