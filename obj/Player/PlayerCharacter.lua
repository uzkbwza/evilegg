local PlayerCharacter = GameObject2D:extend("PlayerCharacter")

local PlayerBullet = require("obj.Player.Bullet.BasePlayerBullet")

local SHOOT_DISTANCE = 5
local SHOOT_INPUT_DELAY = 1

local WALK_SPEED = 1.4
local HOVER_SPEED = 0.14
-- local DRIFT_SPEED = 0.05
local HOVER_IMPULSE = 2.0

local WALK_DRAG = 0.1
local HOVER_DRAG = 0.05

local MIN_HOVER_TIME = 14
local PICKUP_RADIUS = 8

function PlayerCharacter:new(x, y)
	PlayerCharacter.super.new(self, x, y)

	
	self.speed = WALK_SPEED
	self.drag = WALK_DRAG
    self.default_drag = self.drag
	self.team = "player"

	self.terrain_collision_radius = 2
    self.body_height = 3
	self.is_player = true

	self.shoot_held_time = 0
	
    self.aim_radius = 12

	self.moving_direction = Vec2(1, 0)

    self.hurt_bubble_radius = 2
	
	self.max_hp = 1
	
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
	self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
	self:lazy_mixin(Mixins.Behavior.Flippable)
    self:lazy_mixin(Mixins.Behavior.AutoStateMachine, "Walk")
	self:lazy_mixin(Mixins.Behavior.Health)
	-- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)

    self:add_elapsed_time()
	self:add_elapsed_ticks()

	self.sprite = textures.player_character

	self.shooting = false
    self.mouse_aim_offset = Vec2(1, 0)
	self.mouse_mode = true
	self.persist = true


	self:add_signal("died")
end

function PlayerCharacter:on_terrain_collision(normal_x, normal_y)
    self:terrain_collision_bounce(normal_x, normal_y)
	-- self:die()
end

function PlayerCharacter:enter()
	self:add_hurt_bubble(0, 0, self.hurt_bubble_radius, "main")
    self:add_tag("player")
	-- self:start_invulnerability_timer(60)
end


function PlayerCharacter:start_invulnerability_timer(duration)
	self:start_timer("invulnerability", duration)
end

