local HUDLayer = CanvasLayer:extend("HUDLayer")
local LevelBonus = require("levelbonus.LevelBonus")

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
	
	table.sort(temp_bonuses, function(a, b)
		if a.bonus.negative and not b.bonus.negative then
			return false
		end
		if not a.bonus.negative and b.bonus.negative then
			return true
		end

		if try_function(a.bonus.xp) * a.count == try_function(b.bonus.xp) * b.count then
			return try_function(a.bonus.score) * a.count > try_function(b.bonus.score) * b.count
		end
		return try_function(a.bonus.xp) * a.count > try_function(b.bonus.xp) * b.count
	end)

    self.game_layer.world.waiting_on_bonus_screen = true
	
    local function update_bonus_info(bonus, b, count)
		b.score = bonus.ignore_score_multiplier and try_function(bonus.score) or game_state:determine_score(try_function(bonus.score))
		if bonus.negative then
			b.score = -b.score
		end
		b.xp = try_function(bonus.xp)
		if game_state.final_room_cleared then
			b.xp = 0
		end
        b.score_multiplier = try_function(bonus.score_multiplier)
		if bonus.negative then 
			b.score_multiplier = -b.score_multiplier
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
		return true
	end

    s:start(function()
        local wait = function(time)
            for i = 1, time do
				if not self.skipping_bonus_screen then
					s:wait(1)
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
		
		for i = 1, #self.after_level_bonus_screen.bonuses do
            local b = self.after_level_bonus_screen.bonuses[i]
            for j = 1, b.count do
                -- b.count = b.count - 1

				-- for getting score and xp to add to the game state
				local one_b = {
					name = b.name,
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
				total.xp = max(total.xp, 0)
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
				game_state:add_score(one_b.score, one_b.name)
                game_state:add_score_multiplier(one_b.score_multiplier)
				game_state:apply_level_bonus_difficulty(one_b.bonus.difficulty_modifier)
				
				if b.score_highlight_coroutine then
					s:stop(b.score_highlight_coroutine)
				end
                b.score_highlight_coroutine = s:start(function()
					b.score_apply_highlight_amount = 1
					s:tween_property(b, "score_apply_highlight_amount", 1, 0, 12, "outCubic")
				end)


                self:play_sfx("ui_bonus_screen_beep2", 0.75)
                if wait_for_bonus(b) then
                    wait(4)
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
			self:play_sfx("ui_bonus_screen_beep", 0.5)
			
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
            if stepify_floor_safe(self.score_display, step) % (step * 5) == 0 then
                self:play_sfx("score_add", 0.15)
            end
        end
    end
    if game_state.score < self.score_display then
        self.score_display = game_state.score
    end

	local input = self:get_input_table()
	if (input.skip_bonus_screen_held) and self.after_level_bonus_screen then
		self.skipping_bonus_screen = true
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
end

local bonus_palette = PaletteStack:new(Color.black, Color.white)

function HUDLayer:can_pause()
	if self.after_level_bonus_screen then
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

    -- figure out how much of padded_str we’d have to chop off
    local diff_len  = #padded_str - #unpadded_str
    local hidden_str = padded_str:sub(1, diff_len)

    -- positive offset: move right by this many chars or pixels
    local x_offset = font
        and font:getWidth(hidden_str)
        or diff_len

    return padded_str, unpadded_str, x_offset
end

function HUDLayer:pre_world_draw()
    local game_area_width = conf.viewport_size.x - conf.room_padding.x * 2
    local game_area_height = conf.viewport_size.y - conf.room_padding.y * 2
    local x_start = (graphics.main_viewport_size.x - conf.viewport_size.x) / 2
    local y_start = (graphics.main_viewport_size.y - conf.viewport_size.y) / 2 - 2
    local h_padding = conf.room_padding.x - 2
    local v_padding = conf.room_padding.y - 9
    local left = x_start + h_padding
    local top = y_start + v_padding - 1
    local bottom = y_start + v_padding + game_area_height + 11
    local font = fonts.hud_font

    local border_color = self.game_layer.world:get_border_rainbow()


    graphics.set_font(font)
    graphics.set_color(Color.white)

    local charwidth = fonts.hud_font:getWidth("0")

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

	local high_score = savedata.category_highs[game_state.leaderboard_category] and savedata.category_highs[game_state.leaderboard_category].score or 0

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
	end


	local score_without_zeroes = comma_sep(self.score_display)

    -- graphics.print(score_without_zeroes, score_width, 0)
	-- graphics.print(score_without_zeroes, score_width + 9, 0)

	graphics.set_color(border_color)
	graphics.print_right_aligned(score_without_zeroes, font, 0, 0)
	graphics.set_color(Color.grey)
	
    local scoremult1 = "×["
    local scoremult2 = string.format("%-.2f", game_state:get_score_multiplier(false))
    local scoremult3 = string.format("+%02d", game_state:get_rescue_chain_multiplier())
	local scoremult4 = "   "
	local scoremult5 = "]"

    local greenoid_color = Color.green
	if self:is_timer_running("greenoid_harmed_flash") then
		greenoid_color = idivmod_eq_zero(self.tick, 3, 2) and Color.red or Color.green
	end
    graphics.print_multicolor(font, 0, 0, scoremult1, Color.grey, scoremult2, Color.white, scoremult3, greenoid_color,
        scoremult4, Color.white, scoremult5, Color.grey)
	graphics.set_color(Color.white)
	graphics.drawp_centered(textures.ally_rescue1, nil, 0, font:getWidth(scoremult1..scoremult2..scoremult3) + 6, 4)
	graphics.pop()
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
		local flashing = self:is_timer_running("upgrade_flash_" .. upgrade.name) and idivmod_eq_zero(self.tick, 3, 2)
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

    -- graphics.print_outline(Color.black, string.format("%dXP", game_state.xp), charwidth * 6, 0)
    graphics.pop()
    -- graphics.print_outline(Color.black, string.format("x%-4.1f", game_state:get_score_multiplier()), charwidth * 16, 0)
    graphics.pop()

    graphics.push()


    if self.after_level_bonus_screen then
        local font2 = fonts.depalettized.image_font2
        graphics.set_font(font2)
        local middle_x = self.viewport_size.x / 2
        local middle_y = self.viewport_size.y / 2
        local bonus_count = #self.after_level_bonus_screen.bonuses
        graphics.translate(middle_x - 106, middle_y - 8)
        local total_highlight_amount = 0
        for i, bonus in ipairs(self.after_level_bonus_screen.bonuses) do
			
			local font_color = idivmod_eq_zero((-self.tick / 2) + i, 2, 4) and (bonus.negative and Color.darkred or Color.orange) or (bonus.negative and Color.red or Color.yellow)
			graphics.set_color(font_color)
            graphics.push("all")
            if bonus.score_apply_highlight_amount and bonus.score_apply_highlight_amount > 0.55 then
                graphics.set_color(Color.cyan)
                total_highlight_amount = max(total_highlight_amount, bonus.score_apply_highlight_amount)
            end

            local y = (i - (bonus_count + 1) / 2) * 10
            -- local text = string.format("%-20s %8d [+%3dXP] [X%2d]", tr[bonus.name], bonus.score, bonus.xp, bonus.count)
			graphics.printp(tr[bonus.name], font2, nil, 0, -12, y)
			
			local score_without_zeroes = comma_sep(bonus.score * bonus.count)
			local width = font2:getWidth(score_without_zeroes)

            graphics.printp(score_without_zeroes, font2, nil, 0, 60, y)
            graphics.printp(string.format("×%-3.2f", bonus.score_multiplier * bonus.count), font2, nil, 0,
                60 + width, y)
            graphics.printp(string.format("+%-2dXP", floor(bonus.xp * bonus.count)), font2, nil, 0, 150, y)
            graphics.printp(string.format("×%d", bonus.count), font2, nil, 0, 210, y)
            graphics.pop()
        end
        local y = (bonus_count + 1) / 2 * 10
		local font_color = idivmod_eq_zero((-self.tick / 2), 3, 3) and Color.purple or Color.magenta
		graphics.push("all")
		graphics.set_color(font_color)
        if bonus_count > 0 then
            graphics.line(0, y + 2, 210, y + 2)
        end
        y = y + 5
        if total_highlight_amount > 0.55 then
            graphics.set_color(Color.cyan)
        end
        graphics.printp("TOTAL", font2, nil, 0, -0, y)

		local input = self:get_input_table()

		if self.after_level_bonus_screen.start_prompt then
        	graphics.printp("PRESS " .. (input.last_input_device == "gamepad" and "START" or "TAB") .. " TO CONTINUE", font2, nil, 0, -0, y + 10)
		end
        
		local score_without_zeroes = comma_sep(self.after_level_bonus_screen.total.score)
		local width = font2:getWidth(score_without_zeroes)
		graphics.printp(score_without_zeroes, font2, nil, 0, 60, y)
		graphics.printp(string.format("×%-3.2f", self.after_level_bonus_screen.total.score_multiplier), font2, nil, 0,
            60 + width, y)
        graphics.printp(string.format("+%-2dXP", floor(self.after_level_bonus_screen.total.xp)), font2, nil, 0, 150, y)
        graphics.pop()
    end
	graphics.pop()
	

end

function HUDLayer:create_persistent_ui()
	self.upgrades = {
		{
			name = "fire_rate",
			color1 = Color.cyan,
			color2 = Color.skyblue,
		},
		{
			name = "damage",
			color1 = Color.red,
			color2 = Color.darkred,
		},
		{
			name = "bullets",
			color1 = Color.magenta,
			color2 = Color.purple,
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
