local DeliveryGuy = GameObject:extend("DeliveryGuy")
local Bullet = require("obj.Player.DeliveryGuyBullet")
local DeathFx = require("fx.death_effect")

function DeliveryGuy:new(x, y, invuln)
    DeliveryGuy.super.new(self, x, y)

    self.collision_rect = Rect.centered(0, 0, 1.0, 1.0)
    self.collision_offset = Vec2(0, 0)
    self.solid = false

    self:add_elapsed_time()
    self:add_elapsed_ticks()

    self:add_signal("level_complete")
	self:add_signal("died")

    local old_bump_filter = Mixins.Behavior.BumpCollision.default_bump_filter
    self.bump_filter = function(item, other)
        local result = old_bump_filter(item, other)
        return result
    end
    self.is_player = true
	
    self.state = "Walking"
	-- order kinda matters!
	self:implement(Mixins.Behavior.AutoStateMachine)
    self:implement(Mixins.Behavior.BumpCollision)
    self:implement(Mixins.Fx.Rumble)
    self:implement(Mixins.Behavior.FreezeFrames)
    self:implement(Mixins.Behavior.Flippable)
	self:implement(Mixins.Behavior.GridTerrainQuery)
    self:implement(Mixins.Behavior.TunnelSnapping)
	self:implement(Mixins.Behavior.Hittable)

    local hazard_sensor_config = {
        collision_rect = Rect.centered(0, 0, 4, 4),
        entered_function = function(self, other)
            self:on_hit(other)
        end,
        bump_mask = to_layer_bit(PHYSICS_HAZARD),
		sense_sensors = true,
    }

	local object_sensor_config = {
        collision_rect = Rect.centered(0, 0, 16, 16),
        entered_function = function(self, other)
			if other.is_pickup and not self.cutscene then	
				other:pickup()
			end
			if other.level_complete_tile and not self.level_complete then
				self.level_complete = true
				self:emit_signal("level_complete")
			end
        end,
        bump_mask = to_layer_bit(PHYSICS_OBJECT)
	}
    
	self:add_bump_sensor(hazard_sensor_config)
	self:add_bump_sensor(object_sensor_config)

    self.z_index = 0
    self:set_flip(1)

    self:enable_bump_layer(PHYSICS_PLAYER)
    self:enable_bump_mask(PHYSICS_ENEMY, PHYSICS_TERRAIN)

    self:add_sfx("player_shoot", 0.85, 1, false, 1)
	self:add_sfx("player_jump", 1)

	self.speed = 1.5
	self.input_move_dir = Vec2(0, 0)
	

	self.left_pressed_at = -1
	self.right_pressed_at = -1
	self.up_pressed_at = -1
	
	self.down_pressed_at = -1
	self.can_shoot = true

	self.facing_direction_x = 0
	self.facing_direction_y = -1
	self.cutscene = false
	self.cutscene_input = {
		move_up_pressed = true,
		move_down_pressed = true,
		move_left_pressed = true,
		move_right_pressed = true,
		aim_up_pressed = true,
		aim_down_pressed = true,
		aim_left_pressed = true,
		aim_right_pressed = true,
		move_up_released = true,
		move_down_released = true,
		move_left_released = true,
		move_right_released = true,
		aim_up_released = true,
		aim_down_released = true,
		aim_left_released = true,
		aim_right_released = true,
        aim = Vec2(0, 0),
		aim_digital = Vec2(0, 0),
		move_normalized = Vec2(0, 0),
		move_up = false,
		move_down = false,
		move_left = false,
		move_right = false,
		aim_up = false,
		aim_down = false,
		aim_left = false,
		aim_right = false,
		move_up_released = false,
		move_down_released = false,
		move_left_released = false,
		move_right_released = false,
		aim_up_released = false,
		aim_down_released = false,
		aim_left_released = false,
		aim_right_released = false,
	}

	self.aim_up_pressed_at = -1
	self.aim_down_pressed_at = -1
	self.aim_left_pressed_at = -1
	self.aim_right_pressed_at = -1

	self.last_moved_x = 1
	self.last_moved_y = 1

	local old_move_to = self.move_to

    self.move_to = function(self, x, y, filter, noclip, ...)
        if self.ignore_collision then
			-- print("here")

			old_move_to(self, x, y, filter, true, ...)
			return
		end
		old_move_to(self, x, y, filter, noclip, ...)
	end
    if invuln then
		local s = self.sequencer
        self.invuln = true
		self.ignore_collision = true
        s:start(function()
            s:wait(45)
			self.ignore_collision = false
			s:wait(45)
			self.invuln = false
		end)
	end
