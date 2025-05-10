local default_savedata = {
	name = "",
    scores = {},
    codex_items = {},
	new_codex_items = {},
}

local SCORE_COUNT = 100

local savedata = {}

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

local just_started = true
function savedata:initial_load()
    self:load()
    self:save()

    self:apply_save_data()
	just_started = false
end


function savedata:apply_save_data()
end

function savedata:sort_scores()
    table.sort(self.scores, function(a, b) return a.score > b.score end)
    
	while #self.scores > SCORE_COUNT do
        table.remove(self.scores)
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

function savedata:add_score(run)
    table.insert(self.scores, run)
    self:sort_scores()
    self:save()
    self:apply_save_data()
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
