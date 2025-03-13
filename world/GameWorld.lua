local GameWorld = World:extend("GameWorld")
local O = require("obj")
local EnemySpawn = require("obj.EnemySpawn")
local SpawnDataTable = require("obj.spawn_data")
local Room = require("room.Room")
local shash = require "lib.shash"
local ScoreNumberEffect = require("fx.score_number_effect")
local TextPopupEffect = require("fx.text_popup_effect")

local CAMERA_OFFSET_AMOUNT = 20
local MAX_ENEMIES = 100
local MAX_HAZARDS = 50
-- local MAX_ENEMIES = 10000

local ROOM_CHOICE = true



function GameWorld:new(x, y)
	self.draw_sort = function(a, b)
		local az = a.z_index or 0
		local bz = b.z_index or 0

		if az < bz then
			return true
		elseif az > bz then
			return false
		end

		local avalue = a.pos.y + az - (a.body_height or 0)
		local bvalue = b.pos.y + bz - (b.body_height or 0)
		if avalue == bvalue then
			return a.pos.x < b.pos.x
		end
		return avalue < bvalue
	end
	GameWorld.super.new(self, x, y)

    self:add_signal("enemy_added")
    self:add_signal("enemy_died")
	self:add_signal("level_transition_started")

	self:lazy_mixin(Mixins.Behavior.AutoStateMachine, "Normal")


	self:add_spatial_grid("game_object_grid", 32)
    self:add_spatial_grid("declump_objects", 32)
	self:add_spatial_grid("pickup_objects", 32)
    self:add_spatial_grid("fungus_grid", 32)
    self:add_spatial_grid("bullet_grid", 32)
	self:add_spatial_grid("chargers", 32)
	self:add_spatial_grid("rescue_grid", 32)

	self.hurt_bubbles = {}
	self.hurt_bubbles["player"] = shash.new(32)
    self.hurt_bubbles["enemy"] = shash.new(32)
    self.hurt_bubbles["neutral"] = shash.new(32)
	
	self.hit_bubbles = {}
	self.hit_bubbles["player"] = shash.new(32)
    self.hit_bubbles["enemy"] = shash.new(32)
    self.hit_bubbles["neutral"] = shash.new(32)

    self.empty_update_objects = bonglewunch() 
	
    self.object_class_counts = {}
	self:add_signal("player_died")

	self.players = {}
    self.last_player_positions = {}
    self.last_player_body_positions = {}
	self.player_entered_direction = Vec2(rng.random_4_way_direction())

	self.notification_queue = {}
end

function GameWorld:enter()	
	-- we'll use this object when we need to time stuff with object_time_scale instead of the base world time.
	self:ref("timescaled", self:add_object(GameObject()))
    self.timescaled.persist = true
    self.timescaled:add_elapsed_ticks()
    self.timescaled:add_sequencer()
	
	self:clear_floor_canvas()

    audio.play_music("drone", 0.9)
    self:play_sfx("level_start", 0.95, 1.0)

    self.camera.persist = true

    game_state.level = game_state.level - 1
    local start_room = self:create_random_room()

    self:initialize_room(start_room)

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


	-- local threshold_notifs = {
	-- 	upgrade = tr.notif_upgrade_available,
	-- 	heart = tr.notif_heart_available,
	-- 	powerup =  tr.notif_powerup_available,
	-- 	item = tr.notif_item_available,

	-- }

    -- signal.connect(game_state, "xp_threshold_reached", self, "on_xp_threshold_reached", function(threshold_type)
	-- 	if self.state == "RoomClear" then
	-- 		return
	-- 	end
    --     local function threshold_notify(text, palette_name)
    --         self:quick_notify(
    --             text,
    --             palette_name,
    --             "pickup_ready_notification",
    --             0.75
    --         )
    --     end
		
	-- 	local notif = threshold_notifs[threshold_type]
	-- 	threshold_notify(notif, "notif_upgrade_available")
		
    -- end)

end

function GameWorld:quick_notify(text, palette_name, sound, sound_volume)
	print("notifying: " .. text)

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
    }

    -- self:notify_all_players(notification)
	table.insert(self.notification_queue, notification)
