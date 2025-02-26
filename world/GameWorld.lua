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
end

function GameWorld:enter()
	audio.play_music("drone", 1)

    self.camera.persist = true

    local start_room = self:create_random_room()

    self:initialize_room(start_room)
end

function GameWorld:create_random_room()
    local room = Room(self, game_state.level+1, game_state.difficulty)
    return room
end

function GameWorld:initialize_room(room)
    self.enemies_to_kill = {}

	self:play_sfx("level_start", 0.95, 1.0)

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
        if self.player then
            self.player:move_to(0, 0)
        end
        if not self.player then
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

	local s = self.sequencer

	local spawn_positions = self.room:spawn_wave()
	s:start(function()

		-- Spawn pickups
		for _, position in ipairs(spawn_positions.pickup) do
            local spawn = self:spawn_object(EnemySpawn(position.x, position.y, "pickup"))
			signal.connect(spawn, "finished", self, "on_spawn_finished", function()
				self:spawn_wave_pickup(position.type(position.x, position.y))
			end)
			s:wait(1)
		end

		-- Spawn hazards and enemies in parallel
		self:spawn_wave_group(s, spawn_positions.hazard, "hazard", "wave_hazard", "spawning_hazards", MAX_HAZARDS)
		self:spawn_wave_group(s, spawn_positions.enemy, "enemy", "wave_enemy", "spawning_enemies", MAX_ENEMIES)

		-- Wait for enemies to finish spawning
		while self.spawning_enemies do
			s:wait(1)
		end

		if self.room.wave < self.room.last_wave then
			self:start_wave_timer(max(600 - game_state.difficulty * 60, 120))
		end
	end)
end

function GameWorld:spawn_wave_group(s, positions, spawn_type, tag_name, spawning_flag_name, max_count)
	self[spawning_flag_name] = true
	s:start(function()
        for _, position in ipairs(positions) do
			
			local type_data = EnemyDataTable.data[position.type.__class_type_name]
			local max_instances = type_data.max_spawns + (game_state.difficulty - 1)
			local current_instances = self.object_class_counts[position.type] or 0
			
            if current_instances >= max_instances then
				goto continue
            end
			
			local spawn = self:spawn_object(EnemySpawn(position.x, position.y, spawn_type))
			self:add_tag(spawn, tag_name)
			signal.connect(spawn, "finished", self, "on_spawn_finished", function()
				if spawn_type == "hazard" then
					self:spawn_wave_hazard(position.type(position.x, position.y))
				else
					self:spawn_wave_enemy(position.type(position.x, position.y))
				end
			end)
			s:wait(5)

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
end

function GameWorld:spawn_wave_enemy(enemy)
    local enemy_object = self:spawn_object(enemy)
	self:register_spawn_wave_enemy(enemy_object)
	enemy_object:move(0, enemy_object.body_height / 2)
end

function GameWorld:register_spawn_wave_enemy(enemy_object)
    self.enemies_to_kill[enemy_object] = true
	self:add_tag(enemy_object, "wave_enemy")
	self:add_tag(enemy_object, "wave_spawn")


    signal.connect(enemy_object, "died", self, "enemies_to_kill_table_on_enemy_died", function()
        local s = self.sequencer
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
                            obj:highlight_self()
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

function GameWorld:create_player()
	local player = self:spawn_object(O.Player.PlayerCharacter(0, 0))
	signal.connect(player, "died", self, "on_player_died", function()
        self:on_player_died()
    end)

    self:ref("player", player)
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
		s:wait(120)
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
    local s = self.sequencer

    s:start(function()
        -- self.frozen = true
        self.object_time_scale = 0.125
		self:play_sfx("old_player_respawn", 0.5, 1.0)
        s:wait(45)
		self.object_time_scale = 1.0
		self:clear_objects()
		game_state.level = game_state.level + 1
        self:initialize_room(self:create_random_room())
    end)
end

function GameWorld:get_update_objects()
	if self.frozen then return self.empty_update_objects end

	return World.get_update_objects(self)
end

function GameWorld:update(dt)
	self.camera_aim_offset = self.camera_aim_offset or Vec2(0, 0)

	if self.player then
        self.last_player_pos = self.last_player_pos or self.player.pos:clone()
		self.last_player_pos.x = self.player.pos.x
        self.last_player_pos.y = self.player.pos.y
		
		local bx, by = self.player:get_body_center()
		self.last_player_body_pos = self.last_player_body_pos or Vec2(bx, by)
		self.last_player_body_pos.x = bx
        self.last_player_body_pos.y = by
		
		self.camera_target.pos.x, self.camera_target.pos.y =
			splerp_vec_unpacked(
				self.camera_target.pos.x, self.camera_target.pos.y,
                self.player.pos.x + self.camera_aim_offset.x, self.player.pos.y + self.camera_aim_offset.y,
                dt,
				300.0
            )
		self.camera_aim_offset.x, self.camera_aim_offset.y =
		splerp_vec_unpacked(
				self.camera_aim_offset.x, self.camera_aim_offset.y,
                self.player.aim_direction.x * CAMERA_OFFSET_AMOUNT, self.player.aim_direction.y * CAMERA_OFFSET_AMOUNT,
                dt,
				600.0
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

    	if self.is_new_tick and self.tick % 18 == 0 then
        	graphics.push("all")
				graphics.origin()
        		graphics.set_canvas(self.floor_canvas)
				for i =1,1 do
					graphics.set_color(0, 0, 0, 0.08)
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
