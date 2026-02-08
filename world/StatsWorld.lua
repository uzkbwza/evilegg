local StatsWorld = World:extend("StatsWorld")
local O = require("obj")
local SpawnDataTable = require("obj.spawn_data")
local PickupDataTable = require("obj.pickup_table")
local LevelBonus = require("bonus.LevelBonus")
local EndGameBonus = require("bonus.EndGameBonus")
local Room = require("room.Room")
local CodexWorld = require("world.CodexWorld")

local MENU_ITEM_H_PADDING = 12
local MENU_ITEM_V_PADDING = 6
local LINE_HEIGHT = 11
local STAT_VALUE_X = 100

function StatsWorld:new()
    StatsWorld.super.new(self)
    self:add_signal("exit_menu_requested")
    self.draw_sort = self.y_sort
end

function StatsWorld:enter()
    self.camera:move(conf.viewport_size.x / 2, conf.viewport_size.y / 2)

    self:ref("menu_root", self:spawn_object(O.Menu.GenericMenuRoot(0, 0, 1, 1)))

    self:ref("back_button",
             self:add_menu_item(O.PauseScreen.PauseScreenButton(MENU_ITEM_H_PADDING, MENU_ITEM_V_PADDING, "⮌",
                                                                10, 10, false))):focus()

    signal.connect(self.back_button, "selected", self, "back_button_selected", function()
                   local s = self.sequencer
                   s:start(function()
                           self.handling_input = false
                           s:wait(1)
                           self:emit_signal("exit_menu_requested")
                           end)
                   end)

    self:build_stats_display()
end

function StatsWorld:build_stats_display()
    self.stat_lines = {}
    
    local category = leaderboard.default_category
    local category_highs = savedata:get_category_highs(category) or {}
    
    local total_kills = (savedata.total_kills or 0)
    local total_rescues = (savedata.total_rescues or 0)
    local total_runs = (savedata.total_runs or 0)
    local total_playtime = savedata.total_playtime or 0

    -- Calculate total deaths
    local total_deaths = savedata.death_count or 0
    
    -- Count codex items
    local codex_count = 0
    for _ in pairs(savedata.codex_items or {}) do
        codex_count = codex_count + 1
    end
    
    -- Add start_unlocked glossary entries that aren't already in codex_items
    local start_unlocked_glossary = CodexWorld.get_start_unlocked_glossary_names()
    for _, name in ipairs(start_unlocked_glossary) do
        if not (savedata.codex_items or {})[name] then
            codex_count = codex_count + 1
        end
    end

    -- Add start_unlocked bonus entries that aren't already in codex_items
    local hidden_level_bonuses = {
        bonus_twin_killed = true,
        bonus_boss_defeated = true,
        bonus_cursed_room = true,
        bonus_hard_room = true,
    }
    for _, v in pairs(LevelBonus) do
        if not hidden_level_bonuses[v.text_key] and not (savedata.codex_items or {})[v.text_key] then
            codex_count = codex_count + 1
        end
    end
    for _, v in pairs(EndGameBonus) do
        if not (savedata.codex_items or {})[v.name_key] then
            codex_count = codex_count + 1
        end
    end

    
    -- Count total available codex entries
    local total_codex_entries = self:count_total_codex_entries()
    
    -- Build stats list
    local stats = {
                   { label = string.format(tr.stats_version_header, GAME_LEADERBOARD_VERSION), value = ""},
                   { label = tr.stats_high_score, value = comma_sep(category_highs.score or 0)},
                   { label = tr.stats_highest_level, value = tostring(category_highs.level or 0)},
                   { label = tr.stats_best_kills, value = comma_sep(category_highs.kills or 0)},
                   { label = tr.stats_best_rescues, value = comma_sep(category_highs.rescues or 0)},
                   { spacer = true },
                   { label = tr.stats_total_runs, value = comma_sep(total_runs)},
                   { label = tr.stats_total_kills, value = comma_sep(total_kills)},
                   { label = tr.stats_total_rescues, value = comma_sep(total_rescues)},
                --    { label = tr.stats_total_deaths, value = comma_sep(total_deaths)},
                   { label = tr.stats_total_playtime, value = format_hhmmssms(total_playtime)},
                   { label = tr.stats_wins, value = comma_sep(savedata.wins or 0)},
                   { label = tr.stats_planets_saved, value = comma_sep(savedata.planets_saved or 0)},
                --    { spacer = true },
                   { label = tr.stats_codex_entries, value = string.format("%d / %d", codex_count, total_codex_entries)},}
    
    
    -- Add best time if player has achieved good ending

    if category_highs.game_time and category_highs.game_time > 0 then
        local time_ms = category_highs.game_time

        local time_str = format_hhmmssms(time_ms)
        table.insert(stats, 6, { label = tr.stats_best_time, value = time_str})
    end
    
    self.stats = stats
