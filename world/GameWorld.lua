local GameWorld = World:extend("GameWorld")
local O = require("obj")
local EnemySpawns = require("obj.EnemySpawn")
local SpawnDataTable = require("obj.spawn_data")
local Room = require("room.Room")
local EggRoom = require("room.EggRoom")
local shash = require "lib.shash"
local ScoreNumberEffect = require("fx.score_number_effect")
local TextPopupEffect = require("fx.text_popup_effect")
local XpPickup = require("obj.XpPickup")
local EggWrath = require("obj.Spawn.Enemy.EggWrath")
local PenitentSoul = require("obj.Spawn.Enemy.Penitent")[2]
local FatigueZone = require("obj.Spawn.Enemy.FatigueZone")
local Cutscene = require("obj.Cutscene")
local BeginningCutscene = Cutscene.BeginningCutscene
local CAMERA_OFFSET_AMOUNT = 20
local MAX_ENEMIES = 100
local MAX_HAZARDS = 50
-- local MAX_ENEMIES = 10000

local ROOM_CHOICE = true
local CAMERA_TARGET_OFFSET = Vec2(0, 2)

local EGG_ROOM_START = 30
local EGG_ROOM_PERIOD = 20

local FLOOR_CANVAS_WIDTH = 1024
local FLOOR_CANVAS_HEIGHT = 1024

function GameWorld:new(x, y)
	self.draw_sort = function(a, b)
		local az = a.z_index or 0
		local bz = b.z_index or 0

		if az < bz then
			return true
		elseif az > bz then
			return false
		end

		local avalue = a.pos.y + az
		local bvalue = b.pos.y + bz
		if avalue == bvalue then
			return a.pos.x < b.pos.x
		end
		return avalue < bvalue
	end
	GameWorld.super.new(self, x, y)

	self:add_signal("enemy_added")
	self:add_signal("enemy_died")
    self:add_signal("level_transition_started")
	self:add_signal("player_died")
	self:add_signal("player_death_sequence_finished")

	local grid_size = 24

	self:add_spatial_grid("game_object_grid", grid_size)
	self:add_spatial_grid("declump_objects", grid_size)
	self:add_spatial_grid("pickup_objects", grid_size)
	self:add_spatial_grid("fungus_grid", grid_size)
	self:add_spatial_grid("bullet_grid", grid_size)
	self:add_spatial_grid("chargers", grid_size)
	self:add_spatial_grid("rescue_grid", grid_size)
	self:add_spatial_grid("dancer_grid", grid_size)

	self.hurt_bubbles = {}
	self.hurt_bubbles["player"] = shash.new(grid_size)
	self.hurt_bubbles["enemy"] = shash.new(grid_size)
	self.hurt_bubbles["neutral"] = shash.new(grid_size)

	self.hit_bubbles = {}
	self.hit_bubbles["player"] = shash.new(grid_size)
	self.hit_bubbles["enemy"] = shash.new(grid_size)
	self.hit_bubbles["neutral"] = shash.new(grid_size)

	self.empty_update_objects = bonglewunch()

	self.object_class_counts = {}
	self:add_signal("room_cleared")
	self:add_signal("all_spawns_cleared")

	self.players = {}
	self.last_player_positions = {}
	self.last_player_body_positions = {}
	self.player_entered_direction = Vec2(rng:random_4_way_direction())
	self.room_clear_fx_t = -1
	self.player_hurt_fx_t = -1
    self.room_border_fade_in_time = 0
	self.floor_drawing = true
	
	self.floor_canvas_width = FLOOR_CANVAS_WIDTH
	self.floor_canvas_height = FLOOR_CANVAS_HEIGHT

	self.border_rainbow_offset = 0

    -- self.pre_boss_hard_room = rng:randi(11, EGG_ROOM_START - 1)
    -- self.pre_boss_cursed_room = rng:randi(11, EGG_ROOM_START - 1)
    -- while self.pre_boss_cursed_room == self.pre_boss_hard_room do
    --     self.pre_boss_cursed_room = rng:randi(11, EGG_ROOM_START - 1)
    -- end

    self.rendering_content = true

	self.notification_queue = {}

	self.draining_bullet_powerup = false

	self.waiting_on_bonus_screen = false

    self:lazy_mixin(Mixins.Behavior.AllyFinder)


	self:init_state_machine()
end

function GameWorld:enter()
	-- we'll use this object when we need to time stuff with object_time_scale instead of the base world time.
	self:ref("timescaled", self:add_object(GameObject()))
	self.timescaled.persist = true
	self.timescaled:add_elapsed_ticks()
    self.timescaled:add_sequencer()
	self.timescaled.update = function(self, dt)
        if game_state.bullet_powerup and self.draining_bullet_powerup then
            game_state:drain_bullet_powerup_time(dt)
        end

        self.world.room.elapsed_scaled = self.world.room.elapsed_scaled + dt
        self.world.room.tick_scaled = floor(self.world.room.elapsed_scaled)
	end
	
	-- self:play_sfx("level_start", 0.95, 1.0)

	self.camera.persist = true

    game_state.level = game_state.level - 1
    if not (debug.enabled and debug.skip_tutorial_sequence) then
		game_state.level = game_state.level - 1
	end
	
	local start_room = self:create_room((debug.enabled and debug.skip_tutorial_sequence and {}) or {start_room = true})

    self:initialize_room(start_room)
    
    if not (debug.enabled and debug.skip_tutorial_sequence) then
		self.player_hatched = false
    else
        self.player_hatched = true
	end


	self:clear_floor_canvas(false)

	signal.connect(game_state, "player_upgraded", self, "on_player_upgraded", function(upgrade_type)
		self:quick_notify(
			"+" .. tr[upgrade_type.notification_text],
			upgrade_type.notification_palette
		)
	end)

	signal.connect(game_state, "player_downgraded", self, "on_player_downgraded", function(upgrade_type)
		self:quick_notify(
			"-" .. tr[upgrade_type.notification_text],
			-- upgrade_type.notification_palette
			"notif_downgrade"
		)
	end)

	signal.connect(game_state, "player_heart_gained", self, "on_player_heart_gained", function(heart_type)
		self:quick_notify(
			"+" .. tr[heart_type.notification_text],
			heart_type.notification_palette
		)
	end)
	
	signal.connect(game_state, "player_overhealed", self, "on_player_overhealed", function()
		self:quick_notify(
			tr.notif_overhealed,
			"notif_heart_up"
		)
    end)
	
	signal.connect(game_state, "player_overflowed", self, "on_player_overflowed", function()
		self:quick_notify(
			tr.notif_overflowed
		)
    end)
	
	signal.connect(game_state, "secondary_weapon_ammo_gained", self, "on_secondary_weapon_ammo_gained", function(amount)
		self:quick_notify(
			"+" .. tr.notif_ammo,
			nil,
			nil,
			0.0,
			50,			
			true
			-- ammo_type.notification_palette
			-- "notif_upgrade_available"
		)
	end)

	signal.connect(game_state, "player_running_out_of_ammo", self, "on_player_running_out_of_ammo", function()
		self:quick_notify(
            tr.notif_running_out_of_ammo,
            "notif_low_ammo",
            nil,
            0,
            60,
            true
		)
    end)

    signal.connect(game_state, "tried_to_use_secondary_weapon_with_no_ammo", self, "on_player_out_of_ammo", function()
		self:quick_notify(
			self.room.curse_famine and tr.notif_famine or tr.notif_out_of_ammo,
            self.room.curse_famine and "notif_famine" or "notif_no_ammo",
            nil,
            0,
            30,
            true
        )
    end)
    
    signal.connect(game_state, "ran_out_of_ammo", self, "on_ran_out_of_ammo", function()
        self:quick_notify(
			tr.notif_out_of_ammo,
            "notif_no_ammo",
            nil,
            0,
            60,
            true
        )
    end)

    signal.connect(game_state, "player_artefact_removed", self, "on_player_artefact_removed", function(artefact)
        self:quick_notify(
            "-" .. tr[artefact.name],
            "notif_downgrade"
            -- "notif_artefact_removed"
        )
    end)

	-- signal.connect(game_state, "player_powerup_gained", self, "on_player_powerup_gained", function(powerup_type)
	-- 	self:quick_notify(
	-- 		"+NOTHING",
	-- 		"notif_upgrade_available"
	-- 	)
	-- end)


	local threshold_notifs = {
		upgrade = tr.notif_upgrade_available,
		heart = tr.notif_heart_available,
		powerup = tr.notif_powerup_available,
		artefact = tr.notif_artefact_available,

	}

	signal.connect(game_state, "xp_threshold_reached", self, "on_xp_threshold_reached", function(threshold_type)
		-- if self.state == "RoomClear" then
		-- 	return
		-- end
		local duration = nil
		if self.state == "RoomClear" then
			duration = 200
		end
		local function threshold_notify(text, palette_name)
			self:quick_notify(
				text,
				palette_name,
				"pickup_ready_notification",
				0.75,
				duration
			)
		end

		local notif = threshold_notifs[threshold_type]
		threshold_notify(notif, "notif_upgrade_available")
	end)


    local s = self.timescaled.sequencer


    s:start(function()

        if not game_state.skip_intro and not (debug.enabled and debug.skip_tutorial_sequence) then
            local player = self.players[1]

            player:hide()
            
            -- cutscene block
            self:ref("beginning_cutscene", self:spawn_object(BeginningCutscene(0, 0)))
            while self.beginning_cutscene do
                s:wait(1)
            end
            -----------------
            

            player:show()
        end
        
        if not game_state.skip_intro and not (debug.enabled and debug.skip_tutorial_sequence) then

            -- s:start(function()
            local player = self.players[1]

            s:start(function()
                
                
                while audio:get_playing_music() do
                    s:wait(1)
                end
                

                s:wait(60)
                
                audio.play_music_if_stopped("music_drone")
            end)
            s:wait(35)
            if not game_state.hatched then
                self.tutorial_state = 1
            end
            s:wait_for_signal(player, "egg_ready")
            -- end)
        elseif game_state.skip_intro then
            audio.play_music_if_stopped("music_drone")
            self.tutorial_state = 1
        end
    end)
