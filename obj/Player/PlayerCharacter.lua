local PlayerCharacter = GameObject2D:extend("PlayerCharacter")

local PlayerDrone = GameObject2D:extend("PlayerDrone")

local PlayerBullet = require("obj.Player.Bullet.BasePlayerBullet")

local HoverFx = Effect:extend("HoverFx")
local HoverDashFx = Effect:extend("HoverDashFx")
local HoverFireTrail = GameObject2D:extend("HoverFireTrail")

local DeathFlash = require("fx.enemy_death_flash")
local DeathSplatter = require("fx.enemy_death_pixel_splatter")

local RocketBullet = require("obj.Player.Bullet.RocketBullet")

local PlayerShadow = Effect:extend("PlayerShadow")

local AimDraw = GameObject2D:extend("AimDraw")

local SHOOT_DISTANCE = 6
local SHOOT_INPUT_DELAY = 1

local WALK_SPEED = 1.4
local HOVER_SPEED = 0.2
local HOVER_SPEED_UPGRADE = 0.35
-- local DRIFT_SPEED = 0.05
local HOVER_IMPULSE = 2.0

local WALK_DRAG = 0.1
local HOVER_DRAG = 0.05
local HOVER_DRAG_UPGRADE = 0.075

local MIN_HOVER_TIME = 14
local PICKUP_RADIUS = 8

PlayerCharacter.bullet_powerups = {
	["BaseBullet"] = PlayerBullet,
	["RocketPowerup"] = RocketBullet,
}

function PlayerCharacter:new(x, y)
    PlayerCharacter.super.new(self, x, y)

    self.speed = WALK_SPEED
    self.drag = WALK_DRAG
    self.default_drag = self.drag
    self.team = "player"

    self.terrain_collision_radius = 2
    self.body_height = 3
    self.is_player = true
    self.hover_vel = Vec2()
    self.hover_accel = Vec2()
    self.hover_impulse = Vec2()
	self.mouse_pos_x, self.mouse_pos_y = 0, 0

    self.shoot_held_time = 0

    self.aim_radius = 12

    self.moving_direction = Vec2(1, 0)
    self.hover_particle_direction = self.moving_direction:clone()

    self.hurt_bubble_radius = 2

    self.max_hp = 1

    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
    self:lazy_mixin(Mixins.Behavior.Flippable)
    self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
    self:lazy_mixin(Mixins.Behavior.Health)

    -- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)

    self.sprite = textures.player_character

    self.shooting = false
    self.mouse_aim_offset = Vec2(1, 0)
    self.mouse_mode = true
    self.persist = true

    self:add_signal("died")
    self:add_signal("got_hurt")
    self:init_state_machine()

    signal.connect(game_state, "player_artefact_gained", self, "on_artefact_gained")
    signal.connect(game_state, "player_artefact_removed", self, "on_artefact_removed")
end

function PlayerCharacter:on_artefact_gained(artefact, slot)
	if artefact.key == "drone" and not self.drone then
		self:spawn_drone()
	end
end

function PlayerCharacter:on_artefact_removed(artefact, slot)
    if artefact.key == "drone" then
		if self.drone then
			self.drone:queue_destroy()
		end
	end
end

function PlayerCharacter:on_terrain_collision(normal_x, normal_y)
	self.bounce_sfx_horizontal = false
	self.bounce_sfx_vertical = false
	if normal_x ~= 0 then
		self.hover_vel.x = self.hover_vel.x * -1
        self.bounce_sfx_horizontal = true
	end
	if normal_y ~= 0 then
		self.hover_vel.y = self.hover_vel.y * -1
		self.bounce_sfx_vertical = true
	end
end


function PlayerCharacter:spawn_drone()
    local drone = self:spawn_object(PlayerDrone(self.pos.x, self.pos.y))
    drone:ref("player", self)
	self:ref("drone", drone)
end

function AimDraw:new(x, y, player)
	AimDraw.super.new(self, x, y)
	self:ref("player", player)
	self.z_index = 1000
	self:add_time_stuff()
	self.persist = true
end

function AimDraw:update(dt)
	if not self.player then return end

	self:move_to(self.player.pos.x, self.player.pos.y)
