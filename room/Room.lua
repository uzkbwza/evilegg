local Room = Object:extend("Room")
local SpawnTypeTable = require("room.SpawnType")
local RoomType = require("room.RoomType")
local BasePickup = require("obj.Pickup.BasePickup")
local EnemyDataTable = require("obj.enemy_data")

-- Room configuration constants
local ROOM_PADDING = 20
local BULLET_BOUNDS_PADDING = 20

-- Maximum values for different entity types
local MAX_ENEMY_TYPES = 12
local MAX_HAZARDS = 30
local MAX_PICKUPS = 10
local MAX_WAVES = 3
local MAX_HAZARD_TYPES = 4
local MAX_PICKUP_TYPES = 3

local SPAWN_VARIANCE = 2

Room.max_enemies = 50

function Room:new(world, level, difficulty)
	-- Store basic room properties
	self.world = world
	self.level = level
	self.difficulty = difficulty
	
	-- Calculate room dimensions
	local room_width = conf.room_size.x
	local room_height = conf.room_size.y
	self.wave = 1
	
	-- Calculate room boundaries with padding
	self.left = -room_width / 2 + ROOM_PADDING
	self.right = room_width / 2 - ROOM_PADDING
	self.top = -room_height / 2 + ROOM_PADDING
	self.bottom = room_height / 2 - ROOM_PADDING
	
	-- Store padded dimensions
	self.room_width = room_width - ROOM_PADDING * 2
	self.room_height = room_height - ROOM_PADDING * 2
	
	-- Create boundary rectangles
	self.bounds = Rect(self.left, self.top, self.right, self.bottom)
	self.bullet_bounds = Rect(
		self.left - BULLET_BOUNDS_PADDING, 
		self.top - BULLET_BOUNDS_PADDING,
		self.room_width + BULLET_BOUNDS_PADDING * 2, 
		self.room_height + BULLET_BOUNDS_PADDING * 2
	)
	
	self.padding = ROOM_PADDING
	self.possible_spawns = self:get_possible_spawns()
	self.number_of_waves = self:get_number_of_waves()
	print("waves: " .. self.number_of_waves)
	self.last_wave = self.number_of_waves
end

function Room:spawn_wave()
	self.possible_spawns = self:get_possible_spawns()

	local spawner = self:get_spawner()
	return spawner:spawn()
end

function Room:get_spawner()
	-- Select spawn type based on weights
	local spawn_type = rng.weighted_choice_dict(SpawnTypeTable.weights)
	return spawn_type(self:get_spawn_info())
end

function Room:get_spawn_info()
    print("num enemies", self:get_num_enemies())
	local spawn_types, spawns_left = self:get_current_wave_spawn_weights()
	return {
		room_width = self.room_width,
		room_height = self.room_height,
		player_position = self.world.last_player_pos and self.world.last_player_pos:clone() or Vec2(0, 0),
		num_enemies = self:get_num_enemies(),
		num_hazards = self:get_num_hazards(),
		num_pickups = 0, -- self:get_num_pickups(),
		spawn_types = spawn_types,
		spawns_left = spawns_left,
	}
end

function Room:get_spawn_counts()

end