end

function StatsWorld:count_total_codex_entries()
    local count = 0
    
    -- Count enemies, hazards, rescues from SpawnDataTable
    for _, category in ipairs({"enemy", "hazard", "rescue"}) do
        for _, spawn in ipairs(SpawnDataTable.data_by_type[category] or {}) do
            if spawn.name ~= "BaseSpawn" and not spawn.codex_hidden then
                count = count + 1
            end
        end
    end
    
    -- Count pickups (upgrades, hearts, powerups)
    for _, upgrade in pairs(PickupDataTable.upgrades or {}) do
        if not upgrade.base and not upgrade.codex_hidden then
            count = count + 1
        end
    end
    for _, heart in pairs(PickupDataTable.hearts or {}) do
        if not heart.base and not heart.codex_hidden then
            count = count + 1
        end
    end
    for _, powerup in pairs(PickupDataTable.powerups or {}) do
        if not powerup.base and not powerup.codex_hidden then
            count = count + 1
        end
    end
    
    -- Count artefacts and secondary weapons
    for _, artefact in pairs(PickupDataTable.artefacts or {}) do
        if not artefact.base and not artefact.codex_hidden then
            count = count + 1
        end
    end
    
    -- Count glossary entries from CodexWorld
    count = count + #CodexWorld.get_glossary_entries()
    
    -- Count curses from Room.curses
    for _ in pairs(Room.curses or {}) do
        count = count + 1
    end
    
    -- Count level bonuses
    for _ in pairs(LevelBonus or {}) do
        count = count + 1
    end
    
    -- Count end game bonuses (only if player has beaten the game, matching codex behavior)
    -- if savedata.has_beaten_game then
        for _ in pairs(EndGameBonus or {}) do
            count = count + 1
        end
    -- end
    
    return count
end

function StatsWorld:add_menu_item(item)
    self.menu_root:add_child(self:spawn_object(item))
    return item
end

function StatsWorld:update(dt)
    local input = self:get_input_table()
    if input.ui_cancel_pressed then
        self.back_button:select()
    end
end

function StatsWorld:draw()
    local font = fonts.depalettized.image_bigfont1
    graphics.set_font(font)
    graphics.print(tr.menu_stats_button, font, 28, MENU_ITEM_V_PADDING - 3, 0, 1, 1)
    
    -- Draw stats
    local small_font = fonts.depalettized.image_font1
    graphics.set_font(small_font)
    
    local current_y = MENU_ITEM_V_PADDING + 18
    
    local color = Color.cyan
    local past_current_version = false
    
    for i, stat in ipairs(self.stats or {}) do
        if stat.spacer then
            graphics.set_color(Color.darkergrey)
            graphics.line(MENU_ITEM_H_PADDING, current_y + 2, MENU_ITEM_H_PADDING + conf.viewport_size.x - (MENU_ITEM_H_PADDING * 2), current_y + 2)
            current_y = current_y + 4
            color = Color.skyblue
            past_current_version = true
        else
            graphics.set_color(color)
            graphics.print(stat.label:upper(), small_font, MENU_ITEM_H_PADDING, current_y)
            
            graphics.set_color(past_current_version and Color.white or Palette.rainbow:get_color(floor(self.elapsed * -0.13 + i)))
            graphics.print(stat.value, small_font, STAT_VALUE_X, current_y)
            
            current_y = current_y + LINE_HEIGHT
        end
    end
    
    -- graphics.set_color(Color.darkgrey)
    -- graphics.print_right_aligned(GAME_LEADERBOARD_VERSION, small_font,
                                --  conf.viewport_size.x - MENU_ITEM_H_PADDING, conf.viewport_size.y - small_font:getHeight() - 7)
    graphics.set_color(Color.white)
    StatsWorld.super.draw(self)
end

return StatsWorld
