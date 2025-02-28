local GameWorld = World:extend("GameWorld")local O = require("obj")
local EnemySpawn = require("obj.EnemySpawn")
local EnemyDataTable = require("obj.enemy_data")
local Room = require("room.Room")
local shash = require "lib.shash"

local CAMERA_OFFSET_AMOUNT = 20
local MAX_ENEMIES = 100
local MAX_HAZARDS = 50


function GameWorld:new(x, y)
	GameWorld.super.new(self, x, y)

    self:add_signal("enemy_added")
    self:add_signal("enemy_died")

	self:lazy_mixin(Mixins.Behavior.AutoStateMachine, "Spawning")

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

	self:add_spatial_grid("game_object_grid", 32)
    self:add_spatial_grid("declump_objects", 32)
	self:add_spatial_grid("pickup_objects", 32)
    self:add_spatial_grid("fungus_grid", 32)
	self:add_spatial_grid("bullet_grid", 32)

	self.hurt_bubbles = {}
	self.hurt_bubbles["player"] = shash.new(32)
    self.hurt_bubbles["enemy"] = shash.new(32)
	
	self.hit_bubbles = {}
	self.hit_bubbles["player"] = shash.new(32)
    self.hit_bubbles["enemy"] = shash.new(32)

    self.empty_update_objects = bonglewunch() 
	
    self.object_class_counts = {}
	self:add_signal("player_died")

	self.players = {}
    self.last_player_positions = {}
    self.last_player_body_positions = {}
	self.player_entered_direction = Vec2(0, -1)

end

function GameWorld:enter()
	audio.play_music("drone", 1)

    self.camera.persist = true

    local start_room = self:create_random_room(false)

    self:initialize_room(start_room)
end

function GameWorld:create_random_room(increment_level)
	if increment_level == nil then increment_level = true end
	local level_history = nil
	local old_room = self.room
    if old_room then
        level_history = old_room.level_history
    end
	
	local level = game_state.level
    if increment_level then
        level = level + 1
    end
	
	local room = Room(self, level, game_state.difficulty, level_history)
	
	-- for _, room in ipairs(self.current_room_selection or {}) do
	-- 	for obj, _ in pairs(room.all_spawn_types) do
	-- 		room.redundant_spawns[obj] = true
	-- 	end
	-- end

	room:build()

	return room
end

function GameWorld:initialize_room(room)
    self.enemies_to_kill = {}

    self:play_sfx("level_start", 0.95, 1.0)
	
	game_state.level = room.level

    self.room = room


    self:defer(function()
        self.lower_floor_canvas = graphics.new_canvas(self.room.room_width, self.room.room_height)
		self.temp_floor_canvas = graphics.new_canvas(self.room.room_width, self.room.room_height)
        self.floor_canvas = graphics.new_canvas(self.room.room_width, self.room.room_height)
		self.temp_floor_canvas_settings = {
			self.temp_floor_canvas,
			stencil=true,
		}
    end)

    local s = self.sequencer

    s:start(function()
        for i, player in pairs(self.players) do
            local direction = self.player_entered_direction
            if direction.x ~= 0 or direction.y ~= 0 then
                player:move_to(-direction.x * self.room.room_width / 2, -direction.y * self.room.room_height / 2)
            else
                player:move_to(0, 0)
            end
			player.vel:mul_in_place(0.0)
			player:change_state("Walk")
        end
		
        if table.is_empty(self.players) then
            self:create_player()
        end
		
		s:wait(15)

        self:spawn_wave()

    end)

    self:ref("camera_target", GameObject2D(0, 0))

    self.camera:follow(self.camera_target)
    self.camera:set_limits(self.room.left - self.room.padding, self.room.top - self.room.padding,
        self.room.right + self.room.padding,
        self.room.bottom + self.room.padding)
end

function GameWorld:start_wave_timer(duration)
    self:start_timer("wave_timer", duration, function()
		self.room.wave = self.room.wave + 1
        self:spawn_wave()
	end)
end

function GameWorld:spawn_wave()
    -- self:change_state("Spawning")

	if self.room.cleared then return end

    local s = self.sequencer
	self.spawned_on_player = false

    local spawns = self.room:spawn_wave()
	
	s:start(function()

		-- Spawn hazards and enemies in parallel
		self:spawn_wave_group(s, spawns.hazard, "hazard", "wave_hazard", "spawning_hazards", MAX_HAZARDS)
		self:spawn_wave_group(s, spawns.enemy, "enemy", "wave_enemy", "spawning_enemies", MAX_ENEMIES)

		-- Wait for enemies to finish spawning
		while self.spawning_enemies do
			s:wait(1)
		end

		if self.room.wave < self.room.last_wave then
			self:start_wave_timer(max(600 - game_state.difficulty * 60, 120))
		end
	end)