function PlayerCharacter:handle_input(dt)
    local input = self:get_input_table()
    local aim_x, aim_y = input.aim_clamped.x, input.aim_clamped.y
	local aim_x_digital, aim_y_digital = input.aim_digital_clamped.x, input.aim_digital_clamped.y

	local aim_magnitude = vec2_magnitude(aim_x, aim_y)
    local aim_deadzone = 0.5
	local digital_aim_input = aim_x_digital ~= 0 or aim_y_digital ~= 0

	
    if input.mouse.dxy_absolute.x ~= 0 or input.mouse.dxy_absolute.y ~= 0 then
        self.mouse_mode = true
	elseif aim_magnitude > aim_deadzone then
		self.mouse_mode = false
	end

	self.shooting = false

    if not self.mouse_mode then
        if aim_magnitude >= aim_deadzone then
            self.aim_direction:set(aim_x, aim_y)
			self.shooting = true
        end
		self.mouse_aim_offset:set(self.aim_direction.x, self.aim_direction.y)

    else
        local mdx, mdy = input.mouse.dxy_absolute.x, input.mouse.dxy_absolute.y

        if vec2_magnitude_squared(mdx, mdy) > 0 then
            self.mouse_aim_offset.x = self.mouse_aim_offset.x + mdx * gametime.delta * usersettings.mouse_sensitivity
            self.mouse_aim_offset.y = self.mouse_aim_offset.y + mdy * gametime.delta * usersettings.mouse_sensitivity
			self.mouse_aim_offset:limit_length(1)
		end

        self.aim_direction:set(self.mouse_aim_offset.x, self.mouse_aim_offset.y):normalize_in_place()
		-- self.aim_direction:normalize_in_place()
    end
	if input.move_normalized.x ~= 0 or input.move_normalized.y ~= 0 then
		self.moving_direction:set(input.move_normalized.x, input.move_normalized.y)
	end
	if self.state == "Walk" then
        self:move(input.move_clamped.x * dt * self.speed, input.move_clamped.y * dt * self.speed)

    elseif self.state == "Hover" then
		self:apply_force(input.move_normalized.x * self.speed, input.move_normalized.y * self.speed)
	end
	
    self.shooting = self.shooting or input.shoot_held

    if (not (digital_aim_input and self.shoot_held_time < SHOOT_INPUT_DELAY)) and self.shooting and not self:is_tick_timer_running("shoot_cooldown") then
        -- self:fire_bullet(PlayerBullet, self.aim_direction:rotated(tau / 99))
        -- self:fire_bullet(PlayerBullet, self.aim_direction:rotated(-tau / 99))
        
		local cooldown = 0
        -- if self.state == "Walk" then
			self:play_sfx("player_shoot", 0.55, 1)
            self:fire_bullet(PlayerBullet, nil, 0, 2)
            self:fire_bullet(PlayerBullet, nil, 0, -2)
			cooldown = 8
			cooldown = max(cooldown, 1)
        -- elseif self.state == "Hover" then
		-- 	local spray_amount = tau / 32
		-- 	self:fire_bullet(PlayerBullet, self.aim_direction:rotated(spray_amount * 3))
		-- 	self:fire_bullet(PlayerBullet, self.aim_direction:rotated(spray_amount * 2))
		-- 	self:fire_bullet(PlayerBullet, self.aim_direction:rotated(spray_amount))
		-- 	self:fire_bullet(PlayerBullet)
		-- 	self:fire_bullet(PlayerBullet, self.aim_direction:rotated(-spray_amount))
		-- 	self:fire_bullet(PlayerBullet, self.aim_direction:rotated(-spray_amount * 2))
		-- 	self:fire_bullet(PlayerBullet, self.aim_direction:rotated(-spray_amount * 3))
		-- 	cooldown = 20
		-- 	cooldown = max(cooldown, 12)
		-- end
        -- local cooldown = 1
		-- cooldown = max(cooldown, 1)
        self:start_tick_timer("shoot_cooldown", cooldown)
        self:start_timer("hide_crosshair", min(cooldown, 3))
    end
	
	if not self.shooting then
		self.shoot_held_time = 0
	else
		self.shoot_held_time = self.shoot_held_time + dt
	end
end

function PlayerCharacter:update_aim_direction()
end

function PlayerCharacter:get_shoot_position()
    local aim_x, aim_y = self.aim_direction.x, self.aim_direction.y
    return self.pos.x + aim_x * SHOOT_DISTANCE, self.pos.y + aim_y * SHOOT_DISTANCE - self.body_height
end

function PlayerCharacter:hit_by(by)
	if self:is_timer_running("invulnerability") then
		return
	end
	self:damage(by.damage)
end

function PlayerCharacter:on_health_reached_zero()
	self:die()
end

function PlayerCharacter:die()
	self:emit_signal("died")
	self:queue_destroy()
end

function PlayerCharacter:update(dt)
    self:collide_with_terrain()
end


function PlayerCharacter:get_palette()
	if self.state == "Hover" and self.tick % 2 == 0 then
		return Palette.cmyk, 4
	end
	return nil, 0
end

function PlayerCharacter:draw()
    if self:is_timer_running("invulnerability") and floor(gametime.tick / 2) % 2 == 0 then
        return
    end

    self:body_translate()

    if self.mouse_aim_offset.y < -0.45 then
        self:draw_crosshair()
    end

    local palette, offset = self:get_palette()
    graphics.drawp_centered(self.sprite, palette, offset, 0)

    if self.mouse_aim_offset.y >= -0.45 then
        self:draw_crosshair()
    end
