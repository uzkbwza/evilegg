local PlayerCharacter = GameObject2D:extend("PlayerCharacter")

local PlayerBullet = require("obj.Player.Bullet.BasePlayerBullet")

local HoverFx = Effect:extend("HoverFx")
local HoverDashFx = Effect:extend("HoverDashFx")

local DeathFlash = require("fx.enemy_death_flash")
local DeathSplatter = require("fx.enemy_death_pixel_splatter")

local SHOOT_DISTANCE = 6
local SHOOT_INPUT_DELAY = 1

local WALK_SPEED = 1.4
local HOVER_SPEED = 0.2
local HOVER_SPEED_UPGRADE = 0.35
-- local DRIFT_SPEED = 0.05
local HOVER_IMPULSE = 2.0

local WALK_DRAG = 0.1
local HOVER_DRAG = 0.05
local HOVER_DRAG_UPGRADE = 0.085

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
	self.hover_particle_direction = self.moving_direction:clone()

    self.hurt_bubble_radius = 2
	
	self.max_hp = 1
	
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
	self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
	self:lazy_mixin(Mixins.Behavior.Flippable)
    self:lazy_mixin(Mixins.Behavior.AutoStateMachine, "Walk")
	self:lazy_mixin(Mixins.Behavior.Health)
	-- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)

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

local AimDraw = GameObject2D:extend("AimDraw")

function AimDraw:new(x, y, player)
	AimDraw.super.new(self, x, y)
	self:ref("player", player)
	self.z_index = 0.5
	self.persist = true
end

function AimDraw:update(dt)
	if not self.player then return end

	self:move_to(self.player.pos.x, self.player.pos.y)
end


local function crosshair_draw(thickness, color, start_x, start_y, end_x, end_y, dash)
	graphics.set_line_width(thickness)
	graphics.set_color(color)
	if dash then
		graphics.dashline(start_x, start_y, end_x, end_y, 2, 2)
	else
		graphics.line(start_x, start_y, end_x, end_y)
	end
	-- graphics.circle("fill", start_x, start_y, thickness / 2)
	-- graphics.circle("fill", end_x, end_y, thickness / 2)
end

local LASER_SIGHT_DISTANCE_MODIFIER = 2


function AimDraw:draw()
	if not self.player then return end
	self.player:body_translate()
	local aim_x, aim_y = self.player.mouse_aim_offset.x, self.player.mouse_aim_offset.y
	local start_x, start_y = vec2_mul_scalar(aim_x, aim_y, self.player.aim_radius * 0.5)
	local end_x, end_y = vec2_mul_scalar(aim_x, aim_y, self.player.aim_radius * 1.0)
-- if self.player.mouse_mode then
	-- if self:is_timer_running("hide_crosshair") then
		-- graphics.set_color(Color.darkgrey)
	-- else


	local dx, dy = vec2_rotated(aim_x, aim_y, tau / 4)
	dx = dx * 0
	dy = dy * 0

	local start_x1, start_y1 = vec2_normalized_times(start_x, start_y, self.player.aim_radius * 0.5)
	-- local start_x2, start_y2 = vec2_sub(start_x, start_y, dx, dy)
	-- local end_x2, end_y2 = vec2_sub(end_x, end_y, dx, dy)
	-- graphics.set_color(Color.white)
	-- crosshair_draw(3, Color.black, start_x1, start_y1, end_x1 * 4, end_y1 * 4, true)
	local end_x1, end_y1  = vec2_normalized_times(end_x, end_y, self.player.aim_radius)
	crosshair_draw(3, Color.black, start_x1, start_y1, end_x1 * LASER_SIGHT_DISTANCE_MODIFIER, end_y1 * LASER_SIGHT_DISTANCE_MODIFIER, true)
	crosshair_draw(1, Color.magenta, start_x1, start_y1, end_x1 * LASER_SIGHT_DISTANCE_MODIFIER, end_y1 * LASER_SIGHT_DISTANCE_MODIFIER, true)
	end_x1, end_y1  = vec2_add(end_x, end_y, dx, dy)
	start_x1, start_y1 = start_x, start_y
	graphics.set_color(Color.black)
	graphics.circle("fill", start_x1, start_y1, 2)		
	graphics.circle("fill", end_x1 * 0.8, end_y1 * 0.8, 2)
	graphics.set_color(Color.white)
	graphics.circle("fill", start_x1, start_y1, 1)		
	graphics.circle("fill", end_x1 * 0.8, end_y1 * 0.8, 1)
	
	-- crosshair_draw(3, Color.black, start_x1, start_y1, end_x1, end_y1)
	-- crosshair_draw(1, Color.white, start_x1, start_y1, end_x1, end_y1)
	-- crosshair_draw(3, Color.black, start_x2, start_y2, end_x2, end_y2)
	-- crosshair_draw(1, Color.cyan, start_x2, start_y2, end_x2, end_y2)
	-- end

