local enemy_table = filesystem.get_modules("obj/Spawn")

local SpawnDataTable = {
    data = require("obj.spawn_data_table"),
    data_by_type_then_level = {},
    data_by_level_then_type = {},
	data_by_type = {},
    data_by_level = {},
    max_level_by_type = {},
}

local function process_enemy_table(t)
    for _, value in pairs(t) do
        if Object.is(value, Object) then
            local name = value.__class_type_name
            if SpawnDataTable[name] then
                error("duplicate enemy name: " .. name .. " and " .. value.__class_type_name)
            end
            if SpawnDataTable.data[name] then
				-- if not SpawnDataTable[name] then
				-- 	error("no enemy data found for " .. name)
				-- end
                -- error("no enemy data found for " .. name)
				SpawnDataTable[name] = value
                -- SpawnDataTable[value] = SpawnDataTable[name]
                SpawnDataTable.data[name].class = SpawnDataTable[name]
				SpawnDataTable[name].spawn_data = SpawnDataTable.data[name]
            else
				print("no enemy data found for " .. name)
            end

        elseif type(value) == "table" and not Object.is(value, Object) then
            process_enemy_table(value)
        end
    end
end

local function process_spawn_data(t, name)
    local data = {}
	table.merge(data, table.deepcopy(SpawnDataTable.data["BaseSpawn"]))
    if t and t.inherit then
		if type(t.inherit) == "string" then
			table.merge(data, table.deepcopy(process_spawn_data(SpawnDataTable.data[t.inherit], tostring(t))))
		elseif type(t.inherit) == "table" then
            for i = #t.inherit, 1, -1 do
				if not SpawnDataTable.data[t.inherit[i]] then
					error(tostring(name) .. " tried to inherit from " .. t.inherit[i] .. " but no enemy data found for " .. t.inherit[i])
				end
				local inherit_data = table.deepcopy(process_spawn_data(SpawnDataTable.data[t.inherit[i]], tostring(t)))
				table.merge(data, inherit_data)
			end
		end
	end

    for k, v in pairs(t) do
        data[k] = v
    end
	
	data.name = name
	
	return data
end

for k, v in pairs(SpawnDataTable.data) do
    local data = process_spawn_data(v, k)


    SpawnDataTable.data_by_type[data.type] = SpawnDataTable.data_by_type[data.type] or {}
    SpawnDataTable.data_by_type_then_level[data.type] = SpawnDataTable.data_by_type_then_level[data.type] or {}
    SpawnDataTable.data_by_type_then_level[data.type][data.level] = SpawnDataTable.data_by_type_then_level[data.type]
    [data.level] or {}
    table.insert(SpawnDataTable.data_by_type[data.type], data)
    table.insert(SpawnDataTable.data_by_type_then_level[data.type][data.level], data)

    SpawnDataTable.data_by_level[data.level] = SpawnDataTable.data_by_level[data.level] or {}
    SpawnDataTable.data_by_level_then_type[data.level] = SpawnDataTable.data_by_level_then_type[data.level] or {}
    SpawnDataTable.data_by_level_then_type[data.level][data.type] = SpawnDataTable.data_by_level_then_type[data.level]
    [data.type] or {}
    table.insert(SpawnDataTable.data_by_level[data.level], data)
    table.insert(SpawnDataTable.data_by_level_then_type[data.level][data.type], data)

    if not SpawnDataTable.max_level_by_type[data.type] then
        SpawnDataTable.max_level_by_type[data.type] = data.level
    else
        SpawnDataTable.max_level_by_type[data.type] = max(SpawnDataTable.max_level_by_type[data.type], data.level)
    end

    SpawnDataTable.data[k] = data
end

local mt = {
    __index = function(self, key)
        local value = rawget(self, key)
        if value == nil then
            error("no key found in enemy data table: " .. key, 2)
        end
		return value
	end
}


for key, value in pairs(SpawnDataTable.max_level_by_type) do
    for i = 1, value do
        if not SpawnDataTable.data_by_level[i] then
            error("no " .. key .. " data found for level " .. i .. " despite max_level_by_type being " .. value)
        end
    end
end

SpawnDataTable.data["BaseSpawn"].spawnable = false

for _, enemy in pairs(SpawnDataTable.data_by_type["enemy"]) do
    if enemy.score_override then
        enemy.score = enemy.score_override
    else
        enemy.score = ((enemy.spawn_points)) * 10
        if enemy.extra_score then
            enemy.score = enemy.score + enemy.extra_score
        end
    end

	print(string.format("%16s: %-10d", enemy.name, enemy.score))
end

process_enemy_table(enemy_table)

setmetatable(SpawnDataTable, mt)

return SpawnDataTable