end


function AimDraw:laser_sight_draw(thickness, color, start_x, start_y, end_x, end_y, dash)
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
    graphics.push()
    self.player:body_translate()


    graphics.set_color(Color.white)

    if game_state.bullet_powerup then
        graphics.set_color(Color.white)
        local font = fonts.main_font_bold
        graphics.set_font(font)
        local text = string.format("%02d", floor(frames_to_seconds(game_state.bullet_powerup_time)))
        local width = font:getWidth(text)
        graphics.print_outline(Color.black, text, -width / 2, font:getHeight() - 2)
    end

    if self.player.mouse_mode and usersettings.use_absolute_aim then
        local global_mouse_x, global_mouse_y = self.player.mouse_pos_x, self.player.mouse_pos_y
        local mouse_x, mouse_y = self:to_local(global_mouse_x, global_mouse_y)
        local laser_start_x, laser_start_y = vec2_normalized_times(mouse_x, mouse_y, self.player.aim_radius * 0.5)
        local laser_end_x, laser_end_y = mouse_x, mouse_y
		local mouse_dist = vec2_magnitude(mouse_x, mouse_y)
		if mouse_dist > LASER_SIGHT_DISTANCE_MODIFIER * self.player.aim_radius then
			laser_end_x, laser_end_y = vec2_normalized_times(mouse_x, mouse_y, LASER_SIGHT_DISTANCE_MODIFIER * self.player.aim_radius)
		end
		self:laser_sight_draw(3, Color.black, laser_start_x, laser_start_y, laser_end_x, laser_end_y, true)
		self:laser_sight_draw(1, Color.magenta, laser_start_x, laser_start_y, laser_end_x, laser_end_y, true)
		self:draw_crosshair(mouse_x, mouse_y)
    else
        local aim_x, aim_y = self.player.mouse_aim_offset.x, self.player.mouse_aim_offset.y
        local start_x, start_y = vec2_mul_scalar(aim_x, aim_y, self.player.aim_radius * 0.5)
        local end_x, end_y = vec2_mul_scalar(aim_x, aim_y, self.player.aim_radius * 1.0)
        -- if self.player.mouse_mode then
        -- if self:is_timer_running("hide_crosshair") then
        -- graphics.set_color(Color.darkergrey)
        -- else

        local dx, dy             = vec2_rotated(aim_x, aim_y, tau / 4)
        dx                       = dx * 0
        dy                       = dy * 0

        local start_x1, start_y1 = vec2_normalized_times(start_x, start_y, self.player.aim_radius * 0.5)
        -- local start_x2, start_y2 = vec2_sub(start_x, start_y, dx, dy)
        -- local end_x2, end_y2 = vec2_sub(end_x, end_y, dx, dy)
        -- graphics.set_color(Color.white)
        -- self:laser_sight_draw(3, Color.black, start_x1, start_y1, end_x1 * 4, end_y1 * 4, true)
        local end_x1, end_y1     = vec2_normalized_times(end_x, end_y, self.player.aim_radius)

        if self.player.mouse_mode then
            -- graphics.circle("fill", start_x1, start_y1, 5)		
            local aim_vec_x, aim_vec_y = self.player.mouse_aim_offset.x, self.player.mouse_aim_offset.y
            local length = vec2_magnitude(aim_vec_x, aim_vec_y) * LASER_SIGHT_DISTANCE_MODIFIER
            local x, y = end_x1 * length, end_y1 * length
            -- graphics.circle("line", x, y, 5)


            self:laser_sight_draw(3, Color.black, start_x1, start_y1, x, y, true)
            self:laser_sight_draw(1, Color.magenta, start_x1, start_y1, x, y, true)
			self:draw_crosshair(x, y)
        else
            self:laser_sight_draw(3, Color.black, start_x1, start_y1, end_x1 * LASER_SIGHT_DISTANCE_MODIFIER,
                end_y1 * LASER_SIGHT_DISTANCE_MODIFIER, true)
            self:laser_sight_draw(1, Color.magenta, start_x1, start_y1, end_x1 * LASER_SIGHT_DISTANCE_MODIFIER,
                end_y1 * LASER_SIGHT_DISTANCE_MODIFIER, true)
        end

        -- end_x1, end_y1  = vec2_add(end_x, end_y, dx, dy)
        -- start_x1, start_y1 = start_x, start_y
        -- graphics.set_color(Color.black)
        -- graphics.circle("fill", start_x1, start_y1, 2)		
        -- graphics.circle("fill", end_x1 * 0.8, end_y1 * 0.8, 2)
        -- graphics.set_color(Color.white)
        -- graphics.circle("fill", start_x1, start_y1, 1)		
        -- graphics.circle("fill", end_x1 * 0.8, end_y1 * 0.8, 1)
    end



    -- self:laser_sight_draw(3, Color.black, start_x1, start_y1, end_x1, end_y1)
    -- self:laser_sight_draw(1, Color.white, start_x1, start_y1, end_x1, end_y1)
    -- self:laser_sight_draw(3, Color.black, start_x2, start_y2, end_x2, end_y2)
    -- self:laser_sight_draw(1, Color.cyan, start_x2, start_y2, end_x2, end_y2)
    -- end
    graphics.pop()

    -- local rescue_objects = self.world:get_objects_with_tag("rescue_object")
    -- if rescue_objects then
    -- 	for _, rescue in (rescue_objects:ipairs()) do
    -- 		local bx, by = self.player:get_body_center()
    --         local rx, ry = rescue:get_body_center()
    -- 		bx, by = self:to_local(bx, by)
    --         rx, ry = self:to_local(rx, ry)
    --         graphics.set_color(Color.green)
    -- 		graphics.line(bx, by, rx, ry)
    -- 	end
    -- end
