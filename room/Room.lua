local Room = Object:extend("Room")
local SpawnTypeTable = require("room.SpawnType")
local BasePickup = require("obj.Pickup.BasePickup")
local EnemyDataTable = require("obj.enemy_data")

Room.padding = 20
Room.bullet_bounds_padding = 20
Room.target_wave_count = 3
Room.history_size = 1

function Room:new(world, level, difficulty, level_history)
	-- Store basic room properties
	self.world = world
	self.level = level
	self.difficulty = difficulty
	
	self.wave = 1

	-- Calculate room dimensions
	local room_width = conf.room_size.x
	local room_height = conf.room_size.y

	
	-- Calculate room boundaries with padding
	self.left = -room_width / 2 + Room.padding
	self.right = room_width / 2 - Room.padding
	self.top = -room_height / 2 + Room.padding
	self.bottom = room_height / 2 - Room.padding
	
	-- Store padded dimensions
	self.room_width = room_width - Room.padding * 2
	self.room_height = room_height - Room.padding * 2
	
	-- Create boundary rectangles
	self.bounds = Rect(self.left, self.top, self.right, self.bottom)
	self.bullet_bounds = Rect(
		self.left - Room.bullet_bounds_padding, 
		self.top - Room.bullet_bounds_padding,
		self.room_width + Room.bullet_bounds_padding * 2, 
		self.room_height + Room.bullet_bounds_padding * 2
	)
	
    self.padding = Room.padding

	self.all_spawn_types = {}
	self.redundant_spawns = {}

	level_history = level_history or {}

    while #level_history > Room.history_size do
        table.remove(level_history, 1)
    end

    self.level_history = level_history
	table.insert(self.level_history, self)
end

function Room:build()
    self.waves = self:generate_waves()
    self.last_wave = #self.waves
end

function Room:spawn_wave()
	local wave = self.waves[self.wave]
    return wave
end

function Room:generate_enemy_pool()
	local pool = {}
    for i = 1, EnemyDataTable.max_level_by_type["enemy"] do
        local enemy = self:get_random_spawn_with_type_and_level("enemy", i)
		if enemy ~= nil then
			table.insert(pool, enemy)
		end
    end
	return pool
end

function Room:generate_hazard_pool()
    local pool = {}
    for i = 1, EnemyDataTable.max_level_by_type["hazard"] do	
        local hazard = self:get_random_spawn_with_type_and_level("hazard", i)
		if hazard ~= nil then
			table.insert(pool, hazard)
		end
    end
    return pool
end

function Room:get_random_spawn_with_type_and_level(type, level, wave)
	wave = wave or 1
	local spawn_dict = EnemyDataTable.data_by_type_then_level[type][level]
	local spawns = {}
	local weights = {}
	for _, spawn in pairs(spawn_dict) do
        if not spawn.spawnable then goto continue end
		if spawn.min_level and self.level < spawn.min_level then goto continue end
        if spawn.max_level and self.level > spawn.max_level then goto continue end
		if spawn.level > max(self.level * 1.2, 2) then goto continue end
        if spawn.initial_wave_only and wave ~= 1 then goto continue end
		local weight = spawn.room_select_weight
        
        local redundant = false
		if self.redundant_spawns[spawn] then
			redundant = true
		end
		
		if not redundant then
			for _, room in pairs(self.level_history) do
				if room.all_spawn_types[spawn] then
					redundant = true
					break
				end
			end
		end
        if redundant then
			-- print("redundant spawn: " .. spawn.name)
			weight = 1
		end

		table.insert(spawns, spawn)
		table.insert(weights, weight)
		::continue::
	end

	if #spawns == 0 then
		return nil
	end

	local spawn = rng.weighted_choice_array(spawns, weights)
	return spawn
end

function Room:pool_point_modifier()
	return 1 + ((self.level - 1)) * 0.15
end