end

function DeliveryGuy:enter()
    self:add_tag("player")
end

function DeliveryGuy:update(dt)
    if debug.enabled then
		if input.keyboard_held["k"] then
			self:die()
		end
	end
end

function DeliveryGuy:cooldown_end()
    self.can_shoot = true
	if self.buffering_shot then
		self.buffering_shot = false
		self:shoot_bullet()
	end
end

function DeliveryGuy:shoot_bullet(noclip)
    if self.can_shoot then
		self:play_sfx("player_shoot")
        self.can_shoot = false
		local nx, ny = vec2_normalized(self.facing_direction_x, self.facing_direction_y)
        local bullet = Bullet(self.pos.x + nx * 8, self.pos.y + ny * 8, nx, ny)
		bullet.noclip = noclip
		self:spawn_object(bullet)
		self:start_timer(8, self.cooldown_end)
	else
		-- self.buffering_shot = true
	end
end

-- Helper methods

function DeliveryGuy:on_hit(by)
	-- print(by)
	if self.state == "PitJump" and self.state_tick >= 2 and self.state_tick <= 20 then
		return
	end
	if self.invuln then
		return
	end
	if self.cutscene then
		return
	end
	self:die()
end

function DeliveryGuy:die()
	self.world:play_sfx("player_death")
    if self.dead then return end
	self.dead = true
	self:emit_signal("died")
	self:queue_destroy()
	self:die_fx()
end

function DeliveryGuy:fake_die()
    -- self.dead = true
    self:die_fx()
	self:set_visibility(false)
	-- self:emit_signal("died")
	-- self:queue_destroy()
	-- self:die_fx()
end

function DeliveryGuy:die_fx()
	local fx = DeathFx(self.pos.x, self.pos.y, self:get_texture(), self.flip)
    fx.duration = fx.duration * 2
	self:spawn_object(fx)
end

function DeliveryGuy:process_collision(collision)
    local tile_data = table.get_recursive(collision.other, "tile", "data")
    if tile_data and tile_data.hazard then
        self:on_hit(tile_data)
    end
end

function DeliveryGuy:get_texture()
	return floor(self.tick / 10) % 2 == 0 and textures.player_placeholder1 or textures.player_placeholder2
end

function DeliveryGuy:draw()
	-- if true then return end
	if self.invuln and floor(self.tick / 2) % 2 == 0 then
		return
	end
	graphics.push()
	if not self.world.cutscene then
        graphics.origin()

		graphics.translate(self.pos.x, self.pos.y - self.world.scroll)
		if global_state.hudless_level and self.world.level_data.cutscene_offset ~= false then
			graphics.translate(tilesets.TILE_SIZE / 2, 0)
		end
	end

	graphics.draw_centered(self:get_texture(), 0, 0, 0, self.flip, 1, 0, 1)
	graphics.pop()
end


function DeliveryGuy:check_solid_tile(x, y)
	local tile = self:get_bump_tile_relative(x, y, 0)
	if tile and tile.solid then
		return true
	end
	return false
end