end

function AimDraw:draw_crosshair(x, y)
	local size = 9

	graphics.push()
	graphics.translate(x, y)
	
	graphics.push()
	graphics.rotate(self.player.mouse_aim_offset:angle() + self.elapsed * 0.1)
	graphics.set_line_width(3)
	graphics.set_color(Color.black)
	graphics.dashrect_centered(0, 0, size, size, 3, 3)
	graphics.set_line_width(1)
	graphics.set_color(Color.white)
	graphics.dashrect_centered(0, 0, size, size, 3, 3)
	graphics.pop()

	graphics.set_color(Color.black)
	graphics.rectangle_centered("fill", 0, 0, 4, 4)
	graphics.set_color(Color.white)
	graphics.rectangle_centered("fill", 0, 0, 2, 2)
	graphics.pop()
end 

function PlayerCharacter:enter()
	self:add_hurt_bubble(0, 0, self.hurt_bubble_radius, "main")
    self:add_tag("player")
    self:add_tag("move_with_level_transition")
	self:add_tag("ally")
    self:ref("aim_draw", self:spawn_object(AimDraw(0, 0, self)))
	self:ref("shadow", self:spawn_object(PlayerShadow(0, 0, self)))
	self:add_move_function(function()
		self.aim_draw:move_to(self.pos.x, self.pos.y)
    end)
	if game_state.artefacts.drone then
		self:spawn_drone()
	end
	-- self:ref("ground_effect", self:spawn_object(GroundEffect(0, 0, self)))
	-- self:start_invulnerability_timer(60)
end

-- function GroundEffect:new(x, y, player)
-- 	GroundEffect.super.new(self, x, y)
-- 	self:ref("player", player)
-- 	self.z_index = -1
--     self.persist = true
-- 	self:add_time_stuff()
-- 	signal.connect(self.player, "moved", self, "on_moved")
-- end

-- function GroundEffect:on_moved()
-- 	self:move_to(self.player.pos.x, self.player.pos.y)
-- end

-- function GroundEffect:update(dt)
--     if not self.player then
-- 		self:queue_destroy() 
--         return		
-- 	end
-- end