end

local function crosshair_draw(texture, x, y)
	for f = 1.0, 2, 0.5 do
		f = f * 0.5
		graphics.drawp_centered(texture, nil, 0, x * f, y * f, 0)
	end
end

function PlayerCharacter:draw_crosshair()
	local aim_x, aim_y = self.mouse_aim_offset.x, self.mouse_aim_offset.y
	local end_x, end_y = vec2_mul_scalar(aim_x, aim_y, self.aim_radius)
    if self.mouse_mode then
		if self:is_timer_running("hide_crosshair") then
			-- graphics.set_color(Color.darkgrey)
		else
            graphics.set_color(Color.white)
            crosshair_draw(textures.player_crosshair, end_x, end_y)
            crosshair_draw(textures.player_crosshair_fg, end_x, end_y)
			
		end

    end
	graphics.set_color(Color.white)
end

function PlayerCharacter:debug_draw()
	graphics.set_color(Color.blue)
    graphics.circle("fill", self.mouse_aim_offset.x * 10, self.mouse_aim_offset.y * self.aim_radius - self.body_height, 2)
	if debug.can_draw_bounds() then
		graphics.set_color(Color.green)
		local bx, by = self:get_body_center_local()
		graphics.circle("line", bx, by, PICKUP_RADIUS)
	end
end

function PlayerCharacter:alive_update(dt)
    self:handle_input(dt)
    self:check_pickups()
end

function PlayerCharacter:pickup(pickup)
    pickup:on_pickup(self)
end

function PlayerCharacter.try_pickup(pickup, self)
    if circle_collision(self.pos.x, self.pos.y, PICKUP_RADIUS, pickup.pos.x, pickup.pos.y, pickup.pickup_radius) then
        self:pickup(pickup)
	end
end

function PlayerCharacter:check_pickups()
    local x, y, w, h = self:get_pickup_rect()
    self.world.pickup_objects:each(x, y, w, h, PlayerCharacter.try_pickup, self)
end

function PlayerCharacter:get_pickup_rect()
	local bx, by = self:get_body_center_local()
    return bx - PICKUP_RADIUS, by - PICKUP_RADIUS, PICKUP_RADIUS * 2, PICKUP_RADIUS * 2
end

function PlayerCharacter:state_Walk_enter()
	self.speed = WALK_SPEED
	self.drag = WALK_DRAG
end

function PlayerCharacter:state_Walk_update(dt)
	self:alive_update(dt)
	-- local input = self:get_input_table()
	-- if input.hover_held then
	-- 	self:change_state("Hover")
	-- end
end

function PlayerCharacter:state_Hover_enter()
	self.vel:mul_in_place(0)

	local input = self:get_input_table()
	self:apply_impulse(self.moving_direction.x * HOVER_IMPULSE, self.moving_direction.y * HOVER_IMPULSE)
	self.speed = HOVER_SPEED
	self.drag = HOVER_DRAG
end

local HoverFx = Effect:extend("HoverFx")

function HoverFx:new(x, y)
	HoverFx.super.new(self, x, y)
	self.sprite = textures.player_hover_fx
	self.duration = 15
	self.z_index = -1
end

function HoverFx:draw(elapsed, tick, t)
	local scale = 1 - t
	graphics.drawp_centered(self.sprite, nil, tick, 0, 0, 0, scale, scale)
end

function PlayerCharacter:state_Hover_update(dt)
	self:alive_update(dt)
    local input = self:get_input_table()

	if self.state_tick >= MIN_HOVER_TIME and not input.hover_held then
		self:change_state("Walk")
	end
	
	if self.is_new_tick and self.tick % 2 == 0 then
		self:spawn_object_relative(HoverFx(), self:get_body_center_local())
	end
end

function PlayerCharacter:state_Hover_exit()
	self.vel:mul_in_place(0.1)
end

return PlayerCharacter