function DeliveryGuy:handle_movement_input()
	local input = self:get_input_table()

    -- if input.move_up_pressed then
    --     self.up_pressed_at = self.tick
    -- elseif input.move_down_pressed then
    --     self.down_pressed_at = self.tick
    -- elseif input.move_left_pressed then
    --     self.left_pressed_at = self.tick
    -- elseif input.move_right_pressed then
    --     self.right_pressed_at = self.tick
    -- end

	-- if input.move_up_released then
	-- 	self.up_pressed_at = -1
	-- end

	-- if input.move_down_released then
	-- 	self.down_pressed_at = -1
	-- end

	-- if input.move_left_released then
	-- 	self.left_pressed_at = -1
	-- end

    -- if input.move_right_released then
    --     self.right_pressed_at = -1
    -- end
	
	-- local latest_time = -1

    -- if self.up_pressed_at > latest_time then
    --     latest_time = self.up_pressed_at
	-- 	self.input_move_dir.y = -1
	-- 	self.input_move_dir.x = 0	
	-- end

    -- if self.down_pressed_at > latest_time then
	-- 	latest_time = self.down_pressed_at
	-- 	self.input_move_dir.y = 1
	-- 	self.input_move_dir.x = 0	
	-- end

    -- if self.left_pressed_at > latest_time then
    --     latest_time = self.left_pressed_at
	-- 	self.input_move_dir.y = 0
	-- 	self.input_move_dir.x = -1	
	-- end

    -- if self.right_pressed_at > latest_time then
    --     latest_time = self.right_pressed_at
    --     self.input_move_dir.y = 0
    --     self.input_move_dir.x = 1
    -- end
	
    -- if latest_time == -1 then
    --     self.input_move_dir.x = 0
    --     self.input_move_dir.y = 0
    -- end

	self.input_move_dir.x = input.move_normalized.x
    self.input_move_dir.y = input.move_normalized.y

	if self.input_move_dir.x ~= 0 then
		self.last_moved_x = self.input_move_dir.x
	end

	if self.input_move_dir.y ~= 0 then
		self.last_moved_y = self.input_move_dir.y
	end

end

function DeliveryGuy:handle_aim_input()
	local input = self:get_input_table()

    -- if input.aim_up_pressed then
	-- 	self.aim_up_pressed_at = self.tick
	-- elseif input.aim_down_pressed then
    --     self.aim_down_pressed_at = self.tick
	-- elseif input.aim_left_pressed then
    --     self.aim_left_pressed_at = self.tick
    -- elseif input.aim_right_pressed then
    --     self.aim_right_pressed_at = self.tick
    -- end

	-- local latest_time = -1

	-- if input.aim_up_released then
	-- 	self.aim_up_pressed_at = -1
	-- end

	-- if input.aim_down_released then
	-- 	self.aim_down_pressed_at = -1
	-- end

	-- if input.aim_left_released then
	-- 	self.aim_left_pressed_at = -1
	-- end

	-- if input.aim_right_released then
	-- 	self.aim_right_pressed_at = -1
	-- end

    -- if self.aim_up_pressed_at > latest_time then
    --     latest_time = self.aim_up_pressed_at
    --     self.facing_direction_y = -1
    --     self.facing_direction_x = 0
    -- end
	
	-- if self.aim_down_pressed_at > latest_time then
	-- 	latest_time = self.aim_down_pressed_at
	-- 	self.facing_direction_y = 1
	-- 	self.facing_direction_x = 0
	-- end	

	-- if self.aim_left_pressed_at > latest_time then
	-- 	latest_time = self.aim_left_pressed_at
	-- 	self.facing_direction_y = 0
	-- 	self.facing_direction_x = -1
	-- end

    -- if self.aim_right_pressed_at > latest_time then
    --     latest_time = self.aim_right_pressed_at
    --     self.facing_direction_y = 0
    --     self.facing_direction_x = 1
    -- end

	self.facing_direction_x = input.aim_digital.x
	self.facing_direction_y = input.aim_digital.y

	if not self.state == "PitJump" then
		if self.facing_direction_x > 0 and self.snapped_east then
			self.facing_direction_x = 0
			if self.facing_direction_y == 0 then
				self.facing_direction_y = self.last_moved_y
			end
		end

		if self.facing_direction_x < 0 and self.snapped_west then
			self.facing_direction_x = 0
			if self.facing_direction_y == 0 then
				self.facing_direction_y = self.last_moved_y
			end
		end

		if self.facing_direction_y > 0 and self.snapped_south then
			self.facing_direction_y = 0
			if self.facing_direction_x == 0 then
				self.facing_direction_x = self.last_moved_x
			end
		end

		if self.facing_direction_y < 0 and self.snapped_north then
			self.facing_direction_y = 0
			if self.facing_direction_x == 0 then
				self.facing_direction_x = self.last_moved_x
			end
		end
	end

	if self.facing_direction_x == 0 and self.facing_direction_y == 0 then
		self.facing_direction_y = self.last_moved_y
	end

	if self.facing_direction_x ~= 0 then
		self:set_flip(self.facing_direction_x)
	end

	-- print(self.aim_up_pressed_at, self.aim_down_pressed_at, self.aim_left_pressed_at, self.aim_right_pressed_at)