-- function GroundEffect:draw()
--     if not self.player then return end
--     if gametime.tick % 2 == 0 then return end
-- 	graphics.set_color(Color.darkyellow)
-- 	graphics.ellipse("fill", 0, 0, 6, 4, 10)
-- end

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
				self.mouse_aim_offset.x, self.mouse_aim_offset.y = splerp_vec(self.mouse_aim_offset.x, self.mouse_aim_offset.y, aim_x, aim_y, 900, gametime.delta)
			end
		end
    else
        if usersettings.use_absolute_aim then
            local global_mouse_x, global_mouse_y = self:get_mouse_position()
			self.mouse_pos_x = global_mouse_x
			self.mouse_pos_y = global_mouse_y
            local mouse_x, mouse_y = self:to_local(global_mouse_x, global_mouse_y)
            self.mouse_aim_offset:set(vec2_limit_length(mouse_x, mouse_y, 1))
			self.aim_direction:set(self.mouse_aim_offset.x, self.mouse_aim_offset.y):normalize_in_place()
		else
			local mdx, mdy = input.mouse.dxy_absolute.x, input.mouse.dxy_absolute.y

			if vec2_magnitude_squared(mdx, mdy) > 0 then
				self.mouse_aim_offset.x = self.mouse_aim_offset.x + mdx * gametime.delta * usersettings.mouse_sensitivity
                self.mouse_aim_offset.y = self.mouse_aim_offset.y + mdy * gametime.delta * usersettings
                .mouse_sensitivity
				if usersettings.relative_mouse_aim_snap_to_max_range then
                    self.mouse_aim_offset:normalize_in_place()
				else
					self.mouse_aim_offset:limit_length(1)
				end
			end

            self.aim_direction:set(self.mouse_aim_offset.x, self.mouse_aim_offset.y):normalize_in_place()
		end
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
		self.hover_accel.x = self.hover_accel.x + move_amount_x * self.speed
		self.hover_accel.y = self.hover_accel.y + move_amount_y * self.speed
	end
	
    self.shooting = self.shooting or input.shoot_held

    if (not (digital_aim_input and self.shoot_held_time < SHOOT_INPUT_DELAY)) and self.shooting and not self:is_tick_timer_running("shoot_cooldown") then
        
		local cooldown = self:fire_current_bullet()
        -- if self.state == "Walk" then

        local fire_rate = game_state.upgrades.fire_rate
		local modifier = 1
		modifier = modifier - (fire_rate * 0.1) * (cooldown / PlayerBullet.cooldown)
		if game_state.artefacts.crown_of_frenzy and self.world:get_number_of_objects_with_tag("rescue_object") == 0 then
			modifier = modifier * 0.9
		end
        cooldown = cooldown * modifier


        cooldown = max(cooldown, 1)
		
        cooldown = round(cooldown)
		
		dbg("cooldown", cooldown)

        self:start_tick_timer("shoot_cooldown", cooldown)
        -- self:start_timer("hide_crosshair", min(cooldown, 3))
    end
	
	if not self.shooting then
		self.shoot_held_time = 0
	else
		self.shoot_held_time = self.shoot_held_time + dt
	end
end

function PlayerCharacter:fire_current_bullet()
    local class = self.bullet_powerups["BaseBullet"]

    
	local powerup = game_state:get_bullet_powerup()
	
	if powerup then
        class = self.bullet_powerups[powerup.name]
    end
	
    local cooldown = class.cooldown
	local num_bullets = clamp(game_state.upgrades.bullets + (class.num_bullets_modifier or 0), 0, game_state:get_max_upgrade("bullets"))

	self:fire_bullet(class, nil, 0, 0)
    
	self:play_sfx(class.shoot_sfx or "player_shoot", class.shoot_sfx_volume or 0.45, 1)
	
	local spread = class.spread

    for i = 1, num_bullets do
        if num_bullets >= 1 then
            self:fire_bullet(class, self.aim_direction:rotated(deg2rad(spread * i)), 0, class.h_offset * i, true)
            self:fire_bullet(class, self.aim_direction:rotated(deg2rad(-spread * i)), 0, -class.h_offset * i, true)
        end
    end
	
    if self.drone then
		self:fire_bullet_at_position(class, self.aim_direction:clone():mul_in_place(-1), self.drone.pos.x, self.drone.pos.y, true)
	end

	return cooldown
end

function PlayerCharacter:update_aim_direction()
end