end


 
function GameWorld:create_random_room(room_params)
	local level_history = nil
	local old_room = self.room
    if old_room then
        level_history = old_room.level_history
    end
	
    -- TODO DELETE THIS
	level_history = nil

	local level = game_state.level
	level = level + 1
	
	local room = Room(self, level, game_state.difficulty, level_history, MAX_ENEMIES, MAX_HAZARDS)
	
	-- for _, room in ipairs(self.current_room_selection or {}) do
	-- 	for obj, _ in pairs(room.all_spawn_types) do
	-- 		room.redundant_spawns[obj] = true
	-- 	end
	-- end

	room:build(room_params)

	return room
end

function GameWorld:initialize_room(room)

    self.enemies_to_kill = {}
	
	game_state.level = game_state.level + 1

    self.room = room

    local s = self.timescaled.sequencer

    s:start(function()
		
        if table.is_empty(self.players) then
            self:create_player()
        end
		
        s:wait(15)
		
        self:spawn_wave()

    end)

    self:ref("camera_target", GameObject2D(0, 0))

    self.camera:follow(self.camera_target)
    -- self.camera:set_limits()
end

function GameWorld:start_wave_timer(duration)
    self:start_tick_timer("wave_timer", duration, function()
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
                for _ = 1, rng.randi_range(2, 120) do
                    if self.state ~= "RoomClear" then
						-- while self:get_number_of_objects_with_tag("rescue_object") >= max_rescues do
						-- 	s:wait(rng.randi_range(60, 120))
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
				-- 	self:start_tick_timer("rescue_spawn_cooldown", rng.randi_range(40, 120))
				-- end
				


				local rescue_object = self:spawn_object(rescue.rescue.class(self:get_valid_spawn_position()))
				if rescue.pickup then
					rescue_object:register_pickup(rescue.pickup)
				end
				self:add_tag(rescue_object, "rescue_object")
				signal.connect(rescue_object, "picked_up", self, "on_rescue_picked_up", function()
					self:on_rescue_picked_up(rescue_object)
				end)
			-- end)
		end
	end)
end

function GameWorld:on_rescue_picked_up(rescue_object)
    game_state:on_rescue(rescue_object)
	local bx, by = rescue_object:get_body_center()
	self:add_score_object(bx, by, rescue_object.spawn_data.score)
end

function GameWorld:spawn_wave()
	if self.room.cleared then return end

	game_state.wave = self.room.wave

	
	self:change_state("Spawning")

    
	self.wave_started = true
	
	self.spawned_on_player = false

    local spawns, rescue_spawns = self.room:spawn_wave()
	
	local s = self.timescaled.sequencer

    s:start(function()

		local highlights = self:get_objects_with_tag("last_enemy_target")
		if highlights then
			for _, highlight in highlights:ipairs() do
				highlight:queue_destroy()
			end
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
            self:start_wave_timer(max(600 - game_state.difficulty * 60, 120))
        else
			-- print("starting last wave quick clear timer")
			self:start_tick_timer("last_wave_quick_clear", max(600 - game_state.difficulty * 60, 120))
		end
	end)
end

