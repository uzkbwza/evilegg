local HUDLayer = CanvasLayer:extend("HUDLayer")
local LevelBonus = require("bonus.LevelBonus")
local ALWAYS_SHOW_BONUS_DETAILS = true

function HUDLayer:new()
    HUDLayer.super.new(self)
    self.score_display = game_state.score
    self.after_level_bonus_screen = nil
    self:ref("world", self:add_world(Worlds.HUDWorld(0, 0)))
    signal.connect(game_state, "player_artefact_gained", self, "on_artefact_gained")
    signal.connect(game_state, "player_artefact_removed", self, "on_artefact_removed")
    signal.connect(game_state, "player_heart_gained", self, "on_heart_gained")
    signal.connect(game_state, "player_heart_lost", self, "on_heart_lost")
    signal.connect(game_state, "player_upgraded", self, "on_upgrade_gained")
    signal.connect(game_state, "player_downgraded", self, "on_upgrade_lost")
    signal.connect(game_state, "hatched", self, "show")
	signal.connect(game_state, "greenoid_harmed", self, "on_greenoid_harmed")
    self:create_persistent_ui()
end

function HUDLayer:enter()
    self:hide()
end

function HUDLayer:exit()
	self:stop_all_sfx()
end

function HUDLayer:on_artefact_gained(artefact, slot)
	self.world:on_artefact_gained(artefact, slot)
end

function HUDLayer:on_artefact_removed(artefact, slot)
	self.world:on_artefact_removed(artefact, slot)
end
	
function HUDLayer:on_heart_gained()
	self.world:on_heart_gained()
end

function HUDLayer:on_heart_lost()
	self.world:on_heart_lost()
end

function HUDLayer:on_upgrade_gained(upgrade)
    -- self.world:on_upgrade_gained(upgrade)
	self:start_timer("upgrade_flash_" .. upgrade.upgrade_type, 30)
end

function HUDLayer:on_upgrade_lost(upgrade)
	-- self.world:on_upgrade_lost(upgrade)
	self:start_timer("upgrade_flash_" .. upgrade.upgrade_type, 30)
end

function HUDLayer:on_greenoid_harmed()
	self:start_timer("greenoid_harmed_flash", 30)
end

function HUDLayer:is_paused()
    return self.parent.ui_layer.state == "Paused" or self.game_layer.world.paused
end