function PlayerCharacter:create_drone()
	
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

	if debug.enabled then
        if by.parent then
			local process_float = function(x)
				return stepify_safe(x, 0.01)
			end
            local hurt_bubble = self:get_bubble("hurt", "main")
            local hx, hy = hurt_bubble:get_position()
			local byx, byy = by:get_position()
            local r = hurt_bubble.radius
			local byr = by.radius
            print("hit by " ..
            tostring(by.parent) ..
            " who was at " .. process_float(byx) .. ", " .. process_float(byy) .. " with radius " .. process_float(byr))
            print("i was at " .. process_float(hx) .. ", " .. process_float(hy) .. " with radius " .. process_float(r))
            print("which is a difference of " ..
            process_float(hx - byx) ..
            ", " .. process_float(hy - byy) .. " with a total distance of " .. process_float(vec2_distance(hx, hy, byx, byy)))
            if vec2_distance(hx, hy, byx, byy) > r + byr then
				print("this should have missed as the distance is " .. process_float(vec2_distance(hx, hy, byx, byy)) .. " which is greater than the sum of the radii " .. process_float(r + byr))
            else
				print("this should have hit as the distance is " .. process_float(vec2_distance(hx, hy, byx, byy)) .. " which is less than the sum of the radii " .. process_float(r + byr))
			end
			
        else
            print("hit by " .. tostring(by))
        end
	end

    if self:is_invulnerable() then return end

    if by.damage > 0 then
        if game_state.hearts > 0 then
            self:start_invulnerability_timer(90)
            -- self:play_sfx("old_player_death", 0.85)
            game_state:lose_heart()
            -- local percent = game_state.artefacts.stone_trinket and 50 or 100
			-- if rng.percent(percent) then
			game_state:random_downgrade()
            -- end
			
            self:emit_signal("got_hurt")
        elseif game_state.artefacts.sacrificial_twin then
			game_state:use_sacrificial_twin()
            self:emit_signal("got_hurt")
            self:start_invulnerability_timer(90)
        else
            self:damage(1)
        end
    end
	
	local bcx, bcy = self:get_body_center()

	local sprite = self:get_sprite()
    local particle = self:spawn_object(DeathFlash(bcx, bcy, sprite, self.hp == 0 and 10.0 or 3.0, Palette.player_death, 1))
	if self.hp > 0 then
		particle.z_index = -1
	end

	game_state:on_damage_taken()
end

function PlayerCharacter:on_health_reached_zero()
    self:die()

end

function PlayerCharacter:die()
	if self.shadow then
		self.shadow:die()
	end
    self:emit_signal("died")

    -- local object = self:spawn_object(DeathSplatter(bx, by, self.flip, sprite, Palette[sprite], 2, hit_vel_x, hit_vel_y,
    --     bx, by))
	self:queue_destroy()

end

function PlayerCharacter:update(dt)

	-- love.timer.sleep(0.0035)

    self:collide_with_terrain()
    if self.is_new_tick then
        -- local s = self.sequencer
        -- s:start(function()

        -- end)
    end
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
    self.hover_accel:mul_in_place(0)
    self.hover_vel:mul_in_place(0)
	self.hover_impulse:mul_in_place(0)
	self.hover_particle_direction:clone_from(self.moving_direction)
	
	if boost == nil then 
		boost = true
	end
    self.hover_vel:mul_in_place(0)
	self:play_sfx("player_hover", 0.25)

	local input = self:get_input_table()
	if boost or input.move_normalized.x ~= 0 or input.move_normalized.y ~= 0 then
        self:play_sfx("player_dash", 0.5)

		self:spawn_object(HoverDashFx(self.pos.x, self.pos.y, -self.moving_direction.x, -self.moving_direction.y)):ref("player", self)
		
		-- local input = self:get_input_table()
		self.hover_impulse.x = self.hover_impulse.x + self.moving_direction.x * HOVER_IMPULSE
		self.hover_impulse.y = self.hover_impulse.y + self.moving_direction.y * HOVER_IMPULSE
	end
    self.speed = self:get_hover_speed()
    self.drag = self:get_hover_drag()

end

function PlayerCharacter:get_hover_drag()
	local boost = game_state.artefacts.boost_damage
	if boost then
		return HOVER_DRAG_UPGRADE
	end
	return HOVER_DRAG