end

function GameWorld:quick_notify(text, palette_name, sound, sound_volume, duration, ignore_queue)
	if debug.enabled then
		print("notifying: " .. text)
	end

	local palette_stack
	if palette_name then
		palette_stack = PaletteStack(Color.black)
		palette_stack:push(Palette[palette_name .. "_border"], 1)
		palette_stack:push(Palette[palette_name], 1)
	end

	local notification = {
		text = text,
		sound = sound,
		sound_volume = sound_volume,
		palette_stack = palette_stack,
        duration = duration,
		ignore_queue = ignore_queue,
	}

	-- self:notify_all_players(notification)
	if not ignore_queue then
        table.insert(self.notification_queue, notification)
    else
		self:play_notification(notification)
	end
end

function GameWorld:create_room(room_params)
	local level_history = nil
	-- local old_room = self.room
	-- if old_room then
	-- level_history = old_room.level_history
	-- end


	local level = game_state.level
    level = level + 1

	local room
	
	if room_params and room_params.egg_room then
		room = EggRoom(self, level, game_state.difficulty, level_history, MAX_ENEMIES, MAX_HAZARDS)
	else
		room = Room(self, level, game_state.difficulty, level_history, MAX_ENEMIES, MAX_HAZARDS)
	end
	
	-- for _, room in ipairs(self.current_room_selection or {}) do
	-- 	for obj, _ in pairs(room.all_spawn_types) do
	-- 		room.redundant_spawns[obj] = true
	-- 	end
    -- end
	-- if not room_params.start_room then
	room:build(room_params)
	-- end
	

	return room
end

function GameWorld:initialize_room(room)

    self.timescaled:stop_tick_timer("wave_timer")
    self.timescaled:stop_tick_timer("last_wave_quick_clear")

    self.draining_bullet_powerup = false
	self.floor_drawing = true
	if room.draw_floor_canvas == false then
		self.floor_drawing = false
	end

	self.enemies_to_kill = {}

	game_state:on_level_start()

    self.room = room
    
    if self.play_music_next_level then
        audio.play_music_if_stopped("music_drone")
        self.play_music_next_level = false
    end


	local s = self.timescaled.sequencer


    if self.room.curse then
        savedata:add_item_to_codex(self.room.curse)
    end

	s:start(function()
		if table.is_empty(self.players) then
            self:create_player()
		end
		-- for _, player in pairs(self.players) do
		-- 	player:change_state("GameStart")
		-- end

        if self.room.initialize then
			self.room:initialize(self)
		end

		s:wait(15)

		if self.room:should_spawn_waves() then
			self:spawn_wave()
		end
	end)

	self:ref("camera_target", self:add_object(GameObject2D(CAMERA_TARGET_OFFSET.x, CAMERA_TARGET_OFFSET.y))).persist = true

	self.camera:follow(self.camera_target)
	-- self.camera:set_limits()
end

function GameWorld:start_wave_timer(duration)
    self.timescaled:stop_tick_timer("wave_timer")
	self.timescaled:start_tick_timer("wave_timer", duration, function()
		if game_state.game_over then return end
        self.room.wave = self.room.wave + 1

		self:spawn_wave()
	end)
end

