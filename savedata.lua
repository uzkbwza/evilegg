
local function UUID()
	local fn = function(x)
		local r = love.math.random(16) - 1
		r = (x == "x") and (r + 1) or (r % 4) + 9
		return ("0123456789abcdef"):sub(r, r)
	end
	return (("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", fn))
end

local default_savedata = {
	name = "",
    scores = {},
    category_highs = {},
    category_death_count = {},
	death_count = 0,
    codex_items = {},
	new_codex_items = {},
}

local SCORE_COUNT = 100

local savedata = {}
local MAX_NAME_LENGTH = 18

function savedata:load()
    local _, u = pcall(require, "_savedata")

    if type(u) ~= "table" then
        u = default_savedata
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
        self.uid = UUID()
    end

end

function savedata:save()
    local tab = {}
    for k, v in pairs(self) do
        if type(v) == "function" then
            goto continue
        end
        if k == "default_savedata" then
            goto continue
        end
        if not table.equal(v, default_savedata[k]) then
            tab[k] = table.deepcopy(v)
        end
        ::continue::
    end

    love.filesystem.write("_savedata.lua", require("lib.tabley").serialize(tab))
end

function savedata:initial_load()
    self:load()
    self:save()

    self:apply_save_data()
end


function savedata:apply_save_data()
end

function savedata:sort_scores()

	for _, category in pairs(self.scores) do
		table.sort(category, function(a, b) return a.score > b.score end)
	end

	for _, category in pairs(self.scores) do
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
		run.category = debug.enabled and leaderboard.default_category
	end
	self.scores[run.category] = self.scores[run.category] or {}
	table.insert(self.scores[run.category], run)
	self:sort_scores()

	if self.category_highs[run.category] == nil then
		self.category_highs[run.category] = {
		}
	end
	
	if self.category_highs[run.category].score == nil then
		self.category_highs[run.category].score = 0
	end

    if self.category_highs[run.category].kills == nil then
        self.category_highs[run.category].kills = 0
    end
	
	if self.category_highs[run.category].level == nil then
		self.category_highs[run.category].level = 0
	end

    if self.category_highs[run.category].rescues == nil then
        self.category_highs[run.category].rescues = 0
    end

    local category_highs = self.category_highs[run.category]
	
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
	self:save()
	self:apply_save_data()
end

function savedata:get_high_score_run(category)
	category = category or (debug.enabled and leaderboard.default_category)
    self:sort_scores()
	if not self.scores[category] then
		return nil
	end
	return self.scores[category][1]
end


function savedata:_add_codex_item(spawn)
	if not self.codex_items[spawn] then
		print("adding codex item " .. spawn)
		self.new_codex_items[spawn] = true
		self.codex_items[spawn] = true
	end
end

function savedata:add_item_to_codex(spawn)

	self:_add_codex_item(spawn)
	self:save()
	self:apply_save_data()
end

function savedata:add_items_to_codex(spawns)
    for i, spawn in ipairs(spawns) do
        self:_add_codex_item(spawn)
    end

    self:save()
    self:apply_save_data()
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



return savedata