end

function GameWorld:spawn_wave_group(s, wave, spawn_type, tag_name, spawning_flag_name, max_count)
	self[spawning_flag_name] = true
	s:start(function()
        for i, spawn_data in ipairs(wave) do
            if not self[spawning_flag_name] then
                break
            end

			if self.player_died then
				break
			end
			
            local spawn_x, spawn_y = self:get_valid_enemy_spawn_position()

			-- local max_spawns = spawn.max_spawns or math.huge

			-- local max_instances = spawn.max_spawns + (game_state.difficulty - 1)
			local current_instances = self.object_class_counts[spawn_data.class] or 0
			
            -- if current_instances >= max_instances then
			-- 	goto continue
            -- end
			
			local spawn = self:spawn_object(EnemySpawn(spawn_x, spawn_y, spawn_type))
			self:add_tag(spawn, tag_name)
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
		self[spawning_flag_name] = false
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
        local s = self.sequencer
		game_state.enemies_killed = game_state.enemies_killed + 1
		self.enemies_to_kill[enemy_object] = nil
		s:start(function()
			if table.is_empty(self.enemies_to_kill) then
				if not self.spawning_enemies then
					if self.room.wave == self.room.last_wave then
						-- s:wait(10)
						self:on_room_clear()
                    else
						self:play_sfx("wave_finished_early", 0.75, 1.0)
						self:start_wave_timer(10)
					end
				end
            else
                if not self.spawning_enemies and self.room.wave == self.room.last_wave then
                    if self:get_number_of_objects_with_tag("wave_enemy") == 5 then
                        for _, obj in self:get_objects_with_tag("wave_enemy"):ipairs() do
							if obj and obj.highlight_self then
								obj:highlight_self()
							end
                            s:wait(5)
                        end
						-- s:wait(0)
						self:play_sfx("highlight_last_enemies", 1, 1.0)
					end
				end
			end
		end)
    end)

    signal.connect(enemy_object, "destroyed", self, "enemies_to_kill_table_on_enemy_destroyed", function()
        self.enemies_to_kill[enemy_object] = nil
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
		self:play_sfx("old_player_death", 0.5, 1.0)
		self:play_sfx("hazard_death", 0.5, 1.0)
        self.object_time_scale = 0.125
		s:wait(60)
		self.player_died = true
        -- s:wait(120)
		local input = self:get_input_table()
		while not input.restart_held do
			s:wait(1)
		end
		self:emit_signal("player_died")
	end)
    -- local s = self.sequencer

    -- s:start(function()
    --     s:wait(30)
    --     -- self:clear_objects()
	-- 	if not self.player then
	-- 		self:create_player()
	-- 		self.player:start_invulnerability_timer(60)
	-- 	end
	-- 	-- s:wait(15)
    --     -- self:initialize_room()
    -- end)
end

function GameWorld:on_room_clear()
	if self.room.cleared then
		return
	end

    local s = self.sequencer
	self.room.cleared = true

    s:start(function()
        -- self.frozen = true
        self.object_time_scale = 0.125
		self:play_sfx("old_player_respawn", 0.5, 1.0)
        s:wait(45)
        self.object_time_scale = 1.0
        while table.is_empty(self.players) do
            s:wait(1)
        end
		
        for i, player in pairs(self.players) do
            player:change_state("Hover")
        end

        self.current_room_selection = {}
        local directions = { Vec2(1, 0), Vec2(0, 1), Vec2(-1, 0), Vec2(0, -1) }

        for i = 1, 4 do
            local direction = directions[i]
			if direction == -self.player_entered_direction then
                table.remove(directions, i)
				break
			end
		end

        -- for i = 1, 3 do
        --     local direction = directions[i]
        --     local spawn_pos_x, spawn_pos_y = direction.x * self.room.room_width / 2, direction.y * self.room.room_height / 2
		-- 	local room = self:create_random_room()
        --     table.insert(self.current_room_selection, room)
        --     local room_object = O.RoomObject(spawn_pos_x, spawn_pos_y, room)
		-- 	room_object.direction = direction
        --     signal.connect(room_object, "room_chosen", self, "on_room_chosen", function()
        --         self.player_entered_direction = direction
		-- 		self:clear_objects()
		-- 		self:initialize_room(room)
		-- 	end)
		-- 	self:spawn_object(room_object)
        -- end

		self.player_entered_direction = Vec2(0, 0)
		self:clear_objects()
        local room = self:create_random_room()
		self:initialize_room(room)

    end)
end

function GameWorld:get_update_objects()
	if self.frozen then return self.empty_update_objects end

	return World.get_update_objects(self)