end

function PlayerCharacter:get_hover_speed()
	local boost = game_state.artefacts.boost_damage
	if boost then
	return HOVER_SPEED_UPGRADE
	end
	return HOVER_SPEED
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
            local mag = self.hover_vel:magnitude()
            self.hover_vel.x = self.moving_direction.x * mag
            self.hover_vel.y = self.moving_direction.y * mag
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

	self.hover_particle_direction:splerp_in_place(self.moving_direction, 10, dt)
	
	if self.is_new_tick then
        for i = 1, (1) do
            local bx, by = self:get_body_center()
            local offsx, offsy = rng.random_vec2_times(rng.randfn(0, 1.0))
            bx = bx + offsx
            by = by + offsy
            local vel_x, vel_y = self.hover_particle_direction.x, self.hover_particle_direction.y
            local current_vel_magnitude = self.hover_vel:magnitude()
            vel_x = vel_x * current_vel_magnitude * 2
            vel_y = vel_y * current_vel_magnitude * 2
            vel_x = vel_x + self.hover_vel.x
            vel_y = vel_y + self.hover_vel.y
            local random = false
            if rng.percent(15) or vec2_magnitude_squared(vel_x, vel_y) < vec2_magnitude_squared(self.moving_direction.x, self.moving_direction.y) then
                vel_x, vel_y = rng.random_vec2_times(game_state.artefacts.boost_damage and 5 or 4)
                random = true
            end

            vel_x, vel_y = vec2_rotated(vel_x, vel_y, rng.randfn(0, tau / 32))
            vel_x, vel_y = vec2_mul_scalar(vel_x, vel_y,
                rng.randfn(1.0, 0.25) * (((not random) and game_state.artefacts.boost_damage) and 1.75 or 1.5))
            vel_x, vel_y = vec2_clamp_magnitude(vel_x, vel_y, 1, math.huge)

            local offsx2, offsy2 = vec2_normalized_times(-vel_x, -vel_y, 5)
            offsx2 = offsx2 * abs(rng.randfn(0, 1.0))
            offsy2 = offsy2 * abs(rng.randfn(0, 1.0))
            bx = bx + offsx2
            by = by + offsy2

            vel_x, vel_y = vec2_mul_scalar(vel_x, vel_y, 0.25)

            -- if not random and game_state.artefacts.boost_damage then
            --     if vec2_magnitude(vel_x, vel_y) < (4) then
            --         vel_x, vel_y = vec2_normalized_times(vel_x, vel_y, 4)
            --     end
            -- end

            self:spawn_object(HoverFx(bx, by - 1, vel_x, vel_y)):ref("player", self)
        end
        if game_state.artefacts.boost_damage and (self.state_tick - 1) % (self.hover_vel:magnitude() > 2.0 and 5 or 15) == 0 then
			self:spawn_object(HoverFireTrail(self.pos.x, self.pos.y))
		end
    end

		
	self.hover_vel.x = self.hover_vel.x + self.hover_accel.x * dt
    self.hover_vel.y = self.hover_vel.y + self.hover_accel.y * dt
	self.hover_vel.x = self.hover_vel.x + self.hover_impulse.x
	self.hover_vel.y = self.hover_vel.y + self.hover_impulse.y
	-- self.pos.x = self.pos.x + self.hover_vel.x * dt
    -- self.pos.y = self.pos.y + self.hover_vel.y * dt
	self:move(self.hover_vel.x * dt, self.hover_vel.y * dt)

    self.hover_vel.x, self.hover_vel.y = vec2_drag(self.hover_vel.x, self.hover_vel.y, self.drag, dt)
    self.hover_impulse:mul_in_place(0)
	self.hover_accel:mul_in_place(0)

	if debug.enabled then
		dbg("hover speed", self.hover_vel:magnitude())
	end


    if self.bounce_sfx_horizontal then
        if abs(self.hover_vel.x) > 0.3 then
            self:play_sfx("entity_bounce")
        end
		self.bounce_sfx_horizontal = false
	end
	if self.bounce_sfx_vertical then
		if abs(self.hover_vel.y) > 0.3 then
			self:play_sfx("entity_bounce")
		end
		self.bounce_sfx_vertical = false
	end