function Room:generate_waves()
    local narrative_weights = {
        narratives = {},
        weights = {},
    }
	
    for _narrative_name, narrative in pairs(Room.narrative_types) do
        if narrative.min_level and self.level < narrative.min_level then goto continue end
        if narrative.max_level and self.level > narrative.max_level then goto continue end
        if narrative.min_wave and self.wave < narrative.min_wave then goto continue end
        if narrative.max_wave and self.wave > narrative.max_wave then goto continue end
 
        table.insert(narrative_weights.narratives, narrative)
        table.insert(narrative_weights.weights, narrative.weight)

        ::continue::
    end

    local waves = {}
    local enemy_pool = self:generate_enemy_pool()
	local hazard_pool = self:generate_hazard_pool()

    local function get_random_narrative()
        if debug.enabled then
			if Room.narrative_types.debug_enemy.enabled then
				return Room.narrative_types.debug_enemy
			end
		end
        return rng.weighted_choice_array(narrative_weights.narratives, narrative_weights.weights)
    end

    local wave_types = {
        pool_point_buy = function(narrative, pool, wave)
            local max_difficulty = narrative.max_difficulty or math.huge

            local weights = {}
			for _, enemy in pairs(pool) do
				table.insert(weights, 10000 / enemy.spawn_points)
			end

            local num_points = narrative.points * self:pool_point_modifier()
            while num_points > 0 do
                local enemy = rng.weighted_choice_array(pool, weights)
                if enemy.level <= max_difficulty then
					num_points = num_points - enemy.spawn_points
					table.insert(wave, enemy)
				end
            end
        end,

		specific_enemy = function(narrative, pool, wave)
			for i = 1, narrative.count do
				table.insert(wave, EnemyDataTable[narrative.enemy])
			end
		end,
		
		hazard_pool_point_buy = function(pool, wave)
            local weights = {}
			for _, enemy in pairs(pool) do
				table.insert(weights, 10000 / enemy.spawn_points)
			end

            local num_points = 100 * self:pool_point_modifier()
            while num_points > 0 do
                local hazard = rng.weighted_choice_array(pool, weights)
                num_points = num_points - hazard.spawn_points
				table.insert(wave, hazard)
            end
		end
	}

    local function process_narrative(narrative)
        local sub_narratives = narrative.sub_narratives
		local wave_number = 1
        for i = 1, #sub_narratives do
            local sub_narrative = sub_narratives[i]
            if wave_types[sub_narrative.type] ~= nil then
                local pool_modification_chance_per_enemy = sub_narrative.pool_modification_chance_per_enemy or 0.1

                for j = 1, #enemy_pool do
                    local enemy = enemy_pool[j]
                    if rng.chance(pool_modification_chance_per_enemy) then
                        enemy = self:get_random_spawn_with_type_and_level("enemy", enemy.level, wave_number)
                    end

                    if wave_number > 1 and enemy ~= nil and enemy.initial_wave_only then
                        enemy = self:get_random_spawn_with_type_and_level("enemy", enemy.level, wave_number)
                    end

					if enemy ~= nil then
						enemy_pool[j] = enemy
					end
                end
				
                for j = 1, #hazard_pool do
					local hazard = hazard_pool[j]
                    if rng.chance(pool_modification_chance_per_enemy) then
                        hazard = self:get_random_spawn_with_type_and_level("hazard", hazard.level, wave_number)
                    end

                    if wave_number > 1 and hazard ~= nil and hazard.initial_wave_only then
                        hazard = self:get_random_spawn_with_type_and_level("hazard", hazard.level, wave_number)
                    end

					if hazard ~= nil then
						hazard_pool[j] = hazard
					end
				end

                local wave = {
					number = wave_number,
                    enemy = {},
					hazard = {},
                }
				
				if not sub_narrative.disable_hazards then
					wave_types.hazard_pool_point_buy(hazard_pool, wave.hazard)
				end

                wave_types[sub_narrative.type](sub_narrative, enemy_pool, wave.enemy)
				table.insert(waves, wave)
				wave_number = wave_number + 1
				for _, enemy in pairs(wave.enemy) do
					self.all_spawn_types[enemy] = true
				end
				for _, hazard in pairs(wave.hazard) do
					self.all_spawn_types[hazard] = true
				end
			else
				error("unknown narrative wave type: " .. sub_narrative.type)
			end
		end
	end

	while #waves < Room.target_wave_count do
        local narrative = get_random_narrative()
		process_narrative(narrative)
	end

	return waves
end


Room.narrative_types = {
    debug_enemy = {
        weight = 0,
        enabled = false,
		sub_narratives = {
			[1] = {
				disable_hazards = true,
                type = "specific_enemy",
                enemy = "Turret",
				count = 10,
            },
		}
	},

    basic = {
		weight = 10000,
		tags = {},
		sub_narratives = {
			[1] = {
                type = "pool_point_buy",
				points = 200,
				max_difficulty = 3,
            },
			[2] = {
				type = "pool_point_buy",
				points = 300,
                max_difficulty = 4,
            },
			[3] = {
				type = "pool_point_buy",
				points = 400,
            },
		}
    },
	
    -- basic_boss = {
    --     weight = 10000,
	-- 	tags = {},
	-- 	sub_narratives = {
	-- 		[1] = {
    --             type = "pool_point_buy",
	-- 			points = 250,
	-- 			max_difficulty = 2,
	-- 		},
	-- 		[2] = {
	-- 			type = "pool_point_buy",
	-- 			points = 300,
	-- 			max_difficulty = 4,
	-- 		},
	-- 		[3] = {
	-- 			type = "pool_point_buy",
	-- 			points = 300,
	-- 			boss = true,
	-- 		},
	-- 	}
	-- },	
}

return Room
