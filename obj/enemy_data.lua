local BaseEnemy = require("obj.Enemy.BaseEnemy")
local enemy_table = filesystem.get_modules("obj/Enemy")

local EnemyDataTable = {
    data = require("obj.enemy_data_table"),
    data_by_type_then_level = {},
    data_by_level_then_type = {},
	data_by_type = {},
    data_by_level = {},
    max_level_by_type = {},
}

local function process_enemy_table(t)
    for _, value in pairs(t) do
        if Object.is(value, BaseEnemy) then
            local name = value.__class_type_name
            if EnemyDataTable[name] then
                error("duplicate enemy name: " .. name .. " and " .. value.__class_type_name)
            end
            if EnemyDataTable.data[name] then
				-- if not EnemyDataTable[name] then
				-- 	error("no enemy data found for " .. name)
				-- end
                -- error("no enemy data found for " .. name)
				EnemyDataTable[name] = value
                -- EnemyDataTable[value] = EnemyDataTable[name]
                EnemyDataTable.data[name].class = EnemyDataTable[name]
            else
				print("no enemy data found for " .. name)
            end

        elseif type(value) == "table" and not Object.is(value, Object) then
            process_enemy_table(value)
        end
    end
end

local function process_enemy_data(t, name)
    local data = {}
	table.merge(data, table.deepcopy(EnemyDataTable.data["BaseEnemy"]))
    if t and t.inherit then
		if type(t.inherit) == "string" then
			table.merge(data, table.deepcopy(process_enemy_data(EnemyDataTable.data[t.inherit], tostring(t))))
		elseif type(t.inherit) == "table" then
            for i = #t.inherit, 1, -1 do
				if not EnemyDataTable.data[t.inherit[i]] then
					error(tostring(name) .. " tried to inherit from " .. t.inherit[i] .. " but no enemy data found for " .. t.inherit[i])
				end
				local inherit_data = table.deepcopy(process_enemy_data(EnemyDataTable.data[t.inherit[i]], tostring(t)))
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

for k, v in pairs(EnemyDataTable.data) do
    local data = process_enemy_data(v, k)
    
	
	EnemyDataTable.data_by_type[data.type] = EnemyDataTable.data_by_type[data.type] or {}
    EnemyDataTable.data_by_type_then_level[data.type] = EnemyDataTable.data_by_type_then_level[data.type] or {}
	EnemyDataTable.data_by_type_then_level[data.type][data.level] = EnemyDataTable.data_by_type_then_level[data.type][data.level] or {}
	table.insert(EnemyDataTable.data_by_type[data.type], data)
    table.insert(EnemyDataTable.data_by_type_then_level[data.type][data.level], data)
	
	EnemyDataTable.data_by_level[data.level] = EnemyDataTable.data_by_level[data.level] or {}
	EnemyDataTable.data_by_level_then_type[data.level] = EnemyDataTable.data_by_level_then_type[data.level] or {}
	EnemyDataTable.data_by_level_then_type[data.level][data.type] = EnemyDataTable.data_by_level_then_type[data.level][data.type] or {}
	table.insert(EnemyDataTable.data_by_level[data.level], data)
	table.insert(EnemyDataTable.data_by_level_then_type[data.level][data.type], data)

	if not EnemyDataTable.max_level_by_type[data.type] then
		EnemyDataTable.max_level_by_type[data.type] = data.level
	else
		EnemyDataTable.max_level_by_type[data.type] = max(EnemyDataTable.max_level_by_type[data.type], data.level)
	end
	
    EnemyDataTable.data[k] = data
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


for key, value in pairs(EnemyDataTable.max_level_by_type) do
    for i = 1, value do
        if not EnemyDataTable.data_by_level[i] then
            error("no " .. key .. " data found for level " .. i .. " despite max_level_by_type being " .. value)
        end
    end
end

EnemyDataTable.data["BaseEnemy"].spawnable = false


process_enemy_table(enemy_table)

setmetatable(EnemyDataTable, mt)

return EnemyDataTable
