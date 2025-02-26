local BaseSpawnType = Object:extend("BaseSpawnType")
local BasicRandomSpawn = BaseSpawnType:extend("BasicRandomSpawn")


local spawn_type_table = {
	weights = {},
}

local function get_empty_spawn_positions()
	return {
		hazard = {},
		enemy = {},
		pickup = {},
		all = {},
	}
end

function BaseSpawnType:new(spawn_info)
	--[[
	{
		room_width = 100,
		room_height = 100,
		player_position = {
			x = 0,
			y = 0,
		},
		spawn_types = {
			enemy = {
				enemy_type = weight,
				...
			},
			hazard = {
				hazard_type = weight,
				...
			},
			pickup = {
				pickup_type = weight,
				...
			},
		},
		spawns_left = {
			Walker = 999999,
			Shielder = 1,
			...
		}
		num_enemies = 10,
		num_hazards = 10,
		num_pickups = 10,
	}
	]]
    self.spawn_info = spawn_info
end

function BaseSpawnType:spawn()
end

function BasicRandomSpawn:new(room)
    BasicRandomSpawn.super.new(self, room)
end

function BasicRandomSpawn:spawn()
    self.spawn_positions = get_empty_spawn_positions()
	local spawn_positions = self.spawn_positions

	local pickup_types, pickup_weights = table.keys_and_values(self.spawn_info.spawn_types.pickup)
	local enemy_types, enemy_weights = table.keys_and_values(self.spawn_info.spawn_types.enemy)
	local hazard_types, hazard_weights = table.keys_and_values(self.spawn_info.spawn_types.hazard)

	print("spawn pickup")
    for _ = 1, self.spawn_info.num_pickups do
        local x, y = self:get_valid_spawn_position("pickup")
        local pickup = rng.weighted_choice_array(pickup_types, pickup_weights)
        local tab = { x = x, y = y, type = pickup }
        if tab.type == nil then
			error("pickup is nil: " .. pickup.name)
		end
		table.insert(spawn_positions.pickup, tab)
        table.insert(spawn_positions.all, tab)
        self.spawn_info.spawns_left[pickup] = self.spawn_info.spawns_left[pickup] - 1
		if self.spawn_info.spawns_left[pickup] <= 0 then
            -- self.spawn_info.spawn_types.pickup[pickup] = nil
			print("no more spawns left for pickup " .. pickup.name)
			local i = table.find(pickup_types, pickup)
            table.remove(pickup_types, i)
			table.remove(pickup_weights, i)
		end
	end
	
	print("spawn hazard")
    for _ = 1, self.spawn_info.num_hazards do
		local x, y = self:get_valid_spawn_position("hazard")
		local hazard = rng.weighted_choice_array(hazard_types, hazard_weights)
        local tab = { x = x, y = y, type = hazard.class }
		if tab.type == nil then
			error("hazard is nil: " .. hazard.name)
		end
		table.insert(spawn_positions.hazard, tab)
		table.insert(spawn_positions.all, tab)
		self.spawn_info.spawns_left[hazard] = self.spawn_info.spawns_left[hazard] - 1
		if self.spawn_info.spawns_left[hazard] <= 0 then
            -- self.spawn_info.spawn_types.hazard[hazard] = nil
            print("no more spawns left for hazard " .. hazard.name)
			local i = table.find(hazard_types, hazard)
            table.remove(hazard_types, i)
			table.remove(hazard_weights, i)
		end
	end

	print("spawn enemy")
    for _ = 1, self.spawn_info.num_enemies do
        local x, y = self:get_valid_spawn_position("enemy")
        local enemy = rng.weighted_choice_array(enemy_types, enemy_weights)

        local tab = { x = x, y = y, type = enemy.class }
		if tab.type == nil then
			error("enemy is nil: " .. enemy.name)
		end
        table.insert(spawn_positions.enemy, tab)
        table.insert(spawn_positions.all, tab)
		self.spawn_info.spawns_left[enemy] = self.spawn_info.spawns_left[enemy] - 1
		if self.spawn_info.spawns_left[enemy] <= 0 then
            -- self.spawn_info.spawn_types.enemy[enemy] = nil
			print("no more spawns left for enemy " .. enemy.name)
			local i = table.find(enemy_types, enemy)
            table.remove(enemy_types, i)
			table.remove(enemy_weights, i)
		end
    end
	
	return spawn_positions
end

function BasicRandomSpawn:get_valid_spawn_position(_type)
	local MIN_DISTANCE_BETWEEN_ENEMIES = 16
	local SPAWN_ON_PLAYER_AT_THIS_DISTANCE = 80

    local x, y = 0, 0
    local c = 0
	local spawned_on_player = false
    if not self.spawned_on_player and rng.percent(5) and vec2_distance(0, 0, self.spawn_info.player_position.x, self.spawn_info.player_position.y) > SPAWN_ON_PLAYER_AT_THIS_DISTANCE then	
        x = self.spawn_info.player_position.x
		y = self.spawn_info.player_position.y
        spawned_on_player = true
	end
    while vec2_distance(x, y, 0, 0) < 32 do
        if c > 0 then
            spawned_on_player = false
        end
        -- while vec2_distance(x, y, self.spawn_info.player_position.x, self.spawn_info.player_position.y) < 32 do
        x = rng.randi_range(-self.spawn_info.room_width / 2, self.spawn_info.room_width / 2)
        y = rng.randi_range(-self.spawn_info.room_height / 2, self.spawn_info.room_height / 2)
        for i = 1, 100 do
            local valid = true
            for _, position in ipairs(self.spawn_positions.all) do
                if vec2_distance(x, y, position.x, position.y) < MIN_DISTANCE_BETWEEN_ENEMIES then
                    valid = false
                    x = rng.randi_range(-self.spawn_info.room_width / 2, self.spawn_info.room_width / 2)
                    y = rng.randi_range(-self.spawn_info.room_height / 2, self.spawn_info.room_height / 2)
                    break
                end
            end
            if valid then
                break
            end
        end
        c = c + 1
        if c > 100 then
            print("failed to find valid spawn position")
			break
        end
    end
	if spawned_on_player then
		self.spawned_on_player = true
	end
	return x, y
end

local function add_to_spawn_type_table(spawn_type, weight)
	spawn_type_table.weights[spawn_type] = weight
    spawn_type_table[spawn_type.__class_type_name] = spawn_type
end

add_to_spawn_type_table(BasicRandomSpawn, 1000)

return spawn_type_table
