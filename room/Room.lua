local Room = Object:extend("Room")
local BasePickup = require("obj.Spawn.Pickup.BasePickup")
local SpawnDataTable = require("obj.spawn_data")

local debug_force_enabled = false
local debug_force = "bonus_police"

local debug_enemy_enabled = false
local debug_enemy = "HoopSnake"
local num_debug_enemies = 1

Room.narrative_types = {
    debug_enemy = {
        debug_force = debug_enemy_enabled,
		enemy_spawn_group = "basic",
		hazard_spawn_group = "basic",
		
		is_debug = true,
        weight = 0,
		sub_narratives = {
			[1] = {
				disable_hazards = true,
                type = "specific_enemy",
                enemy = debug_enemy,
				count = num_debug_enemies,
            },
			[2] = {
				disable_hazards = true,
                type = "specific_enemy",
                enemy = debug_enemy,
				count = num_debug_enemies,
            },
			[3] = {
				disable_hazards = true,
                type = "specific_enemy",
                enemy = debug_enemy,
				count = num_debug_enemies,
            },
		}
	},

    basic_early = {
		weight = 1000,
        tags = {},
		enemy_spawn_group = "basic",
		hazard_spawn_group = "basic",
		max_level = 4,
		sub_narratives = {
			[1] = {
                type = "pool_point_buy",
				points = 50,
				max_difficulty = 3,
            },
			[2] = {
				type = "pool_point_buy",
				points = 100,
                max_difficulty = 4,
            },
			[3] = {
				type = "pool_point_buy",
				points = 175,
            },
		}
    },

	basic = {
		weight = 1000,
        tags = {},
		enemy_spawn_group = "basic",
        hazard_spawn_group = "basic",
		wave_pool_modification_chance = 0.05,

		min_level = 5,
		sub_narratives = {
			[1] = {
                type = "pool_point_buy",
				points = 75,
                max_difficulty = 3,
            },
			[2] = {
				type = "pool_point_buy",
				points = 125,
                max_difficulty = 4,
            },
			[3] = {
				type = "pool_point_buy",
				points = 200,
            },
		}
    },

    bonus_mono_enemy = {
        weight = 2000,
        bonus = true,
		enemy_spawn_group = "basic",
		hazard_spawn_group = "basic",
        tags = {},
		sub_narratives = {
			[1] = {
                type = "pool_point_buy",
				exclude_enemies = { "Walker", "Roamer", "Shielder", "Mortar", "Cultist", "Hand" },
                points = 100,
				disable_hazards = true,
                max_difficulty = 3,
				random_pool_size = 1,
			},
			[2] = {
				type = "pool_point_buy",
				exclude_enemies = { "Walker", "Roamer", "Shielder", "Mortar", "Cultist", "Hand" },
                points = 175,
				disable_hazards = true,
                max_difficulty = 4,
				random_pool_size = 1,
            },
			[3] = {
				type = "pool_point_buy",
				exclude_enemies = { "Walker", "Roamer", "Shielder", "Cultist", "Hand",  },
                points = 250,
				random_pool_size = 1,
            },
		}
    },
	
    -- basic_themed = {
	-- 	inherit = "basic",
	-- 	pick_random_enemy_spawn_group = true,
	-- 	enemy_spawn_group = { "bodypart" },
	-- },
	
    bonus_themed = {
        inherit = "basic",
		min_level = 1,
		weight = 1000,
		bonus = true,
        -- pick_random_enemy_spawn_group = true,
		-- use_random_enemy_spawn_group_for_hazards = true,
        -- enemy_spawn_group = { "bodypart" },
		selectable = false,
		sub_narratives = {
            [1] = {
				disable_hazards = true,
				points = 100,
            },
			[2] = {
				disable_hazards = true,
				points = 175,
            },
			[3] = {
				-- disable_hazards = true,
				points = 250,
            },
		}
	},

	bonus_exploder = {
        inherit = "bonus_themed",
        enemy_spawn_group = { "exploder" },
        hazard_spawn_group = { "exploder" },
        weight = 500,
		min_level = 5,
		sub_narratives = {
			[1] = {
				disable_hazards = false,
			},
        	[2] = {
				disable_hazards = false,
			},
		}
	},

    bonus_full_spawn_group = {
        inherit = "basic",
		selectable = false,
        -- enemy_spawn_group = { "bodypart" },
		-- hazard_spawn_group = { "bodypart" },
        enemy_use_full_spawn_group = true,
		-- hazard_use_full_spawn_group = true,
		weight = 500,
		bonus = true,
	},

	bonus_bodyparts = {
        inherit = "bonus_full_spawn_group",
		min_level = 7,
        enemy_spawn_group = { "bodypart" },
		-- debug_force = true,
        -- hazard_spawn_group = { "bodypart" },
		sub_narratives = {
            [1] = {
				disable_hazards = true,
			},
			[2] = {
				disable_hazards = true,
            },
			[3] = {

            },
		}
	},

	bonus_police = {
        inherit = "bonus_themed",
        enemy_spawn_group = { "police" },
        -- hazard_spawn_group = { "police" },
        weight = 500,
		min_level = 9,
		sub_narratives = {
			[1] = {
				disable_hazards = false,
			},
        	[2] = {
				disable_hazards = false,
			},
		}
	},

	
	
    -- basic_boss = {
    --     weight = 1000,
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

if debug_enemy_enabled then
	debug_force = "debug_enemy"
	debug_force_enabled = true
end

local function process_narrative_type(narrative_name, narrative)
	if narrative.processed then return end
    narrative.name = narrative_name
    if narrative.inherit then
        local parent = Room.narrative_types[narrative.inherit]
        if parent and not parent.processed then
			process_narrative_type(narrative.inherit, parent)
		end
        for k, v in pairs(parent) do
            if k == "sub_narratives" then
                if narrative.sub_narratives then
                    for i, sub_narrative in pairs(v) do
                        if narrative.sub_narratives[i] then
                            narrative.sub_narratives[i] = table.merged(sub_narrative, narrative.sub_narratives[i], true)
                        else
                            narrative.sub_narratives[i] = sub_narrative
                        end
                    end
                else
                    narrative[k] = table.deepcopy(v)
                end
            else
                if narrative[k] == nil and k ~= "selectable" then
                    narrative[k] = v
                end
            end
        end
    end
	narrative.processed = true
end

for narrative_name, narrative in pairs(Room.narrative_types) do
	process_narrative_type(narrative_name, narrative)
end

for k, narrative in pairs(Room.narrative_types) do
	if narrative.selectable == nil then
		narrative.selectable = true
	end
end


Room.horiz_padding = conf.room_padding.x
Room.vert_padding = conf.room_padding.y
Room.bullet_bounds_padding_x = max(Room.horiz_padding, 0) + 5
Room.bullet_bounds_padding_y = max(Room.vert_padding, 0) + 5
Room.target_wave_count = 3
Room.history_size = 1



function Room:new(world, level, difficulty, level_history, max_enemies, max_hazards)
	-- Store basic room properties
	self.world = world
	self.level = level
	self.difficulty = difficulty
	self.max_enemies = max_enemies
	self.max_hazards = max_hazards
	

	self.wave = 1
    self.elapsed = 0
    self.tick = 0

	-- Calculate room dimensions
	local room_width = conf.room_size.x
	local room_height = conf.room_size.y

	-- Calculate room boundaries with padding
	self.left = -room_width / 2
	self.right = room_width / 2
	self.top = -room_height / 2
	self.bottom = room_height / 2
	
	-- Store padded dimensions
	self.room_width = room_width
	self.room_height = room_height

	-- print(self.room_width, self.room_height)
	
	-- Create boundary rectangles
	self.bounds = Rect(self.left, self.top, self.right, self.bottom)
	self.bullet_bounds = Rect(
		self.left - Room.bullet_bounds_padding_x, 
		self.top - Room.bullet_bounds_padding_y,
		self.room_width + Room.bullet_bounds_padding_x * 2, 
		self.room_height + Room.bullet_bounds_padding_y * 2
	)
	
    -- self.padding = Room.padding

	self.all_spawn_types = {}
    self.redundant_spawns = {}

    self.needs_upgrade = false
	self.needs_artefact = false
	self.bonus_room = false

	self.rescues = {}


    self.total_enemy_score = 0
	self.total_rescue_score = 0

	level_history = level_history or {}

    while #level_history > Room.history_size do
        table.remove(level_history, 1)
    end

    self.level_history = level_history
	table.insert(self.level_history, self)
end

function Room:build(params)
	params = params or {}
    if params.bonus_room then
        self.bonus_room = true
        -- self.level = floor(self.level * 1.5) + 2
    end
    if params.needs_upgrade then
        self.needs_upgrade = true
    end
    if params.needs_artefact then
        self.needs_artefact = true
    end
    if params.needs_heart then
        self.needs_heart = true
    end
	if params.wants_heart then
		self.wants_heart = true
	end
	

    self.is_hard = self.level > 6 and rng.percent(6)
    if self.is_hard then
		self.level = self.level + clamp(floor(self.level * 0.5), 3, 20)
	end

	self.level = max(floor(self.level * (1 + game_state:get_difficulty_modifier())), self.level)

    self.waves, self.rescue_waves = self:generate_waves()
    self.last_wave = #self.waves
	for _, wave in pairs(self.waves) do
		for _, enemy in pairs(wave.enemy) do
			self.total_enemy_score = self.total_enemy_score + enemy.score
		end
	end

	for _, wave in pairs(self.rescue_waves) do
		for _, rescue in pairs(wave) do
			self.total_rescue_score = self.total_rescue_score + rescue.rescue.score
		end
	end

    self.total_score = self.total_enemy_score + self.total_rescue_score
	
	-- print("level generated at difficulty " .. self.level)
end

function Room:should_spawn_waves()
	return true
end

function Room:add_spawn_type(spawn_type)
	self.all_spawn_types[spawn_type] = self.all_spawn_types[spawn_type] or { count = 0 }
	self.all_spawn_types[spawn_type].count = self.all_spawn_types[spawn_type].count + 1
end

function Room:spawn_wave()
    local wave = self.waves[self.wave]
	local rescue_wave = self.rescue_waves[self.wave]
    return wave, rescue_wave
end

function Room:generate_rescue_pool()
	local pool = {}
	for i = 1, min(SpawnDataTable.max_level_by_type["rescue"], floor(max((self.level) / 2, 1))) do
		local rescue = self:get_random_spawn_with_type_and_level("rescue", i)
		if rescue ~= nil then
			table.insert(pool, rescue)
		end
	end
	return pool
end

function Room:generate_enemy_pool(narrative)

    if narrative.enemy_use_full_spawn_group then
        local pool = {}
		for _, spawn_group in pairs(narrative.enemy_spawn_group) do
			if SpawnDataTable.data_by_type_then_spawn_group["enemy"][spawn_group] then
				for _, spawn in pairs(SpawnDataTable.data_by_type_then_spawn_group["enemy"][spawn_group]) do
					if self:is_valid_spawn(spawn, narrative, 1) then
						table.insert(pool, spawn)
					end
				end
			end
		end
		return pool
	end

	if narrative["pick_random_enemy_spawn_group"] then
        narrative.enemy_spawn_group = { rng.choose(narrative.enemy_spawn_group) }
    end

	
	
    local pool = {}
	
    for i = 1, SpawnDataTable.max_level_by_type["enemy"] do
        local enemy = self:get_random_spawn_with_type_and_level("enemy", i, nil, narrative)
		if enemy ~= nil then
			table.insert(pool, enemy)
		end
    end
	return pool
end

function Room:generate_hazard_pool(narrative)

	if narrative.hazard_use_full_spawn_group then
        local pool = {}
        for _, spawn_group in pairs(narrative.hazard_spawn_group) do
			if SpawnDataTable.data_by_type_then_spawn_group["hazard"][spawn_group] then
				for _, spawn in pairs(SpawnDataTable.data_by_type_then_spawn_group["hazard"][spawn_group]) do
					if self:is_valid_spawn(spawn, narrative, 1) then
						table.insert(pool, spawn)
					end
				end
			end
		end
		return pool
	end
	
	if narrative["pick_random_enemy_spawn_group"] then
		if narrative.use_random_enemy_spawn_group_for_hazards then 
			narrative.hazard_spawn_group = narrative.enemy_spawn_group
		end
    end

	local pool = {}
    for i = 1, SpawnDataTable.max_level_by_type["hazard"] do	
        local hazard = self:get_random_spawn_with_type_and_level("hazard", i, nil, narrative)
		if hazard ~= nil then
			table.insert(pool, hazard)
		end
    end
    return pool
end

function Room:is_valid_spawn(spawn, narrative, wave)
	wave = wave or 1
	if not spawn.spawnable then return false end
	if spawn.min_level and self.level < spawn.min_level then return false end
	if spawn.max_level and self.level > spawn.max_level then return false end
	if spawn.level > max((self.level + 1) * 0.75, 2) then return false end
	if spawn.initial_wave_only and wave ~= 1 then return false end
	return true
end

function Room:get_random_spawn_with_type_and_level(spawn_type, level, wave, narrative) 
    wave = wave or 1
	
	-- local min_level = narrative and narrative.min_level or 1
	-- local max_level = narrative and narrative.max_level or SpawnDataTable.max_level_by_type[spawn_type]

	-- if rng.percent(25) then
	-- 	level = rng.randi(min_level, max_level)
	-- end

	local spawns = {}
    local weights = {}
    local narrative_spawn_group = { "basic" }
	
	
    if narrative then
        narrative_spawn_group = narrative[spawn_type .. "_spawn_group"] or { "basic" }
    end
	
	if type(narrative_spawn_group) == "string" then
		narrative_spawn_group = { narrative_spawn_group }
	end
	
	local is_basic = false
    for i = 1, #narrative_spawn_group do
        if narrative_spawn_group[i] == "basic" then
            is_basic = true
            break
        end
    end
	
    local spawn_dict = {}
	
    for _, spawn_group in pairs(narrative_spawn_group) do
		local possible_spawns = SpawnDataTable.data_by_type_then_spawn_group_then_level[spawn_type][spawn_group]
		if possible_spawns and possible_spawns[level] then
			table.merge(spawn_dict, possible_spawns[level])
		end
	end
	
    for _, spawn in pairs(spawn_dict) do
		local valid = self:is_valid_spawn(spawn, narrative, wave)
		if not valid then
			goto continue
		end

		local weight = spawn.room_select_weight

		if is_basic and spawn.basic_select_weight_modifier then
			weight = weight * (spawn.basic_select_weight_modifier)
		end

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

	local spawn = rng.weighted_choice(spawns, weights)
	return spawn
end

function Room:pool_point_modifier()
	-- return 1 + ((self.level - 1)) * 0.125 + floor((self.level - 1) / 10) * 0.01
	return 1 + ((self.level - 1)) * 0.12 + floor((self.level - 1) / 10) * 0.5
end

function Room:generate_waves()
    local narrative_weights = {
        narratives = {},
        weights = {},
    }
	
    for _narrative_name, narrative in pairs(Room.narrative_types) do
		-- print(_narrative_name)
		if not narrative.selectable then goto continue end
        if narrative.min_level and self.level < narrative.min_level then goto continue end
        if narrative.max_level and self.level > narrative.max_level then goto continue end
        if narrative.min_wave and self.wave < narrative.min_wave then goto continue end
        if narrative.max_wave and self.wave > narrative.max_wave then goto continue end
        if narrative.bonus and not self.bonus_room then goto continue end
		if not narrative.bonus and self.bonus_room then goto continue end
        if narrative.is_debug then goto continue end
	
        table.insert(narrative_weights.narratives, narrative)
        table.insert(narrative_weights.weights, narrative.weight)

        ::continue::
    end

    local waves = {}
	local rescue_waves = {}
    local enemy_pool = {}
	local hazard_pool = {}

    local function get_random_narrative()
        if debug.enabled then
			-- for _, narrative in pairs(Room.narrative_types) do
			-- 	if narrative.debug_force then
			-- 		return narrative
			-- 	end
            -- end
            if debug_force_enabled then
				return Room.narrative_types[debug_force]
			end
		end
        return table.deepcopy(rng.weighted_choice(narrative_weights.narratives, narrative_weights.weights))
    end

    local wave_types = {
        pool_point_buy = function(narrative, pool, wave)
            local max_difficulty = narrative.max_difficulty or math.huge

            local weights = {}
			
			for _, enemy in pairs(pool) do
				table.insert(weights, (1000 / enemy.spawn_points) * (enemy.spawn_weight_modifier or 1))
			end

			local counts = {}
			local c = 0
            local num_points = narrative.points * self:pool_point_modifier()
            while num_points > 0 and #wave < self.max_enemies do
				local inserted = false	
                local enemy = rng.weighted_choice(pool, weights)
                if enemy and enemy.max_spawns and enemy.max_spawns <= (counts[enemy.name] or 0) then
					local index = table.search_list(pool, enemy)
					table.remove(pool, index)
					table.remove(weights, index)
				else
					if enemy and enemy.level <= max_difficulty then
						num_points = num_points - enemy.spawn_points
						table.insert(wave, enemy)
						counts[enemy.name] = (counts[enemy.name] or 0) + 1
						inserted = true
					end
				end
				if not inserted then
					c = c + 1
					if c > 10 then
						print("ending attempts to insert enemy")
						break
					end
				end
            end
        end,

		specific_enemy = function(narrative, pool, wave)
			for i = 1, min(narrative.count, self.max_enemies) do
				table.insert(wave, SpawnDataTable.data[narrative.enemy])
			end
		end,
		
		hazard_pool_point_buy = function(pool, wave)
            local weights = {}
			
			for _, enemy in pairs(pool) do
				table.insert(weights, 1000 / enemy.spawn_points)
			end

			local counts = {}

            local num_points = 50 * self:pool_point_modifier()
			local c = 0
            while num_points > 0 and #wave < self.max_hazards do
				local inserted = false

                local hazard = rng.weighted_choice(pool, weights)
				if hazard and hazard.max_spawns and hazard.max_spawns <= (counts[hazard.name] or 0) then
					local index = table.search_list(pool, hazard)
					table.remove(pool, index)
					table.remove(weights, index)
				else
					if hazard then
						num_points = num_points - hazard.spawn_points
						table.insert(wave, hazard)
						counts[hazard.name] = (counts[hazard.name] or 0) + 1
						inserted = true
					end
				end
				if not inserted then
					c = c + 1
					if c > 10 then
						print("ending attempts to insert hazard")
						break
					end
				end
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
                local max_enemy_difficulty = min(sub_narrative.max_difficulty or math.huge,
                    SpawnDataTable.max_level_by_type["enemy"])
                local min_enemy_difficulty = max(sub_narrative.min_difficulty or 1, 1)

                for j = 1, #enemy_pool do
                    local enemy = enemy_pool[j]
                    if rng.chance(pool_modification_chance_per_enemy) then
                        enemy = self:get_random_spawn_with_type_and_level("enemy", enemy.level, wave_number, narrative)
                    end

                    if wave_number > 1 and enemy ~= nil and enemy.initial_wave_only then
                        enemy = self:get_random_spawn_with_type_and_level("enemy", enemy.level, wave_number, narrative)
                    end

                    if enemy ~= nil then
                        enemy_pool[j] = enemy
                    end
                end

                for j = 1, #hazard_pool do
                    local hazard = hazard_pool[j]
                    if rng.chance(pool_modification_chance_per_enemy) then
                        hazard = self:get_random_spawn_with_type_and_level("hazard", hazard.level, wave_number, narrative)
                    end

                    if wave_number > 1 and hazard ~= nil and hazard.initial_wave_only then
                        hazard = self:get_random_spawn_with_type_and_level("hazard", hazard.level, wave_number, narrative)
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

                local current_enemy_pool = enemy_pool

                local custom_pool_single_enemy_functions = {}
                local custom_wave_pool = {}

                if sub_narrative.random_pool_size then
                    for _ = 1, sub_narrative.random_pool_size do
                        table.insert(custom_pool_single_enemy_functions, function()
                            local level = rng.randi(min_enemy_difficulty, max_enemy_difficulty)
                            local enemy = self:get_random_spawn_with_type_and_level("enemy", level, wave_number, sub_narrative)
                            return enemy
                        end)
                    end
                end

                if #custom_pool_single_enemy_functions > 0 then
                    current_enemy_pool = custom_wave_pool
                    for _, func in ipairs(custom_pool_single_enemy_functions) do
                        local enemy = func()
                        if sub_narrative.exclude_enemies then
                            local c = 1
                            while enemy and table.list_has(sub_narrative.exclude_enemies, enemy.name) do
                                enemy = func()
                                c = c + 1
                                if c > 100 then
                                    break
                                end
                            end
                        end
						if enemy then
							table.insert(custom_wave_pool, enemy)
						end
                    end
                end

                if not sub_narrative.disable_hazards then
                    wave_types.hazard_pool_point_buy(hazard_pool, wave.hazard)
                end

                if #current_enemy_pool == 0 then
                    current_enemy_pool = enemy_pool
                end

                wave_types[sub_narrative.type](sub_narrative, current_enemy_pool, wave.enemy)

                table.insert(waves, wave)
                wave_number = wave_number + 1
                for _, enemy in pairs(wave.enemy) do
                    self:add_spawn_type(enemy)
                end
                for _, hazard in pairs(wave.hazard) do
                    self:add_spawn_type(hazard)
                end
            else
                error("unknown narrative wave type: " .. sub_narrative.type)
            end
        end
    end

    local narrative = get_random_narrative()
	
	
	print(narrative.name)
	
	enemy_pool = self:generate_enemy_pool(narrative)
    while #enemy_pool < 1 do
		enemy_pool = self:generate_enemy_pool(narrative)
	end

	hazard_pool = self:generate_hazard_pool(narrative)

	process_narrative(narrative)



	for wave_number = 1, #waves do
		local rescue_pool = self:generate_rescue_pool()
        local rescue_weights = {}
        local rescue_wave = {}
		local rescue_pickups = {}
        for _, rescue in pairs(rescue_pool) do
			table.insert(rescue_weights, rescue.spawn_weight)
		end

		for j = 1, wave_number do
            local rescue = rng.weighted_choice(rescue_pool, rescue_weights)
			-- print(rescue.name, rescue.spawn_weight)
            if rescue ~= nil then
                self:add_spawn_type(rescue)
                table.insert(rescue_wave, {rescue = rescue, pickup = nil})
            end
		end

		table.insert(rescue_waves, rescue_wave)
	end


    -- here we decide which rescues will have pickups, if any
	-- 2 is the most chaotic wave so we will try to put pickups in that one first
    -- TODO: generalize this for levels with more or less than 3 waves
	local pickup_wave_precedence = { 2, 3, 1 }
    local pickups_left = true
    self.consumed_upgrade = false
	-- self.consumed_powerup = false
    self.consumed_heart = false
	self.consumed_artefact = false

    local min_powerup_level = 4

    local max_num_powerups = 2
    local num_powerups = 0
	
	local hard_chance = 0
	if self.is_hard then
		hard_chance = 15
	end
	
    local upgrade_pickup_chance = abs(rng.randfn(30 + max(game_state.num_queued_upgrades, 0) * 10, 1)) + hard_chance
	-- local heart_pickup_chance = abs(rng.randfn(10, 5)) + hard_chance

	-- print(game_state.num_queued_upgrades, game_state.num_queued_hearts, game_state.num_queued_artefacts)

	-- print(upgrade_pickup_chance, heart_pickup_chance, artefact_pickup_chance)

    for _, wave_number in ipairs(pickup_wave_precedence) do
		if rescue_waves[wave_number] == nil then
			goto continue
		end
        pickups_left =
            game_state.num_queued_upgrades > 0 or
            -- game_state.num_queued_powerups > 0 or
            game_state.num_queued_hearts > 0

        if not pickups_left then
            break
        end

        local wave = rescue_waves[wave_number]
        local possible_indices = {}
        for i = 1, #wave do
            table.insert(possible_indices, i)
        end
        while pickups_left and #possible_indices > 0 do
            local index = rng.randi(1, #possible_indices)
            local rescue = wave[possible_indices[index]]
            table.remove(possible_indices, index)

            if game_state.num_queued_upgrades > 0 and not self.consumed_upgrade and rng.percent(upgrade_pickup_chance) then
                rescue.pickup = game_state:get_random_available_upgrade()
                self.consumed_upgrade = rescue.pickup
            -- elseif not self.consumed_heart and rng.percent(heart_pickup_chance) then
            --     rescue.pickup = game_state:get_random_heart()
            --     self.consumed_heart = rescue.pickup
            elseif num_powerups < max_num_powerups and self.level >= min_powerup_level then
				local powerup_pickup_chance = min(abs(rng.randfn(30, 20)) * (self.level - min_powerup_level) * 0.01, 5) + 2 + hard_chance
				if rng.percent(powerup_pickup_chance) then
					rescue.pickup = game_state:get_random_powerup()
					num_powerups = num_powerups + 1
				end
            end
			if rescue.pickup ~= nil then
				self:add_spawn_type(rescue.pickup)
			end
        end
		::continue::
    end

    if self.needs_upgrade and not self.consumed_upgrade and not game_state:is_fully_upgraded() then
        local upgrade = game_state:get_random_available_upgrade(false)
		print(upgrade)
        local rescue = rng.choose(rng.choose(rescue_waves))
		while rescue.pickup ~= nil do
			rescue = rng.choose(rng.choose(rescue_waves))
		end
        rescue.pickup = upgrade
        self:add_spawn_type(upgrade)
        self.consumed_upgrade = upgrade
    end
	-- local artefact_pickup_chance = abs(rng.randfn(40 + max(game_state.num_queued_artefacts, 0) * 55, 5)) + hard_chance

	if game_state.num_queued_artefacts > 0 or (self.needs_artefact) then
        local artefact = game_state:get_random_available_artefact()
		if artefact then
			game_state:prune_artefact(artefact)
			self:add_spawn_type(artefact)
			self.consumed_artefact = true
			self.artefacts = self.artefacts or {}
			table.insert(self.artefacts, artefact)
		end
	end

	if self.consumed_upgrade then
		game_state:prune_upgrade(self.consumed_upgrade)
	end

	
    local should_have_heart = self.wants_heart

	if self.needs_heart then
		should_have_heart = true
    elseif self.wants_heart then
		should_have_heart = rng.percent(90)

		if self.consumed_upgrade then
			should_have_heart = should_have_heart and rng.percent(5)
		end

        if self.consumed_artefact then
            should_have_heart = should_have_heart and rng.percent(5)
        end

	end


	if should_have_heart and not self.consumed_heart then
	-- if self.needs_heart  then
		local heart = game_state:get_random_heart()
        local rescue = rng.choose(rng.choose(rescue_waves))
		while rescue.pickup ~= nil do
			rescue = rng.choose(rng.choose(rescue_waves))
		end
		rescue.pickup = heart
		self:add_spawn_type(heart)
		self.consumed_heart = heart
	end
	

	return waves, rescue_waves
end

return Room