end

function PlayerCharacter:state_Hover_exit()
    self.hover_vel:mul_in_place(0.0)
	self:stop_sfx("player_hover")
end

function PlayerCharacter:exit()
	self:stop_sfx("player_hover")
end

HoverFx.damage_scale = 0.06
HoverFx.hit_velocity = 0.1

function HoverFx:new(x, y, vel_x, vel_y)
	HoverFx.super.new(self, x, y)
	self.sprite = textures.player_hover_fx
    self.duration = 8 + max(rng.randfn(0, 3), 1) * (game_state.artefacts.boost_damage and 1.5 or 1)
	self.drag = 0.2
	-- if game_state.artefacts.boost_damage then self.drag = 0.05 end
	self.size = max(rng.randfn(game_state.artefacts.boost_damage and 10.0 or 8.0, 1.25), 1.0)
	-- self.z_index = -1
    self.hover_vel = Vec2(vel_x, vel_y):mul_in_place(1.5)
	self.terrain_collision_radius = 1
    self.body_height = 0
	self.team = "player"
	self.palette = game_state.artefacts.boost_damage and Palette.hover_thruster_damage or Palette.hover_thruster
    -- self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
end

-- function HoverFx:enter()
	-- if game_state.artefacts.boost_damage then
	-- 	self:add_hit_bubble(0, 0, self.size * 1.3, "main", self.damage_scale * self.size)
	-- end
-- end

function HoverFx:hit_other(other, bubble)
    local bx, by = self:get_body_center()
	local ox, oy = other:get_body_center()
    local dx, dy = vec2_direction_to(bx, by, ox, oy)
	local t = self.elapsed / self.duration
	local scale = remap01_lower(pow(1 - t, 2), 0.1) * self.size
	local vel_x, vel_y = vec2_normalized_times(dx, dy, self.hit_velocity * scale)
	other:apply_impulse(vel_x, vel_y)
end

function HoverFx:update(dt)
    self:move(-self.hover_vel.x * dt, -self.hover_vel.y * dt)
    self.hover_vel.x, self.hover_vel.y = vec2_drag(self.hover_vel.x, self.hover_vel.y, self.drag, dt)

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
		color = (self.palette):interpolate_clamped(t)
		graphics.set_color(color)
	end
	graphics.rectangle_centered(t < 0.25 and "fill" or "line", 0, 0, scale, scale)
end

function HoverFireTrail:new(x, y)
    HoverFireTrail.super.new(self, x, y)
    self.sprite = textures.player_hover_fire_trail
	self.team = "player"
    self.duration = 90 + rng.randfn(0, 6)
    self.z_index = 0
    self.persist = false
    self.hit_cooldown = 2
	self.particles = {}
	self.to_remove = {}
    self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
	self.random_offset = rng.randi(0, 100)
end

function HoverFireTrail:enter()
    self:add_hit_bubble(0, 0, 9, "main", 0.15)
end

function HoverFireTrail:update(dt)
    local hitbox = self:get_bubble("hit", "main")
	local radius = hitbox.radius
    hitbox.radius = approach(radius, 5, 0.05 * dt)
    if not self.done and self.elapsed > self.duration then
        self.done = true
        self.melee_attacking = false
		self:stop_sfx("player_boost_fire")
    end

	table.clear(self.to_remove)

	
    for particle in pairs(self.particles) do
        particle.elapsed = particle.elapsed + dt
        -- particle.pos.x = particle.pos.x + particle.vel_x * dt
        if particle.elapsed > particle.duration then
            table.insert(self.to_remove, particle)
        end
    end
	
	for _, particle in ipairs(self.to_remove) do
		self.particles[particle] = nil
	end

    if self.is_new_tick and not self.done then
        for i = 1, rng.randi(2) do
			if rng.percent(10) then
				local particle = {}
				particle.x, particle.y = rng.random_vec2_times(rng.randf_range(0, self:get_bubble("hit", "main").radius * 2))
				particle.size = rng.randfn(3, 1)
				particle.elapsed = 0
				particle.duration = rng.randf_range(10, 50)
				particle.speed = rng.randf_range(0.15, 0.4)
				self.particles[particle] = true
			end
		end
	end

	if self.done then 
        if table.is_empty(self.particles) then
            self:queue_destroy()
        end
    else
		self:play_sfx_if_stopped("player_boost_fire", 0.25)
	end
