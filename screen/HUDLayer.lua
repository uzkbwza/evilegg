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
	self:create_persistent_ui()
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
		return try_function(a.bonus.xp) * a.count > try_function(b.bonus.xp) * b.count
	end)

    self.game_layer.world.waiting_on_bonus_screen = true
	
    local function update_bonus_info(bonus, b, count)
		b.score = game_state:determine_score(try_function(bonus.score))
		b.xp = try_function(bonus.xp)
		b.score_multiplier = try_function(bonus.score_multiplier)
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
                b.count = b.count + 1
                update_bonus_info(bonus, b, b.count)
                self:play_sfx("bonus_screen_beep", 0.5)
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
                total.xp = total.xp + b.xp
                total.score_multiplier = total.score_multiplier + b.score_multiplier

				local xp = one_b.xp
                while xp > 0 do
					local amount = min(rng.randf_range(1, 60), xp)
					local x, y = self.game_layer.world:closest_last_player_pos(0, 0)
					self.game_layer.world:spawn_xp(x, y, amount)
					xp = xp - amount
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
				
                self:play_sfx("bonus_screen_beep2", 0.75)
                if wait_for_bonus(b) then
                    wait(4)
                end
			end
		end
		
		wait(5)
		self.after_level_bonus_screen.start_prompt = true
		wait(595)
		
		for i = #self.after_level_bonus_screen.bonuses, 1, -1 do
			local bonus = self.after_level_bonus_screen.bonuses[i]
			table.remove(self.after_level_bonus_screen.bonuses, i)
            s:wait(2)
			self:play_sfx("bonus_screen_beep", 0.5)
			
		end
		
		self.after_level_bonus_screen = nil
		self:play_sfx("bonus_screen_beep", 0.5)

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
    graphics.set_font(font)
    graphics.set_color(Color.white)

    local charwidth = fonts.hud_font:getWidth("0")

    graphics.push()
    graphics.translate(left, top)
    graphics.set_color(Color.darkgrey)
    graphics.print(string.format("LVL%02d ", game_state.level % 100), 0, 0)
    -- graphics.set_color(Palette.rainbow:tick_color(gametime.tick, 0, 10))
    graphics.set_color(Color.white)
    graphics.print(string.format("LVL%2d ", game_state.level % 100), 0, 0)
    graphics.print(string.format("WAVE%01d ", game_state.wave), charwidth * 7, 0)
    graphics.print(string.format("%d [×%-.2f ×%dGNOIDS]", self.score_display, game_state:get_score_multiplier(false), game_state:get_rescue_chain_multiplier()), charwidth * 13, 0)
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
			
			local font_color = idivmod_eq_zero((-self.tick / 2) + i, 2, 4) and Color.blue or Color.skyblue
			graphics.set_color(font_color)
            graphics.push("all")
            if bonus.score_apply_highlight_amount and bonus.score_apply_highlight_amount > 0.55 then
                graphics.set_color(Color.yellow)
                total_highlight_amount = max(total_highlight_amount, bonus.score_apply_highlight_amount)
            end

            local y = (i - (bonus_count + 1) / 2) * 10
            -- local text = string.format("%-20s %8d [+%3dXP] [X%2d]", tr[bonus.name], bonus.score, bonus.xp, bonus.count)
            graphics.printp(tr[bonus.name], font2, nil, 0, -12, y)
            graphics.printp(string.format("%8d×%-.2f", bonus.score * bonus.count, bonus.score_multiplier), font2, nil, 0,
                60, y)
            graphics.printp(string.format("+%-2dXP", floor(bonus.xp * bonus.count)), font2, nil, 0, 150, y)
            graphics.printp(string.format("×%d", bonus.count), font2, nil, 0, 210, y)
            graphics.pop()
        end
        local y = (bonus_count + 1) / 2 * 10
        if bonus_count > 0 then
            graphics.line(0, y + 2, 210, y + 2)
        end
        y = y + 5
        graphics.push("all")
        local font_color = idivmod_eq_zero((-self.tick / 2), 2, 4) and Color.darkgreen or Color.green
        graphics.set_color(font_color)
        if total_highlight_amount > 0.55 then
            graphics.set_color(Color.cyan)
        end
        graphics.printp("TOTAL", font2, nil, 0, -0, y)

		local input = self:get_input_table()

		if self.after_level_bonus_screen.start_prompt then
        	graphics.printp("PRESS " .. (input.last_input_device == "gamepad" and "START" or "TAB") .. " TO CONTINUE", font2, nil, 0, -0, y + 10)
		end
        graphics.printp(
        string.format("%8d×%-.2f", self.after_level_bonus_screen.total.score,
            self.after_level_bonus_screen.total.score_multiplier), font2, nil, 0, 60, y)
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
	graphics.push("all")
	local parent = self.parent
    if parent.ui_layer.state == "Paused" and not parent.ui_layer.options_menu then
        -- if parent.game_layer.world.players[1] and parent.game_layer.world.players[1].pos.y < -20 then
		-- 	self.draw_guide_on_bottom = true
		-- elseif parent.game_layer.world.players[1] and parent.game_layer.world.players[1].pos.y > 20 then
		-- 	self.draw_guide_on_bottom = false
		-- end
		if self.draw_guide_on_bottom then
            graphics.push()
            graphics.translate(0, conf.viewport_size.y / 2 + 50)
            self:draw_guide_placeholder()
            graphics.pop()
        else
            self:draw_guide_placeholder()
        end
    end
	graphics.pop()
end

function HUDLayer:draw_guide_placeholder()
    local x_start = (graphics.main_viewport_size.x - conf.viewport_size.x) / 2

	graphics.translate(x_start, 0)
	
	local font = fonts.depalettized.image_font1
	graphics.set_font(font)
    graphics.set_color(Color.white)

	-- todo: localize
	local gamepad = input.last_input_device == "gamepad"

    local controls = {
        { label = gamepad and "LEFT STICK" or "WASD", action = "MOVE"},
        { label = gamepad and "RIGHT STICK" or "MOUSE", action = "SHOOT"},
        { label = gamepad and "LEFT TRIGGER" or "SPACE", action = "BOOST" },
        -- { label = "RMB/RIGHT TRIGGER: ", action = "SECONDARY WEAPON" },
		{ label = "", action = "SAVE THE GREENOIDS" },
    }
	
    local vert = 11

	-- graphics.translate(-conf.viewport_size.x / 2, -conf.viewport_size.y / 2)

	graphics.translate(11, 0)
	for i, control in ipairs(controls) do
		local label = control.label
		if #label > 0 then
			label = control.label .. " - "
		end
		graphics.translate(0, vert)
		graphics.set_color(Color.white)
		graphics.print_outline(Color.black, label, 0, 0)
		graphics.set_color(Color.green)
		graphics.print_outline(Color.black, control.action, font:getWidth(label), 0)
	end
end


return HUDLayer