-- end
	graphics.set_color(Color.white)
end

function PlayerCharacter:enter()
	self:add_hurt_bubble(0, 0, self.hurt_bubble_radius, "main")
    self:add_tag("player")
	self:add_tag("ally")
	self:ref("aim_draw", self:spawn_object(AimDraw(0, 0, self)))
	self:add_move_function(function()
		self.aim_draw:move_to(self.pos.x, self.pos.y)
	end)
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
            self.aim_direction:set(aim_x, aim_y):normalize_in_place()
            self.shooting = true
			self.mouse_aim_offset:set(aim_x, aim_y)
		else

			if aim_magnitude > 0.1 then
				self.mouse_aim_offset.x, self.mouse_aim_offset.y = splerp_vec(self.mouse_aim_offset.x, self.mouse_aim_offset.y, aim_x, aim_y, gametime.delta, 900)
			end
		end
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

	local move_amount_x = input.move_clamped.x
	local move_amount_y = input.move_clamped.y
	if move_amount_x > 0.9 then
		move_amount_x = 1
	elseif move_amount_x < -0.9 then
		move_amount_x = -1
	end
	if move_amount_y > 0.9 then
		move_amount_y = 1
	elseif move_amount_y < -0.9 then
		move_amount_y = -1
	end

	local magnitude = vec2_magnitude(move_amount_x, move_amount_y)
	if magnitude > 0.9 then
		magnitude = 1
	elseif magnitude < -0.9 then
		magnitude = pow(magnitude, 2)
	end
	
	move_amount_x = move_amount_x * magnitude
	move_amount_y = move_amount_y * magnitude
    if self.state == "Walk" then

		self:move(move_amount_x * dt * self.speed, move_amount_y * dt * self.speed)
    elseif self.state == "Hover" then
		self:apply_force(move_amount_x * self.speed, move_amount_y * self.speed)
	end
	
    self.shooting = self.shooting or input.shoot_held

    if (not (digital_aim_input and self.shoot_held_time < SHOOT_INPUT_DELAY)) and self.shooting and not self:is_tick_timer_running("shoot_cooldown") then
        -- self:fire_bullet(PlayerBullet, self.aim_direction:rotated(tau / 99))
        -- self:fire_bullet(PlayerBullet, self.aim_direction:rotated(-tau / 99))
        
		local cooldown = 0
        -- if self.state == "Walk" then
		self:fire_bullet(PlayerBullet, nil, 0, 0)
        self:play_sfx("player_shoot", 0.45, 1)
		if game_state.upgrades.bullets >= 1 then
            self:fire_bullet(PlayerBullet, self.aim_direction:rotated(deg2rad(5)), 0, 2, true)

            self:fire_bullet(PlayerBullet, self.aim_direction:rotated(deg2rad(-5)), 0, -2, true)
            -- self:fire_bullet(PlayerBullet, nil)
		end
		if game_state.upgrades.bullets >= 2 then

            self:fire_bullet(PlayerBullet, self.aim_direction:rotated(deg2rad(10)), 0, 4, true)

            self:fire_bullet(PlayerBullet, self.aim_direction:rotated(deg2rad(-10)), 0, -4, true)

		end
        cooldown = 8
        local fire_rate = game_state.upgrades.fire_rate
		local modifier = 1 - (fire_rate * 0.1)
        cooldown = max(cooldown * modifier, 1)
        -- if game_state.upgrades.bullets == 1 then
        --     cooldown = cooldown * 1.0
		-- elseif game_state.upgrades.bullets >= 2 then
		-- 	cooldown = cooldown * 1.0
		-- end
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
        self:start_tick_timer("shoot_cooldown", round(cooldown))
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

function PlayerCharacter:is_invulnerable()
    if self:is_timer_running("invulnerability") then
        return true
    end

	if self.world.room and self.world.room.tick < 10 then 
		return true 
	end

	if self.world.room and self.world.room.cleared then
		return true
	end

	if global_state.debug_invulnerable then
		return true
	end

	return false
end

function PlayerCharacter:hit_by(by)
    if self:is_invulnerable() then return end
		
    -- self:start_timer("death_flash", 1, function()
    -- end)
	
    if game_state.hearts <= 0 then
        self:damage(by.damage)
	else
        self:start_invulnerability_timer(90)
		self:play_sfx("old_player_death", 0.85)
        game_state:lose_heart()
		game_state:random_downgrade()
	end

	local bx, by = self:get_body_center()
	local sprite = self:get_sprite()
	self:spawn_object(DeathFlash(bx, by, sprite, self.hp == 0 and 10.0 or 3.0, Palette.player_death, 1))