end

function GameWorld:update(dt)
    self.camera_aim_offset = self.camera_aim_offset or Vec2(0, 0)

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
	
	if num_players > 0 then

		self.camera_target.pos.x, self.camera_target.pos.y =
			splerp_vec_unpacked(
				self.camera_target.pos.x, self.camera_target.pos.y,
				average_player_x + self.camera_aim_offset.x, average_player_y + self.camera_aim_offset.y,
				dt,
				300.0
			)
			
		self.camera_aim_offset.x, self.camera_aim_offset.y =
			splerp_vec_unpacked(
				self.camera_aim_offset.x, self.camera_aim_offset.y,
				average_player_aim_direction_x * CAMERA_OFFSET_AMOUNT, average_player_aim_direction_y * CAMERA_OFFSET_AMOUNT,
				dt,
				600.0
			)

	end
	-- end
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
	
    if input.debug_skip_wave_held and not self.room.cleared then
        self.spawning_enemies = false
		self.spawning_hazards = false
        local objects = self:get_objects_with_tag("wave_enemy")
		if objects then
            for _, obj in objects:ipairs() do
				if obj.world then
					if obj.die then
						obj:die()
					elseif not obj.is_queued_for_destruction then
						-- obj:queue_destroy()
					end
				end
			end
		end
	end
end

function GameWorld:get_valid_enemy_spawn_position()
	local MIN_DISTANCE_BETWEEN_ENEMIES = 32
	local SPAWN_ON_PLAYER_AT_THIS_DISTANCE = 80

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
    for i = 1, 100 do
        local valid = true
        local wave_enemies = self:get_objects_with_tag("wave_enemy")
        local wave_hazards = self:get_objects_with_tag("wave_hazard")

        if valid and wave_enemies then
            for _, object in wave_enemies:ipairs() do
                if vec2_distance(x, y, object.pos.x, object.pos.y) < MIN_DISTANCE_BETWEEN_ENEMIES then
                    valid = false
                    break
                end
            end
        end
        if valid and wave_hazards then
            for _, object in wave_hazards:ipairs() do
                if vec2_distance(x, y, object.pos.x, object.pos.y) < MIN_DISTANCE_BETWEEN_ENEMIES then
                    valid = false
                    break
                end
            end
        end

        if valid then
			for i, object in pairs(self.last_player_body_positions) do
				if vec2_distance(x, y, object.x, object.y) < MIN_DISTANCE_BETWEEN_ENEMIES then
					valid = false
					break
				end
			end
		end

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
            graphics.translate(obj.pos.x, obj.pos.y)
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

    	if self.is_new_tick and self.tick % 12 == 0 then
        	graphics.push("all")
				graphics.origin()
        		graphics.set_canvas(self.floor_canvas)
				for i =1,1 do
					graphics.set_color(0, 0, 0, 0.065)
				end
				graphics.rectangle("fill", 0, 0, self.room.room_width, self.room.room_height)
			graphics.pop()
		end

		graphics.draw(self.floor_canvas)

		local MIN_BRIGHTNESS = 0.01
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

	if self.player_died then
		graphics.push("all")

		graphics.set_color(1, 1, 1, 1)
		graphics.translate(0, 0)
		local font = graphics.font["PixelOperator-Bold"]
        graphics.set_font(font)
		local text = string.format("YOU DIED ON LEVEL %d\nENEMIES KILLED: %d\nPRESS R OR START TO RESTART", game_state.level, game_state.enemies_killed)
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

function GameWorld:draw_room_bounds()
	local r = self.room

	local tlx, tly = r.left, r.top
	local trx, try = r.right, r.top
	local brx, bry = r.right, r.bottom
	local blx, bly = r.left, r.bottom


	graphics.set_color(Color.red)
	-- graphics.rectangle("line", tlx, tly, r.right - r.left + 1, r.bottom - r.top + 1)
	-- graphics.points(tlx, tly, trx, try, brx, bry, blx, bly)
	-- graphics.line(tlx, tly, trx, try)
	-- -- graphics.line(trx, try, brx, bry)
    -- graphics.line(brx, bry, blx, bly)
	graphics.dashrect(tlx, tly, r.right - r.left + 1, r.bottom - r.top + 1, 2, 2)
	-- graphics.line(blx, bly, tlx, tly)
end

function GameWorld:state_Normal_enter()
	self.frozen = false
end

function GameWorld:state_Spawning_enter()
	-- self.object_time_scale = 0.025
	-- self.frozen = true
end

function GameWorld:state_Spawning_exit()
	-- self.object_time_scale = 1.0
	-- self.frozen = false
end

return GameWorld