end

function HoverFireTrail:draw()

    if self.elapsed < self.duration then
        local color = Palette.trail_fire_ground:tick_color(self.tick + self.random_offset, 0, 1)
		if color ~= Color.black then
        	graphics.set_color(color)
        	local size = self:get_bubble("hit", "main").radius * 2 * (1 + sin(self.elapsed * 0.3) * 0.2) * 0.75
        	graphics.rectangle_centered(idivmod_eq_zero(self.tick, 2, 2) and "line" or "fill", 0, 0, size, size)
		end
    end
	
	for particle in pairs(self.particles) do
		graphics.set_color(Palette.fire:tick_color(particle.elapsed, 0, 3))
		local size = particle.size * (1 - particle.elapsed / particle.duration)
		graphics.rectangle_centered("fill", particle.x, particle.y - particle.elapsed * particle.speed, size, size)
	end

end

function HoverFireTrail:exit()
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
			graphics.set_color(Color.darkergrey)
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
function PlayerDrone:new(x, y)
	PlayerDrone.super.new(self, x, y)
	self.sprite = textures.player_drone
	self.z_index = 1000
	self.persist = true
	self.size = 16
	self.player = nil
	self.target = Vec2(x, y)
	self:add_time_stuff()
end

function PlayerDrone:enter()
	self:add_tag("move_with_level_transition")
end

function PlayerDrone:update(dt)
    if self.player then
        self.target.x, self.target.y = self.player.pos.x, self.player.pos.y
    else
        self:queue_destroy()
    end
    -- local offs_x, offs_y = vec2_from_polar(20, self.elapsed / 18)
	local offs_x, offs_y = 0, 0
	local x, y = splerp_vec(self.pos.x, self.pos.y, -self.target.x + offs_x, -self.target.y + offs_y, 200, dt)
	self:move_to(x, y)
end

function PlayerDrone:draw()
	if gametime.tick % 2 == 0 then return end
    graphics.set_color(Color.white)
    graphics.drawp_centered(textures.ally_drone, nil, 0)
end


function PlayerShadow:new(x, y, target)
    PlayerShadow.super.new(self, x, y)
	self.persist = true
    self:add_sequencer()
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.duration = 0
    self:ref("target", target)
	self.z_index = -2
	self.size = 7
    self.random_offset = rng.randi(0, 100)
    signal.connect(self.target, "moved", self, "on_target_moved", function()
		self:move_to(self.target.pos.x, self.target.pos.y)
	end)
end

function PlayerShadow:die()
    local s = self.sequencer
    self.dead = true
	self.size = self.size * 2.5
    s:start(function()
        s:tween_property(self, "size", self.size, self.size * 4, 20, "linear")
        self:queue_destroy()
    end)
end

function PlayerShadow:draw(elapsed)
    local almost_dead = false
	if not self.target then
        if idivmod_eq_zero(self.random_offset + gametime.tick, 2, 2) then
            return
        end
    elseif idivmod_eq_zero(self.random_offset + gametime.tick, 1, 3) then
		return
    else
		almost_dead = game_state.hearts <= 0 and idivmod_eq_zero(gametime.tick, 5, 2)
	end
	

    local color = self.dead and Color.red or (idivmod_eq_zero(gametime.tick, 2, 2) and (almost_dead and Color.red or Color.skyblue) or (almost_dead and Color.yellow or Color.green))
    local size = max(self.size + min(-self.size + self.elapsed * 0.2, 0), 1)
    graphics.set_color(color)
	graphics.set_line_width(1)
	-- if almost_dead then
	-- end
    graphics.rectangle_centered("line", 0, 0, size, size * 0.75)
    graphics.rectangle_centered("line", 0, 0, size + 4, size * 0.75 + 4)

end

AutoStateMachine(PlayerCharacter, "Walk")

return PlayerCharacter