function HUDLayer:start_after_level_bonus_screen()
	self.skipping_bonus_screen = false
	if not self.game_layer.world then
		return
	end

	local s = self.sequencer
    self.after_level_bonus_screen = {
        bonuses = {},
        total = {
            score = 0,
            xp = 0,
			score_multiplier = 0,
		},
    }

	local temp_bonuses = {}

    for bonus, count in pairs(game_state.level_bonuses) do
        table.insert(temp_bonuses, {
			bonus = LevelBonus[bonus],
            count = count,
        })
    end

    local codex_items = {
    }
	

    for _, bonus in ipairs(temp_bonuses) do
        if bonus.bonus.text_key then
            table.insert(codex_items, bonus.bonus.text_key)
        end
    end

    savedata:add_items_to_codex(codex_items)

    table.sort(temp_bonuses, function(a, b)
		if a.bonus.priority and not b.bonus.priority then
			return true
		end
        if not a.bonus.priority and b.bonus.priority then
            return false
        end
		
		if a.bonus.priority and b.bonus.priority then
			return a.bonus.priority > b.bonus.priority
		end
		
		if a.bonus.negative and not b.bonus.negative then
			return false
		end
		if not a.bonus.negative and b.bonus.negative then
			return true
		end

		local a_score_multiplier = resolve(a.bonus.score_multiplier) or 0
		local b_score_multiplier = resolve(b.bonus.score_multiplier) or 0

		if a_score_multiplier ~= 0 and b_score_multiplier == 0 then
			return true
		end
		if a_score_multiplier == 0 and b_score_multiplier ~= 0 then
			return false
		end

		
		local a_negative = a.bonus.negative and -1 or 1
		local b_negative = b.bonus.negative and -1 or 1


		if resolve(a.bonus.xp) * a.count * a_negative == resolve(b.bonus.xp) * b.count * b_negative then
			return resolve(a.bonus.score) * a.count * a_negative > resolve(b.bonus.score) * b.count * b_negative
		end
		return resolve(a.bonus.xp) * a.count * a_negative > resolve(b.bonus.xp) * b.count * b_negative
	end)

    self.game_layer.world.waiting_on_bonus_screen = true
	
    local function update_bonus_info(bonus, b, count)
		-- b.score = stepify_floor(resolve(bonus.score), 10)
		
		-- b.score = bonus.ignore_score_multiplier and resolve(bonus.score) or stepify_floor((resolve(bonus.score)) * 20, 10)
		b.score = bonus.ignore_score_multiplier and resolve(bonus.score) or game_state:determine_score(resolve(bonus.score))
		-- b.score = bonus.ignore_score_multiplier and b.score or game_state:determine_score(b.score / 20)
        b.score = stepify_floor(b.score, 10)
        if bonus.negative then
			b.score = -abs(b.score)
		end
		b.xp = resolve(bonus.xp)
        if game_state.final_room_cleared then
            b.xp = 0
        end
        b.score_multiplier = resolve(bonus.score_multiplier)

        if bonus.negative then
            b.score_multiplier = -abs(b.score_multiplier)
        end

		if game_state.final_room_cleared then
			b.score_multiplier = 0
		end
		
		b.negative = bonus.negative
	end

    local function wait_for_bonus(bonus)
        local fast = {
			["bonus_kill"] = 10,
		}
        if fast[bonus.name] then
            return bonus.count % fast[bonus.name] == 0
        end
        if bonus.count > 10 then
			return bonus.count % 5
		end
		return true
	end

    s:start(function()
        local wait = function(time)
            for i = 1, time do

				if not self.skipping_bonus_screen then
                    s:wait(1)
					if not self:should_show_bonus_screen() then
						self.skipping_bonus_screen = true
					end
				end
			end
		end
		
		wait(2)
        for _, bonus_table in pairs(temp_bonuses) do
            local bonus = bonus_table.bonus
            local b = {
                name = bonus.text_key,
                count = 0,
				bonus = bonus,
            }
            
            table.insert(self.after_level_bonus_screen.bonuses, b)
            while b.count < bonus_table.count do

				-- if b.count == 0 then
					-- self:play_sfx("ui_bonus_screen_beep3", 0.5)
				-- else
				self:play_sfx("ui_bonus_screen_beep", 0.5)
				-- end

                b.count = b.count + 1
                update_bonus_info(bonus, b, b.count)

                if wait_for_bonus(b) then
					wait(2)
				end
            end
        end
		 
        wait(30)
		

        local total_score = 0
		local total_possible_negative_score = 0
		
		for i = 1, #self.after_level_bonus_screen.bonuses do
            local b = self.after_level_bonus_screen.bonuses[i]
            for j = 1, b.count do

                -- b.count = b.count - 1

				-- for getting score and xp to add to the game state
				local one_b = {
					name = resolve(b.name),
					count = 1,
					bonus = b.bonus,
                }
				
				update_bonus_info(b.bonus, one_b, 1)
                -- update_bonus_info(b.bonus, b, b.count)
				
				local total = self.after_level_bonus_screen.total
				total.score = total.score + b.score
				if not game_state.final_room_cleared then
					total.xp = total.xp + b.xp
				end
				total.score_multiplier = total.score_multiplier + b.score_multiplier

				total.score = max(total.score, 0)
				-- total.xp = max(total.xp, 0)
                -- total.score_multiplier = max(total.score_multiplier, 0)

				if not game_state.final_room_cleared then
					local xp = one_b.xp
					while xp > 0 do
						local amount = xp
						local x, y = self.game_layer.world:closest_last_player_pos(0, 0)
						self.game_layer.world:spawn_xp(x, y, amount)
						xp = xp - amount
					end
				end

				if one_b.score > 0 then
					total_score = total_score + one_b.score
					total_possible_negative_score = total_possible_negative_score + one_b.score
				end


                local score = one_b.score
				
                if score < 0 then
                    score = max(score, -total_possible_negative_score)
					total_possible_negative_score = total_possible_negative_score - abs(score)
				end


				game_state:add_score(score, one_b.name, true)
                game_state:add_score_multiplier(one_b.score_multiplier)
				game_state:apply_level_bonus_difficulty(one_b.bonus.difficulty_modifier)
				
				if b.score_highlight_coroutine then
					s:stop(b.score_highlight_coroutine)
				end
                b.score_highlight_coroutine = s:start(function()
					b.score_apply_highlight_amount = 1
					s:tween_property(b, "score_apply_highlight_amount", 1, 0, 12, "outCubic")
				end)

                if not self.skipping_bonus_screen then 
                    self:play_sfx("ui_bonus_screen_beep2", 0.75)
                end
                if wait_for_bonus(b) then
                    wait(3)
                end

			end
		end
		
        wait(5)
        
        self.after_level_bonus_screen.start_prompt = true
        
		while not self.skipping_bonus_screen do
			s:wait(1)
		end
		
		for i = #self.after_level_bonus_screen.bonuses, 1, -1 do
			local bonus = self.after_level_bonus_screen.bonuses[i]
			table.remove(self.after_level_bonus_screen.bonuses, i)
            s:wait(2)

            -- if self:should_show() then
			self:play_sfx("ui_bonus_screen_beep", 0.5)
			-- end
			
		end
		
		self.after_level_bonus_screen = nil
		self:play_sfx("ui_bonus_screen_beep", 0.5)
		
		s:wait(2)
				
        if self.game_layer.world then
            self.game_layer.world.waiting_on_bonus_screen = false
        end

	end)
