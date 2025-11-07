local default_savedata = {
	name = "",
    scores = {},
    category_highs = {},
    category_death_count = {},
	death_count = 0,
    codex_items = {},
    new_codex_items = {},
    run_upload_queue = {},
    new_version_force_intro = true,
    last_died_at = 0,
	game_version = GAME_VERSION,
    leaderboard_version = GAME_LEADERBOARD_VERSION,
    leaderboard_sort_index = 1,
    leaderboard_period = "daily",
    leaderboard_wep_filter = "all",
    done_shader_performance_test = false,
    has_seen_title_screen = false,
    has_pressed_codex_category_button = false,
    -- update_force_cutscene = true,
}

local SCORE_COUNT = 100

local savedata = {}
local MAX_NAME_LENGTH = 18

local VERSIONS_WITH_NEW_INTRO = {
    "0.8.9",
}


-- Compare two version strings like "0.8.9" or "1.2.3-rc1".
-- Returns 1 if a > b, -1 if a < b, 0 if equal.
function savedata:version_compare(a, b)
    local function parse_version(v)
        v = tostring(v or "")
        local parts = {}
        for part in v:gmatch("[^%.]+") do
            local num = tonumber(part:match("^(%d+)")) or 0
            local suffix = part:match("%d+(.*)")
            if suffix == "" then suffix = nil end
            parts[#parts + 1] = { num = num, suffix = suffix }
        end
        return parts
    end

    local pa, pb = parse_version(a), parse_version(b)
    local max_len = math.max(#pa, #pb)
    for i = 1, max_len do
        local va = pa[i] or { num = 0, suffix = nil }
        local vb = pb[i] or { num = 0, suffix = nil }
        if va.num ~= vb.num then

            return (va.num > vb.num) and 1 or -1
        end

        local sa, sb = va.suffix, vb.suffix
        if sa ~= sb then
            if sa == nil and sb ~= nil then return 1 end   -- release > pre-release
            if sa ~= nil and sb == nil then return -1 end  -- pre-release < release
            if sa ~= nil and sb ~= nil then
                if sa ~= sb then
                    return (sa > sb) and 1 or -1
                end
            end
        end
    end
    return 0
end

-- Convenience: true if version a is newer than version b
function savedata:is_version_newer(a, b)
    return savedata:version_compare(a, b) == 1
end

function savedata:is_version_older(a, b)
    return savedata:version_compare(a, b) == -1
end



function savedata:load()
    local _, u = pcall(require, "_savedata")

    if type(u) ~= "table" then
        u = table.deepcopy(default_savedata)
    end

    for k, v in pairs(default_savedata) do
        if u[k] == nil then
            u[k] = table.deepcopy(v)
        end
    end

    for k, v in pairs(u) do
        self[k] = table.deepcopy(v)
    end

    if self.uid == nil then
        self.uid = rng:uuid()
    end

    if self.scores[GAME_LEADERBOARD_VERSION] == nil then
        self.scores[GAME_LEADERBOARD_VERSION] = {}
    end

    if self.category_highs[GAME_LEADERBOARD_VERSION] == nil then
        self.category_highs[GAME_LEADERBOARD_VERSION] = {}
    end

    if self.game_version ~= GAME_VERSION then
        self.was_old_game_version = true
        self.old_game_version = self.game_version
        if self.old_game_version == nil then
            self.old_game_version = "0.0.0"
        end
        self.game_version = GAME_VERSION
        for _, version in ipairs(VERSIONS_WITH_NEW_INTRO) do
            if self:version_compare(self.old_game_version, version) < 0 and self:version_compare(self.game_version, version) >= 0 then
                self.new_version_force_intro = true
                break
            end
        end
    end

    if self.leaderboard_version ~= GAME_LEADERBOARD_VERSION then
        self.was_old_leaderboard_version = true
        self.old_leaderboard_version = self.leaderboard_version
        self.leaderboard_version = GAME_LEADERBOARD_VERSION
    end

	-- print("uid: ", self:get_uid())
end

function savedata:get_uid()
    -- if steam then
        -- return tostring(steam.user.get_steam_id())
    -- end
    return self.uid
end

local ignore = {
	["default_savedata"] = true,
	["was_old_game_version"] = true,
	["was_old_leaderboard_version"] = true,
	["old_game_version"] = true,
	["old_leaderboard_version"] = true,
}

function savedata:save()
    local tab = {}
    for k, v in pairs(self) do
        if type(v) == "function" then
            goto continue
        end
        if ignore[k] then
            goto continue
        end
        -- if not table.equal(v, default_savedata[k]) then
		tab[k] = table.deepcopy(v)
        -- end
        ::continue::
    end

	local s = require("lib.tabley").serialize(tab)

    love.filesystem.write("_savedata.lua", s)
end

function savedata:initial_load()
    self:load()
    self:save()

    self:apply_save_data()
end


function savedata:apply_save_data()
end

function savedata:sort_scores()

    for _, category in pairs(self.scores[GAME_LEADERBOARD_VERSION]) do
        table.sort(category, function(a, b) return a.score > b.score end)
    end
	
	for _, category in pairs(self.scores[GAME_LEADERBOARD_VERSION]) do
		while #category > SCORE_COUNT do
			table.remove(category)
		end
	end
end

function savedata:reset_to_default()
	for k, v in pairs(default_savedata) do
		self[k] = v
	end
	self:save()
	self:load()
	self:apply_save_data()
end

function savedata:set_save_data(key, value)
    if self[key] == value then return end
    self[key] = value
    self:save()
    self:apply_save_data()
end

function savedata:add_category_death(category)	
	if self.category_death_count[category] == nil then
        self.category_death_count[category] = 0
    end
    self.category_death_count[category] = self.category_death_count[category] + 1
    self:save()
    self:apply_save_data()
end

function savedata:add_score(run)

	run = table.deepcopy(run)
	
	if run.category == nil then
		run.category = leaderboard.default_category
	end
	self.scores[GAME_LEADERBOARD_VERSION][run.category] = self.scores[GAME_LEADERBOARD_VERSION][run.category] or {}
	table.insert(self.scores[GAME_LEADERBOARD_VERSION][run.category], run)
    self:sort_scores()
    

    if self.category_highs[GAME_LEADERBOARD_VERSION][run.category] == nil then
        self.category_highs[GAME_LEADERBOARD_VERSION][run.category] = {}
    end
    
    local category_highs = self.category_highs[GAME_LEADERBOARD_VERSION][run.category]
	
	if category_highs.score == nil then
		category_highs.score = 0
	end

    if category_highs.kills == nil then
        category_highs.kills = 0
    end
	
	if category_highs.level == nil then
		category_highs.level = 0
	end

    if category_highs.rescues == nil then
        category_highs.rescues = 0
    end

    if category_highs.game_time == nil then
        category_highs.game_time = 0
    end

    if GAME_VERSION == "0.7.3" then
        if floor(category_highs.game_time) ~= category_highs.game_time then
            category_highs.game_time = floor(frames_to_seconds(category_highs.game_time) * 1000)
        end
    end
	
	if run.score > category_highs.score then
		category_highs.score = run.score
	end

	if run.kills > category_highs.kills then
		category_highs.kills = run.kills
	end

	if run.level > category_highs.level then
		category_highs.level = run.level
	end

	if run.rescues > category_highs.rescues then
		category_highs.rescues = run.rescues
	end

    if (category_highs.game_time <= 0 or (run.game_time < category_highs.game_time)) and run.good_ending then
        category_highs.game_time = run.game_time
    end

	self:save()
	self:apply_save_data()
end

function savedata:get_high_score_run(category)
	category = category or (leaderboard.default_category)
    self:sort_scores()
	if not self.scores[GAME_LEADERBOARD_VERSION][category] then
		return nil
	end
	return self.scores[GAME_LEADERBOARD_VERSION][category][1]
end

function savedata:get_category_highs(category)
	category = category or (leaderboard.default_category)
	if not self.category_highs[GAME_LEADERBOARD_VERSION][category] then
		return nil
	end
	return self.category_highs[GAME_LEADERBOARD_VERSION][category]
end

function savedata:_add_codex_item(spawn)
	if not self.codex_items[spawn] then
		print("adding codex item " .. spawn)
		self.new_codex_items[spawn] = true
        self.codex_items[spawn] = true
        return true
	end
end

function savedata:add_item_to_codex(spawn)
	if self:_add_codex_item(spawn) then
		self:save()
		self:apply_save_data()
	end
end

function savedata:add_items_to_codex(spawns)
    local changed = false
    for i, spawn in ipairs(spawns) do
        if self:_add_codex_item(spawn) then
            changed = true
        end
    end

    if changed then
        self:save()
        self:apply_save_data()
    end
end

function savedata:check_codex_item(spawn)
	return self.codex_items[spawn]
end

function savedata:is_new_codex_item(spawn)
    return self.new_codex_items[spawn]
end

function savedata:clear_new_codex_item(spawn)
    if not self.new_codex_items[spawn] then
        return
    end

    self.new_codex_items[spawn] = nil
    self:save()
    self:apply_save_data()
end

function savedata:on_death()
    if usersettings.retry_cooldown then
        self:set_save_data("last_died_at", os.time())
        self:set_save_data("retry_cooldown_seconds", max(10, (game_state and game_state.level) or 10))
    end
end

function savedata:get_seconds_until_retry_cooldown_is_over()
    local last_died_at = self.last_died_at
    if last_died_at == 0 then
        return 0
    end

    return last_died_at + self.retry_cooldown_seconds - os.time()
end

return savedata