end

function PlayerCharacter:on_health_reached_zero()
	self:die()
end

function PlayerCharacter:die()

    self:emit_signal("died")

    -- local object = self:spawn_object(DeathSplatter(bx, by, self.flip, sprite, Palette[sprite], 2, hit_vel_x, hit_vel_y,
    --     bx, by))
	self:queue_destroy()

end

function PlayerCharacter:update(dt)
    self:collide_with_terrain()
end

-- function PlayerCharacter:get_palette()
--     if self.state == "Hover" and self.tick % 2 == 0 then
--         return Palette.cmyk, 4
--     end
--     return nil, 0
-- end

function PlayerCharacter:get_sprite()
    return self.sprite
end

function PlayerCharacter:draw()
    if self:is_timer_running("invulnerability") and floor(gametime.tick / 2) % 2 == 0 then
        return
    end

    self:body_translate()

    -- if self.mouse_aim_offset.y < -0.45 then
    --     self:draw_crosshair()
    -- end

    local palette, offset = self:get_palette()
    graphics.drawp_centered(self:get_sprite(), palette, offset, 0)

    -- if self.mouse_aim_offset.y >= -0.45 then
    --     self:draw_crosshair()
    -- end
end

function PlayerCharacter:draw_crosshair()
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
    if pickup.pickupable and circle_collision(self.pos.x, self.pos.y, PICKUP_RADIUS, pickup.pos.x, pickup.pos.y, pickup.pickup_radius) then
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
	local input = self:get_input_table()
	if input.hover_held then
		self:change_state("Hover")
    end
    if input.debug_toggle_invulnerability_pressed then
		global_state.debug_invulnerable = not global_state.debug_invulnerable

	end
end

function PlayerCharacter:state_Hover_enter(boost)
	self.hover_particle_direction:clone_from(self.moving_direction)
	
	if boost == nil then 
		boost = true
	end
    self.vel:mul_in_place(0)
	self:play_sfx("player_hover", 0.25)

	local input = self:get_input_table()
	if boost or input.move_normalized.x ~= 0 or input.move_normalized.y ~= 0 then
        self:play_sfx("player_dash", 0.5)

		self:spawn_object(HoverDashFx(self.pos.x, self.pos.y, -self.moving_direction.x, -self.moving_direction.y)):ref("player", self)
		
		-- local input = self:get_input_table()
		self:apply_impulse(self.moving_direction.x * HOVER_IMPULSE, self.moving_direction.y * HOVER_IMPULSE)
	end
    self.speed = self:get_hover_speed()
    self.drag = self:get_hover_drag()
end

function PlayerCharacter:get_hover_drag()
	-- local boost = game_state.upgrades.boost
	-- if boost > 0 then
	-- 	return HOVER_DRAG_UPGRADE
	-- end
	return HOVER_DRAG
end

function PlayerCharacter:get_hover_speed()
	-- local boost = game_state.upgrades.boost
	-- if boost > 0 then
	-- return HOVER_SPEED_UPGRADE
	-- end
	return HOVER_SPEED
end


function HoverFx:new(x, y, vel_x, vel_y)
	HoverFx.super.new(self, x, y)
	self.sprite = textures.player_hover_fx
	self.duration = 8 + max(rng.randfn(0, 3), 1)
	self.size = max(rng.randfn(8.0, 1.25), 1.0)
	-- self.z_index = -1
	self.vel = Vec2(vel_x, vel_y)
end

function HoverFx:update(dt)
	self:move(-self.vel.x * dt, -self.vel.y * dt)
end

function HoverFx:draw(elapsed, tick, t)
	self:draw_particle(false, elapsed, tick, t)
end

function HoverFx:draw_particle(floor, elapsed, tick, t)
	if tick % 5 == 0 then
		return
	end
	local scale = remap01_lower(pow(1 - t, 2), 0.1) * self.size

	local color
	if floor then
		local alpha = clamp(rng.randfn(0.05, 0.05), 0.00, 0.15)
		-- local redmod = abs(rng.randfn(0.0, 0.05))
		graphics.set_color(alpha * 0.5, alpha * 0.30, alpha)
	else
		color = Palette.hover_thruster:interpolate_clamped(t)
		graphics.set_color(color)
	end
	graphics.rectangle_centered(t < 0.25 and "fill" or "line", 0, 0, scale, scale)
end