end

function HUDLayer:update(dt)

    local should_show = self:should_show()


    if self.is_new_tick then
        if game_state.score > self.score_display then
            local step = 1
            local difference = game_state.score - self.score_display
            for i = 0, 10 do
                local ten_step = pow(10, i)
                if difference >= ten_step * 2 then
                    step = step + ten_step
                end
            end

            self.score_display = self.score_display + step
            if stepify_floor_safe(self.score_display, step) % (step * 5) == 0 and not game_state.cutscene_hide_hud then
                self:play_sfx("score_add", 0.15)
            end
        end
    end
    if game_state.score < self.score_display then
        self.score_display = game_state.score
    end

    local input = self:get_input_table()
	

    if ((input.skip_bonus_screen_held) or (not self:should_show_bonus_screen())) and self.after_level_bonus_screen then
        self.skipping_bonus_screen = true
    end

    if should_show and self.after_level_bonus_screen then
        self.force_show_hud = true
    elseif not self.after_level_bonus_screen then
        self.force_show_hud = false
    end
    

	if input.show_hud_held then
		self:start_timer("show_hud_held", 40)
	end 

	for i, meter in ipairs(self.xp_bars) do
		if meter.xp < game_state.xp then
			meter.xp = approach(meter.xp, game_state.xp, dt * 30)
		end
	end
    if self.is_new_tick and self.tick % 4 == 0 then
        local first = self.xp_bars[1]
        table.remove(self.xp_bars, 1)
        table.insert(self.xp_bars, first)
    end
	
	self.world.showing = should_show
	self.force_show_time = self:is_timer_running("show_hud_held")
end

local bonus_palette = PaletteStack:new(Color.black, Color.white)

function HUDLayer:should_show_bonus_screen()
    if game_state.force_bonus_screen then return true end
    return self:should_show()
end

function HUDLayer:should_show()

    -- do
        -- return true
    -- end

	if game_state.cutscene_hide_hud then return false end

	
    if self:is_paused() and not self.game_layer.world.options_menu_open then return true end
	if game_state.game_over_screen_force_hud then return true end

    if self:is_timer_running("show_hud_held") then return true end

    if self.force_show_hud then return true end


	return usersettings.show_hud
end

function HUDLayer:can_pause()
	if self.after_level_bonus_screen and self:should_show() then
		return false
	end
	return true
end

