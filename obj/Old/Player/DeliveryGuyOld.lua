local DeliveryGuy = GameObject:extend("DeliveryGuy")

function DeliveryGuy:new(x, y)
    DeliveryGuy.super.new(self, x, y)

    self.collision_rect = Rect.centered(0, 0, 5, 11)
    self.collision_offset = Vec2(0, 2)
    self.solid = false

    self:add_elapsed_time()
    self:add_elapsed_ticks()

    local old_bump_filter = Mixins.Behavior.BumpCollision.default_bump_filter
    self.bump_filter = function(item, other)
        local result = old_bump_filter(item, other)
        return result
    end

    self.state = "Idle"
	-- order kinda matters!
	self:implement(Mixins.Behavior.AutoStateMachine)
    self:implement(Mixins.Behavior.BumpCollision)
    self:implement(Mixins.Fx.Rumble)
    self:implement(Mixins.Behavior.FreezeFrames)
    self:implement(Mixins.Behavior.SimplePhysics)
    self:implement(Mixins.Behavior.GroundedCheck)
    self:implement(Mixins.Behavior.Flippable)
    self:implement(Mixins.Behavior.UseOneWayPlatforms)

    local hazard_sensor_config = {
        collision_rect = Rect.centered(0, 2, 5, 11),
        entered_function = function(self, other)
            self:take_damage()
        end,
        bump_mask = to_layer_bit(PHYSICS_HAZARD)
    }
    self:add_bump_sensor(hazard_sensor_config)

    self.grounded_max_horizontal_speed = 1.9
    self.air_max_horizontal_speed = 1.9

    self:set_physics_limits({
        max_horizontal_speed = self.grounded_max_horizontal_speed,
        max_upward_speed = 2.2,
        max_downward_speed = 2.2,
    })

    self.base_gravity = 0.090
    self.gravity = self.base_gravity
    self.last_aerial_vel = self.vel:clone()

    self.z_index = 1
    self:set_flip(1)

    self:enable_bump_layer(PHYSICS_PLAYER)
    self:enable_bump_mask(PHYSICS_TERRAIN, PHYSICS_ENEMY)


    self.landing_tick = 0
    self.world_persistent = true

    self.h_accel_ground = 0.3
    self.h_accel_air = 0.1
    self.ground_h_drag = 0.25
    self.air_h_drag = 0.02
    self.jump_impulse = 1.78
    self.coyote_time = 0

    self.can_hold_jump = true
    self.air_time = 0
    self.is_grounded = true
    self.took_damage_this_tick = false

    -- Implement the AutoStateMachine AFTER setting starting_state
end

function DeliveryGuy:enter()
    self:add_tag("player")
end

function DeliveryGuy:update(dt)
    local input = self:get_input_table()
    local is_grounded = self.is_grounded

    -- General (non-state-specific) update logic:
    if is_grounded then
        self.max_horizontal_speed = self.grounded_max_horizontal_speed
        self.air_time = 0
    else
        self.max_horizontal_speed = self.air_max_horizontal_speed
        self.last_aerial_vel.x = self.vel.x
        self.last_aerial_vel.y = self.vel.y
        self.air_time = self.air_time + dt
    end

    if not is_grounded then
        self.coyote_time = self.coyote_time - dt
    end

	
    if self.took_damage_this_tick then
        self:defer(function(self)
            self.took_damage_this_tick = false
        end)
    end
	
    dbg("player vel", self.vel)
    dbg("player pos", self.pos)
    dbg("player is_grounded", self.is_grounded)
    dbg("player state", self.state)
	dbg("player can_hold_jump", self.can_hold_jump)
end

-- Helper methods
function DeliveryGuy:grounded_idle_drag(input)
    if input.move.x ~= 0 and sign(input.move.x) == sign(self.vel.x) then
        self.horizontal_drag = 0.0
    else
        self.horizontal_drag = self.ground_h_drag
    end
end

function DeliveryGuy:air_idle_drag(input)
    if input.move.x ~= 0 and sign(input.move.x) == sign(self.vel.x) then
        self.horizontal_drag = 0.0
    else
        self.horizontal_drag = self.air_h_drag
    end
end

function DeliveryGuy:jump_check(input)
    if input.primary_pressed then
        if self.vel.y > 0 then
            self.vel.y = 0
        end

        self:change_state("Aerial")
        self:apply_impulse(0, -self.jump_impulse)
        self.coyote_time = 0
		self:defer(function(self)
			self.can_hold_jump = true
		end)

    end
end

function DeliveryGuy:land_check()
    if not self.is_grounded then return end
    if self.is_queued_for_destruction then return end

    self.landing_tick = self.tick
    self:change_state("Idle")
end

function DeliveryGuy:fall_check()
    if not self.is_grounded then
        self:change_state("Aerial")
        self.coyote_time = 4
    end
end

function DeliveryGuy:take_damage()
    self:queue_destroy()
    self.took_damage_this_tick = true
end

function DeliveryGuy:process_collision(collision)
    local tile_data = table.get_recursive(collision.other, "tile", "data")
    if tile_data and tile_data.hazard then
        self:take_damage()
    end
end

function DeliveryGuy:check_landing_squat()
    if self.is_grounded then
        return self.tick - self.landing_tick < 5
    end
    return false
end

function DeliveryGuy:draw()
    graphics.draw_centered(textures.player_placeholder, 0, 0, 0, 1, 1, 0, 1)
end


------------------------------------------
-- States
------------------------------------------

-- State: Idle
function DeliveryGuy:state_Idle_update()
    local input = self:get_input_table()

    if input.move.x ~= 0 then
        self:change_state("Walking")
    end
    self:fall_check()
    self:jump_check(input)
    self:grounded_idle_drag(input)
end

-- State: Walking
function DeliveryGuy:state_Walking_update()
    local input = self:get_input_table()

    if input.move.x == 0 then
        self:change_state("Idle")
    end

    self:set_flip(input.move.x)
    self:apply_force(input.move.x * self.h_accel_ground, 0)
    self:fall_check()
    self:jump_check(input)
    self:grounded_idle_drag(input)
end

-- State: Aerial
function DeliveryGuy:state_Aerial_update()
    local input = self:get_input_table()

    -- Check if we can still jump within coyote time
    if self.coyote_time > 0 then
        self:jump_check(input)
    end

    self:apply_force(input.move.x * self.h_accel_air, 0)
    self:air_idle_drag(input)
    self:land_check()

    -- Now handle can_hold_jump logic here, after jump_check() might have updated it:
    if input.primary_held and self.can_hold_jump then
        self.gravity = 0.0
    else
        self.gravity = self.base_gravity
    end

    if self.air_time > 30 or self.vel.y >= 0 or (not input.primary_held) then
        self.can_hold_jump = false
    end
end

return DeliveryGuy