function GameWorld:spawn_rescues(spawns)
	local s = self.timescaled.sequencer
	-- local max_rescues = 2 + floor(game_state.level / 15)
	s:start(function()
		for _, rescue in pairs(spawns) do
            -- s:start(function()
            local beginning = true
			for _ = 1, beginning and 120 or rng:randi(60, 120) do
				beginning = false
				if self.state ~= "RoomClear" then
					-- while self:get_number_of_objects_with_tag("rescue_object") >= max_rescues do
					-- 	s:wait(rng:randi(60, 120))
					-- end
					-- while self:is_tick_timer_running("rescue_spawn_cooldown") do
					--     s:wait(1)
					-- end
					s:wait(1)
				else
					break
				end
			end
			-- if self.state ~= "RoomClear" then
			-- 	self.timescaled:start_tick_timer("rescue_spawn_cooldown", rng:randi(40, 120))
			-- end

			if game_state.game_over then return end



			-- local rescue_object = self:spawn_object(rescue.rescue.class(self:get_valid_spawn_position()))
			local rescue_object = self:spawn_rescue(rescue.rescue.class, rescue.pickup, self:get_valid_spawn_position())
		end
	end)
end

function GameWorld:spawn_rescue(rescue_class, pickup, x, y)
	local rescue_object = self:spawn_object(rescue_class(x, y))
	if pickup then
		rescue_object:register_pickup(pickup)
	end
	self:add_tag(rescue_object, "rescue_object")
	signal.connect(rescue_object, "picked_up", self, "on_rescue_picked_up", function()
		self:on_rescue_picked_up(rescue_object)
	end)
    return rescue_object
end

function GameWorld:on_rescue_picked_up(rescue_object)
    local bx, by = rescue_object:get_body_center()
    if not rescue_object.no_score then
        self:add_score_object(bx, by, rescue_object.spawn_data.score, "rescues")
    end
    if game_state.artefacts.clock then
		self.clock_slowed = true
		self:play_sfx("clock_slow", 0.75, 1.0)
		self.timescaled:start_tick_timer("clock_slow", 5 + min(game_state.rescue_chain, 20), function()
		-- self.timescaled:start_tick_timer("clock_slow", 30, function()
			self.clock_slowed = false
		end)
	end
	game_state:on_rescue(rescue_object)
	self:quick_notify(string.format("×%d", game_state:get_rescue_chain_multiplier()), nil, nil, nil, 30, true)
end

function GameWorld:spawn_wave()
    if self.room.cleared then return end

	game_state.wave = self.room.wave


	self:change_state("Spawning")

	self.wave_started = true

	self.spawned_on_player = false

	local spawns, rescue_spawns = self.room:spawn_wave()

	local s = self.timescaled.sequencer

	if spawns then
		s:start(function()
			local highlights = self:get_objects_with_tag("last_enemy_target")
			for _, highlight in highlights:ipairs() do
				highlight:queue_destroy()
			end
			if self.highlight_last_enemies_sequence then self.timescaled.sequencer:stop(self.highlight_last_enemies_sequence) end
			
			self.room.highlighting_enemies = false

			self:spawn_rescues(rescue_spawns)
			-- Spawn hazards and enemies in parallel
			
			self:spawn_wave_group(s, spawns.hazard, "hazard", "wave_hazard", MAX_HAZARDS)
			self:spawn_wave_group(s, spawns.enemy, "enemy", "wave_enemy", MAX_ENEMIES)

			s:wait(5)

			-- Wait for enemies to finish spawning
			while self:get_number_of_objects_with_tag("enemy_spawner") > 0 do
				s:wait(1)
			end

			if self.state == "Spawning" then
				self:change_state("Normal")
			end

			if self.room.wave < self.room.last_wave then
				self:start_wave_timer(540)
			else
				self.timescaled:start_tick_timer("last_wave_quick_clear", 540)
			end
		end)
	end
end

function GameWorld:get_quick_clear_time_left_ratio()
	if game_state.game_over then return 0 end
	if self.state == "RoomClear" then
		return 0
	elseif self.state == "LevelTransition" then
		return 0
	elseif self.timescaled:is_tick_timer_running("last_wave_quick_clear") then
		return 1 - self.timescaled:tick_timer_progress("last_wave_quick_clear")
	elseif self.timescaled:is_tick_timer_running("wave_timer") then
		return 1 - self.timescaled:tick_timer_progress("wave_timer")
	else
		return 0
	end
end

function GameWorld:spawn_wave_group(s, wave, spawn_type, tag_name, max_count)
	s:start(function()
		for i, spawn_data in ipairs(wave) do
			if debug.enabled and input.debug_skip_wave_held then
				break
			end

			if game_state.game_over then
				return
			end
			

			local spawn_x, spawn_y = self:get_valid_spawn_position()

			-- local max_spawns = spawn.max_spawns or math.huge

			-- local max_instances = spawn.max_spawns + (game_state.difficulty - 1)
			-- local current_instances = self.object_class_counts[spawn_data.class] or 0

			-- if current_instances >= max_instances then
			-- 	goto continue
			-- end

			local class = EnemySpawns.EnemySpawn
			if spawn_data.enemy_spawn_effect then
				class = EnemySpawns[spawn_data.enemy_spawn_effect]
			end

			local spawn = self:spawn_something(spawn_data.class, spawn_x, spawn_y, class, spawn_type, function(object)
				if spawn_type == "hazard" then
					self:spawn_wave_hazard(object)
				else
					self:spawn_wave_enemy(object)
				end
				self.draining_bullet_powerup = true
			end)
			-- self:add_tag(spawn, "enemy_spawner")
			-- self:add_tag(spawn, tag_name)

			if i % 3 == 0 then
				s:wait(5)
			end
			-- s:wait(1)
			-- end

			while self:get_number_of_objects_with_tag(tag_name) > max_count do
				s:wait(1)
			end
			::continue::
		end
	end)
end

function GameWorld:spawn_something(class, x, y, enemy_spawner_class, enemy_spawn_type, enter_function)
    enemy_spawner_class = enemy_spawner_class or EnemySpawns.EnemySpawn
	if x == nil or y == nil then
		x, y = self:get_valid_spawn_position()
	end
    local spawn = self:spawn_object(enemy_spawner_class(x, y, enemy_spawn_type or "enemy"))
    self:add_tag(spawn, "enemy_spawner")
    signal.connect(spawn, "finished", self, "on_spawn_finished", function()
		local object = self:spawned_object_enter(class(x, y))
		if enter_function then
			enter_function(object)
		end
    end)
    return spawn
end

function GameWorld:spawned_object_enter(spawn)
	local object = self:spawn_object(spawn)
	object:add_enter_function(object.life_flash)
	return object
end

function GameWorld:spawn_wave_hazard(hazard)
	-- local hazard_object = self:spawned_object_enter(hazard)
	self:add_tag(hazard, "wave_spawn")
	self:add_tag(hazard, "wave_hazard")
	-- hazard_object:move(0, hazard_object.body_height / 2)
	-- self:register_spawn_wave_hazard(hazard_object)
end

function GameWorld:spawn_wave_enemy(enemy)
    -- local enemy_object = self:spawned_object_enter(enemy)
    self:register_spawn_wave_enemy(enemy)
    -- enemy_object:move(0, enemy_object.body_height / 2)
end

function GameWorld:register_non_wave_enemy_required_kill(enemy_object)
    self.enemies_to_kill[enemy_object] = true
    signal.connect(enemy_object, "died", self, "enemies_to_kill_table_on_enemy_died", function()
        self.enemies_to_kill[enemy_object] = nil
    end)

    signal.connect(enemy_object, "destroyed", self, "enemies_to_kill_table_on_enemy_destroyed", function()
        self.enemies_to_kill[enemy_object] = nil
    end)
end

function GameWorld:register_spawn_wave_enemy(enemy_object)
    self.enemies_to_kill[enemy_object] = true
    self:add_tag(enemy_object, "wave_enemy")
    self:add_tag(enemy_object, "wave_spawn")

    signal.connect(enemy_object, "died", self, "enemies_to_kill_table_on_enemy_died", function()
        local bx, by = enemy_object:get_body_center()

		self:add_score_object(bx, by, enemy_object:get_score(), "kills")

		local closest_player
		local closest_distance = math.huge
		for _, player in pairs(self.players) do
			local distance = enemy_object.pos:distance_to(player.pos)
			if distance < closest_distance then
				closest_distance = distance
				closest_player = player
			end
		end

		if closest_player then
			local distance = max(closest_distance, 1)
			local max_distance = 100
			if distance < max_distance then
				local bonus = pow((max_distance - distance) / max_distance, 1.4) * (enemy_object:get_score())
				game_state.aggression_bonus = game_state.aggression_bonus + bonus
			end
		end

        self:spawn_object(XpPickup(bx, by, enemy_object:get_xp()))
        -- game_state:level_bonus("kill")

        self.enemies_to_kill[enemy_object] = nil
        game_state:add_kill()

        if self.room.curse_penitence and rng:percent(8 * (enemy_object.max_hp or 1)) then
            self:register_non_wave_enemy_required_kill(self:spawn_object(PenitentSoul(bx, by)))
        end
    end)

    signal.connect(enemy_object, "destroyed", self, "enemies_to_kill_table_on_enemy_destroyed", function()
        self.enemies_to_kill[enemy_object] = nil
    end)
end

function GameWorld:spawn_xp(x, y, amount)
	local xp_object = self:spawn_object(XpPickup(x, y, amount))
end

function GameWorld:get_random_position_in_room()
	local room_width = self.room.room_width
	local room_height = self.room.room_height
	local x = rng:randf(-room_width / 2, room_width / 2)
	local y = rng:randf(-room_height / 2, room_height / 2)
	return x, y
end


function GameWorld:add_score_object(x, y, score, score_category)
	if game_state.game_over then return end
	score = game_state:determine_score(score)
    game_state:add_score(score, score_category)
	if score > 0 then
		local score_object = self:spawn_object(ScoreNumberEffect(x, y, score))
	end
end

function GameWorld:on_wave_cleared()
	self.wave_started = false

	local s = self.timescaled.sequencer
	s:start(function()
		if game_state.game_over then return end

		if self.room.wave == self.room.last_wave then
			-- s:wait(10)
			if self.timescaled:is_tick_timer_running("last_wave_quick_clear") then
				-- print("last wave finished early")
				self:play_sfx("wave_finished_early", 0.75, 1.0)
				game_state:level_bonus("quick_wave")
			end
			self:on_room_clear()
		else
			self:play_sfx("wave_finished_early", 0.75, 1.0)
			game_state:level_bonus("quick_wave")
			self:start_wave_timer(10)
		end
	end)
end

function GameWorld:closest_last_player_pos(x, y)
	local closest_player_pos = nil
	local closest_distance = math.huge

	for _, player_pos in pairs(self.last_player_positions) do
		local distance = vec2_distance_squared(x, y, player_pos.x, player_pos.y)
		if distance < closest_distance then
			closest_distance = distance
			closest_player_pos = player_pos
		end
	end

	if closest_player_pos then
		return closest_player_pos.x, closest_player_pos.y
	end

	return 0, 0
end

function GameWorld:closest_last_player_body_pos(x, y)
	local closest_player_pos = nil
	local closest_distance = math.huge

	for _, player_pos in pairs(self.last_player_body_positions) do
		local distance = vec2_distance_squared(x, y, player_pos.x, player_pos.y)
		if distance < closest_distance then
			closest_distance = distance
			closest_player_pos = player_pos
		end
	end

	if closest_player_pos then
		return closest_player_pos.x, closest_player_pos.y
	end

	return 0, 0
end

function GameWorld:create_player(player_id)
    player_id = player_id or #self.players + 1

	local player = self:spawn_object(O.Player.PlayerCharacter(0, 0))
	signal.connect(player, "died", self, "on_player_died")

	signal.connect(player, "got_hurt", self, "on_player_got_hurt")

	self.players[player_id] = player
	self.last_player_positions[player_id] = player.pos
	self.last_player_body_positions[player_id] = Vec2(player:get_body_center())

	signal.connect(player, "moved", self, "on_player_moved", function()
		self.last_player_positions[player_id] = player.pos
		self.last_player_body_positions[player_id] = Vec2(player:get_body_center())
	end)

	signal.connect(player, "destroyed", self, "on_player_destroyed", function()
		self.players[player_id] = nil
		-- self.last_player_positions[player_id] = nil
		-- self.last_player_body_positions[player_id] = nil
	end)

    signal.connect(player, "hatched", self, "on_player_hatched", function()
        self.player_hatched = true

        game_state:on_hatched()

		savedata:set_save_data("new_version_force_intro", false)
        -- savedata:set_save_data("update_force_cutscene", false)


		if debug.enabled and debug.skip_tutorial_sequence then
			self:room_border_fade("in")
			return
		end
		
		local s = self.timescaled.sequencer
        if game_state.skip_intro then
			self:room_border_fade("in")
            self:soft_room_clear()
			s:start(function()
				self.tutorial_state = nil
				local level = game_state.level
                s:wait(45)
				if game_state.level == level then
					self.tutorial_state = 2
				end
			end)
			return
		end

        -- if game_state.level ~= 0 then
        --     return
        -- end
		

		self.tutorial_sequence = s:start(function()
			s:wait(5)
			self:room_border_fade("in", 3)
			self.tutorial_state = nil
            -- s:wait(25)
			s:wait(45)
            self.tutorial_state = 2
			s:wait(70)
			-- self.tutorial_state = nil
            self:soft_room_clear()
			self.tutorial_sequence = nil
		end)
		
	end)

	return player
end

function GameWorld:soft_room_clear()
	local s = self.timescaled.sequencer
    s:start(function()
		while self:get_number_of_objects_with_tag("xp_pickup") > 0 do
			s:wait(1)
		end
		self:change_state("RoomClear")
		self.next_rooms = self:create_next_rooms()
		self.waiting_on_rooms = true
        self.draining_bullet_powerup = false
	end)
end

function GameWorld:clear_objects()
	for _, object in self.objects:ipairs() do
		if not object.persist then
			object:queue_destroy()
        elseif object.on_level_transition then
            object:on_level_transition()
        end
	end
end

function GameWorld:on_player_got_hurt()
	local s = self.sequencer
    s:start(function()
        s:start(function()
            s:tween_property(self, "player_hurt_fx_t", 0, 1, 45, "linear")
			self.player_hurt_fx_t = -1
		end)
		self:play_sfx("player_hurt", 0.85, 1.0)
		self:play_sfx("hazard_death", 0.5, 1.0)
		self.object_time_scale = 0.025
		-- self.player_death_fx = true
		-- self.` = true
		s:wait(20)
		-- self.player_death_fx = false
		self.object_time_scale = 1

		-- s:wait(120)

	end)
end

function GameWorld:on_player_died()
    local s = self.sequencer

    s:start(function()
        s:start(function()
            s:tween_property(self, "player_hurt_fx_t", 0, 1, 75, "linear")
            self.player_hurt_fx_t = -1
        end)
        self:play_sfx("player_death", 0.85, 1.0)
        self:emit_signal("player_died")
        self:play_sfx("hazard_death", 0.5, 1.0)
        self.object_time_scale = 0.025
        self.player_death_fx = true
        self.player_died = true
        self:end_tick_timer("wave_timer")
        self:end_tick_timer("last_wave_quick_clear")
        savedata:on_death()
        audio.stop_music()
        if not game_state.artefacts.blast_armor then
            game_state:on_game_over()
        end
        s:wait(60)
        self.player_death_fx = false
        if game_state.artefacts.blast_armor then
            self.object_time_scale = 1.0
            s:wait(5)
            game_state:on_game_over()
            s:start(function()
                s:tween_property(self, "object_time_scale", 1.0, 0.15, 90, "linear")
            end)
        end
        -- else
        self.object_time_scale = 0.15
        -- end

        -- s:wait(18)

        -- while self:get_number_of_objects_with_tag("enemy") > 0 do
        --     local waited = false
        --     local enemies = self:get_objects_with_tag("enemy")

        --     for i, enemy in enemies:ipairs() do

        --         if enemy:has_tag("hazard") then
        --             self:remove_tag(enemy, "enemy")
        --             goto continue
        --         end

        --         if enemy.spawn_data and enemy.spawn_data.boss then
        --             self:remove_tag(enemy, "enemy")
        --             goto continue
        --         end

        --         -- if game_state.artefacts.death_cap and enemy:has_tag("fungus") then
        --         --     goto continue
        --         -- end

        --         if enemy.die then
        --             enemy:die(self:get_random_object_with_tag("player"))
        --         elseif not enemy.is_queued_for_destruction then
        --             enemy:queue_destroy()
        --         end
        --         if i % 5 == 0 then
        --             s:wait(5)
        --             waited = true
        --         end

        --         ::continue::
        --     end
        --     if not waited then
        --         s:wait(1)
        --     end
        -- end


        -- while self:get_number_of_objects_with_tag("rescue_object") > 0 do
        --     local waited = false
        --     local rescues = self:get_objects_with_tag("rescue_object")
        --     for _, rescue in rescues:ipairs() do
        --         -- local player = self:get_random_object_with_tag("player")
        --         rescue:die()
        --         s:wait(5)
        --         waited = true
        --     end
        --     if not waited then
        --         s:wait(1)
        --     end
        -- end


        self:emit_signal("player_death_sequence_finished")
        -- s:wait(120)
    end)
end

function GameWorld:create_next_rooms()
    local next_level = game_state.level + 1


	print(next_level - EGG_ROOM_START)
	
	if (next_level - EGG_ROOM_START) >= 0 and (next_level - EGG_ROOM_START) % EGG_ROOM_PERIOD == 0 then
        return {
			self:create_egg_room()
		}
	end

	local rooms = {}

	local needs_upgrade = game_state.num_queued_upgrades > 0 and not game_state:is_fully_upgraded()
	local needs_artefact = game_state.num_queued_artefacts > 0
	local wants_heart = game_state.num_queued_hearts > 0

	local upgrade_room = rng:randi(1, 3)
	local artefact_room = rng:randi(1, 3)
	-- local heart_room = next_level <= EGG_ROOM_START and upgrade_room or rng:randi(1, 3)
	local heart_room = upgrade_room
	local hard_room = rng:randi(1, 3)
    local ammo_room = rng:randi(1, 3)
    local cursed_room = rng:randi(1, 3)
	
	game_state.already_selected_secondary_weapon_this_level = false
	game_state.recently_selected_artefacts = {}
	game_state.recently_selected_upgrades = {}
	game_state.recently_selected_curses = {}

    local cursed_frequency = 3
    if game_state.level >= EGG_ROOM_START then
        cursed_frequency = 2
    end
    if game_state.level >= EGG_ROOM_START + EGG_ROOM_PERIOD then
        cursed_frequency = 1
    end

    local force_percent = 4 + max(0, ceil(((next_level) - EGG_ROOM_START) / EGG_ROOM_PERIOD)) * 2
    
    local force_cursed = rng:percent(force_percent)

    local num_cursed_rooms = 0

	for i = 1, 3 do 
        local cursed = (game_state.level >= 6 and (((i == cursed_room) or force_cursed) and (game_state.level % cursed_frequency == 0)))
        if cursed then
            num_cursed_rooms = num_cursed_rooms + 1
        end
        if num_cursed_rooms >= 2 and next_level < EGG_ROOM_START then
            cursed = false
            force_cursed = false
        end
		local room = self:create_room({
			-- bonus_room = game_state.level > 1 and ((next_level) % 3 == 0),
			bonus_room = game_state.level > 3 and ((next_level) % 5 == 0),
			needs_upgrade = needs_upgrade and i == upgrade_room,
			needs_artefact = needs_artefact and i == artefact_room,
            needs_heart = wants_heart and i == heart_room,
			wants_heart = wants_heart,
			hard_room = i == hard_room and (game_state.level >= EGG_ROOM_START),
			force_ammo = i == ammo_room and game_state.level,
            cursed_room = cursed,
            allow_ignorance = not (force_cursed and i ~= cursed_room),
            -- cursed_room = true
		})
		table.insert(rooms, room)
	end

	table.sort(rooms, function(a, b)
		return a.total_score < b.total_score
	end)

	for i = 1, 3 do
		rooms[i].points_rating = i
	end

	table.shuffle(rooms) 

	return rooms
end

function GameWorld:create_egg_room()
    local room = self:create_room({
		egg_room = true,
	})

	return room
end

function GameWorld:spawn_room_objects()

	local rooms = self.next_rooms

	self.current_room_selection = {}
	local directions = { Vec2(1, 0), Vec2(0, 1), Vec2(-1, 0), Vec2(0, -1) }

	table.shuffle(directions)

	for i = 1, 4 do
		local direction = directions[i]
		if direction == -self.player_entered_direction then
			table.remove(directions, i)
			break
		end
	end

	local consumed_upgrade = false
	-- local consumed_powerup = false
	local consumed_heart = false
	local consumed_artefact = false


	local room_objects = {}

	for i = 1, #rooms do
		local room = rooms[i]
		local direction = directions[i]
        if room.is_egg_room then
            direction = Vec2(0, -1)
        end

		
		
		consumed_upgrade = consumed_upgrade or room.consumed_upgrade
		-- consumed_powerup = consumed_powerup or room.consumed_powerup
		consumed_heart = consumed_heart or room.consumed_heart
		consumed_artefact = consumed_artefact or room.consumed_artefact
		
		if room.consumed_upgrade then
			print(room.consumed_upgrade.upgrade_type)
		end
		
		local spawn_pos_x, spawn_pos_y = direction.x * self.room.room_width / 2, direction.y * self.room.room_height / 2
		local room_object = O.RoomObject(spawn_pos_x, spawn_pos_y, room)
		room_object.direction = direction
		room_object.points_rating = room.points_rating
		signal.connect(room_object, "room_chosen", self, "on_room_chosen", function()
			self.player_entered_direction = direction
			-- local s = self.sequencer
			-- s:start(function()
			self:change_state("LevelTransition", room)
			local s = self.sequencer
			if self.room_clear_coroutine then
				s:stop(self.room_clear_coroutine)
				self.room_clear_coroutine = nil
				self.room_clear_fx_t = -1
			end

			-- end)
		end)
		table.insert(room_objects, room_object)
	end

	local s = self.timescaled.sequencer

	local s2 = self.sequencer

    if consumed_upgrade then
		game_state:consume_upgrade()
	end

	if consumed_heart then
		game_state:consume_heart()
	end

	if consumed_artefact then
		game_state:consume_artefact()
	end

	s2:start(function()
		while self.room_clear_fx_t >= 0 do
			s2:wait(1)
		end
		s:start(function()
			for i = 1, #room_objects do
				self:spawn_object(room_objects[i])
				s:wait(2)
			end

			self.waiting_on_rooms = false
		end)
	end)
end

function GameWorld:start_room_clear_fx()
	local s = self.sequencer
	-- self.camera:start_rumble(1, 90)
	self.room_clear_coroutine = s:start(function()
		s:tween_property(self, "room_clear_fx_t", 0, 1, 60, "linear")
		self.room_clear_fx_t = -1
		self.room_clear_coroutine = nil
	end)
end

function GameWorld:spawn_artefact(artefact)
	local artefact_object = self:spawn_object(O.Artefact.ArtefactSpawn(0, 0, artefact))
	self:add_tag(artefact_object, "artefact")
end

function GameWorld:on_final_boss_killed()
    self.final_boss_killed = true
	game_state:on_final_room_cleared()
	self:on_room_clear()
end

function GameWorld:can_pause()
    if self.room_clear_nopause and usersettings.show_hud then
        return false
    end
	
	-- if self.state ~= "RoomClear" then
	-- 	return false
	-- end

	return true
end

function GameWorld:on_room_clear()
	if self.room.cleared then
		return
	end

	self.draining_bullet_powerup = false

	self:change_state("RoomClear")

	self:emit_signal("room_cleared")


	self:stop_tick_timer("wave_timer")
	self:stop_tick_timer("last_wave_quick_clear")

    if not game_state.hit_by_egg_wrath and self.room.curse == "curse_wrath" then
        game_state:level_bonus("tactful")
    end
    
    if self.room.is_hard then
        game_state:level_bonus("hard_room")
    end
    
    if self.room.curse then
        game_state:level_bonus("cursed_room")
    end

	self.room_clear_nopause = true

	local s = self.timescaled.sequencer

	self.room.cleared = true

	self:start_room_clear_fx()

	s:start(function()
		-- self.frozen = true
		self.object_time_scale = 0.125

		self:play_sfx("level_finished", 0.85, 1.0)



		s:wait(5)

		self.object_time_scale = 1.0


		while self:get_number_of_objects_with_tag("enemy") > 0 do
			local enemies = self:get_objects_with_tag("enemy")

			local waited = false
            for i, enemy in enemies:ipairs() do

                if game_state.artefacts.death_cap and enemy:has_tag("fungus") then
					self:remove_tag(enemy, "enemy")
					goto continue
				end
				
				if enemy.die then
					enemy:die()
				elseif not enemy.is_queued_for_destruction then
					enemy:queue_destroy()
				end
                if i % 5 == 0 then
                    s:wait(2)
                    waited = true
                end
				
				::continue::
			end
			if not waited then
				s:wait(2)
			end
		end



		while table.is_empty(self.players) do
			s:wait(1)
		end


		while self:get_number_of_objects_with_tag("rescue_object") > 0 do
			local rescues = self:get_objects_with_tag("rescue_object")
			local waited = false
			for _, rescue in rescues:ipairs() do
				local player = self:get_random_object_with_tag("player")
				player:pickup(rescue)
				s:wait(2)
				waited = true
			end
			if not waited then
				s:wait(2)
			end
		end

		if ROOM_CHOICE then
			for i, player in pairs(self.players) do
				-- player:change_state("Hover", false)
			end
		end

		game_state:on_room_clear()

		s:wait(5)

		self:emit_signal("all_spawns_cleared")

        while self.waiting_on_bonus_screen do
            s:wait(1)
        end

		self.room_clear_nopause = false
		
		if game_state.final_room_entered then
			for _, player in pairs(self.players) do
				player:die()
			end
			return
		end

        game_state.last_spawned_artefacts = {}

        while self:get_number_of_objects_with_tag("xp_pickup") > 0 do
            s:wait(1)
        end

        -- spawn artefacts
        if self.room.artefacts then
            for _, artefact in ipairs(self.room.artefacts) do
                game_state.last_spawned_artefacts[artefact.key] = true
                self:spawn_artefact(artefact)
                s:wait(10)
            end
            s:wait(70)
        end
		
		s:wait(5)

		while self:get_number_of_objects_with_tag("artefact") > 0 do
			s:wait(1)
		end

        while self:get_number_of_objects_with_tag("xp_pickup") > 0 do
            s:wait(1)
        end

        -- i want to be able to debug room generation so we're not running it in this coroutine
		if not self.final_boss_killed then
			self.waiting_on_rooms = true
		end
	end)
end

function GameWorld:get_update_objects()
	if self.frozen then return self.empty_update_objects end

	return World.get_update_objects(self)
end

function GameWorld:always_update(dt)
    if not self.moving_camera_target then
        -- local target_x, target_y = self.showing_hud and CAMERA_TARGET_OFFSET.x or 0,
        -- self.showing_hud and CAMERA_TARGET_OFFSET.y or 0

        -- self.camera_target:move_to(vec2_approach(self.camera_target.pos.x, self.camera_target.pos.y, target_x, target_y, dt * 0.5))
    end
    if debug.enabled then
        dbg("quick_clear_time_left_ratio", self:get_quick_clear_time_left_ratio(), Color.yellow)
        dbg("wave_timer", self.timescaled:tick_timer_time_left("wave_timer"), Color.yellow)
        dbg("last_wave_quick_clear", self.timescaled:tick_timer_time_left("last_wave_quick_clear"), Color.yellow)
    end
end

function GameWorld:update(dt)


	self.camera_aim_offset = self.camera_aim_offset or Vec2(0, 0)

	self.timescaled.draining_bullet_powerup = self.draining_bullet_powerup
	self.room.elapsed = self.room.elapsed + dt
	self.room.tick = floor(self.room.elapsed)

	-- if self.player then
	-- self.last_player_pos = self.last_player_pos or self.player.pos:clone()
	-- self.last_player_pos.x = self.player.pos.x
	-- self.last_player_pos.y = self.player.pos.y

	-- local bx, by = self.player:get_body_center()
	-- self.last_player_body_pos = self.last_player_body_pos or Vec2(bx, by)
	-- self.last_player_body_pos.x = bx
	-- self.last_player_body_pos.y = by

	local average_player_x, average_player_y = 0, 0
	local average_player_aim_direction_x, average_player_aim_direction_y = 0, 0
	local num_positions = 0
	local num_players = 0

	for i, pos in pairs(self.last_player_positions) do
	    average_player_x = average_player_x + pos.x
	    average_player_y = average_player_y + pos.y
	    num_positions = num_positions + 1
	end

	for i, player in pairs(self.players) do
	    average_player_aim_direction_x = average_player_aim_direction_x + player.aim_direction.x
	    average_player_aim_direction_y = average_player_aim_direction_y + player.aim_direction.y
	    num_players = num_players + 1
	end

	average_player_x = average_player_x / num_positions
	average_player_y = average_player_y / num_positions
	average_player_aim_direction_x = average_player_aim_direction_x / num_players
	average_player_aim_direction_y = average_player_aim_direction_y / num_players


	if self.state ~= "LevelTransition" and self.room.free_camera then
		if num_players > 0 then
			self.camera_target.pos.x, self.camera_target.pos.y =
				splerp_vec(
					self.camera_target.pos.x, self.camera_target.pos.y,
					average_player_x + self.camera_aim_offset.x, average_player_y + self.camera_aim_offset.y,
					300.0,
					dt
				)

			self.camera_aim_offset.x, self.camera_aim_offset.y =
				splerp_vec(
					self.camera_aim_offset.x, self.camera_aim_offset.y,
					average_player_aim_direction_x * CAMERA_OFFSET_AMOUNT,
					average_player_aim_direction_y * CAMERA_OFFSET_AMOUNT,
					600.0,
					dt
				)
		end
		if self.camera_target.pos.x < self.room.left then
			self.camera_target.pos.x = self.room.left
		elseif self.camera_target.pos.x > self.room.right then
			self.camera_target.pos.x = self.room.right
		end
		if self.camera_target.pos.y < self.room.top then
			self.camera_target.pos.y = self.room.top
		elseif self.camera_target.pos.y > self.room.bottom then
			self.camera_target.pos.y = self.room.bottom
		end
    end

	self.border_rainbow_offset = self.border_rainbow_offset + dt / max(20 / self.room.wave, 1)

	if input.debug_skip_wave_held and not self.room.cleared then
		local objects = self:get_objects_with_tag("wave_enemy")
		for _, obj in objects:ipairs() do
			if obj.world then
				if obj.die then
					obj:die(self:get_random_object_with_tag("player"))
				elseif not obj.is_queued_for_destruction then
					-- obj:queue_destroy()
				end
			end
		end
	end

	if debug.enabled then
		dbg("enemies_to_kill", table.length(self.enemies_to_kill))
		dbg("world state", self.state, Color.skyblue)
		dbg("number of objects", self.objects:length())
		-- dbg("waiting_on_rooms", self.waiting_on_rooms)
	end

	if not table.is_empty(self.notification_queue) and not self.timescaled:is_timer_running("player_notify_cooldown") then
        local notification = table.remove(self.notification_queue, 1)
		self:play_notification(notification)
		self.timescaled:start_timer("player_notify_cooldown", 52)
	end

    if self.room.curse and self.state == "Normal" or self.state == "Spawning" then
        local curse = self.room.curse
        if curse == "curse_wrath" then
            local player = self:get_random_player()
            if self.room.tick_scaled > 60 and self.timescaled.is_new_tick and not self.timescaled:is_tick_timer_running("wrath_timer") and rng:percent(1.0) and player then
                self.timescaled:start_tick_timer("wrath_timer", 110)
                local pbx, pby = player:get_body_center()
                self:spawn_object(EggWrath(pbx, pby))
            end
        elseif curse == "curse_fatigue" and self.timescaled.is_new_tick and rng:percent(1) and self:get_number_of_objects_with_tag("fatigue_zone") < 3 then
            self:spawn_object(FatigueZone(self:get_random_position_in_room()))
        end
    end


end

function GameWorld:play_notification(notification)
	if notification.sound then
		self:play_sfx(notification.sound, notification.sound_volume)
	end
	if notification.custom_position == nil then
		for _, player in pairs(self.players) do
			local bx, by = player:get_body_center()
			local effect = self:notification_popup(bx, by - 12, notification)
			effect:ref("player", player)
			effect:add_update_function(function(self, dt)
				if self.player then
					local bx, by = self.player:get_body_center()
					self:move_to(splerp_vec(self.pos.x, self.pos.y, bx, by - self.elapsed * 0.15 - 12, 300, dt))
				end
			end)
			effect.custom_movement = true
		end
	end
end

function GameWorld:notification_popup(x, y, notification)
	notification = notification or {}
	local text = notification.text
	local palette_stack = notification.palette_stack

	local effect = TextPopupEffect(x, y, text, palette_stack, notification.duration)
	return self:add_object(effect)
end

function GameWorld:get_valid_spawn_position(depth)
	local MIN_DISTANCE_BETWEEN_ENEMIES = 32
	local SPAWN_ON_PLAYER_AT_THIS_DISTANCE = 80
	local MIN_DISTANCE_FROM_PLAYER = 48

	depth = depth or 1

	local x, y = 0, 0
	local c = 0
	local spawned_on_player = false

	local random_player_pos = rng:choose(table.values(self.last_player_body_positions))

	-- while vec2_distance(x, y, self.last_player_body_pos.x, self.last_player_body_pos.y) < 32 do
	-- if c > 0 then
	-- 	spawned_on_player = false
	-- end
	-- while vec2_distance(x, y, self.player_position.x, self.player_position.y) < 32 do
	x = rng:randi(-self.room.room_width / 2, self.room.room_width / 2)
	y = rng:randi(-self.room.room_height / 2, self.room.room_height / 2)
	local wave_enemies = self:get_objects_with_tag("wave_enemy")
	local hazards = self:get_objects_with_tag("hazard")
	local wave_spawners = self:get_objects_with_tag("enemy_spawner")
	local rescues = self:get_objects_with_tag("rescue_object")

	for i = 1, 10 do
		local valid = true

		if valid then
			for _, object in rescues:ipairs() do
				if vec2_distance(x, y, object.pos.x, object.pos.y) < MIN_DISTANCE_BETWEEN_ENEMIES then
					valid = false
					break
				end
			end
		end

		if valid then
			for _, object in wave_spawners:ipairs() do
				if vec2_distance(x, y, object.pos.x, object.pos.y) < MIN_DISTANCE_BETWEEN_ENEMIES then
					valid = false
					break
				end
			end
		end

		if valid then
			for _, object in wave_enemies:ipairs() do
				if vec2_distance(x, y, object.pos.x, object.pos.y) < MIN_DISTANCE_BETWEEN_ENEMIES then
					valid = false
					break
				end
			end
		end

		if valid then
			for _, object in hazards:ipairs() do
				if vec2_distance(x, y, object.pos.x, object.pos.y) < MIN_DISTANCE_BETWEEN_ENEMIES then
					valid = false
					break
				end
			end
		end

		-- if valid then
		-- 	for i, object in pairs(self.last_player_body_positions) do
		-- 		if vec2_distance(x, y, object.x, object.y) < MIN_DISTANCE_FROM_PLAYER then
		-- 			valid = false
		-- 			break
		-- 		end
		-- 	end
		-- end

		if valid then
			break
		else
			x = rng:randi(-self.room.room_width / 2, self.room.room_width / 2)
			y = rng:randi(-self.room.room_height / 2, self.room.room_height / 2)
		end
		-- end

		c = c + 1

		-- if c > 100 then
		--     print("failed to find valid spawn position")
		--     break
		-- end
	end

	if not self.spawned_on_player and rng:percent(1) and vec2_distance(0, 0, random_player_pos.x, random_player_pos.y) > SPAWN_ON_PLAYER_AT_THIS_DISTANCE then
		x = random_player_pos.x
		y = random_player_pos.y
		spawned_on_player = true
	else
		for i, object in pairs(self.last_player_body_positions) do
			if vec2_distance(x, y, object.x, object.y) < MIN_DISTANCE_FROM_PLAYER and depth < 5 then
				return self:get_valid_spawn_position(depth + 1)
			end
		end
	end


	if spawned_on_player then
		self.spawned_on_player = true
	end

	return x, y
end

function GameWorld:update_draw_params()
end

-- function GameWorld:track_object_class_count(obj)
--     self.object_class_counts[obj.class] = (self.object_class_counts[obj.class] or 0) + 1
-- 	signal.connect(obj, "destroyed", self, "on_object_class_count_changed", function()
-- 		self.object_class_counts[obj.class] = (self.object_class_counts[obj.class] or 0) - 1
-- 		if self.object_class_counts[obj.class] <= 0 then
-- 			self.object_class_counts[obj.class] = nil
-- 		end
-- 	end)
-- end

function GameWorld:add_object(obj)
	GameWorld.super.add_object(self, obj)
	if obj.floor_draw then
		self:add_tag(obj, "floor_draw")
	end

	return obj
end

function GameWorld:draw_shared(...)
	-- self:update_draw_params()
	GameWorld.super.draw_shared(self, ...)
end

function GameWorld:point_is_in_bounds(x, y)
	return x >= self.room.left and x <= self.room.right and y >= self.room.top and y <= self.room.bottom
end

function GameWorld:get_clear_color()

	if self.room.get_clear_color then
		local color = self.room:get_clear_color()
		if color then
			return color
		end
	end

	local flash_length1 = 0.7
	if self.player_hurt_fx_t < flash_length1 and self.player_hurt_fx_t > 0 and iflicker(self.tick, 2, 2) then
		return Color(0.3 * remap(self.player_hurt_fx_t, 0, flash_length1, 1, 0), 0.0, 0.0, 1.0)
	end
	
	local flash_length2 = 0.6
	if self.room_clear_fx_t < flash_length2 and self.room_clear_fx_t > 0 then
		return Color(0.0, 0.0, 0.15 * remap(self.room_clear_fx_t, 0, flash_length2, 1, 0), 1.0)
	end

	if self.timescaled:is_tick_timer_running("clock_slow") then
		local t = self.timescaled:tick_timer_time_left("clock_slow") / self.timescaled:tick_timer_duration("clock_slow")
		t = ease("outExpo")(t)
		local shade = 0.075
		return Color(shade * t, shade * t, shade * t, 1.0)
	end


	return Color.transparent
end

function GameWorld:clear_floor_canvas(deferred)
    if deferred == nil then deferred = true end

    local f = self.clear_function or function()
		local width = max(FLOOR_CANVAS_WIDTH, self.room.room_width + 512)
        local height = max(FLOOR_CANVAS_HEIGHT, self.room.room_height + 512)
		self.floor_canvas_width = width
		self.floor_canvas_height = height
		self.lower_floor_canvas = graphics.new_canvas(width, height)
		self.current_frame_floor_canvas = graphics.new_canvas(width, height,
			{ readable = true })
		self.empty_canvas = graphics.new_canvas(width, height)
		self.persistent_floor_canvas = graphics.new_canvas(width, height)
		self.previous_persistent_floor_canvas = graphics.new_canvas(width, height, { readable = true })
		self.full_brightness_floor_canvas = graphics.new_canvas(width, height)
		self.previous_full_brightness_floor_canvas = graphics.new_canvas(width, height, { readable = true })
		self.current_frame_floor_canvas_settings = {
			self.current_frame_floor_canvas,
			stencil = true,

		}
		self.output_canvas = graphics.new_canvas(width, height)
	end

	self.clear_function = f

	if deferred then
		self:defer(f)
	else
		f()
	end
end

function GameWorld:floor_canvas_push()
	graphics.push("all")
	graphics.set_color(1, 1, 1, 1)
	graphics.set_canvas(self.current_frame_floor_canvas)
	graphics.origin()
	graphics.translate(self.floor_canvas_width / 2, self.floor_canvas_height / 2)
end

function GameWorld:floor_canvas_pop()
	graphics.pop()
end

local shader_black = {0, 0, 0, 0}


function GameWorld:draw_floor_canvas()

    
	do
		graphics.push("all")
		graphics.set_canvas(self.current_frame_floor_canvas_settings)
		graphics.clear(0, 0, 0, 0)
		graphics.pop()
	end


    do
		-- if not self.paused then
			self:floor_canvas_push()
			if self.tags and self.tags["floor_draw"] then
				for _, obj in (self.tags["floor_draw"]):ipairs() do
					do
						graphics.push("all")
						graphics.translate(self:get_object_draw_position(obj))
						obj:floor_draw()
						graphics.pop()
					end
				end
			end
			self:floor_canvas_pop()
		-- end
	end

	graphics.set_color(1, 1, 1, 1)

    do
        graphics.push("all")
        graphics.set_color(1, 1, 1, 1)
        graphics.translate(-self.floor_canvas_width / 2, -self.floor_canvas_height / 2)

        local level_transition_alpha = 1.0
        if self.state == "LevelTransition" then
            level_transition_alpha = max(1 - self.state_elapsed / 5, 0)
        end

        do
            graphics.push("all")
            local shader = graphics.shader.alphareplace
            graphics.set_canvas(self.persistent_floor_canvas)
            shader:send("input_texture", self.previous_persistent_floor_canvas)
            shader:send("replace_texture", self.current_frame_floor_canvas)

            -- Fade out old floor every few ticks
            shader:send("old_alpha", (self.timescaled.is_new_tick and self.timescaled.tick % 10 == 0) and 0.93 or 1.0)
            graphics.set_shader(shader)

            graphics.origin()
            graphics.clear(0, 0, 0, 0)
            -- Draw floor objects
            graphics.draw(self.empty_canvas)

            graphics.set_canvas(self.full_brightness_floor_canvas)
            graphics.set_shader()
            graphics.draw(self.current_frame_floor_canvas)
            graphics.pop()
        end

        do
            graphics.push("all")
            graphics.set_canvas(self.previous_persistent_floor_canvas)
            graphics.origin()
            graphics.clear(0, 0, 0, 0)
            graphics.draw(self.persistent_floor_canvas)
            graphics.pop()
        end

        do
            graphics.push("all")
            graphics.set_canvas(self.output_canvas)
            graphics.origin()
            graphics.clear(0, 0, 0, 0)

            graphics.set_color(level_transition_alpha, level_transition_alpha, level_transition_alpha, 1)
            graphics.draw(self.persistent_floor_canvas)

            graphics.set_color(1, 1, 1, 0.225 * level_transition_alpha)
            graphics.draw(self.full_brightness_floor_canvas)
            graphics.pop()
        end

        do
            graphics.push("all")
            local shader = graphics.shader.alphamask
            shader:send("mask_color", shader_black)
            graphics.set_shader(shader)
            graphics.draw(self.output_canvas)
            graphics.pop()
        end

        graphics.pop()
    end
end

function GameWorld:draw()
	if self.floor_drawing then
		self:draw_floor_canvas()
	end

	local r = self.room
	local tlx, tly = r.left, r.top
	local trx, try = r.right, r.top
	local blx, bly = r.left, r.bottom

    local floor_darken_row_width = self.floor_canvas_width
    local floor_darken_row_height = (self.floor_canvas_height - self.room.room_height) / 2
    local floor_darken_column_height = self.floor_canvas_height - floor_darken_row_height * 2
    local floor_darken_column_width = (self.floor_canvas_width - self.room.room_width) / 2

    do
		graphics.push("all")
		local clear_color = self:get_clear_color()
        graphics.set_color(clear_color.r, clear_color.g, clear_color.b, 0.6)
		-- graphics.rectangle("fill", tlx - floor_darken_column_width, tly - floor_darken_row_height, floor_darken_row_width, floor_darken_row_height)
		-- graphics.rectangle("fill", blx - floor_darken_column_width, bly, floor_darken_row_width, floor_darken_row_height)
		-- graphics.rectangle("fill", tlx - floor_darken_column_width, tly, floor_darken_column_width, floor_darken_column_height)
		-- graphics.rectangle("fill", trx, try, floor_darken_column_width, floor_darken_column_height)
		graphics.pop()
    end
	
	

	-- Handle room bounds drawing based on clear effect
	-- local draw_bounds_over = self.room_clear_fx_t < 0.45 and self.room_clear_fx_t > 0
    -- if not draw_bounds_over then
    self:draw_room_bounds()
        -- self:draw_top_info()
    -- end
    
    graphics.push("all")
    self:draw_top_info()
    graphics.pop()

	-- Draw tutorial text if active
	if self.tutorial_state and not self.paused then
		graphics.set_color(Color.green)
		local font = fonts.depalettized.image_font2
        graphics.set_font(font)

		if self.tutorial_state == 1 then
			-- graphics.print_centered(tr.tutorial_boost2, font, 0, 28)
			graphics.print_centered(tr.tutorial_boost:format(input.last_input_device == "gamepad" and control_glyphs.lt or control_glyphs.space), font, 0, 16)
		elseif self.tutorial_state == 2 then
			graphics.print_centered(tr.tutorial_move:format(input.last_input_device == "gamepad" and control_glyphs.l or tr.control_wasd), font, 0, -6)
			graphics.print_centered(tr.tutorial_shoot:format(input.last_input_device == "gamepad" and control_glyphs.r or control_glyphs.lmb), font, 0, 9)
		end
	end


    -- Draw base game world
    if self.rendering_content then
        GameWorld.super.draw(self)
    end

	-- Draw room bounds on top if needed
	-- if draw_bounds_over then
        -- self:draw_room_bounds()
        
	-- end
end

local function format_score(n, lead_zeros, font)
    lead_zeros = math.max(lead_zeros or 0, 0)

    local abs_str = tostring(math.abs(n))
    local sign    = n < 0 and "-" or ""

    -- how many zeros to pad so total digits ≥ lead_zeros
    local zero_count = math.max(lead_zeros - #abs_str, 0)
    local pad_str    = string.rep("0", zero_count) .. abs_str

    local padded_str   = sign .. comma_sep(pad_str)
    local unpadded_str = sign .. comma_sep(abs_str)

    -- figure out how much of padded_str we'd have to chop off
    local diff_len  = #padded_str - #unpadded_str
    local hidden_str = padded_str:sub(1, diff_len)

    -- positive offset: move right by this many chars or pixels
    local x_offset = font
        and font:getWidth(hidden_str)
        or diff_len

    return padded_str, unpadded_str, x_offset
end

function GameWorld:draw_quick_clear_progress_bar()
    -- Draw quick clear progress bar
    local left = self.room.left + 61
    local top = self.room.top

    local quick_clear_ratio = clamp01(self:get_quick_clear_time_left_ratio())
    if quick_clear_ratio > 0 then
        quick_clear_ratio = 1 - quick_clear_ratio
    end
    local border_color = self:get_border_rainbow()
    local colormod = lerp(1 - quick_clear_ratio, 1, 0.15)
    if quick_clear_ratio < (3 / 10) and iflicker(self.tick, 5, 2) and self.state == "Normal" then
        colormod = 0.0
    end
    graphics.set_color(border_color.r * colormod, border_color.g * colormod, border_color.b * colormod)
    local x_scale = 130 * quick_clear_ratio
    local y_scale = 3
    graphics.rectangle("fill", (left + 1), top - y_scale - 2, x_scale, y_scale)
end

function GameWorld:draw_top_info()


	if not self.showing_hud then
		return
	end
    
    self:draw_quick_clear_progress_bar()

    graphics.origin()
    local screen = self.canvas_layer
    graphics.translate(self.viewport_size.x / 2 - conf.viewport_size.x / 2, self.viewport_size.y / 2 - conf.viewport_size.y / 2)
    -- local offsx, offsy = self:get_object_draw_position(self.camera)
    -- offsx, offsy = vec2_add(offsx, offsy, self.camera:get_draw_offset())
    -- graphics.translate(offsx, offsy)

    if not self.player_hatched then
        return
    end

    local x_start = 0
    local y_start = - 2
    
    
    x_start = floor(x_start)
    y_start = floor(y_start)

    local h_padding = conf.room_padding.x - 2
    local v_padding = conf.room_padding.y - 9



    local left = x_start + h_padding
    local top = y_start + v_padding - 1
    local font = fonts.hud_font

    local border_color = self:get_border_rainbow()
    local charwidth = fonts.hud_font:getWidth("0")

    local hud_layer = self.canvas_layer.parent.hud_layer






	graphics.set_font(font)
	graphics.set_color(Color.white)


	graphics.push()
	graphics.translate(floor(left), top)
	-- graphics.set_color(Color.darkergrey)
	graphics.set_color(Color.grey)
	-- graphics.print("LVL", 0, 0)
	local level_with_zeroes, level_without_zeroes, level_x = format_score(game_state.level % 100, 2, font)
	level_x = level_x
	local zero_start = font:getWidth("LVL")

	graphics.print("LVL", 0, 0)
	graphics.set_color(Color.darkergrey)
	
	graphics.print(level_with_zeroes, zero_start, 0)

	graphics.set_color(Color.white)
	-- graphics.set_color(Palette.rainbow:tick_color(gametime.tick, 0, 10))
	
	graphics.print(level_without_zeroes, level_x + zero_start, 0)
	graphics.set_color(Color.grey)
	graphics.print("WAVE", 32, 0)
	graphics.set_color(Color.white)
	graphics.print(string.format("%01d", game_state.wave), font:getWidth("WAVE") + 32, 0)
	graphics.set_color(Color.darkergrey)
	
	
	graphics.translate(charwidth * 20 + 6, 0)
	graphics.translate(charwidth * 11 + 3, 0)


	local category_high = savedata:get_category_highs(game_state.leaderboard_category)
	local high_score = category_high and category_high.score or 0

	local beat_high = false
	if hud_layer.score_display < high_score then
		graphics.set_color(Color.darkgrey)
		local i = 1
		local finished = false
		local tens = 1
		while not finished do
			if idiv(hud_layer.score_display, tens) > 0 then
				tens = tens * 10
			else
				finished = true
			end
		end
		high_score = high_score - (high_score % tens) + hud_layer.score_display
		local best_score = comma_sep(high_score)
		graphics.set_color(Color.darkergrey)
        graphics.print_right_aligned(best_score, font, 0, 0)
    else
		beat_high = true
	end

	local score_without_zeroes = comma_sep(hud_layer.score_display)

	graphics.set_color(beat_high and Palette.high_score_ingame:tick_color(self.tick, 0, 7) or border_color)
	graphics.print_right_aligned(score_without_zeroes, font, 0, 0)
	graphics.set_color(Color.grey)
	
	local scoremult1 = "×["
	-- local scoremult6 = "["
	local scoremult2 = string.format("%-.2f", game_state:get_score_multiplier(false))
	local scoremult3 = string.format("×%02d", max(1, game_state:get_rescue_chain_multiplier()))
	-- local scoremult3 = string.format("+%02d", game_state:get_rescue_chain_multiplier())
	local scoremult4 = "   "
    local scoremult5 = "]"

	local greenoid_color = Color.green
	if self:is_timer_running("greenoid_harmed_flash") then
		greenoid_color = iflicker(self.tick, 3, 2) and Color.red or Color.green
	end
	graphics.print_multicolor(font, 0, 0, scoremult1, Color.grey, scoremult2, Color.white, scoremult3, greenoid_color,
		scoremult4, Color.white, scoremult5, Color.grey)
	graphics.set_color(Color.white)
	graphics.drawp_centered(textures.ally_rescue1, nil, 0, font:getWidth(scoremult1..scoremult2..scoremult3) + 6, 4)
    graphics.pop()
end

function GameWorld:get_border_color()
    if self.room.get_border_color then
        local room_color = self.room:get_border_color()
        if room_color then
            return room_color
        end
    end

    if self.player_death_fx then
        return Palette.player_death_border:get_color(floor(self.tick / 2))
    end

    if self.player_died then
        return Color.red
    end

    if self.player_hurt_fx_t > 0 then
        return iflicker(self.tick, 2, 2) and Color.black or Color.red
    end

    if self.state == "RoomClear" then
        return Palette.room_clear_border:get_color(floor(gametime.tick / 4))
    end

    if self.timescaled:is_tick_timer_running("clock_slow") then
        return Color.transparent
    end

    if self.state == "Spawning" then
        return Palette.spawning_border:get_color(floor(gametime.tick / 4))
    end

    if self.state == "LevelTransition" then
        return Color.black
    end

    return self:get_border_rainbow()
end

function GameWorld:get_border_rainbow()
	return Palette.rainbow:get_color(floor(self.border_rainbow_offset))
end

function GameWorld:is_border_dash_swapped()
	if iflicker(self.tick, 4, 2) then
		return false
	end

	if self.player_death_fx then
		return true
	end

	-- if self.player_died then
	--     return true
	-- end

	if self.state == "Spawning" then
		return true
	end

	return false
end

function GameWorld:draw_room_bounds()
	local r = self.room

	local tlx, tly = r.left, r.top

	
	local min_t = 1.0
    local color = self:get_border_color()

	if self.room_clear_fx_t > min_t or self.room_clear_fx_t == -1 then
        local dash_swapped = self:is_border_dash_swapped()
		local solid_color = self.state == "RoomClear" or self.player_hurt_fx_t < 0.5 and self.player_hurt_fx_t > 0
		-- graphics.rectangle("line", tlx, tly, r.right - r.left + 1, r.bottom - r.top + 1)
		-- graphics.points(tlx, tly, trx, try, brx, bry, blx, bly)
		-- graphics.line(tlx, tly, trx, try)
		-- -- graphics.line(trx, try, brx, bry)
		-- graphics.line(brx, bry, blx, bly)
		graphics.set_line_width(1)
		local scale = 0
		if self.room then
			local t = clamp(self.room_border_fade_in_time / 30, 0, 1.0)
			scale = 1.05 - ease("outCubic")(t) * 0.05
			if t > 0.7 then 
				scale = 1.0
			end
		end
		local red, green, blue = color.r, color.g, color.b
		local alpha = ease("outCubic")(clamp(self.room_border_fade_in_time / 20, 0, 1.0))
		if self.room_clear_fx_t > min_t then
			alpha = alpha * (remap_clamp(self.room_clear_fx_t, min_t, 1, 0, 1))
		end

        local r2,g2,b2 = red * alpha, green * alpha, blue * alpha
		graphics.set_color(r2, g2, b2)

		graphics.push()
        graphics.translate(tlx + r.room_width / 2, tly + r.room_height / 2)

        local border_dash_offset = 0
        -- local border_dash_offset = ease("outCubic")(inverse_lerp_clamp(0, 600, r.elapsed)) * 100


        if self.room.wave < self.room.last_wave then
            local offs = remap_clamp(self:get_quick_clear_time_left_ratio(), 0.85, 1, 0, 1)
            offs = ease("inCubic")(offs) * 10
            offs = offs * (self.room.wave % 2 == 0 and 1 or -1)
            border_dash_offset = border_dash_offset + offs
        end
        
        if Color.distance_unpacked(r2, g2, b2, 0, 0, 0) > 0.001 then

            if not solid_color then
                if dash_swapped then
                    border_dash_offset = border_dash_offset + 0.5
                    -- graphics.set_color(red * alpha, green * alpha, blue * alpha)
                    -- graphics.rectangle("line", (-r.room_width / 2) * scale, (-r.room_height / 2) * scale, r.room_width * scale + 1,
                    --     r.room_height * scale + 1)
                    -- graphics.set_color(0, 0, 0, 1)
                end
                graphics.dashrect((-r.room_width / 2) * scale, (-r.room_height / 2) * scale, r.room_width * scale + 1,
                    r.room_height * scale + 1, 2, 2, border_dash_offset)
            else
                if self.player_hurt_fx_t < 0.5 and self.player_hurt_fx_t > 0 then
                    graphics.set_line_width(2)
                end
                graphics.rectangle("line", (-r.room_width / 2) * scale, (-r.room_height / 2) * scale, r.room_width * scale + 1,
                r.room_height * scale + 1)
            end
        end
		graphics.pop()
	end

	-- graphics.dashrect(tlx + 1, tly + 1, r.right - r.left - 1, r.bottom - r.top - 1, 2, 2)

	if self.room_clear_fx_t >= 0 then
		if iflicker(self.tick, 1, 2) and self.room_clear_fx_t > 0.75 then
			return
		end
		local t_eased = ease("inOutCirc")(clamp(self.room_clear_fx_t, 0, 1.0))
		local t_eased_out = ease("outCirc")(clamp(self.room_clear_fx_t, 0, 1.0))
		local t_eased_out2 = ease("outInSine")(clamp(self.room_clear_fx_t, 0, 1.0))
		local t_linear = self.room_clear_fx_t
		local line_width = clamp((1 - t_eased) * 5, 1, 5)
		graphics.set_line_width(line_width)
		local rect_offset = 50 * t_eased_out + 2
		local rect_offset2 = -(5 * ((1 - t_linear)) + 1)
		local rect_offset3 = 20 * t_eased_out + 2
		local rect_offset4 = 200 * t_eased_out + 2
		if line_width > 0.5 then
			graphics.set_color(Palette.rainbow:tick_color(self.tick + 3, 0, 3))
			graphics.rectangle_centered("line", 0, 0, r.room_width + 1 + rect_offset3, r.room_height + 1 + rect_offset3)
		end
		graphics.set_line_width(1)
		graphics.set_color(Palette.rainbow:tick_color(self.tick + 9, 0, 3))
		graphics.rectangle_centered("line", 0, 0, r.room_width + rect_offset4, r.room_height + rect_offset4 + 1)
		-- graphics.set_line_width(1)
		-- if iflicker(self.tick, 2, ceil(10 - t_eased * 10)) then
		-- return
		-- end
		graphics.set_color(Palette.rainbow:tick_color(self.tick, 0, 3))
		graphics.rectangle_centered("line", 0, 0, r.room_width + rect_offset2, r.room_height + rect_offset2 + 1)
		graphics.set_color(Palette.rainbow:tick_color(self.tick + 6, 0, 3))
		graphics.rectangle_centered("line", 0, 0, r.room_width + rect_offset, r.room_height + rect_offset + 1)
	end
	-- graphics.line(blx, bly, tlx, tly)
end

function GameWorld:state_Normal_enter()
end

function GameWorld:state_Normal_update(dt)
	if self.wave_started and self.enemies_to_kill and table.is_empty(self.enemies_to_kill) then
		self:on_wave_cleared()
	end

	if input.debug_skip_wave_held then
		if self.state == "Normal" and self.state_tick > 5 then
			self.timescaled:end_tick_timer("wave_timer")
		end
	end

	-- if self.room.wave == self.room.last_wave then
	local s = self.timescaled.sequencer
	local enemies_left = self:get_number_of_objects_with_tag("wave_enemy")
    if self.room.can_highlight_enemies and enemies_left <= 5 and enemies_left > 0 and not self.room.highlighting_enemies then
		self.highlight_last_enemies_sequence = s:start(function()
			for _, obj in self:get_objects_with_tag("wave_enemy"):ipairs() do
				if obj and obj.highlight_self then
					obj:highlight_self()
				end
				s:wait(5)
			end
			-- s:wait(0)
            if not self.room.highlighting_enemies then
                self:play_sfx("highlight_last_enemies", 1, 1.0)
                self.room.highlighting_enemies = true
            end
		end)
	end
    -- end
    

end


function GameWorld:get_effective_fire_rate()
    local fire_rate = game_state.upgrades.fire_rate
    if game_state.artefacts.crown_of_frenzy and self:get_number_of_objects_with_tag("rescue_object") == 0 then
        fire_rate = fire_rate + 1
    end
    return fire_rate
end


function GameWorld:state_RoomClear_enter()
end

function GameWorld:state_RoomClear_exit()
	self.waiting_on_rooms = false
end

function GameWorld:state_RoomClear_update(dt)
	if self.waiting_on_rooms then
		self.next_rooms = self:create_next_rooms()
		self:spawn_room_objects()
		self.waiting_on_rooms = false
	end
end

function GameWorld:state_Spawning_enter()
	-- self.object_time_scale = 0.025
	-- self.frozen = true
end

function GameWorld:state_Spawning_exit()
	-- self.object_time_scale = 1.0
	-- self.frozen = false
end

function GameWorld:state_LevelTransition_enter(room)
    self.tutorial_state = nil
    self.sequencer:stop(self.tutorial_sequence)
	
	local room_objects = self:get_objects_with_tag("room_object")
	for _, obj in room_objects:ipairs() do
		obj:die()
	end

	self.frozen = true
	self.transitioning_to_room = room
	local s = self.sequencer

	-- self.frozen = true
	s:start(function()
		local length = 10

		self:play_sfx("level_start", 0.95, 1.0)

		s:wait(2)
		s:start(function()
			s:wait(5)
			collectgarbage("collect")
		end)

		local move_tween = "linear"

        local direction = self.player_entered_direction
		
        local transition_objects = self:get_objects_with_tag("move_with_level_transition")
		for i, obj in transition_objects:ipairs() do
		-- for i, player in pairs(self.players) do
			local obj_pos = obj.pos:clone()
			local new_spot_x, new_spot_y

			if direction.x ~= 0 or direction.y ~= 0 then
				new_spot_x, new_spot_y = direction.x ~= 0 and (-direction.x * (self.room.room_width / 2 - 16)) or obj_pos.x, direction.y ~= 0 and (-direction.y * (self.room.room_height / 2 - 16)) or obj_pos.y
			else
				new_spot_x, new_spot_y = 0, 0
			end

			local final_offset_x = (new_spot_x + direction.x * self.room.room_width) - obj_pos.x
			local final_offset_y = (new_spot_y + direction.y * self.room.room_height) - obj_pos.y

			local move_obj = function(t)
				if direction.x ~= 0 or direction.y ~= 0 then
					obj:move_to(obj_pos.x + final_offset_x * t, obj_pos.y + final_offset_y * t)
				else
					obj:move_to(obj_pos.x, obj_pos.y)
				end
				if obj.is_player then
					obj.vel:mul_in_place(0.0)
					obj.hover_vel:mul_in_place(0.0)
				end
			end
			s:start(function()
				s:tween(move_obj, 0, 1, length, move_tween)
				obj:move_to(new_spot_x, new_spot_y)
				if obj.is_player then
					obj:change_state("Walk")
				end
			end)
		end

		local camera_pos = self.camera_target.pos:clone()
        local move_camera = function(t)
            local new_x, new_y = camera_pos.x + (direction.x * self.room.room_width) * t,
                camera_pos.y + (direction.y * self.room.room_height) * t
            self.camera_target:move_to(new_x, new_y)
        end
		
		
		s:start(function()
			self.moving_camera_target = true
			s:tween(move_camera, 0, 1, length, move_tween)
			self.camera_target:move_to(CAMERA_TARGET_OFFSET.x, CAMERA_TARGET_OFFSET.y)
			self.moving_camera_target = false
        end)
		

		s:wait(length - 1)
		self:clear_floor_canvas()
		self:clear_objects()
		s:wait(2)


		s:wait(1)
		self:change_state("Normal")
	end)
end

function GameWorld:state_LevelTransition_update(dt)
end

function GameWorld:state_LevelTransition_exit()
	self:initialize_room(self.transitioning_to_room)
	self.transitioning_to_room = nil
    self.frozen = false
    self:room_border_fade("in", 2)
    game_state:on_level_transition()
end

function GameWorld:room_border_fade(in_or_out, time_scale)
    local s = self.sequencer

    self.fade_sequence = s:start(function()
        s:tween_property(self, "room_border_fade_in_time", in_or_out == "in" and 0 or 600, in_or_out == "in" and 600 or 0, 600 * (time_scale or 1), "linear")
		self.fade_sequence = nil
    end)
end

function GameWorld:state_LevelTransition_draw()
	graphics.push("all")
	graphics.set_color(1, 1, 1, 1)
	local r = self.room

	local tlx, tly = r.left, r.top
	-- local trx, try = r.right, r.top
	-- local brx, bry = r.right, r.bottom
	-- local blx, bly = r.left, r.bottom


	graphics.set_color(Color.white)
	-- graphics.rectangle("line", tlx, tly, r.right - r.left + 1, r.bottom - r.top + 1)
	-- graphics.points(tlx, tly, trx, try, brx, bry, blx, bly)
	-- graphics.line(tlx, tly, trx, try)
	-- -- graphics.line(trx, try, brx, bry)
	-- graphics.line(brx, bry, blx, bly)
	graphics.set_line_width(1)
	-- graphics.rectangle("line", tlx, tly, r.right - r.left + 1, r.bottom - r.top + 1)
	graphics.pop()
end

function GameWorld:destroy()
	GameWorld.super.destroy(self)
end

AutoStateMachine(GameWorld, "Normal")

return GameWorld