-- format_score(n, lead_zeros, show_zeros[, font])
--   n          : integer
--   lead_zeros : total minimum digit‐count (including the number itself)
--   show_zeros : (unused here—both strings are returned; you can ignore it)
--   font       : optional LÖVE Font for pixel‐accurate offset
-- returns: padded_str, unpadded_str, x_offset
local function format_score(n, lead_zeros, font)
    lead_zeros = math.max(lead_zeros or 0, 0)

    local abs_str = tostring(math.abs(n))
    local sign    = n < 0 and "-" or ""

    -- how many zeros to pad so total digits ≥ lead_zeros
    local zero_count = math.max(lead_zeros - #abs_str, 0)
    local pad_str    = string.rep("0", zero_count) .. abs_str

    local padded_str   = sign .. comma_sep(pad_str)
    local unpadded_str = sign .. comma_sep(abs_str)

    -- figure out how much of padded_str we'd have to chop off
    local diff_len  = #padded_str - #unpadded_str
    local hidden_str = padded_str:sub(1, diff_len)

    -- positive offset: move right by this many chars or pixels
    local x_offset = font
        and font:getWidth(hidden_str)
        or diff_len

    return padded_str, unpadded_str, x_offset
end

function HUDLayer:draw_top()
    local x_start = (graphics.main_viewport_size.x - conf.viewport_size.x) / 2
    local y_start = (graphics.main_viewport_size.y - conf.viewport_size.y) / 2 - 2
    local h_padding = conf.room_padding.x - 2
    local v_padding = conf.room_padding.y - 9
    local left = x_start + h_padding
    local top = y_start + v_padding - 1
    local font = fonts.hud_font

    local border_color = self.game_layer.world:get_border_rainbow()
    local charwidth = fonts.hud_font:getWidth("0")

	
    local should_show = self:should_show()


	if not should_show then
		return
	end

	graphics.set_font(font)
	graphics.set_color(Color.white)


	graphics.push()
	graphics.translate(floor(left), top)
	-- graphics.set_color(Color.darkergrey)
	graphics.set_color(Color.grey)
	-- graphics.print("LVL", 0, 0)
	local level_with_zeroes, level_without_zeroes, level_x = format_score(game_state.level % 100, 2, font)
	level_x = level_x
	local zero_start = font:getWidth("LVL")

	graphics.print("LVL", 0, 0)
	graphics.set_color(Color.darkergrey)
	
	graphics.print(level_with_zeroes, zero_start, 0)

	graphics.set_color(Color.white)
	-- graphics.set_color(Palette.rainbow:tick_color(gametime.tick, 0, 10))
	
	graphics.print(level_without_zeroes, level_x + zero_start, 0)
	graphics.set_color(Color.grey)
	graphics.print("WAVE", 32, 0)
	graphics.set_color(Color.white)
	graphics.print(string.format("%01d", game_state.wave), font:getWidth("WAVE") + 32, 0)
	graphics.set_color(Color.darkergrey)
	
	
	graphics.translate(charwidth * 20 + 6, 0)
	graphics.translate(charwidth * 11 + 3, 0)


	local category_high = savedata:get_category_highs(game_state.leaderboard_category)
	local high_score = category_high and category_high.score or 0

	local beat_high = false
	if self.score_display < high_score then
		graphics.set_color(Color.darkgrey)
		local i = 1
		local finished = false
		local tens = 1
		while not finished do
			if idiv(self.score_display, tens) > 0 then
				tens = tens * 10
			else
				finished = true
			end
		end
		high_score = high_score - (high_score % tens) + self.score_display
		local best_score = comma_sep(high_score)
		graphics.set_color(Color.darkergrey)
        graphics.print_right_aligned(best_score, font, 0, 0)
    else
		beat_high = true
	end


	local score_without_zeroes = comma_sep(self.score_display)

	-- graphics.print(score_without_zeroes, score_width, 0)
	-- graphics.print(score_without_zeroes, score_width + 9, 0)

	graphics.set_color(beat_high and Palette.high_score_ingame:tick_color(self.tick, 0, 7) or border_color)
	graphics.print_right_aligned(score_without_zeroes, font, 0, 0)
	graphics.set_color(Color.grey)
	
	local scoremult1 = "×["
	-- local scoremult6 = "["
	local scoremult2 = string.format("%-.2f", game_state:get_score_multiplier(false))
	local scoremult3 = string.format("×%02d", max(1, game_state:get_rescue_chain_multiplier()))
	-- local scoremult3 = string.format("+%02d", game_state:get_rescue_chain_multiplier())
	local scoremult4 = "   "
    local scoremult5 = "]"

	local greenoid_color = Color.green
	if self:is_timer_running("greenoid_harmed_flash") then
		greenoid_color = iflicker(self.tick, 3, 2) and Color.red or Color.green
	end
	graphics.print_multicolor(font, 0, 0, scoremult1, Color.grey, scoremult2, Color.white, scoremult3, greenoid_color,
		scoremult4, Color.white, scoremult5, Color.grey)
	graphics.set_color(Color.white)
	graphics.drawp_centered(textures.ally_rescue1, nil, 0, font:getWidth(scoremult1..scoremult2..scoremult3) + 6, 4)
    graphics.pop()

end

function HUDLayer:pre_world_draw()

	local room_elapsed = self.game_layer.world.room.elapsed
	local world = self.game_layer.world
	local show_time_on_room_clear = world.state == "RoomClear" or world.state == "LevelTransition"
	local show_time_on_room_start = room_elapsed < 60 or room_elapsed < 90 and iflicker(gametime.tick, 3, 2)

    local should_show = self:should_show()

    if should_show and (show_time_on_room_clear or show_time_on_room_start or self:is_paused()) or self.force_show_time or self:is_timer_running("show_hud_held") then
		local font2 = fonts.depalettized.image_font2
		graphics.set_font(font2)
		graphics.set_color(Color.white)
        local text = format_hhmmssms1(game_state.game_time_ms)
        graphics.push("all")
        graphics.translate(self.viewport_size.x / 2, self.viewport_size.y / 2)
		graphics.print(text, conf.room_size.x / 2 - 1 - font2:getWidth(text), 96)
        graphics.pop()
	end


    local game_area_width = conf.viewport_size.x - conf.room_padding.x * 2
    local game_area_height = conf.viewport_size.y - conf.room_padding.y * 2
    local x_start = (graphics.main_viewport_size.x - conf.viewport_size.x) / 2
    local y_start = (graphics.main_viewport_size.y - conf.viewport_size.y) / 2 - 2
    local h_padding = conf.room_padding.x - 2
    local v_padding = conf.room_padding.y - 9
    local left = x_start + h_padding
    local bottom = y_start + v_padding + game_area_height + 11


    local should_show = self:should_show()

	graphics.push()
    graphics.translate(left, bottom)

	graphics.push()
	-- for i = 1, game_state.max_hearts do
	--     graphics.draw(i <= game_state.hearts and textures.pickup_heart_icon2 or textures.pickup_empty_heart_icon,
	--         (i - 1) * 14, -1)
	-- end
	-- for i = 1, game_state.max_artefacts do
	--     local texture = game_state.selected_artefact_slot == i and (textures.hud_artefact_slot2) or
	--     textures.hud_artefact_slot1
	--     graphics.draw(texture, 127 + (i - 1) * 14, -1)
	--     -- if game_state.artefact_slots[i] then
	--         -- graphics.draw(game_state.artefact_slots[i].icon, 127 + (i - 1) * 14, -1)
	--     -- end
	-- end

    if should_show then
        -- local num_xp_bars = #self.xp_bars
        local xp_bar_width = 4
        local bar_x = 259
        local bar_start = 0
        local bar_end = 11
        local bar_y = bar_end
        local bar_height = bar_end - bar_start

        graphics.set_color(Color.darkergrey)
        graphics.rectangle("fill", bar_x, bar_start, xp_bar_width, bar_height)


        -- self.bar_sort = self.bar_sort or function(a, b)
        -- 	local xp_start = game_state[a.start]
        -- 	local xp_end = game_state[a.name]
        -- 	local a_ratio = remap_clamp(a.xp, xp_start, xp_end, 0, 1)
        -- 	local xp_start = game_state[b.start]
        -- 	local xp_end = game_state[b.name]
        -- 	local b_ratio = remap_clamp(b.xp, xp_start, xp_end, 0, 1)
        -- 	return a_ratio > b_ratio
        -- end
        -- table.sort(self.xp_bars, self.bar_sort)

        for i, bar in ipairs(self.xp_bars) do
            local xp_start = game_state[bar.start]
            local xp_end = game_state[bar.name]
            local ratio = max(remap_clamp(bar.xp, xp_start, xp_end, 0, 1), 1 / (bar_end - bar_start))
            -- if i == 2 then
            -- print(xp_start, xp_end, game_state.xp)
            -- end

            graphics.set_color(bar.color)
            graphics.rectangle("fill", bar_x + 1, bar_y, xp_bar_width - 2, -bar_height * ratio)
            -- graphics.set_color(bar.color)
            -- graphics.rectangle("fill", bar_x, bar_y + 1, xp_bar_width, 1)
        end

        -- local num_xp_meters = #self.xp_bars
        -- local circle_center_x = 40
        -- local circle_center_y = 6
        -- local radius = 6

        -- graphics.set_color(Color.darkergrey)
        -- graphics.line(circle_center_x, circle_center_y, circle_center_x, circle_center_y - radius)

        -- graphics.push("all")
        -- for i, meter in ipairs(self.xp_bars) do

        -- 	graphics.set_color(meter.color)
        -- 	graphics.axis_quantized_line(circle_center_x, circle_center_y, circle_center_x + meter.x, circle_center_y + meter.y, 3, 3, false, 1)
        -- 	print(meter.x, meter.y)
        -- 	graphics.rectangle_centered("fill", circle_center_x + meter.x, circle_center_y + meter.y, 3, 3)
        -- end
        -- graphics.pop()

        graphics.push("all")
        local upgrade_base = 224
        local upgrade_height = 12
        local upgrade_width = 6
        local upgrade_separation = 1
        for i, upgrade in ipairs(self.upgrades) do
            local flashing = self:is_timer_running("upgrade_flash_" .. upgrade.name) and iflicker(self.tick, 3, 2)
            local max_level = game_state:get_max_upgrade(upgrade.name)
            if not flashing then
                for j = max_level, 1, -1 do
                    local height = upgrade_height / max_level
                    graphics.set_color(Color.darkergrey)

                    local top_height = max((height - (upgrade_separation)) * .6)
                    local bottom_height = height - top_height - upgrade_separation
                    if j <= game_state.upgrades[upgrade.name] then
                        graphics.set_color(upgrade.color1)
                        graphics.rectangle("fill", upgrade_base + (i - 1) * (upgrade_width + upgrade_separation),
                            (max_level - j) * (height), upgrade_width, top_height)
                        graphics.set_color(upgrade.color2)
                        graphics.rectangle("fill", upgrade_base + (i - 1) * (upgrade_width + upgrade_separation),
                            (max_level - j) * (height) + top_height, upgrade_width, bottom_height)
                    else
                        graphics.rectangle("fill", upgrade_base + (i - 1) * (upgrade_width + upgrade_separation),
                            (max_level - j) * (height), upgrade_width, height - upgrade_separation)
                    end
                end
            end
        end
        graphics.pop()
    end

	-- graphics.print_outline(Color.black, string.format("%dXP", game_state.xp), charwidth * 6, 0)
	graphics.pop()
	-- graphics.print_outline(Color.black, string.format("x%-4.1f", game_state:get_score_multiplier()), charwidth * 16, 0)
	graphics.pop()
		

    
	graphics.push()


    if self.after_level_bonus_screen and self:should_show_bonus_screen() and not self:is_paused() then
        local font2 = fonts.depalettized.image_font2
        graphics.set_font(font2)
        local middle_x = self.viewport_size.x / 2
        local middle_y = self.viewport_size.y / 2
        local bonus_count = #self.after_level_bonus_screen.bonuses
        graphics.translate(middle_x - 106, middle_y - 8)
        local total_highlight_amount = 0
		local total_flashing = iflicker((-self.tick / 2), 2, 4)
        for i, bonus in ipairs(self.after_level_bonus_screen.bonuses) do
			
            local is_flashing = iflicker((-self.tick / 2) + i, 2, 4)
			
			local bonus_name_color, score_color, multiplier_color, xp_color, count_color, cross_color, is_highlighted = self:get_bonus_screen_item_colors(bonus, is_flashing, i)
			
			
            if is_highlighted then
                total_highlight_amount = max(total_highlight_amount, bonus.score_apply_highlight_amount)
            end

			graphics.set_color(bonus_name_color)
            graphics.push("all")

            local y = (i - (bonus_count + 1) / 2) * 10
            -- local text = string.format("%-20s %8d [+%3dXP] [X%2d]", tr[bonus.name], bonus.score, bonus.xp, bonus.count) 
			graphics.print(type(bonus.name) == "function" and bonus.name() or tr[bonus.name], -12, y)
			
			local has_score = ALWAYS_SHOW_BONUS_DETAILS or bonus.score ~= 0 or bonus.score_multiplier ~= 0
			local has_multiplier = ALWAYS_SHOW_BONUS_DETAILS or bonus.score_multiplier ~= 0

			if has_score and has_multiplier then
				local score_without_zeroes = comma_sep(bonus.score * bonus.count)
				local multiplier_text = string.format("%-3.2f", bonus.score_multiplier * bonus.count)
				graphics.print_multicolor(font2, 60, y, score_without_zeroes, score_color, "×", cross_color, multiplier_text, multiplier_color)
			elseif has_score then
				local score_without_zeroes = comma_sep(bonus.score * bonus.count)
				graphics.set_color(score_color)
				graphics.print(score_without_zeroes, 60, y)
			elseif has_multiplier then
				local multiplier_text = string.format("%-3.2f", bonus.score_multiplier * bonus.count)
				graphics.print_multicolor(font2, 60, y, "×", cross_color, multiplier_text, multiplier_color)
			end

			if ALWAYS_SHOW_BONUS_DETAILS or bonus.xp ~= 0 then
				graphics.set_color(xp_color)
				graphics.print(string.format("+%-2dXP", floor(bonus.xp * bonus.count)), 150, y)
			end
            graphics.set_color(count_color)
			if bonus.bonus.always_show_count or bonus.count > 1 then
				graphics.print(string.format("×%d", bonus.count), 210, y)
			end
            graphics.pop()
        end
        local y = (bonus_count + 1) / 2 * 10
		local total_color = Color.magenta
		-- local total_color = total_flashing and Color.purple or Color.magenta
		graphics.push("all")
		graphics.set_color(total_color)
        if bonus_count > 0 then
            graphics.line(0, y + 2, 210, y + 2)
        end
        y = y + 5
        if total_highlight_amount > 0.55 then
            graphics.set_color(Color.cyan)
        else
            graphics.set_color(total_color)
        end
        graphics.print(tr.bonus_screen_total, -0, y)

		local input = self:get_input_table()

		if self.after_level_bonus_screen.start_prompt then
        	graphics.print(string.format(tr.bonus_screen_continue, input:get_skip_bonus_screen_prompt()), -0, y + 10)
		end
        
		local total_score_text = comma_sep(self.after_level_bonus_screen.total.score)
		graphics.set_color(Palette.rainbow:tick_color(self.tick, 0, 3))
		graphics.print(total_score_text, 60, y)
		local current_x = 60 + font2:getWidth(total_score_text)

		local multiplier_text = string.format("%-3.2f", self.after_level_bonus_screen.total.score_multiplier)
		graphics.print_multicolor(font2, current_x, y, "×", total_color, multiplier_text, total_flashing and Color.skyblue or Color.green)

		graphics.set_color(total_color)
        graphics.print(string.format("+%-2dXP", floor(self.after_level_bonus_screen.total.xp)), 150, y)
        graphics.pop()
    end
	graphics.pop()
	

end

function HUDLayer:get_bonus_screen_item_colors(bonus, is_flashing, offset)
	local dark_color = is_flashing and Color.darkgrey or Color.grey
    local cross_color = is_flashing and Color.darkergrey or Color.darkgrey

	local highlight_color = Color.cyan

    if bonus.score_apply_highlight_amount and bonus.score_apply_highlight_amount > 0.55 then
        return highlight_color, highlight_color, highlight_color, highlight_color, highlight_color, highlight_color, true
    end

    -- local fallback_color = is_flashing and Color.orange or Color.yellow
	
    local bonus_name_color = (is_flashing and Color.darkorange or Color.orange)
	
	if bonus.score_multiplier ~= 0 then
		bonus_name_color = (is_flashing and Color.orange or Color.yellow)
	end
	
	if bonus.xp ~= 0 then
        bonus_name_color = (is_flashing and Color.blue or Color.skyblue)
    end

	
    local score_color = (is_flashing and Color.orange or Color.yellow)
	local count_color =  score_color
	
	local xp_color = bonus_name_color
	
	
    if bonus.bonus.custom_color_function then
        bonus_name_color = bonus.bonus.custom_color_function(bonus, is_flashing, offset)
        count_color = bonus_name_color
	end
	


	local multiplier_color = is_flashing and Color.skyblue or Color.green
	
	
	if bonus.negative then
        local negative_color = is_flashing and Color.darkred or Color.red
        bonus_name_color = negative_color
        score_color = negative_color
        multiplier_color = negative_color
        xp_color = negative_color
        count_color = negative_color
    end
	
    if bonus.score_multiplier == 0 then
        multiplier_color = dark_color
    end
	
    if bonus.score == 0 and bonus.score_multiplier == 0 then
        score_color = dark_color
    end
	
	if bonus.xp == 0 then
        xp_color = dark_color
    end
	
	if bonus.count == 0 then
        count_color = dark_color
    end
	

    -- bonus_name_color, score_color, multiplier_color, xp_color, count_color, cross_color, is_highlighted
    return bonus_name_color, score_color, multiplier_color, xp_color, count_color, cross_color, false
end

function HUDLayer:create_persistent_ui()
	self.upgrades = {
        {
            name = "damage",
            color1 = Color.red,
            color2 = Color.darkred,
        },
		{
			name = "fire_rate",
			color1 = Color.cyan,
			color2 = Color.skyblue,
		},
		{
            name = "bullet_speed",
			color1 = Color.green,
			color2 = Color.darkgreen,
		},
		{
            name = "range",
			color1 = Color.yellow,
			color2 = Color.orange,
		},
        {
            name = "bullets",
            color1 = Color.magenta,
            color2 = Color.purple,
        },
	}

	self.xp_bars = {
		{
			name = "upgrade_xp_target",
			start = "reached_upgrade_xp_at",
			color = Color.cyan,
			xp = 0,
			x = 0,
			y = 0,
		},
		{
			name = "heart_xp_target",
			start = "reached_heart_xp_at",
			color = Color.magenta,
			xp = 0,
			x = 0,
			y = 0,
		},
		{
			name = "artefact_xp_target",
			start = "reached_artefact_xp_at",
			color = Color.yellow,
			xp = 0,
			x = 0,
			y = 0,
		},
	}
end


function HUDLayer:draw()
    HUDLayer.super.draw(self)

    if self.game_layer.world.fog_of_war then
        local x = self.game_layer.pos.x
        local y = self.game_layer.pos.y
        local width = self.game_layer.viewport_size.x
        local height = self.game_layer.viewport_size.y
        local color = Color.white
        if self.game_layer.world.room.get_screen_border_color then
            color = self.game_layer.world.room:get_screen_border_color()
        end
        
        if color == nil then
            color = Color.transparent
        end
        graphics.set_color(color)
        graphics.set_line_width(2)
        graphics.rectangle("line", x, y+1, width, height-2)
    end

	-- graphics.push("all")
	-- local parent = self.parent
    -- if parent.ui_layer.state == "Paused" and not parent.ui_layer.options_menu then
    --     -- if parent.game_layer.world.players[1] and parent.game_layer.world.players[1].pos.y < -20 then
	-- 	-- 	self.draw_guide_on_bottom = true
	-- 	-- elseif parent.game_layer.world.players[1] and parent.game_layer.world.players[1].pos.y > 20 then
	-- 	-- 	self.draw_guide_on_bottom = false
	-- 	-- end
	-- 	if self.draw_guide_on_bottom then
    --         graphics.push()
    --         graphics.translate(0, conf.viewport_size.y / 2 + 50)
    --         self:draw_guide_placeholder()
    --         graphics.pop()
    --     else
    --         self:draw_guide_placeholder()
    --     end
    -- end
	-- graphics.pop()
end

-- function HUDLayer:draw_guide_placeholder()
--     local x_start = (graphics.main_viewport_size.x - conf.viewport_size.x) / 2

-- 	graphics.translate(x_start, 0)
	
-- 	local font = fonts.depalettized.image_font1
-- 	graphics.set_font(font)
--     graphics.set_color(Color.white)

-- 	-- todo: localize
-- 	local gamepad = input.last_input_device == "gamepad"

--     local controls = {
--         { label = gamepad and "LEFT STICK" or "WASD", action = "MOVE"},
--         { label = gamepad and "RIGHT STICK" or "MOUSE", action = "SHOOT"},
--         { label = gamepad and "LEFT TRIGGER" or "SPACE", action = "BOOST" },
--         -- { label = "RMB/RIGHT TRIGGER: ", action = "SECONDARY WEAPON" },
-- 		{ label = "", action = "SAVE THE GREENOIDS" },
--     }
	
--     local vert = 11

-- 	-- graphics.translate(-conf.viewport_size.x / 2, -conf.viewport_size.y / 2)

-- 	graphics.translate(11, 0)
-- 	for i, control in ipairs(controls) do
-- 		local label = control.label
-- 		if #label > 0 then
-- 			label = control.label .. " - "
-- 		end
-- 		graphics.translate(0, vert)
-- 		graphics.set_color(Color.white)
-- 		graphics.print_outline(Color.black, label, 0, 0)
-- 		graphics.set_color(Color.green)
-- 		graphics.print_outline(Color.black, control.action, font:getWidth(label), 0)
-- 	end
-- end


return HUDLayer
