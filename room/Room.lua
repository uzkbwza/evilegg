local Room = Object:extend("Room")
local BasePickup = require("obj.Spawn.Pickup.BasePickup")
local SpawnDataTable = require("obj.spawn_data")

Room.narrative_types = {
    debug_enemy = {
        enabled = false,
		
		is_debug = true,
        weight = 0,
		sub_narratives = {
			[1] = {
				-- disable_hazards = true,
                type = "specific_enemy",
                enemy = "Cultist",
				count = 10,
            },
		}
	},

    basic_early = {
		weight = 1000,
        tags = {},
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

    bonus_mono_character = {
        weight = 1000,
		bonus = true,
        tags = {},
		sub_narratives = {
			[1] = {
                type = "pool_point_buy",
				exclude_enemies = { "Shielder", "Mortar", "Cultist",},
                points = 100,
				disable_hazards = true,
                max_difficulty = 3,
				random_pool_size = 1,
			},
			[2] = {
				type = "pool_point_buy",
				exclude_enemies = { "Shielder", "Mortar", "Cultist", },
                points = 175,
				disable_hazards = true,
                max_difficulty = 4,
				random_pool_size = 1,
            },
			[3] = {
				type = "pool_point_buy",
				exclude_enemies = { "Shielder", "Cultist", },
                points = 250,
				random_pool_size = 1,
            },
		}
	}
	
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


Room.horiz_padding = conf.room_padding.x
Room.vert_padding = conf.room_padding.y
Room.bullet_bounds_padding_x = max(Room.horiz_padding, 0) * 2
Room.bullet_bounds_padding_y = max(Room.vert_padding, 0) * 2
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

	print(self.room_width, self.room_height)
	
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
	
    self.is_hard = self.level > 6 and rng.percent(10)
    if self.is_hard then
		self.level = self.level + clamp(floor(self.level * 0.5), 3, 20)
	end

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

function Room:generate_enemy_pool()
	local pool = {}
    for i = 1, SpawnDataTable.max_level_by_type["enemy"] do
        local enemy = self:get_random_spawn_with_type_and_level("enemy", i)
		if enemy ~= nil then
			table.insert(pool, enemy)
		end
    end
	return pool
end

function Room:generate_hazard_pool()
    local pool = {}
    for i = 1, SpawnDataTable.max_level_by_type["hazard"] do	
        local hazard = self:get_random_spawn_with_type_and_level("hazard", i)
		if hazard ~= nil then
			table.insert(pool, hazard)
		end
    end
    return pool
end

function Room:get_random_spawn_with_type_and_level(type, level, wave)
	wave = wave or 1
	local spawn_dict = SpawnDataTable.data_by_type_then_level[type][level]
	local spawns = {}
	local weights = {}
	for _, spawn in pairs(spawn_dict) do
        if not spawn.spawnable then goto continue end
		if spawn.min_level and self.level < spawn.min_level then goto continue end
        if spawn.max_level and self.level > spawn.max_level then goto continue end
		if spawn.level > max((self.level + 1) * 0.75, 2) then goto continue end
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

	local spawn = rng.weighted_choice(spawns, weights)
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
		-- print(_narrative_name)
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
    local enemy_pool = self:generate_enemy_pool()
	local hazard_pool = self:generate_hazard_pool()

    local function get_random_narrative()
        if debug.enabled then
			if Room.narrative_types.debug_enemy.enabled then
				return Room.narrative_types.debug_enemy
			end
		end
        return rng.weighted_choice(narrative_weights.narratives, narrative_weights.weights)
    end

    local wave_types = {
        pool_point_buy = function(narrative, pool, wave)
            local max_difficulty = narrative.max_difficulty or math.huge

            local weights = {}
			
			for _, enemy in pairs(pool) do
				table.insert(weights, (1000 / enemy.spawn_points) * (enemy.spawn_weight_modifier or 1))
			end

            local num_points = narrative.points * self:pool_point_modifier()
            while num_points > 0 and #wave < self.max_enemies do
                local enemy = rng.weighted_choice(pool, weights)
                if enemy.level <= max_difficulty then
					num_points = num_points - enemy.spawn_points
					table.insert(wave, enemy)
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

            local num_points = 75 * self:pool_point_modifier()
            while num_points > 0 and #wave < self.max_hazards do
                local hazard = rng.weighted_choice(pool, weights)
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
				local max_enemy_difficulty = min(sub_narrative.max_difficulty or math.huge, SpawnDataTable.max_level_by_type["enemy"])
				local min_enemy_difficulty = max(sub_narrative.min_difficulty or 1, 1)

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

				local current_enemy_pool = enemy_pool

                local custom_pool_single_enemy_functions = {}
				local custom_wave_pool = {}

                if sub_narrative.random_pool_size then
                    for _ = 1, sub_narrative.random_pool_size do
						table.insert(custom_pool_single_enemy_functions, function()
							local level = rng.randi(min_enemy_difficulty, max_enemy_difficulty)
							local enemy = self:get_random_spawn_with_type_and_level("enemy", level, wave_number)
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
							while table.list_has(sub_narrative.exclude_enemies, enemy.name) do
                                enemy = func()
								c = c + 1
								if c > 100 then
									break
								end
							end
						end
						table.insert(custom_wave_pool, enemy)
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
                    self.all_spawn_types[enemy] = self.all_spawn_types[enemy] or 0
                    self.all_spawn_types[enemy] = self.all_spawn_types[enemy] + 1
                end
                for _, hazard in pairs(wave.hazard) do
                    self.all_spawn_types[hazard] = self.all_spawn_types[hazard] or 0
                    self.all_spawn_types[hazard] = self.all_spawn_types[hazard] + 1
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
                self.all_spawn_types[rescue] = self.all_spawn_types[rescue] or 0
                self.all_spawn_types[rescue] = self.all_spawn_types[rescue] + 1
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
	self.consumed_powerup = false
    self.consumed_heart = false
	self.consumed_item = false

	-- local upgrade_pickup_chance = 0
	local upgrade_pickup_chance = abs(rng.randfn(25 + (game_state.num_queued_upgrades - 1) * 10, 15))
	local powerup_pickup_chance = abs(rng.randfn(20 + (game_state.num_queued_powerups - 1) * 10, 20))
	local heart_pickup_chance = abs(rng.randfn(5 + (game_state.num_queued_hearts - 1) * 10, 20))
	local item_pickup_chance = abs(rng.randfn(5 + (game_state.num_queued_items - 1) * 10, 5))

    for _, wave_number in ipairs(pickup_wave_precedence) do
        pickups_left =
            game_state.num_queued_upgrades > 0 or
            game_state.num_queued_powerups > 0 or
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
                self.consumed_upgrade = true
            elseif game_state.num_queued_hearts > 0 and not self.consumed_heart and rng.percent(heart_pickup_chance) then
                rescue.pickup = game_state:get_random_heart()
                self.consumed_heart = true
            elseif game_state.num_queued_powerups > 0 and not self.consumed_powerup and rng.percent(powerup_pickup_chance) then
                -- rescue.pickup = game_state:get_random_powerup()
                -- self.consumed_powerup = true
            end
			if rescue.pickup ~= nil then
				self.all_spawn_types[rescue.pickup] = self.all_spawn_types[rescue.pickup] or 0
				self.all_spawn_types[rescue.pickup] = self.all_spawn_types[rescue.pickup] + 1
			end
        end
    end

    if self.needs_upgrade and not self.consumed_upgrade and not game_state:is_fully_upgraded() then
        local upgrade = game_state:get_random_available_upgrade(false)
		local rescue = rng.choose(rng.choose(rescue_waves))
        rescue.pickup = upgrade
		self.all_spawn_types[upgrade] = self.all_spawn_types[upgrade] or 0
        self.all_spawn_types[upgrade] = self.all_spawn_types[upgrade] + 1
		self.consumed_upgrade = true
	end
	
	if game_state.num_queued_items > 0 and rng.percent(item_pickup_chance) then
		-- local item = game_state:get_random_available_item()
		-- self.all_spawn_types[item] = self.all_spawn_types[item] or 0
        -- self.all_spawn_types[item] = self.all_spawn_types[item] + 1
		-- self.consumed_item = true
	end

	return waves, rescue_waves
end

return Room