function HoverDashFx:new(x, y, vel_x, vel_y)
	HoverDashFx.super.new(self, x, y)
	self.duration = 20
	self.particles = {}
	for i = 1, 20 do
		local particle = {}
		particle.pos = Vec2(0, 0)
		particle.vel_x, particle.vel_y = rng.random_vec2_times(rng.randfn(rng.randf_range(0.2, 2.5), 0.1))
		local vel_mod = rng.randf(0.25, 3)
		particle.vel_x = particle.vel_x + vel_x * vel_mod
		particle.vel_y = particle.vel_y + vel_y * vel_mod
		particle.size = 1
		local alpha = clamp(rng.randfn(0.15, 0.005), 0.00, 0.18)
		particle.color = Color(alpha * 0.5, alpha * 0.30, alpha)
		table.insert(self.particles, particle)
	end
end

function HoverDashFx:update(dt)
	for i, particle in ipairs(self.particles) do
		particle.pos.x = particle.pos.x + particle.vel_x * dt
		particle.pos.y = particle.pos.y + particle.vel_y * dt
		particle.vel_x, particle.vel_y = vec2_drag(particle.vel_x, particle.vel_y, 0.1, dt)
	end
end

function HoverDashFx:draw(elapsed, tick, t)
	self:draw_particles()
end

function HoverDashFx:floor_draw()
	if self.tick < 10 then
		if self.is_new_tick and self.tick == 2 then
			graphics.set_color(Color.darkgrey)
			graphics.circle("line", 0, 0, 5)
		end
		return
	end
	self:draw_particles()
end

function HoverDashFx:draw_particles()
	for i, particle in ipairs(self.particles) do
		graphics.set_color(particle.color)
		graphics.rectangle_centered("fill", particle.pos.x, particle.pos.y, particle.size, particle.size)
	end
end

function HoverFx:floor_draw()
	if self.is_new_tick and (rng.percent(5) or (self.player and rng.percent(100 - self.player.state_tick * 5))) then
		local elapsed = self.elapsed
		local tick = self.tick
		local t = elapsed / self.duration
		self:draw_particle(true, elapsed, tick, t)
	end
end

function PlayerCharacter:state_Hover_update(dt)
	self.drag = self:get_hover_drag()
	self.speed = self:get_hover_speed()

	if self.is_new_tick and (self.tick % 20 == 0 or self.state_tick == 1) then
		self:play_sfx("player_hover", 0.25)
	end

    if self.state_tick < 4 then
        -- self:defer(function()
        if self.moving_direction.x ~= 0 or self.moving_direction.y ~= 0 then
            local mag = self.vel:magnitude()
            self.vel.x = self.moving_direction.x * mag
            self.vel.y = self.moving_direction.y * mag
        end
        -- end)
    end
	
	self:alive_update(dt)
    local input = self:get_input_table()

	if self.state_tick >= MIN_HOVER_TIME and not input.hover_held then
		-- if not self.world.room.cleared then
			self:change_state("Walk")
		-- end
	end

	self.hover_particle_direction:splerp_in_place(self.moving_direction, dt, 10)
	
	if self.is_new_tick then
		local bx, by = self:get_body_center()
		local offsx, offsy = rng.random_vec2_times(rng.randfn(0, 1.0))
		bx = bx + offsx
		by = by + offsy
		local vel_x, vel_y = self.hover_particle_direction.x, self.hover_particle_direction.y
		local current_vel_magnitude = self.vel:magnitude()
		vel_x = vel_x * current_vel_magnitude * 2
		vel_y = vel_y * current_vel_magnitude * 2
		vel_x = vel_x + self.vel.x
		vel_y = vel_y + self.vel.y
		if vec2_magnitude_squared(vel_x, vel_y) < vec2_magnitude_squared(self.moving_direction.x, self.moving_direction.y) then
			vel_x, vel_y = rng.random_vec2_times(4)
		end

		vel_x, vel_y = vec2_rotated(vel_x, vel_y, rng.randfn(0, tau / 32))
		vel_x, vel_y = vec2_mul_scalar(vel_x, vel_y, rng.randfn(1.0, 0.25) * 1.5)
		vel_x, vel_y = vec2_clamp_magnitude(vel_x, vel_y, 1, math.huge)

		local offsx2, offsy2 = vec2_normalized_times(-vel_x, -vel_y, 5)
		offsx2 = offsx2 * abs(rng.randfn(0, 1.0))
		offsy2 = offsy2 * abs(rng.randfn(0, 1.0))
		bx = bx + offsx2
		by = by + offsy2

		vel_x, vel_y = vec2_mul_scalar(vel_x, vel_y, 0.25)

        self:spawn_object(HoverFx(bx, by - 1, vel_x, vel_y)):ref("player", self)
    end

	if debug.enabled then
		dbg("hover speed", self.vel:magnitude())
	end
end

function PlayerCharacter:state_Hover_exit()
    self.vel:mul_in_place(0.1)
	self:stop_sfx("player_hover")
end

function PlayerCharacter:exit()
	self:stop_sfx("player_hover")
end

return PlayerCharacter