function GameWorld:spawn_wave_group(s, wave, spawn_type, tag_name, max_count)
	s:start(function()
        for i, spawn_data in ipairs(wave) do

			if debug.enabled and input.debug_skip_wave_held then
				break
			end

            if self.player_died then
                break
            end

            local spawn_x, spawn_y = self:get_valid_spawn_position()

            -- local max_spawns = spawn.max_spawns or math.huge

            -- local max_instances = spawn.max_spawns + (game_state.difficulty - 1)
            -- local current_instances = self.object_class_counts[spawn_data.class] or 0

            -- if current_instances >= max_instances then
            -- 	goto continue
            -- end

            local spawn = self:spawn_object(EnemySpawn(spawn_x, spawn_y, spawn_type))
			self:add_tag(spawn, "enemy_spawner")
            -- self:add_tag(spawn, tag_name)
            signal.connect(spawn, "finished", self, "on_spawn_finished", function()
                if spawn_type == "hazard" then
                    self:spawn_wave_hazard(spawn_data.class(spawn_x, spawn_y))
                else
                    self:spawn_wave_enemy(spawn_data.class(spawn_x, spawn_y))
                end
            end)
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

function GameWorld:spawn_wave_pickup(pickup)
    local pickup_object = self:spawn_object(pickup)
	pickup_object:move(0, pickup_object.body_height / 2)
    -- self:register_spawn_wave_pickup(pickup_object)
end

function GameWorld:spawn_wave_hazard(hazard)
    local hazard_object = self:spawn_object(hazard)
	self:add_tag(hazard_object, "wave_spawn")
    self:add_tag(hazard_object, "wave_hazard")
	hazard_object:move(0, hazard_object.body_height / 2)
    -- self:register_spawn_wave_hazard(hazard_object)
	hazard_object:add_enter_function(hazard_object.life_flash)
end

function GameWorld:spawn_wave_enemy(enemy)
    local enemy_object = self:spawn_object(enemy)
	self:register_spawn_wave_enemy(enemy_object)
    enemy_object:move(0, enemy_object.body_height / 2)
	enemy_object:add_enter_function(enemy_object.life_flash)
end

function GameWorld:register_spawn_wave_enemy(enemy_object)
    self.enemies_to_kill[enemy_object] = true
	self:add_tag(enemy_object, "wave_enemy")
	self:add_tag(enemy_object, "wave_spawn")

    signal.connect(enemy_object, "died", self, "enemies_to_kill_table_on_enemy_died", function()
        local bx, by = enemy_object:get_body_center()

		self:add_score_object(bx, by, enemy_object:get_score())

        self.enemies_to_kill[enemy_object] = nil
		game_state.enemies_killed = game_state.enemies_killed + 1
    end)

    signal.connect(enemy_object, "destroyed", self, "enemies_to_kill_table_on_enemy_destroyed", function()
        self.enemies_to_kill[enemy_object] = nil
    end)
end

function GameWorld:add_score_object(x, y, score)
	score = game_state:determine_score(score)
	game_state:add_score(score)
	local score_object = self:spawn_object(ScoreNumberEffect(x, y, score))
end

function GameWorld:on_wave_cleared()
	self.wave_started = false

	local s = self.timescaled.sequencer
	s:start(function()
		if self.room.wave == self.room.last_wave then
            -- s:wait(10)
            if self:is_tick_timer_running("last_wave_quick_clear") then
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
	signal.connect(player, "died", self, "on_player_died", function()
        self:on_player_died()
    end)

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

	return player
end

function GameWorld:clear_objects()
	for _, object in self.objects:ipairs() do
		if not object.persist then
			object:queue_destroy()
		end
	end
	
end


function GameWorld:on_player_died()
    local s = self.sequencer
    s:start(function()
		self:play_sfx("old_player_death", 0.85, 1.0)
		self:play_sfx("hazard_death", 0.5, 1.0)
        self.object_time_scale = 0.125
        self.player_death_fx = true
		self.player_died = true
		s:wait(60)
        self.player_death_fx = false
        -- s:wait(120)
		local input = self:get_input_table()
		while not input.restart_held do
			s:wait(1)
		end
		self:emit_signal("player_died")
	end)
end

function GameWorld:spawn_room_objects()
	self.current_room_selection = {}
	local directions = { Vec2(1, 0), Vec2(0, 1), Vec2(-1, 0), Vec2(0, -1) }

	for i = 1, 4 do
		local direction = directions[i]
		if direction == -self.player_entered_direction then
			table.remove(directions, i)
			break
		end
	end

	local consumed_upgrade = false
	local consumed_powerup = false
	local consumed_heart = false
	local consumed_item = false

	local rooms = {}

	local needs_upgrade = game_state.num_queued_upgrades > 0 and not game_state:is_fully_upgraded()

	for i = 1, 3 do
		local room = self:create_random_room({
			bonus_room = (game_state.level) % 5 == 0,
			needs_upgrade = needs_upgrade and i == 3,
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

	local room_objects = {}

	for i = 1, 3 do
		local direction = directions[i]
		local spawn_pos_x, spawn_pos_y = direction.x * self.room.room_width / 2, direction.y * self.room.room_height / 2
		local room = rooms[i]
		
		consumed_upgrade = consumed_upgrade or room.consumed_upgrade
		consumed_powerup = consumed_powerup or room.consumed_powerup
		consumed_heart = consumed_heart or room.consumed_heart
		consumed_item = consumed_item or room.consumed_item

		local room_object = O.RoomObject(spawn_pos_x, spawn_pos_y, room)
		room_object.direction = direction
		room_object.points_rating = room.points_rating
		signal.connect(room_object, "room_chosen", self, "on_room_chosen", function()
			self.player_entered_direction = direction
			-- local s = self.sequencer
			-- s:start(function()
			self:change_state("LevelTransition", room)

			-- end)
		end)
		table.insert(room_objects, room_object)
	end

	local s = self.timescaled.sequencer
	s:start(function()
		for i = 1, 3 do
			self:spawn_object(room_objects[i])
			s:wait(2)
		end
	end)

	if consumed_upgrade then
		game_state:consume_upgrade()
	end
	
	if consumed_powerup then
		game_state:consume_powerup()
	end
	
	if consumed_heart then
		game_state:consume_heart()
	end
	
	if consumed_item then
		game_state:consume_item()
	end

	self.waiting_on_rooms = false
end

function GameWorld:on_room_clear()
	if self.room.cleared then
		return
	end

    self:change_state("RoomClear")

    local s = self.timescaled.sequencer

	self.room.cleared = true

    s:start(function()


		
        -- self.frozen = true
        self.object_time_scale = 0.125

        self:play_sfx("level_finished", 0.85, 1.0)
		

        s:wait(5)
		
		self.object_time_scale = 1.0


        while self:get_number_of_objects_with_tag("enemy") > 0 do
			local enemies = self:get_objects_with_tag("enemy")

			local waited = false
            if enemies then
                for i, enemy in enemies:ipairs() do
					if enemy.die then
						enemy:die(self:get_random_object_with_tag("player"))
					elseif not enemy.is_queued_for_destruction then
						enemy:queue_destroy()
					end
                    if i % 5 == 0 then
                        s:wait(2)
						waited = true
                    end
                end
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
            if rescues then
                for _, rescue in rescues:ipairs() do
                    local player = self:get_random_object_with_tag("player")
                    player:pickup(rescue)
					s:wait(2)
					waited = true
                end
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


		s:wait(20)

		self.waiting_on_rooms = true
    end)
end

function GameWorld:get_update_objects()
	if self.frozen then return self.empty_update_objects end

	return World.get_update_objects(self)
end

function GameWorld:update(dt)
    self.camera_aim_offset = self.camera_aim_offset or Vec2(0, 0)

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

	-- end
	

	-- if self.state ~= "LevelTransition" then
		-- if num_players > 0 then
		-- 	self.camera_target.pos.x, self.camera_target.pos.y =
		-- 		splerp_vec(
		-- 			self.camera_target.pos.x, self.camera_target.pos.y,
		-- 			average_player_x + self.camera_aim_offset.x, average_player_y + self.camera_aim_offset.y,
		-- 			dt,
		-- 			300.0
		-- 		)
	
		-- 	self.camera_aim_offset.x, self.camera_aim_offset.y =
		-- 		splerp_vec(
		-- 			self.camera_aim_offset.x, self.camera_aim_offset.y,
		-- 			average_player_aim_direction_x * CAMERA_OFFSET_AMOUNT,
		-- 			average_player_aim_direction_y * CAMERA_OFFSET_AMOUNT,
		-- 			dt,
		-- 			600.0
		-- 		)
		-- end
		-- if self.camera_target.pos.x < self.room.left then
		-- 	self.camera_target.pos.x = self.room.left
		-- elseif self.camera_target.pos.x > self.room.right then
		-- 	self.camera_target.pos.x = self.room.right
		-- end
		-- if self.camera_target.pos.y < self.room.top then
		-- 	self.camera_target.pos.y = self.room.top
		-- elseif self.camera_target.pos.y > self.room.bottom then
		-- 	self.camera_target.pos.y = self.room.bottom
		-- end
	-- end
	
	if input.debug_skip_wave_held and not self.room.cleared then
		local objects = self:get_objects_with_tag("wave_enemy")
		if objects then
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
	end

    if debug.enabled then
        dbg("enemies_to_kill", table.length(self.enemies_to_kill))
        dbg("world_state", self.state, Color.green)
        dbg("number of objects", self.objects:length())
		dbg("waiting_on_rooms", self.waiting_on_rooms)
    end

    if not table.is_empty(self.notification_queue) and not self.timescaled:is_timer_running("player_notify_cooldown") then
        local notification = table.remove(self.notification_queue, 1)

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
						self:move_to(splerp_vec(self.pos.x, self.pos.y, bx, by - self.elapsed * 0.15 - 12, dt, 300))
					end
                end)
				effect.custom_movement = true
            end
            self.timescaled:start_timer("player_notify_cooldown", 45)
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

	local random_player_pos = rng.choose(table.values(self.last_player_body_positions))

    -- while vec2_distance(x, y, self.last_player_body_pos.x, self.last_player_body_pos.y) < 32 do
	-- if c > 0 then
	-- 	spawned_on_player = false
	-- end
	-- while vec2_distance(x, y, self.player_position.x, self.player_position.y) < 32 do
	x = rng.randi_range(-self.room.room_width / 2, self.room.room_width / 2)
	y = rng.randi_range(-self.room.room_height / 2, self.room.room_height / 2)
	local wave_enemies = self:get_objects_with_tag("wave_enemy")
	local hazards = self:get_objects_with_tag("hazard")
    local wave_spawners = self:get_objects_with_tag("enemy_spawner")
	local rescues = self:get_objects_with_tag("rescue_object")

    for i = 1, 10 do
        local valid = true

		if valid and rescues then
			for _, object in rescues:ipairs() do
				if vec2_distance(x, y, object.pos.x, object.pos.y) < MIN_DISTANCE_BETWEEN_ENEMIES then
					valid = false
					break
				end
			end
		end
        
		if valid and wave_spawners then
            for _, object in wave_spawners:ipairs() do
                if vec2_distance(x, y, object.pos.x, object.pos.y) < MIN_DISTANCE_BETWEEN_ENEMIES then
                    valid = false
                    break
                end
            end
        end

        if valid and wave_enemies then
            for _, object in wave_enemies:ipairs() do
                if vec2_distance(x, y, object.pos.x, object.pos.y) < MIN_DISTANCE_BETWEEN_ENEMIES then
                    valid = false
                    break
                end
            end
        end

        if valid and hazards then
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
            x = rng.randi_range(-self.room.room_width / 2, self.room.room_width / 2)
            y = rng.randi_range(-self.room.room_height / 2, self.room.room_height / 2)
        end
        -- end

        c = c + 1

        -- if c > 100 then
        --     print("failed to find valid spawn position")
        --     break
        -- end
    end
	
	if not self.spawned_on_player and rng.percent(1) and vec2_distance(0, 0, random_player_pos.x, random_player_pos.y) > SPAWN_ON_PLAYER_AT_THIS_DISTANCE then
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

function GameWorld:track_object_class_count(obj)
    self.object_class_counts[obj.class] = (self.object_class_counts[obj.class] or 0) + 1
	signal.connect(obj, "destroyed", self, "on_object_class_count_changed", function()
		self.object_class_counts[obj.class] = (self.object_class_counts[obj.class] or 0) - 1
		if self.object_class_counts[obj.class] <= 0 then
			self.object_class_counts[obj.class] = nil
		end
	end)
end

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

function GameWorld:draw()
	graphics.push("all")
	graphics.set_canvas(self.temp_floor_canvas_settings)
    graphics.clear(0, 0, 0, 0)
	graphics.pop()

    if self.tags and self.tags["floor_draw"] then
        for _, obj in (self.tags["floor_draw"]):ipairs() do
            self:floor_canvas_push()
            graphics.translate(self:get_object_draw_position(obj))
            obj:floor_draw()
            self:floor_canvas_pop()
        end
    end

    graphics.set_color(1, 1, 1, 1)

    graphics.push("all")
		graphics.set_color(1, 1, 1, 1)
		-- graphics.circle("fill", 0, 0, 5)
		graphics.translate(self.room.left, self.room.top)
    	graphics.push("all")
			graphics.origin()
			graphics.set_canvas(self.floor_canvas)
			graphics.draw(self.temp_floor_canvas)
    	graphics.pop()
		
	
		graphics.push("all")
			graphics.origin()
			graphics.set_canvas(self.lower_floor_canvas)
			-- graphics.set_blend_mode("lighten", "premultiplied")
			-- graphics.translate(self.room.left, self.room.top)
    		-- graphics.circle("fill", 0, 0, 5)
			graphics.draw(self.temp_floor_canvas)
		graphics.pop()

    	-- if self.is_new_tick and self.tick % 12 == 0 then
    	if self.is_new_tick and self.tick % 5 == 0 then
        	graphics.push("all")
				graphics.origin()
        		graphics.set_canvas(self.floor_canvas)
				for i =1,1 do
					graphics.set_color(0, 0, 0, 0.065)
					-- graphics.set_color(0, 0, 0, 0.065)
				end
				graphics.rectangle("fill", 0, 0, self.room.room_width, self.room.room_height)
			graphics.pop()
		end

		graphics.draw(self.floor_canvas)

		-- local MIN_BRIGHTNESS = 0.03
		local MIN_BRIGHTNESS = 0.3
    	graphics.push("all")
			-- graphics.set_canvas(self.floor_canvas)
			-- graphics.set_blend_mode("lighten", "premultiplied")
			graphics.set_color(1, 1, 1, MIN_BRIGHTNESS)
			graphics.translate(0, 0)

			-- graphics.circle("fill", 0, 0, 5)
			graphics.draw(self.lower_floor_canvas)
	    graphics.pop()
		



	graphics.pop()

    self:draw_room_bounds()

	

	-- for _, obj in self:get_objects_with_tag("twinstick_entity"):ipairs() do
		-- graphics.push("all")
		-- graphics.set_color(Color.darkred)
		-- graphics.translate(obj.pos.x, obj.pos.y)
        -- if obj.terrain_collision_radius then
        --     graphics.rectangle("fill", -obj.terrain_collision_radius - 2, -obj.terrain_collision_radius / 2, obj.terrain_collision_radius * 2 + 4, obj.terrain_collision_radius + 2)
        -- end
		-- graphics.pop()
	-- end

    GameWorld.super.draw(self)

	if self.player_died and not self.player_death_fx then
		graphics.push("all")

		graphics.set_color(1, 1, 1, 1)
		graphics.translate(0, 0)
		local font = fonts["PixelOperator-Bold"]
        graphics.set_font(font)
		local text = string.format("YOU DIED ON LEVEL %d\nSCORE: %d\nKILLS: %d\nRESCUES: %d\nPRESS R (KBD) OR START (GAMEPAD)\nTO RESTART", game_state.level, game_state.score, game_state.enemies_killed, game_state.rescues_saved)
		graphics.translate(-font:getWidth(text) / 2, string.number_of_lines(text) * -font:getHeight(text) / 2)
		graphics.print_outline(Color.black, text, 0, 0)
		graphics.pop()
	end

end

function GameWorld:floor_canvas_push()
    graphics.push("all")
	graphics.set_color(1, 1, 1, 1)
	graphics.set_canvas(self.temp_floor_canvas)
	graphics.origin()
	graphics.translate(-self.room.left, -self.room.top)
end

function GameWorld:floor_canvas_pop()
    graphics.pop()
end

function GameWorld:get_border_color()
	
    if self.player_death_fx then
        return Palette.player_death_border:get_color(floor(gametime.tick / 2))
    end

    if self.player_died then
        return Color.red
    end
	
	if self.state == "RoomClear" then
		return Palette.room_clear_border:get_color(floor(gametime.tick / 4))
	end
	
    if self.state == "Spawning" then
        return Palette.spawning_border:get_color(floor(gametime.tick / 4))
    end

	if self.state == "LevelTransition" then
		return Color.black
	end

	return Palette.rainbow:get_color((self.room and self.room.level or 0) + floor(self.state_tick / max(20 / self.room.wave, 1)))
end

function GameWorld:draw_room_bounds()
	local r = self.room

	local tlx, tly = r.left, r.top
	-- local trx, try = r.right, r.top
	-- local brx, bry = r.right, r.bottom
	-- local blx, bly = r.left, r.bottom


	local color = self:get_border_color()
	-- graphics.rectangle("line", tlx, tly, r.right - r.left + 1, r.bottom - r.top + 1)
	-- graphics.points(tlx, tly, trx, try, brx, bry, blx, bly)
	-- graphics.line(tlx, tly, trx, try)
	-- -- graphics.line(trx, try, brx, bry)
    -- graphics.line(brx, bry, blx, bly)
    graphics.set_line_width(1)
    local scale = 0
    if self.room then
        scale = 1.05 - ease("outCubic")(clamp(self.room.elapsed / 30, 0, 1.0)) * 0.05
    end
    local red, green, blue = color.r, color.g, color.b
	local alpha = ease("outCubic")(clamp(self.room.elapsed / 20, 0, 1.0))
	graphics.set_color(red * alpha, green * alpha, blue * alpha)

	graphics.push()
	graphics.translate(tlx + r.room_width / 2, tly + r.room_height / 2)
	graphics.dashrect((-r.room_width / 2) * scale, (-r.room_height / 2) * scale, r.room_width * scale + 1, r.room_height * scale + 1, 2, 2)
    -- graphics.dashrect(tlx + 1, tly + 1, r.right - r.left - 1, r.bottom - r.top - 1, 2, 2)
	graphics.pop()
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
			self:end_tick_timer("wave_timer")
		end
	end

    -- if self.room.wave == self.room.last_wave then
	local s = self.timescaled.sequencer
	local enemies_left = self:get_number_of_objects_with_tag("wave_enemy")
	if enemies_left <= 5 and enemies_left > 0 then
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

function GameWorld:state_RoomClear_enter()
end

function GameWorld:state_RoomClear_exit()
	-- self.waiting_on_rooms = false
end

function GameWorld:state_RoomClear_update(dt)
	if self.waiting_on_rooms then
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
	local room_objects = self:get_objects_with_tag("room_object")
	if room_objects then
		for _, obj in room_objects:ipairs() do
			obj:die()
		end
	end
	self.frozen = true
	self.transitioning_to_room = room
	-- self.frozen = true
	local s = self.sequencer
	s:start(function()

		local length = 10

		self:play_sfx("level_start", 0.95, 1.0)

		s:wait(2)
		
		local move_tween = "linear"

		local direction = self.player_entered_direction
		for i, player in pairs(self.players) do
			local player_pos = player.pos:clone()
			local new_spot_x, new_spot_y

			if direction.x ~= 0 or direction.y ~= 0 then
				new_spot_x, new_spot_y = direction.x ~= 0 and (-direction.x * (self.room.room_width / 2 - 16)) or player_pos.x, direction.y ~= 0 and (-direction.y * (self.room.room_height / 2 - 16)) or player_pos.y
			else
				new_spot_x, new_spot_y = 0, 0
			end
			
			local final_offset_x = (new_spot_x + direction.x * self.room.room_width) - player_pos.x
			local final_offset_y = (new_spot_y + direction.y * self.room.room_height) - player_pos.y

			local move_player = function(t)


				if direction.x ~= 0 or direction.y ~= 0 then
					player:move_to(player_pos.x + final_offset_x * t, player_pos.y + final_offset_y * t)
				else
					player:move_to(player_pos.x, player_pos.y)
				end
					player.vel:mul_in_place(0.0)
			end
			s:start(function()
				s:tween(move_player, 0, 1, length, move_tween )
				player:move_to(new_spot_x, new_spot_y)
				player:change_state("Walk")
			end)
		end

		local camera_pos = self.camera_target.pos:clone()
		local move_camera = function(t)
			local new_x, new_y = camera_pos.x + (direction.x * self.room.room_width) * t, camera_pos.y + (direction.y * self.room.room_height) * t
			self.camera_target:move_to(new_x, new_y)
		end

		s:start(function()
			s:tween(move_camera, 0, 1, length, move_tween )
			self.camera_target:move_to(0, 0)
		end)
		s:wait(length - 1)
		self:clear_floor_canvas()
		self:clear_objects()
		s:wait(2)

		
		s:wait(1)
		self:change_state("Normal")
	end)
end

function GameWorld:clear_floor_canvas()
	self:defer(function()
		self.lower_floor_canvas = graphics.new_canvas(self.room.room_width, self.room.room_height)
		self.temp_floor_canvas = graphics.new_canvas(self.room.room_width, self.room.room_height)
		self.floor_canvas = graphics.new_canvas(self.room.room_width, self.room.room_height)
		self.temp_floor_canvas_settings = {
			self.temp_floor_canvas,
			stencil=true,
		}
	end)
end

function GameWorld:state_LevelTransition_update(dt)
end

	function GameWorld:state_LevelTransition_exit()
	self:initialize_room(self.transitioning_to_room)
	self.transitioning_to_room = nil
	self.frozen = false
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



return GameWorld