end

function DeliveryGuy:get_input_table()
	if self.cutscene then
		return self.cutscene_input
	else
		return DeliveryGuy.super.get_input_table(self)
	end
end
------------------------------------------
-- States
------------------------------------------

-- State: Walking

function DeliveryGuy:state_Walking_enter()
	self.z_index = 0
end

function DeliveryGuy:state_Walking_update(dt)
	local input = self:get_input_table()
    self:handle_movement_input(self.cutscene and self.cutscene_input or nil)
    self:handle_aim_input(self.cutscene and self.cutscene_input or nil)

	local world_scroll = 0
	if self.world.scrolling or self.level_complete then
		world_scroll = dt * self.world.scroll_speed * self.world.scroll_direction
	end

    if self.input_move_dir.y == 0 then
        self:move(0, world_scroll, nil, false)
    end

    if self.input_move_dir.x ~= 0 or self.input_move_dir.y ~= 0 then
        local ymod = world_scroll * abs(self.input_move_dir.y)
        self:move(self.input_move_dir.x * self.speed * dt, (self.input_move_dir.y * self.speed * dt) + ymod)
        if self.input_move_dir.x > 0 then
            self.snapped_east = false
        elseif self.input_move_dir.x < 0 then
            self.snapped_west = false
        end
    end

    if input.aim_up or input.aim_down or input.aim_left or input.aim_right then
        self:shoot_bullet()
    end

    local tile = self:get_tile_relative(0, 0, 0)

    if (not self.ignore_collision) and tile and tile.data and tile.data.terrain_pit then
        self.pit_moving_dir = Vec2(0, 0)

        local cx, cy = self:get_cell()
        local wx, wy = self:cell_to_world(cx, cy)
        local diff = Vec2(wx - self.pos.x, wy - self.pos.y)
        if abs(diff.x) > abs(diff.y) then
            self.pit_moving_dir.x = sign(diff.x)
        else
            self.pit_moving_dir.y = diff.y ~= 0 and sign(diff.y) or self.world.scroll_direction
        end

		local relative_cx = cx - self.pit_moving_dir.x
		local relative_cy = cy - self.pit_moving_dir.y
		local world_pos_x, world_pos_y = self:cell_to_world(relative_cx, relative_cy)

		self.pos = Vec2(world_pos_x, world_pos_y)

		if not self:is_cell_solid(cx + self.pit_moving_dir.x * 1, cy + self.pit_moving_dir.y * 1) then
			self:change_state("PitJump")
			return
		end
	end
end

function DeliveryGuy:state_PitJump_enter()
	self.z_index = 2
	
    local s = self.sequencer
	self:play_sfx("player_jump")
    s:start(function()
		local startx, starty = self:get_cell()
		local endx, endy = startx + self.pit_moving_dir.x * 2, starty + self.pit_moving_dir.y * 2
        s:tween(function(t)
            local x, y = vec2_lerp(startx, starty, endx, endy, t)
			local wx, wy = self:cell_to_world(x, y)
			self.pos = Vec2(wx, wy - math.bump(t) * 15)
        end, 0, 1, 30, "linear")
		self:change_state("Walking")
	end)
end

function DeliveryGuy:state_PitJump_update(dt)
	self:handle_aim_input()
	if input.aim_up or input.aim_down or input.aim_left or input.aim_right then
		self:shoot_bullet(true)
	end
end

return DeliveryGuy