function Room:get_current_wave_spawn_weights()
	local spawn_types = {
		enemy = {},
		hazard = {},
		pickup = {},
    }
	
	local spawns_left = {

	}
	
	-- Handle enemy spawns
	local any_valid = false
	local valid_spawn_types = {}

	-- Debug logging for possible enemies
	print("possible enemies:")
	for _, v in ipairs(self.possible_spawns.enemy) do
		print(v.name)
	end

	-- Find valid enemy spawn types
	for _, v in ipairs(self.possible_spawns.enemy) do
		if self:is_valid_wave_spawn_type(v) then
			any_valid = true
			table.insert(valid_spawn_types, v)
			print("valid enemy spawn type found: " .. v.name)
		end
	end
	
	if not any_valid then
		print("failed to find valid enemy spawn type, none are valid")
	end

	print("number of valid spawn types: " .. #valid_spawn_types)

	-- Select enemy types for this wave
	for i = 1, self:get_number_of_wave_enemy_types() do
		print("getting enemy type " .. i .. " for wave " .. self.wave)

		if #valid_spawn_types == 0 then
			print("no possible spawns for enemy " .. i)
			break
		end

		local spawn_type = rng.choose(valid_spawn_types)
		
		-- Find valid spawn type
		local c = 0
		while any_valid and (not spawn_types.enemy[spawn_type] or (not self:is_valid_wave_spawn_type(spawn_type))) do
			spawn_type = rng.choose(valid_spawn_types)
			c = c + 1
			if c > 100 then
				print("failed to find valid enemy wave spawn type, looped too many times")
				break
			end
		end

		print("enemy type: " .. spawn_type.name)
		-- Calculate final weight for this enemy type
		spawn_types.enemy[spawn_type] = self:get_spawn_type_weight(spawn_type) * spawn_type.room_spawn_weight
		spawns_left[spawn_type] = spawn_type.max_spawns + (self.difficulty - 1)
		table.erase(valid_spawn_types, spawn_type)
	end

	-- Handle hazard spawns
	print("possible hazards:")
	for _, v in ipairs(self.possible_spawns.hazard) do
		print(v.name)
	end

	for i = 1, self:get_number_of_wave_hazard_types() do
		local spawn_type = rng.choose(self.possible_spawns.hazard)
		local c = 0
		
		-- Find valid hazard spawn type
		while not self:is_valid_wave_spawn_type(spawn_type) do
			spawn_type = rng.choose(self.possible_spawns.hazard)
			c = c + 1
			if c > 100 then
				print("failed to find valid hazard wave spawn type, looped too many times")
				break
			end
		end
		
		-- Calculate final weight for this hazard type
		spawn_types.hazard[spawn_type] = self:get_spawn_type_weight(spawn_type) * spawn_type.room_spawn_weight
		spawns_left[spawn_type] = spawn_type.max_spawns + (self.difficulty - 1)
	end

	-- Handle pickup spawns
    for i = 1, self:get_number_of_wave_pickup_types() do
        local spawn_type = rng.choose(self.possible_spawns.pickup)
        spawn_types.pickup[spawn_type] = 1
        spawns_left[spawn_type] = 999999
    end

	return spawn_types, spawns_left
end

function Room:get_number_of_waves()
	-- Base number of waves plus bonuses
	local base_waves = 3
	local level_bonus = self.level / 2.5
	local difficulty_bonus = (self.difficulty - 1) * 5
	
	-- Calculate total waves and clamp between 3 and MAX_WAVES + difficulty bonus
	local total = base_waves + level_bonus + difficulty_bonus
	return floor(max(min(total, MAX_WAVES + (self.difficulty - 1)), 3))
end

function Room:get_number_of_wave_enemy_types()
	local base = 2
	local level_bonus = self.level - 1
	local difficulty_bonus = self.difficulty - 1
	return min(base + level_bonus + difficulty_bonus, MAX_ENEMY_TYPES)
end

function Room:get_number_of_wave_hazard_types()
	local base = 2
	local level_bonus = self.level - 1
	local difficulty_bonus = self.difficulty - 1
	return min(base + level_bonus + difficulty_bonus, MAX_HAZARD_TYPES)
end

function Room:get_number_of_wave_pickup_types()
	local base = 2
	local level_bonus = self.level - 1
	local difficulty_bonus = self.difficulty - 1
	return min(base + level_bonus + difficulty_bonus, MAX_PICKUP_TYPES)
end

function Room:get_number_of_enemy_types()
	-- Calculate maximum allowed amount
	local base = 1
	local level_bonus = self.level - 1
	local difficulty_bonus = self.difficulty - 1
	local amount = min(base + level_bonus + difficulty_bonus, MAX_ENEMY_TYPES, EnemyDataTable.max_level_by_type["enemy"])
	
	-- Return random number between half and full amount
	return amount
end

function Room:get_number_of_hazard_types()
	-- Calculate maximum allowed amount
	local base = 2
	local level_bonus = 0
	local difficulty_bonus = self.difficulty - 1
	local amount = min(base + level_bonus + difficulty_bonus, MAX_HAZARD_TYPES, EnemyDataTable.max_level_by_type["hazard"])
	
	-- Return random number between half and full amount
	return amount
end

function Room:get_num_enemies()
	-- Base number of enemies
	local base = 10
	local level_bonus = (self.level - 1) / 2
	
	-- Difficulty scaling with exponential and linear components
	local difficulty_exp = pow((self.difficulty - 1), 2)
	local difficulty_linear = (self.difficulty - 1) * 10
	
	-- Wave bonus that scales with level
	local wave_bonus = pow((self.wave - 1) * (3.5 + self.level / 40), 1.5)
	
	-- Calculate total and clamp to maximum
    local total = base + level_bonus + difficulty_exp + difficulty_linear + wave_bonus
	
	return round(min(total, Room.max_enemies))
end

function Room:get_num_hazards()
	-- Calculate components
	local base = 10
	local level_bonus = (self.level - 1) / 5
	local difficulty_bonus = self.difficulty - 1
	local wave_reduction = (self.wave - 1) * 2
	
	-- Calculate total and clamp to maximum
	return min(base + level_bonus + difficulty_bonus - wave_reduction, MAX_HAZARDS)
end

function Room:get_num_pickups()
	-- Only spawn pickups on first wave
	if self.wave > 1 then return 0 end
	
	-- Calculate total pickups and clamp to maximum
	local base = 5
	local level_bonus = self.level - 1
	local difficulty_bonus = self.difficulty - 1
	local wave_bonus = self.wave - 1
	
	return min(base + level_bonus + difficulty_bonus + wave_bonus, MAX_PICKUPS)
end

function Room:get_number_of_pickup_types()
	-- Calculate maximum allowed amount
	local base = 2
	local level_bonus = self.level - 1
	local difficulty_bonus = self.difficulty - 1
	local amount = min(base + level_bonus + difficulty_bonus, MAX_PICKUP_TYPES)
	
	-- Return random number between half and full amount
	return rng.randi_range(max(floor(amount / 2), 1), max(amount, 2))
end

function Room:get_spawn_type_weight(data)
	-- Calculate level ratio (how far from max level)
	local max_level = EnemyDataTable.max_level_by_type[data.type]
	local level_ratio = (max_level - data.level) / max_level
	
	-- Calculate weight components
	local base_weight = 1
	local level_bonus = pow(level_ratio, 2) * 10
	local random_mod = rng.randfn(1.0, 0.025)
	local difficulty_bonus = self.difficulty
	
	-- Return final weight (minimum of 1)
	return max(base_weight + level_bonus * random_mod + difficulty_bonus, 1)
end

function Room:get_possible_spawns()
	-- Calculate number of types for each category
	local number_of_enemy_types = floor(self:get_number_of_enemy_types())
	local number_of_hazard_types = floor(self:get_number_of_hazard_types())
	local number_of_pickup_types = floor(self:get_number_of_pickup_types())


	local spawn_types = {
		enemy = {},
		hazard = {},
		pickup = {},
	}
	

	local existing = self.possible_spawns ~= nil
	

	-- Select enemy types
	for i = 1, number_of_enemy_types do
		local enemy_type = self:get_random_possible_spawn_type("enemy", i)
		local c = 0
		while spawn_types.enemy[enemy_type] do
			enemy_type = self:get_random_possible_spawn_type("enemy", i)
			c = c + 1
			if c > 50 then
				print("failed to find valid enemy spawn type, looped too many times")
				break
			end
		end
		table.insert(spawn_types.enemy, enemy_type)
	end

    -- Select hazard types
	if not existing then
		for i = 1, number_of_hazard_types do
			local hazard_type = self:get_random_possible_spawn_type("hazard", i)
			local c = 0
			while spawn_types.hazard[hazard_type] do
				hazard_type = self:get_random_possible_spawn_type("hazard", i)
				c = c + 1
				if c > 50 then
					print("failed to find valid hazard spawn type, looped too many times")
					break
				end
			end
			table.insert(spawn_types.hazard, hazard_type)
		end
    else
		spawn_types.hazard = self.possible_spawns.hazard
	end
	
	-- Select pickup types
	for i = 1, number_of_pickup_types do
		local pickup_type = self:get_random_pickup_type()
		table.insert(spawn_types.pickup, pickup_type)
	end

	return spawn_types
end

function Room:get_spawn_level(type, type_index)
	return clamp(type_index, 1, EnemyDataTable.max_level_by_type[type])
	-- -- First type is always level 1
	-- if type_index == 1 then
	-- 	return 1
	-- end

	-- -- Get total number of types for this category
	-- local total_types = 0
	-- if type == "enemy" then
	-- 	total_types = self.number_of_enemy_types
	-- elseif type == "hazard" then
	-- 	total_types = self.number_of_hazard_types
	-- end

	-- -- Calculate maximum possible level
	-- local total_levels = max(total_types, (EnemyDataTable.max_level_by_type[type] or 0))
	-- local ratio = min(type_index / total_types, 1)

	-- -- Calculate level with difficulty scaling
	-- local difficulty_scale = max(3.0 - self.difficulty / 5, 0.1)
	-- local altered_ratio = pow(ratio, difficulty_scale) * self.number_of_enemy_types

	-- -- Calculate maximum allowed level based on player level and difficulty
	-- local max_allowed_level = min(
	-- 	EnemyDataTable.max_level_by_type[type], 
	-- 	self.level / 2 + (self.difficulty - 1) * 5
	-- )
	
	-- -- Clamp result and ensure smooth level progression
	-- local result = round(clamp(altered_ratio, 1, max_allowed_level))
	
	-- if result >= 3 and type_index >= 2 then
	-- 	local one_ago = self:get_spawn_level(type, type_index - 1)
	-- 	if result - one_ago > 1 then
	-- 		result = one_ago + 1
	-- 	end
	-- end

	-- return result
end

function Room:is_valid_wave_spawn_type(data)
	-- Only allow initial wave spawns on first wave
	if self.wave > 1 then
		if data.initial_wave_only then return false end
	end
	
	return true
end

function Room:get_random_pickup_type()
	return BasePickup
end

function Room:is_valid_spawnable_enemy(enemy_type)
	return enemy_type.spawnable and enemy_type.min_level <= self.level
end

function Room:get_random_possible_spawn_type(type, type_index)
	-- Get appropriate level for this spawn type
	local level = self:get_spawn_level(type, type_index)
	print(type .. " level for index " .. type_index .. ": " .. level)
	
	-- Get all enemy types at this level
	local enemy_types = EnemyDataTable.data_by_type_then_level[type][level]
	if not enemy_types then
		error("no enemy types found for " .. type .. " at level " .. level)
	end

	-- Build arrays of valid types and their weights
	local values = {}
	local weights = {}
	
	for i, v in ipairs(enemy_types) do
		if self:is_valid_spawnable_enemy(v) then
			table.insert(values, v)
			-- Calculate weight with difficulty bonus
			local base_weight = v.room_select_weight
			local difficulty_bonus = (self.difficulty - 1) * (EnemyDataTable.data["BaseEnemy"].room_select_weight / 2)
			local weight = base_weight + difficulty_bonus
			table.insert(weights, weight)
			print(v.name .. " weight: " .. weight)
		end
	end

	return rng.weighted_choice_array(values, weights)
end

function Room:initialize()
end

return Room
