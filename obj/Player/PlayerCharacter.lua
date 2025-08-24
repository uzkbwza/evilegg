local PlayerCharacter = GameObject2D:extend("PlayerCharacter")

local PlayerDrone = GameObject2D:extend("PlayerDrone")

local PlayerBullet = require("obj.Player.Bullet.BasePlayerBullet")
local PrayerKnotChargeBullet = require("obj.Player.Bullet.PrayerKnotChargeBullet")

local HoverFx = Effect:extend("HoverFx")
local HoverDashFx = Effect:extend("HoverDashFx")
local HoverFireTrail = GameObject2D:extend("HoverFireTrail")

local DeathFlash = require("fx.enemy_death_flash")
local DeathSplatter = require("fx.enemy_death_pixel_splatter")
local JustTheSplatter = require("fx.just_the_splatter")

local RocketBullet = require("obj.Player.Bullet.RocketBullet")

local PlayerShadow = Effect:extend("PlayerShadow")

local AimDraw = GameObject2D:extend("AimDraw")

local TwinDeathEffect = Effect:extend("TwinDeathEffect")

local Explosion = require("obj.Explosion")
local PrayerKnotChargeEffect = GameObject2D:extend("PrayerKnotChargeEffect")
local RingOfLoyaltyBurst = require("obj.Player.Bullet.RingOfLoyaltyBurst")

local SHOOT_DISTANCE = 6
local SHOOT_INPUT_DELAY = 1

local WALK_SPEED = 1.5
local HOVER_SPEED = 0.2
local HOVER_SPEED_UPGRADE = 0.35
-- local DRIFT_SPEED = 0.05
local HOVER_IMPULSE = 2.0

local WALK_DRAG = 0.1
local HOVER_DRAG = 0.05
local HOVER_DRAG_UPGRADE = 0.075

local MIN_HOVER_TIME = 14
local PICKUP_RADIUS = 8

local SECONDARY_BUFFER_TIME = 3
local PRAYER_KNOT_CHARGE_TIME = 65

local FATIGUE_MOVE_SPEED_MODIFIER = 0.45




PlayerCharacter.bullet_powerups = {
	["BaseBullet"] = PlayerBullet,
	["powerup_rocket_name"] = RocketBullet,
    ["PrayerKnotChargeBullet"] = PrayerKnotChargeBullet,
}


PlayerCharacter.secondary_weapon_objects = {
	SwordSlash = require("obj.Player.SecondaryWeapons.SwordSlash"),
	BigLaserBeam = require("obj.Player.SecondaryWeapons.BigLaserBeam")[1],
    BigLaserBeamAimingLaser = require("obj.Player.SecondaryWeapons.BigLaserBeam")[2],
    RepulsionField = require("obj.Player.SecondaryWeapons.RepulsionField"),
	RailGunProjectile = require("obj.Player.SecondaryWeapons.RailGunProjectile"),
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
	self.move_vel = Vec2()
    self.mouse_pos_x, self.mouse_pos_y = 0, 0

    self.bullets_fired = 0
    self.shoot_held_time = 0

    -- self.damage = 1

    self.aim_radius = 12

    self.moving_direction = Vec2(rng:random_vec2())
    self.hover_particle_direction = self.moving_direction:clone()

    self.hurt_bubble_radius = 2

    self.max_hp = 1

    self.prayer_knot_particles = {}
    self.prayer_knot_particles_to_remove = {}

    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
    self:lazy_mixin(Mixins.Behavior.Flippable)
    self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
    self:lazy_mixin(Mixins.Behavior.Health)
    self:lazy_mixin(Mixins.Fx.RetroRumble)


    -- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)

    self.shooting = false
    self.mouse_aim_offset = Vec2(0, -1)
    self.real_mouse_aim_offset = Vec2(0, -1)
	self.real_aim_direction = Vec2(0, -1)
    self.mouse_mode = true
    self.persist = true


    self:add_signal("died")
    self:add_signal("got_hurt")
	self:add_signal("hatched")
	self:add_signal("egg_ready")
    self:init_state_machine()

    signal.connect(game_state, "player_artefact_gained", self, "on_artefact_gained")
    signal.connect(game_state, "player_artefact_removed", self, "on_artefact_removed")

	self.base_body_height = self.body_height

    self.on_prayer_knot_charged = function()
        self.prayer_knot_charged = true
        table.clear(self.prayer_knot_particles)
        table.clear(self.prayer_knot_particles_to_remove)
        self:prayer_knot_charge_fx()
    end
end

function PlayerCharacter:state_GameStart_enter()
	if game_state.skip_intro then
        self:emit_signal("egg_ready")
        self.egg_ready = true
    else
        local s = self.sequencer
        self:move_to(0, -400)
        s:start(function()
            while self.world.beginning_cutscene do
                s:wait(1)
            end
            if game_state.skip_intro then
                self:move_to(0, 0)
                self:emit_signal("egg_ready")
                self.egg_ready = true
                return
            end
			local start_y = self.pos.y
            local tween = function(t)
				-- print(t)
				self:move_to(0, lerp_clamp(start_y, 0, t))
			end
			s:tween(tween, 0, 1.001, 60, "outCubic")
			s:wait(20)
            self:emit_signal("egg_ready")
			self.egg_ready = true
		end)
	end
	self.egg_offset = Vec2(0, 0)
	self.sprite = nil
end

function PlayerCharacter:state_GameStart_draw()
    -- self:body_translate()
    local texture = textures.player_egg
	local palette, offset = self:get_palette()
    graphics.drawp_centered(texture, palette, offset, self.egg_offset.x, self.egg_offset.y)

end
function PlayerCharacter:state_GameStart_update(dt)
	
    if not self.egg_ready then
        return
	end

	local input = self:get_input_table()
    if input.hover_held then
        self:change_state("Hover")
        return
    end
    
	local ix, iy = input.move_normalized.x, input.move_normalized.y

	self.egg_offset.x, self.egg_offset.y = splerp_vec(self.egg_offset.x, self.egg_offset.y, ix * 2, iy * 2, 30, dt)
	self.egg_offset.x, self.egg_offset.y = splerp_vec(self.egg_offset.x, self.egg_offset.y, 0, 0, 300, dt)

    if input:vector_boolean("move", "pressed") then
		self:play_sfx("player_egg_bump")
	end
end

function PlayerCharacter:state_GameStart_exit()
	self:ref("aim_draw", self:spawn_object(AimDraw(0, 0, self)))
	self:ref("shadow", self:spawn_object(PlayerShadow(0, 0, self)))
	self:add_move_function(function()
		self.aim_draw:move_to(self.pos.x, self.pos.y)
    end)
    self.sprite = textures.player_character
	if not (debug.enabled and debug.no_hatch_sound) then
		self:play_sfx("player_egg_hatch")
	end
    local bx, by = self:get_body_center()
	bx = bx + (self.egg_offset and self.egg_offset.x or 0)
	by = by + (self.egg_offset and self.egg_offset.y or 0)

	local input = self:get_input_table()
    local vel_x, vel_y = input.move_normalized.x, input.move_normalized.y
	if vec2_magnitude_squared(vel_x, vel_y) <= 0 then
		vel_x = self.moving_direction.x
		vel_y = self.moving_direction.y
	end
	
    vel_x, vel_y = vec2_mul_scalar(vel_x, vel_y, 20)
	
	self:spawn_object(JustTheSplatter(bx, by, 20, 20, 3.0))
	self:spawn_object(DeathFlash(bx, by, textures.player_egg, 0.25, nil, nil, false))
	self:spawn_object(DeathSplatter(bx, by, 1, textures.player_egg, Palette[textures.player_egg], 1.0, vel_x, vel_y, 0, 0, 3.0))
	-- self:spawn_object(DeathSplatter(bx, by, 1, textures.player_egg, Palette[textures.player_egg], 1.0, 0, 0, 0, 0, 2.0))
	self:emit_signal("hatched")
    self.egg_offset = nil
end

function PlayerCharacter:prayer_knot_charge_fx()
    self:stop_sfx("player_prayer_knot_charge")
    if self.state ~= "Cutscene" then
        self:play_sfx("player_prayer_knot_charged", 0.8)
    end
    local effect = self:spawn_object(PrayerKnotChargeEffect(self.pos.x, self.pos.y))
    effect:ref("player", self)
    signal.connect(self, "moved", effect, "on_player_moved", function()
        effect:move_to(self.pos.x, self.pos.y)
    end)
end

function PlayerCharacter:on_artefact_gained(artefact, slot)
    if artefact.key == "drone" and not self.drone then
        self:spawn_drone()
    end
    if artefact.key == "prayer_knot" then
        self:start_prayer_knot_charge()
    end
end

function PlayerCharacter:start_prayer_knot_charge()
    self:stop_sfx("player_prayer_knot_charge")
    self.prayer_knot_angle = rng:random_angle()
    self.prayer_knot_angle_speed = rng:randf(0.01, 0.06) * rng:rand_sign()
    local time = PRAYER_KNOT_CHARGE_TIME - self.world:get_effective_fire_rate() * 10
    self:start_tick_timer("prayer_knot", time, self.on_prayer_knot_charged)
    self:start_timer("prayer_knot_charge_sfx", time - 36, function()
        if self.state ~= "Cutscene" then
            self:play_sfx("player_prayer_knot_charge", 0.5)
        end
    end)

end

function PlayerCharacter:on_artefact_removed(artefact, slot)
    if artefact.key == "drone" then
		if self.drone then
			self.drone:queue_destroy()
		end
	end
end


local bounce_explosion_params = {
    damage = 8,
    size = 20,
	-- draw_scale = 1.0,
	team = "player",
	-- melee_both_teams = false,
	-- particle_count_modifier = 1,
	-- explode_sfx = "explosion",
	-- explode_sfx_volume = 0.9,
    -- explode_vfx = nil,
	-- force_modifier = 1.0,
	-- ignore_explosion_force = {},
	-- no_effect = false,
}

function PlayerCharacter:on_terrain_collision(normal_x, normal_y)
	self.bounce_sfx_horizontal = false
	self.bounce_sfx_vertical = false

    local bounce_dot = vec2_dot(self.hover_vel.x, self.hover_vel.y, normal_x, normal_y)


    local bounce_mul = 1

    local threshold = 1.9

    local different = self.last_bounce_normal_x ~= normal_x or self.last_bounce_normal_y ~= normal_y
    if game_state.artefacts.blast_armor and bounce_dot <= -threshold and (not self:is_tick_timer_running("bounce_explosion") or different) and self.state_tick > 5 then
        local bx, by = self:get_body_center()
        self:spawn_object(Explosion(bx, by, {
            damage = 8, 
            size = 35 + abs(bounce_dot + threshold) * 8,
            team = "player",
            force_modifier = 1.8,
            explode_sfx = "player_bounce_explosion",
            explode_sfx_volume = 0.9,
        }))
        -- bounce_mul = 1.5
    end
    self:start_tick_timer("bounce_explosion", 20)


    self.last_bounce_normal_x, self.last_bounce_normal_y = normal_x, normal_y

	if normal_x ~= 0 then
		self.hover_vel.x = self.hover_vel.x * -bounce_mul
        self.bounce_sfx_horizontal = true
        
	end
    if normal_y ~= 0 then
        self.hover_vel.y = self.hover_vel.y * -bounce_mul
        self.bounce_sfx_vertical = true
    end
    



end



function PlayerCharacter:spawn_drone()
    local drone = self:spawn_object(PlayerDrone(self.pos.x, self.pos.y))
    drone:ref("player", self)
	self:ref("drone", drone)
end

function PlayerCharacter:can_draw_aim_sight()
	if self:get_stopwatch("firing_big_laser") then
		return false
	end

	if self.big_laser_beam_aiming_laser then
		return false
	end
	if self.big_laser_beam then
		return false
	end
	return true
end

function PlayerCharacter:enter()
	self:add_hurt_bubble(0, 0, self.hurt_bubble_radius, "main")
    self:add_tag("player")
    self:add_tag("move_with_level_transition")
	self:add_tag("ally")

	if game_state.artefacts.drone then
		self:spawn_drone()
	end

	if debug.enabled and debug.skip_tutorial_sequence then
		self:state_GameStart_exit()
	end
	-- self:ref("ground_effect", self:spawn_object(GroundEffect(0, 0, self)))
	-- self:start_invulnerability_timer(60)
end

function PlayerCharacter:on_level_transition()
    table.clear(self.prayer_knot_particles)
    table.clear(self.prayer_knot_particles_to_remove)
end


function PlayerCharacter:start_invulnerability_timer(duration)
	self:start_timer("invulnerability", duration)
end

function PlayerCharacter:set_aim_direction(x, y)
    -- local old_x, old_y = self.aim_direction.x, self.aim_direction.y
    -- local max_speed = self:get_aim_max_speed()
    -- if max_speed then
    --     local diff_x, diff_y = vec2_normalized(x - old_x, y - old_y)
    --     local diff_magnitude = vec2_magnitude(diff_x, diff_y)
    --     -- if diff_magnitude > max_speed * dt then
    --         diff_x, diff_y = vec2_normalized_times(diff_x, diff_y, max_speed * dt)
    --     -- end
    --     x, y = old_x + diff_x, old_y + diff_y
    -- end
    self.aim_direction:set(x, y):normalize_in_place()
end



function PlayerCharacter:set_real_mouse_aim_direction(x, y, dt)
    local old_x, old_y = self.real_mouse_aim_offset.x, self.real_mouse_aim_offset.y
    local max_speed = self:get_aim_max_speed()
    if max_speed then
        local diff_x, diff_y = vec2_normalized(x - old_x, y - old_y)
        local diff_magnitude = vec2_magnitude(diff_x, diff_y)
        -- if diff_magnitude > max_speed * dt then
        diff_x, diff_y = vec2_normalized_times(diff_x, diff_y, max_speed * dt)
        -- end
        x, y = old_x + diff_x, old_y + diff_y
    end
    self.real_mouse_aim_offset:set(x, y)
	if max_speed then
		self.real_mouse_aim_offset:normalize_in_place()
        self.aim_direction:set(self.real_mouse_aim_offset.x, self.real_mouse_aim_offset.y):normalize_in_place()
		self.mouse_aim_offset:set(self.aim_direction.x, self.aim_direction.y)
		-- self.real_mouse_aim_offset:set(self.aim_offset.x, self.aim_offset.y)
	end
	self.real_aim_direction:set(x, y):normalize_in_place()
end

function PlayerCharacter:set_mouse_offset(x, y)
	self.mouse_aim_offset.x, self.mouse_aim_offset.y = vec2_limit_length(x, y, 1)
end

function PlayerCharacter:can_shoot()

    local input = self:get_input_table()
    if input.dont_shoot_held then
        return false
    end

	if self:get_stopwatch("firing_big_laser") then
		return false
	end
	if self.big_laser_beam or self.big_laser_beam_aiming_laser then
		return false
	end
	return true
end

function PlayerCharacter:handle_input(dt)
    local input = self:get_input_table()

    if debug.enabled and input.debug_kill_player_pressed then
        self:die()
    end

    if debug.enabled and input.debug_hurt_player_pressed then
        self:hit_by(self)
    end

    if self.no_input then
        input = input.dummy
    end

    local no_input = input == input.dummy

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
            self:set_mouse_offset(aim_x, aim_y)
            self:set_aim_direction(self.mouse_aim_offset.x, self.mouse_aim_offset.y)
            self.shooting = true
        else
            if aim_magnitude > 0.1 then
                self.mouse_aim_offset.x, self.mouse_aim_offset.y = splerp_vec(self.mouse_aim_offset.x,
                    self.mouse_aim_offset.y, aim_x, aim_y, 900, gametime.delta)
            end
        end
    elseif not no_input then
        if usersettings.use_absolute_aim then
            local global_mouse_x, global_mouse_y = self:get_mouse_position()
            self.mouse_pos_x = global_mouse_x
            self.mouse_pos_y = global_mouse_y
            local mouse_x, mouse_y = self:to_local(global_mouse_x, global_mouse_y)
            mouse_x, mouse_y = vec2_limit_length(mouse_x, mouse_y, 1)
            self:set_mouse_offset(mouse_x, mouse_y)
            self:set_aim_direction(self.mouse_aim_offset.x, self.mouse_aim_offset.y)
        else
            local mdx, mdy = input.mouse.dxy_absolute.x, input.mouse.dxy_absolute.y

            if vec2_magnitude_squared(mdx, mdy) > 0 then
                self:set_mouse_offset(self.mouse_aim_offset.x + mdx * gametime.delta * usersettings.mouse_sensitivity,
                    self.mouse_aim_offset.y + mdy * gametime.delta * usersettings.mouse_sensitivity)
                if usersettings.relative_mouse_aim_snap_to_max_range then
                    local mouse_x, mouse_y = vec2_normalized(self.mouse_aim_offset.x, self.mouse_aim_offset.y)
                    self:set_mouse_offset(mouse_x, mouse_y)
                else
                    local mouse_x, mouse_y = vec2_limit_length(self.mouse_aim_offset.x, self.mouse_aim_offset.y, 1)
                    self:set_mouse_offset(mouse_x, mouse_y)
                end
            end

            self:set_aim_direction(self.mouse_aim_offset.x, self.mouse_aim_offset.y)
        end
        -- self.aim_direction:normalize_in_place()
    end

    self:set_real_mouse_aim_direction(self.mouse_aim_offset.x, self.mouse_aim_offset.y, dt)

    if input.move_normalized.x ~= 0 or input.move_normalized.y ~= 0 then
        self.moving_direction:set(input.move_normalized.x, input.move_normalized.y)
    end

    dbg("aim_direction", self.aim_direction)


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
        if self:is_tick_timer_running("fatigue") then
            move_amount_x = move_amount_x * FATIGUE_MOVE_SPEED_MODIFIER
            move_amount_y = move_amount_y * FATIGUE_MOVE_SPEED_MODIFIER
        end

		self.moving = move_amount_x ~= 0 or move_amount_y ~= 0
        self:move(move_amount_x * dt * self.speed, move_amount_y * dt * self.speed)
        self.move_vel:set(move_amount_x, move_amount_y)
        
        if input.hover_held then
            self:change_state("Hover")
        end
    elseif self.state == "Hover" then
		self.moving = move_amount_x ~= 0 or move_amount_y ~= 0
        self.hover_accel.x = self.hover_accel.x + move_amount_x * self.speed
        self.hover_accel.y = self.hover_accel.y + move_amount_y * self.speed

        if self.state_tick >= MIN_HOVER_TIME and not input.hover_held then
            -- if not self.world.room.cleared then
                self:change_state("Walk")
            -- end
        end
    end

    self.shooting = self.shooting or input.shoot_held

    if self:can_shoot() and (not (digital_aim_input and self.shoot_held_time < SHOOT_INPUT_DELAY)) and self.shooting and not self:is_tick_timer_running("shoot_cooldown") then
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


        -- dbg("cooldown", cooldown)

        self:start_tick_timer("shoot_cooldown", cooldown)
        -- self:start_timer("hide_crosshair", min(cooldown, 3))
    end

    if not self.shooting then
        self.shoot_held_time = 0
    else
        self.shoot_held_time = self.shoot_held_time + dt
    end

    local secondary_stopwatch = self:get_stopwatch("secondary_weapon_held")
    local secondary_weapon = self:get_secondary_weapon()

    local weapon = game_state.secondary_weapon
    local not_enough_ammo = weapon and (
        game_state.secondary_weapon_ammo < weapon.ammo_needed_per_use or
        (weapon.minimum_ammo_needed_to_use and game_state.secondary_weapon_ammo < weapon.minimum_ammo_needed_to_use)
    )

    if input.secondary_weapon_pressed and weapon and (not_enough_ammo or self.world.room.curse == "curse_famine") then
        game_state:on_tried_to_use_secondary_weapon_with_no_ammo()
    end

    if input.secondary_weapon_held and secondary_weapon and secondary_weapon.rapid_fire then
        if self:can_use_secondary_weapon() then
            self:on_secondary_weapon_pressed()
        end
    elseif input.secondary_weapon_pressed then
        self.buffering_secondary_weapon = true
        self:start_tick_timer("secondary_weapon_buffer", SECONDARY_BUFFER_TIME, function()
            self.buffering_secondary_weapon = false
        end)
    elseif self:can_release_secondary_weapon() and (secondary_weapon and secondary_weapon.holdable and self:get_stopwatch("secondary_weapon_held") and not input.secondary_weapon_held) or (input.secondary_weapon_released and not (secondary_weapon and secondary_weapon.holdable)) then
        if secondary_stopwatch then
            self:on_secondary_weapon_released()
        end
    end

    if self.buffering_secondary_weapon then
        if self:can_use_secondary_weapon() then
            self:on_secondary_weapon_pressed()
            self.buffering_secondary_weapon = false
            self:stop_tick_timer("secondary_weapon_buffer")
        end
    end


    if secondary_stopwatch and secondary_weapon and secondary_weapon.holdable then
        local method = "secondary_" .. secondary_weapon.key .. "_held"
        if self[method] then
            self[method](self, dt)
        end
    end
end

function PlayerCharacter:can_release_secondary_weapon()
	if self:is_tick_timer_running("firing_big_laser_minimum_duration") then
		return false
	end
    
    return true
end


function PlayerCharacter:get_aim_max_speed()
	if self:get_stopwatch("firing_big_laser") then
		return 0.045
	end

	return nil
end

function PlayerCharacter:get_secondary_weapon()
	return game_state.secondary_weapon
end

function PlayerCharacter:on_secondary_weapon_pressed()
    if self:is_tick_timer_running("secondary_weapon_cooldown") then
        return
    end
	
    local secondary_weapon = self:get_secondary_weapon()
	if not secondary_weapon then
		return
	end
	
	local method = "secondary_" .. secondary_weapon.key .. "_pressed"
	if self[method] then
		self[method](self)
	end
    if secondary_weapon.holdable then
        self:start_stopwatch("secondary_weapon_held")
    end
	
end

function PlayerCharacter:start_secondary_weapon_cooldown()
	local secondary_weapon = self:get_secondary_weapon()
	if not secondary_weapon then
		return
	end
	if secondary_weapon.cooldown > 0 then
		self:start_tick_timer("secondary_weapon_cooldown", secondary_weapon.cooldown - (secondary_weapon.fire_rate_upgrade_cooldown_reduction or 0) * self.world:get_effective_fire_rate())
	end
end

function PlayerCharacter:on_secondary_weapon_released()
    local secondary_weapon = self:get_secondary_weapon()
	if not secondary_weapon then
		return
	end
	local method = "secondary_" .. secondary_weapon.key .. "_released"
	if self[method] then
		self[method](self)
	end
    self:stop_stopwatch("secondary_weapon_held")
    if secondary_weapon.cooldown > 0 then
        self:start_tick_timer("secondary_weapon_cooldown", secondary_weapon.cooldown - (secondary_weapon.fire_rate_upgrade_cooldown_reduction or 0) * self.world:get_effective_fire_rate())
    end
end

function PlayerCharacter:can_use_secondary_weapon()
    if not game_state.secondary_weapon then
        return false
    end

    if self.world.room.curse_famine then
        return false
    end

    if game_state.secondary_weapon_ammo < game_state.secondary_weapon.ammo_needed_per_use then
        return false
    end

    if game_state.secondary_weapon.minimum_ammo_needed_to_use then
        if game_state.secondary_weapon_ammo < game_state.secondary_weapon.minimum_ammo_needed_to_use then
            return false
        end
    end

    if self:get_stopwatch("secondary_weapon_held") then
        return false
    end
    if self:is_tick_timer_running("secondary_weapon_cooldown") then
        return false
    end
    return true
end

function PlayerCharacter:fire_current_bullet()
    local class = self.bullet_powerups["BaseBullet"]


	game_state:on_bullet_shot()

    
    local powerup = game_state:get_bullet_powerup()
    
    local default = true
	
    if powerup then
        class = self.bullet_powerups[powerup.name]
        default = false
    else
        if game_state.artefacts.prayer_knot then
            if self.prayer_knot_charged then
                class = self.bullet_powerups["PrayerKnotChargeBullet"]
                self.prayer_knot_charged = false
                default = false
            else
                table.clear(self.prayer_knot_particles)
                self:start_prayer_knot_charge()
            end
        end
    end
    
    local cooldown = class.cooldown
    local bullets_upgrade = min(1, game_state.upgrades.bullets)
	local num_bullets = clamp(bullets_upgrade + (class.num_bullets_modifier or 0), 0, game_state:get_max_upgrade("bullets"))

	-- signal.connect(self:fire_bullet(class, nil, 0, 0, false), "bullet_hit", game_state, "on_bullet_hit", nil, true)
	self:fire_bullet(class, nil, 0, 0, false)
    
	self:play_sfx(class.shoot_sfx or "player_shoot", class.shoot_sfx_volume or 0.45, 1)

    if default then
        if game_state.upgrades.damage >= 1 then
            self:play_sfx("player_damage_upgrade_1", 0.25)
        end

        if self.world:get_effective_fire_rate() >= 1 then
            self:play_sfx("player_fire_rate_upgrade_1", 0.25)
        end

        if game_state.upgrades.range == 1 then
            self:play_sfx("player_range_upgrade_1", 0.25)
        end

        if game_state.upgrades.range == 2 then
            self:play_sfx("player_range_upgrade_2", 0.25)
        end

        if game_state.upgrades.bullet_speed >= 1 then
            self:play_sfx("player_bullet_speed_upgrade_1", 0.2)
        end

        if game_state.upgrades.bullets >= 1 then
            if self.world:get_effective_fire_rate() == 1 then
                self:play_sfx("player_bullets_upgrade_1_with_fire_rate_1", 0.35)
            else
                self:play_sfx("player_bullets_upgrade_1", 0.35)
            end
        end
    end
	
	local spread = class.spread

    for i = 1, num_bullets do
        if num_bullets >= 1 then
            local alternate = game_state.upgrades.bullets == 1

            
            if (not alternate) or self.bullets_fired % 2 == 0 then
                self:fire_bullet(class, self.real_aim_direction:rotated(deg2rad(spread * i)), 0, class.h_offset * i, true)
            end
            if (not alternate) or self.bullets_fired % 2 == 1 then
                self:fire_bullet(class, self.real_aim_direction:rotated(deg2rad(-spread * i)), 0, -class.h_offset * i, true)
            end
        end
    end

    self.bullets_fired = self.bullets_fired + 1
	
    if self.drone then
		self:fire_bullet_at_position(class, self.real_aim_direction:clone():mul_in_place(-1), self.drone.pos.x, self.drone.pos.y, true)
	end

	return cooldown
end


function PlayerCharacter:update_aim_direction()
end

function PlayerCharacter:create_drone()
	
end

function PlayerCharacter:get_shoot_position()
    local aim_x, aim_y = self.real_aim_direction.x, self.real_aim_direction.y
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

    if self.force_invuln then
        return true
    end

	if global_state.debug_invulnerable then
		return true
	end

	return false
end

function PlayerCharacter:hit_by(by, force)

    if type(by.damage) == "number" and by.damage <= 0 then return end

	if debug.enabled then
        if by.parent then
			-- local process_float = function(x)
			-- 	return stepify_safe(x, 0.01)
			-- end
            -- local hurt_bubble = self:get_bubble("hurt", "main")
            -- local hx, hy = hurt_bubble:get_position()
			-- local byx, byy = by:get_position()
            -- local r = hurt_bubble.radius
			-- local byr = by.radius
            print("hit by " .. tostring(by.parent))
            -- " who was at " .. process_float(byx) .. ", " .. process_float(byy) .. " with radius " .. process_float(byr))
            -- print("i was at " .. process_float(hx) .. ", " .. process_float(hy) .. " with radius " .. process_float(r))
            -- print("which is a difference of " ..
            -- process_float(hx - byx) ..
            -- ", " .. process_float(hy - byy) .. " with a total distance of " .. process_float(vec2_distance(hx, hy, byx, byy)))
            -- if vec2_distance(hx, hy, byx, byy) > r + byr then
			-- 	print("this should have missed as the distance is " .. process_float(vec2_distance(hx, hy, byx, byy)) .. " which is greater than the sum of the radii " .. process_float(r + byr))
            -- else
			-- 	print("this should have hit as the distance is " .. process_float(vec2_distance(hx, hy, byx, byy)) .. " which is less than the sum of the radii " .. process_float(r + byr))
			-- end
			
        else
            print("hit by " .. tostring(by))
        end
	end

    if self:is_invulnerable() and not force then return end

    local dead = false

    if by.parent and by.parent.is_egg_wrath then
        game_state.hit_by_egg_wrath = true
    end

    if game_state.hearts > 0 then
        self:start_invulnerability_timer(90)
        -- self:play_sfx("old_player_death", 0.85)
        game_state:lose_heart()
        -- local percent = game_state.artefacts.stone_trinket and 50 or 100
        -- if rng:percent(percent) then
        game_state:random_downgrade()
        -- end
        
        self:emit_signal("got_hurt")
    elseif game_state.artefacts.sacrificial_twin then
        game_state:use_sacrificial_twin()
        self:emit_signal("got_hurt")
        self:start_invulnerability_timer(90)
        local s = self.world.sequencer
        s:start(function()
            s:wait(15)
            if not self.is_destroyed then
                self:spawn_twin_death_effect()
            end
        end)

    else
        dead = true
        self:damage(1)
    end
    

    if game_state.artefacts.blast_armor then
        local bx, by = self:get_body_center()
        local timescaled = self.world.timescaled
        timescaled:start_timer("blast_armor_explosion", dead and 5 or 1, function()
            local explo_radius = dead and 180 or 60

            timescaled:spawn_object(Explosion(bx, by, {
                damage = dead and 100 or 12,
                size = explo_radius,
                team = "player",
                -- explode_sfx = "player_bounce_explosion",
                explode_sfx_volume = 0.9,
            }))
        end)
    end

	
	local bcx, bcy = self:get_body_center()

	local sprite = self:get_sprite()
    local particle = self:spawn_object(DeathFlash(bcx, bcy, sprite, self.hp == 0 and 10.0 or 3.0, Palette.player_death, 1, nil, false))
	if self.hp > 0 then
		particle.z_index = -1
	end

	game_state:on_damage_taken()
end

function PlayerCharacter:spawn_twin_death_effect()
    self:spawn_object(TwinDeathEffect(self.pos.x, self.pos.y))
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
    self.moving = false
    if game_state.artefacts.prayer_knot and not self.prayer_knot_charged and not self:is_tick_timer_running("prayer_knot") then
        self:start_prayer_knot_charge()
    elseif self:is_tick_timer_running("prayer_knot") then
        local progress = self:tick_timer_progress("prayer_knot")
        if self.is_new_tick and progress < 0.75 and progress > 0.25 then
            for i=1, 4 do
                local px, py = self.pos.x, self.pos.y
                local offs_x, offs_y = rng:random_vec2_times(rng:randf(0.1, 80))

                local particle = {
                    x = offs_x,
                    y = offs_y,
                    vel_x = 0.0,
                    vel_y = 0.0,
                    accel_x = 0.0,
                    accel_y = 0.0,
                    t = 0.0,
                    size = rng:randf(0.5, 1.5),
                    speed = rng:randf(0.5, 1.5),
                }
                table.insert(self.prayer_knot_particles, particle)
            end
        end
        
        for i = #self.prayer_knot_particles, 1, -1 do
            local particle = self.prayer_knot_particles[i]
            local dx, dy = vec2_direction_to(particle.x, particle.y, 0, 0)
            local dist2 = vec2_distance_squared(particle.x, particle.y, 0, 0)
            particle.accel_x = dx * 1
            particle.accel_y = dy * 1
            particle.x = particle.x + particle.vel_x * dt
            particle.y = particle.y + particle.vel_y * dt
            particle.vel_x = particle.vel_x + particle.accel_x * dt
            particle.vel_y = particle.vel_y + particle.accel_y * dt
            particle.vel_x, particle.vel_y = vec2_drag(particle.vel_x, particle.vel_y, 0.1, dt)
            particle.accel_x = 0
            particle.accel_y = 0
            particle.t = particle.t + dt
            if dist2 < 400 or particle.t > 300 then
                table.insert(self.prayer_knot_particles_to_remove, particle)
            end
        end
    
        for i = #self.prayer_knot_particles_to_remove, 1, -1 do
            table.erase(self.prayer_knot_particles, self.prayer_knot_particles_to_remove[i])
        end

        table.clear(self.prayer_knot_particles_to_remove)


    end
    modloader:call("player_update", self, dt)
end

function PlayerCharacter:get_palette()
    if self:is_tick_timer_running("fatigue") then
        return Palette.fatigued, idiv(self.tick, 3)
    end
    if self.absorbed then
        return Palette.player_absorbed, idiv(self.tick, 3)
    end
    return nil, 0
end

function PlayerCharacter:get_sprite()

    return self.sprite
end

function PlayerCharacter:floor_draw()
    if not self.is_new_tick then
        return
    end
    graphics.push("all")
    -- graphics.set_color(Color.cyan)
    for i = #self.prayer_knot_particles, 1, -1 do
        if rng:percent(0.75) then
            goto continue
        end
        local particle = self.prayer_knot_particles[i]
        local x, y = particle.x, particle.y
        local color = Palette.prayer_knot_particle:get_color_clamped(round(particle.t * particle.speed * 2))
        local mod = 0.15
        graphics.set_color(color.r * mod, color.g * mod, color.b * mod)
        local size = max(1.5 * particle.size, 1)
        graphics.rectangle_centered("fill", x, y, size, size)
        ::continue::
    end
    graphics.pop()
end

function PlayerCharacter:draw()
    if self:is_tick_timer_running("prayer_knot") then
        graphics.push("all")
        graphics.set_line_width(1)
        -- graphics.scale(1.0, 6 / 7)
        local progress = self:tick_timer_progress("prayer_knot")
        if progress <= 0.75 then
            progress = remap(progress, 0.0, 0.75, 0.0, 1.0)
            local size = 48 * pow(ease("outExpo")(progress), 1.24) * 0.5
            if progress > 0.75 then
                graphics.set_color(Color.blue)
            elseif progress > 0.6 then
                graphics.set_color(Color.skyblue)
            else
                graphics.set_color(Color.cyan)
            end
            if progress < 0.8 or gametime.tick % 2 == 0 then
                graphics.poly_regular("line", 0, 0, size * 1 * ease("outCubic")(progress), 4, self.prayer_knot_angle + self.elapsed * self.prayer_knot_angle_speed, 1.0, 5 / 7)
                -- graphics.poly_regular("line", 0, 0, size * 1.25 * ease("outCubic")(progress), 3, self.prayer_knot_angle, 1.0, 6 / 7)
                -- graphics.poly_regular("line", 0, 0, size * 1.6 * ease("outCubic")(progress), 3, self.prayer_knot_angle, 1.0, 6 / 7)


                -- graphics.poly_regular("line", 0, 0, size, 5, tau/8 + self.elapsed * 0.4, 1.0, 6 / 7)
            end
        end
        graphics.pop()
    end

    graphics.push("all")
    -- graphics.set_color(Color.cyan)
    for i = #self.prayer_knot_particles, 1, -1 do
        local particle = self.prayer_knot_particles[i]
        local x, y = particle.x, particle.y
        graphics.set_color(Palette.prayer_knot_particle:get_color_clamped(round(particle.t * particle.speed * 2)))
        local size = max(1.5 * particle.size, 1)
        graphics.rectangle_centered("fill", x, y, size, size)
    end
    graphics.pop()
    
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
    self:collide_with_terrain()
	self:handle_input(dt)
    self:check_pickups()
end

function PlayerCharacter:pickup(pickup)
    
    if pickup.holding_pickup and game_state.artefacts.ring_of_loyalty then
        self:on_ring_of_loyalty_pickup(pickup, pickup:get_body_center())
    end
    pickup:on_pickup(self)
end

function PlayerCharacter:on_ring_of_loyalty_pickup(pickup, bx, by)
    self:play_sfx("pickup_artefact_ring_of_loyalty_trigger2", 1.0)
    local bullet = self:spawn_object(RingOfLoyaltyBurst(bx, by))
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


	self.hover_particle_direction:splerp_in_place(self.moving_direction, 10, dt)
	
	if self.is_new_tick then
        for i = 1, (1) do
            local bx, by = self.pos.x, self.pos.y
            local offsx, offsy = rng:random_vec2_times(rng:randfn(0, 1.0))
            bx = bx + offsx
            by = by + offsy
            local vel_x, vel_y = self.hover_particle_direction.x, self.hover_particle_direction.y
            local current_vel_magnitude = self.hover_vel:magnitude()
            vel_x = vel_x * current_vel_magnitude * 2
            vel_y = vel_y * current_vel_magnitude * 2
            vel_x = vel_x + self.hover_vel.x
            vel_y = vel_y + self.hover_vel.y
            local random = false
            if rng:percent(15) or vec2_magnitude_squared(vel_x, vel_y) < vec2_magnitude_squared(self.moving_direction.x, self.moving_direction.y) then
                vel_x, vel_y = rng:random_vec2_times(game_state.artefacts.boost_damage and 5 or 4)
                random = true
            end

            vel_x, vel_y = vec2_rotated(vel_x, vel_y, rng:randfn(0, tau / 32))
            vel_x, vel_y = vec2_mul_scalar(vel_x, vel_y,
                rng:randfn(1.0, 0.25) * (((not random) and game_state.artefacts.boost_damage) and 1.75 or 1.5))
            vel_x, vel_y = vec2_clamp_magnitude(vel_x, vel_y, 1, math.huge)

            local offsx2, offsy2 = vec2_normalized_times(-vel_x, -vel_y, 5)
            offsx2 = offsx2 * abs(rng:randfn(0, 1.0))
            offsy2 = offsy2 * abs(rng:randfn(0, 1.0))
            bx = bx + offsx2
            by = by + offsy2

            vel_x, vel_y = vec2_mul_scalar(vel_x, vel_y, 0.25)

            -- if not random and game_state.artefacts.boost_damage then
            --     if vec2_magnitude(vel_x, vel_y) < (4) then
            --         vel_x, vel_y = vec2_normalized_times(vel_x, vel_y, 4)
            --     end
            -- end

            self:spawn_object(HoverFx(self.pos.x, self.pos.y, vel_x, vel_y)):ref("player", self)
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
    local modifier = 1.0
    if self:is_tick_timer_running("fatigue") then
        modifier = FATIGUE_MOVE_SPEED_MODIFIER
    end
	self:move(self.hover_vel.x * dt * modifier, self.hover_vel.y * dt * modifier)

    self.hover_vel.x, self.hover_vel.y = vec2_drag(self.hover_vel.x, self.hover_vel.y, self.drag, dt)
    self.hover_impulse:mul_in_place(0)
	self.hover_accel:mul_in_place(0)

	-- if debug.enabled then
		-- dbg("hover speed", self.hover_vel:magnitude())
	-- end


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
	
    if self.big_laser_beam_aiming_laser then
        self.big_laser_beam_aiming_laser:finish()
	end

    if self.big_laser_beam then
		self.big_laser_beam:finish()
	end
end


function PlayerCharacter:state_Cutscene_enter()
	if self:get_stopwatch("secondary_weapon_held") then
		self:on_secondary_weapon_released()
	end

    if self.aim_draw then
        self.aim_draw:hide()
    end

    if self.drone then
		self.drone:hide()
	end

    if self.shadow then
        self.shadow:hide()
    end
end

function PlayerCharacter:state_Cutscene_exit()
    if self.aim_draw then
        self.aim_draw:show()
    end

    if self.drone then
		self.drone:show()
	end

    if self.shadow then
        self.shadow:show()
    end
end

function PlayerCharacter:state_EggRoomStart_enter()
    self.intangible = true
	self:hide()
	if self.shadow then
		self.shadow:hide()
	end
    if self.aim_draw then
        self.aim_draw:hide()
    end
	
    self:start_timer("egg_room_start", 60, function()
        self:show()
		if self.shadow then
			self.shadow:show()
		end
		-- if self.aim_draw then
		-- 	self.aim_draw:show()
        -- end
		
		self:change_state("Walk")
	end)
end

function PlayerCharacter:state_EggRoomStart_exit()
	if self.shadow then
		self.shadow:show()
	end
	if self.aim_draw then
		self.aim_draw:show()
	end
	self.intangible = false
end

function PlayerCharacter:state_EggRoomStart_draw()

end

function PlayerCharacter:get_absorbed()
    self.absorbed = true
    self:start_tick_timer("absorbed", 80, function()
        self:hide()
    end)
    
end

------------------------------------------ secondary weapon methods ------------------------------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------



function PlayerCharacter:secondary_sword_pressed()
    game_state:use_secondary_weapon_ammo()
    self.slash_direction = self.slash_direction or 1
	self.slash_direction = self.slash_direction * -1
	self:spawn_object(self.secondary_weapon_objects.SwordSlash(self.pos.x, self.pos.y, self.real_aim_direction, self.slash_direction))
	self:start_secondary_weapon_cooldown()
end

function PlayerCharacter:secondary_railgun_pressed()
    game_state:use_secondary_weapon_ammo()
	local shoot_pos_x, shoot_pos_y = self:get_shoot_position()

    self:spawn_object(self.secondary_weapon_objects.RailGunProjectile(shoot_pos_x, shoot_pos_y, self.real_aim_direction.x, self.real_aim_direction.y))
	self:start_secondary_weapon_cooldown()
end

local TARGET_DURATION = 24
local FIRE_MIN_DURATION = 36

function PlayerCharacter:secondary_big_laser_pressed()

    local shoot_pos_x, shoot_pos_y = self:get_shoot_position()
	
	local target_duration = TARGET_DURATION - 8 * self.world:get_effective_fire_rate()

	self:ref("big_laser_beam_aiming_laser",
	self:spawn_object(self.secondary_weapon_objects.BigLaserBeamAimingLaser(shoot_pos_x, shoot_pos_y, self.real_aim_direction.x,
            self.real_aim_direction.y, target_duration + 1)))

	self:start_tick_timer("big_laser_beam_aiming_laser", target_duration)
end

function PlayerCharacter:secondary_big_laser_held(dt)

    local stopwatch = self:get_stopwatch("secondary_weapon_held")
	local firing_laser_stopwatch = self:get_stopwatch("firing_big_laser")

    if stopwatch then
		if firing_laser_stopwatch then
            if firing_laser_stopwatch.elapsed > FIRE_MIN_DURATION then
                game_state:use_secondary_weapon_ammo(dt * game_state.secondary_weapon.held_ammo_consumption_rate)
                if game_state.secondary_weapon_ammo <= 0 then
                    self:stop_stopwatch("secondary_weapon_held")
                    self:secondary_big_laser_released()
                    game_state:on_tried_to_use_secondary_weapon_with_no_ammo()
                end
            end
        elseif not self:is_tick_timer_running("big_laser_beam_aiming_laser") then
			game_state:use_secondary_weapon_ammo()
            self:start_stopwatch("firing_big_laser")
			self:start_tick_timer("firing_big_laser_minimum_duration", FIRE_MIN_DURATION)
			local shoot_pos_x, shoot_pos_y = self:get_shoot_position()
			self:ref("big_laser_beam", self:spawn_object(self.secondary_weapon_objects.BigLaserBeam(shoot_pos_x, shoot_pos_y, self.real_aim_direction.x, self.real_aim_direction.y)))
		end

        if self.big_laser_beam then
            self.big_laser_beam:move_to(self:get_body_center())
            self.big_laser_beam:set_direction(self.real_aim_direction.x, self.real_aim_direction.y)
        end
		if self.big_laser_beam_aiming_laser then
			self.big_laser_beam_aiming_laser:move_to(self:get_body_center())
			self.big_laser_beam_aiming_laser:set_direction(self.real_aim_direction.x, self.real_aim_direction.y)
		end
	end
end

function PlayerCharacter:secondary_big_laser_released()
	if self:get_stopwatch("firing_big_laser") then
		self:stop_stopwatch("firing_big_laser")
	end
    if self.big_laser_beam then
		self.big_laser_beam:finish()
        self:unref("big_laser_beam")
    end
    if self.big_laser_beam_aiming_laser then
        self.big_laser_beam_aiming_laser:finish()
        self:unref("big_laser_beam_aiming_laser")
    end
	self:play_sfx("player_big_laser_power_down", 0.8, 1)
end


--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------


HoverFx.damage_scale = 0.06
HoverFx.hit_velocity = 0.1

function HoverFx:new(x, y, vel_x, vel_y)
    HoverFx.super.new(self, x, y)
    self.sprite = textures.player_hover_fx
    self.duration = 8 + max(rng:randfn(0, 3), 1) * (game_state.artefacts.boost_damage and 1.5 or 1)
    self.drag = 0.2
    -- if game_state.artefacts.boost_damage then self.drag = 0.05 end
    self.size = max(rng:randfn(game_state.artefacts.boost_damage and 10.0 or 8.0, 1.25), 1.0)
    -- self.z_index = -1
    self.hover_vel = Vec2(vel_x, vel_y):mul_in_place(1.5)
    self.terrain_collision_radius = 1
    self.body_height = 0
    self.team = "player"
    self.palette = game_state.artefacts.boost_damage and Palette.hover_thruster_damage or Palette.hover_thruster
    -- self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
end

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
		local alpha = clamp(rng:randfn(0.05, 0.05), 0.00, 0.15)
		-- local redmod = abs(rng:randfn(0.0, 0.05))
		graphics.set_color(alpha * 0.5, alpha * 0.30, alpha)
	else
		color = (self.palette):interpolate_clamped(t)
		graphics.set_color(color)
	end
	graphics.rectangle_centered(t < 0.25 and "fill" or "line", 0, 0, scale, scale)
end

HoverFireTrail.cannot_hit_egg = true

function HoverFireTrail:new(x, y)
    HoverFireTrail.super.new(self, x, y)
    self.sprite = textures.player_hover_fire_trail
	self.team = "player"
    self.duration = 90 + rng:randfn(0, 6)
    self.z_index = 0
    self.persist = false
    self.hit_cooldown = 3
	self.particles = {}
	self.to_remove = {}
    self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
	self.random_offset = rng:randi(0, 100)
end

function HoverFireTrail:filter_melee_attack(bubble)
	if bubble.parent and bubble.parent.is_artefact then return false end
	return true
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
        for i = 1, rng:randi(2) do
			if rng:percent(10) then
				local particle = {}
				particle.x, particle.y = rng:random_vec2_times(rng:randf(0, self:get_bubble("hit", "main").radius * 2))
				particle.size = rng:randfn(3, 1)
				particle.elapsed = 0
				particle.duration = rng:randf(10, 50)
				particle.speed = rng:randf(0.15, 0.4)
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
        	graphics.rectangle_centered(iflicker(self.tick, 2, 2) and "line" or "fill", 0, 0, size, size)
		end
    end
	
	for particle in pairs(self.particles) do
		graphics.set_color(Palette.fire:tick_color(particle.elapsed, 0, 3))
		local size = particle.size * (1 - particle.elapsed / particle.duration)
		graphics.rectangle_centered("fill", particle.x, particle.y - particle.elapsed * particle.speed, size, size)
	end

end

function HoverFireTrail:exit()
	self:stop_sfx("player_boost_fire")
end


function HoverDashFx:new(x, y, vel_x, vel_y)
	HoverDashFx.super.new(self, x, y)
	self.duration = 20
	self.particles = {}
	for i = 1, 20 do
		local particle = {}
		particle.pos = Vec2(0, 0)
		particle.vel_x, particle.vel_y = rng:random_vec2_times(rng:randfn(rng:randf(0.2, 2.5), 0.1))
		local vel_mod = rng:randf(0.25, 3)
		particle.vel_x = particle.vel_x + vel_x * vel_mod
		particle.vel_y = particle.vel_y + vel_y * vel_mod
		particle.size = 1
		local alpha = clamp(rng:randfn(0.15, 0.005), 0.00, 0.18)
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
	if self.is_new_tick and (rng:percent(5) or (self.player and rng:percent(100 - self.player.state_tick * 5))) then
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
        self.target.x, self.target.y = self.player.pos.x, self.player.pos.y + self.player.body_height
		self:set_visible(self.player.visible and self.player.state ~= "Cutscene")
    else
        self:queue_destroy()
    end
    -- local offs_x, offs_y = vec2_from_polar(20, self.elapsed / 18)

    if self.world.big_room and self.player then
        -- local offs_x, offs_y = 0, 0
        local offs_x, offs_y = -self.player.real_aim_direction.x * 20, -self.player.real_aim_direction.y * 20

        local x, y = splerp_vec(self.pos.x, self.pos.y, self.target.x + offs_x, self.target.y + offs_y, 200, dt)
        self:move_to(x, y)
    else
        local offs_x, offs_y = 0, 0
        local x, y = splerp_vec(self.pos.x, self.pos.y, -self.target.x + offs_x, -self.target.y + offs_y, 200, dt)
        self:move_to(x, y)
    end

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
    self.random_offset = rng:randi()
    signal.connect(self.target, "moved", self, "on_target_moved", function()
		self:move_to(self.target.pos.x, self.target.pos.y)
	end)
	self.irng = rng:new_instance()
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
        if iflicker(self.random_offset + gametime.tick, 2, 2) then
            return
        end
    elseif iflicker(self.random_offset + gametime.tick, 1, 3) then
		return
    else
		almost_dead = game_state.hearts <= 0 and iflicker(gametime.tick, 5, 2)
	end
	

    local color = self.dead and Color.red or (iflicker(gametime.tick, 2, 2) and (almost_dead and Color.red or Color.skyblue) or (almost_dead and Color.yellow or Color.green))
    local size = max(self.size + min(-self.size + self.elapsed * 0.2, 0), 1)
    graphics.set_color(color)
	graphics.set_line_width(1)
	-- if almost_dead then
	-- end
    graphics.rectangle_centered("line", 0, 0, size, size * 0.75)
    graphics.rectangle_centered("line", 0, 0, size + 4, size * 0.75 + 4)

		
    if self.target and game_state.secondary_weapon and game_state.secondary_weapon.is_railgun and not iflicker(gametime.tick, 1, 2) then

		local oscillation = (sin01(self.elapsed * 0.02) + sin01(self.elapsed * 0.1655) * 0.5 + sin01(self.elapsed * 0.923) * 0.25 + sin01(self.elapsed * 0.03) * 0.125) / 4

        self.target:body_translate()
		
		local start_x, start_y = self.pos.x, self.pos.y
		local vx, vy = vec2_normalized_times(self.target.real_aim_direction.x, self.target.real_aim_direction.y, 300 + 100 * oscillation)
        local end_x, end_y = start_x + vx, start_y + vy
		

		local period = 10
        local irng = self.irng
        local tick1 = stepify(self.tick + self.random_offset, period)
		local tick2 = stepify(self.tick + self.random_offset + period, period)
		irng:set_seed(tick1)
		local offsx1, offsy1 = irng:random_vec2_times(irng:randf(0, 4))
		irng:set_seed(tick2)
        local offsx2, offsy2 = irng:random_vec2_times(irng:randf(0, 4))
		
		local t = inverse_lerp(tick1, tick2, self.elapsed + self.random_offset)

		local offsx, offsy = vec2_lerp(offsx1, offsy1, offsx2, offsy2, t)

		end_x, end_y = vec2_add(end_x, end_y, offsx, offsy)

        local x, y = self.world.room.bullet_bounds:get_line_intersection(start_x, start_y, end_x, end_y)
        if not x or not y then
            x, y = end_x, end_y
        end
		
		x, y = self:to_local(x, y)

        start_x, start_y = self:to_local(start_x, start_y)
        end_x, end_y = self:to_local(end_x, end_y)

		local oscillation2 = sin01(self.elapsed * 0.300) + sin01(self.elapsed * 0.115) + sin01(self.elapsed * 0.215) * 0.5 + sin01(self.elapsed * 0.13) * 0.25 + sin01(self.elapsed * 0.04) * 0.25
		local x1, y1 = start_x, start_y
        local x2, y2 = vec2_lerp(x1, y1, x, y, (-self.elapsed * 0.0025) % 1)
		local x3, y3 = vec2_lerp(x2, y2, x, y, 0.1)
        local x4, y4 = vec2_lerp(x3, y3, x, y, 0.8)
        local x5, y5 = vec2_lerp(x4, y4, x, y, 0.1)
		local x6, y6 = x, y

        graphics.set_line_width(3)
		graphics.set_color(Color.black)
		graphics.line(x1, y1, x2, y2)
		-- graphics.line(x2, y2, x3, y3)
		graphics.line(x3, y3, x4, y4)
		-- graphics.line(x4, y4, x5, y5)
		graphics.line(x5, y5, x6, y6)
		local color = (iflicker(gametime.tick, 2, 2) and (Color.orange) or (Color.yellow))

		local cooldown = self.target and self.target:is_tick_timer_running("secondary_weapon_cooldown")

		if cooldown then
			color = (iflicker(gametime.tick, 2, 2) and (Color.darkpurple) or (Color.purple))
		end

		graphics.set_color(color)
		if iflicker(gametime.tick + 2, 1, 17) then
            graphics.set_color(Color.white)
			if cooldown then
				graphics.set_color(Color.darkgrey)
			end
		end
		graphics.set_line_width(1)
		graphics.line(x1, y1, x2, y2)
		-- graphics.line(x2, y2, x3, y3)
		graphics.line(x3, y3, x4, y4)
		-- graphics.line(x4, y4, x5, y5)
		graphics.line(x5, y5, x6, y6)

	end
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
	if not (self.player and self.player:can_draw_aim_sight()) then return end
	graphics.set_line_width(thickness)
	graphics.set_color(color)
    if dash then
        graphics.dashline(start_x, start_y, end_x, end_y, 2, 2)
    else
        graphics.line(start_x, start_y, end_x, end_y)
    end

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
        local laser_start_x, laser_start_y = vec2_normalized_times(self.player.real_mouse_aim_offset.x, self.player.real_mouse_aim_offset.y, self.player.aim_radius * 0.5)
        local laser_end_x, laser_end_y = mouse_x, mouse_y
		local mouse_dist = vec2_magnitude(mouse_x, mouse_y)
		if mouse_dist > LASER_SIGHT_DISTANCE_MODIFIER * self.player.aim_radius then
			laser_end_x, laser_end_y = vec2_normalized_times(self.player.real_mouse_aim_offset.x, self.player.real_mouse_aim_offset.y, LASER_SIGHT_DISTANCE_MODIFIER * self.player.aim_radius)
		end
		self:laser_sight_draw(3, Color.black, laser_start_x, laser_start_y, laser_end_x, laser_end_y, true)
		self:laser_sight_draw(1, Color.magenta, laser_start_x, laser_start_y, laser_end_x, laser_end_y, true)
		-- self:draw_crosshair(mouse_x, mouse_y, true)
    else
        local aim_x, aim_y = self.player.real_mouse_aim_offset.x, self.player.real_mouse_aim_offset.y
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
            local aim_vec_x, aim_vec_y = self.player.real_mouse_aim_offset.x, self.player.real_mouse_aim_offset.y
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

function AimDraw:draw_crosshair(x, y, force)
	local size = 9

    if not (force or (self.player and self.player:can_draw_aim_sight())) then
		return
	end

	graphics.push()
	graphics.translate(x, y)
	
	graphics.push()
	graphics.rotate(self.player.real_mouse_aim_offset:angle() + self.elapsed * 0.1)
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



function TwinDeathEffect:new(x, y)
    TwinDeathEffect.super.new(self, x, y)
	self.duration = 60
end

function TwinDeathEffect:draw(elapsed, tick, t)
	if self.world.showing_hud then return end
    local size = 30 + elapsed * 16
	graphics.set_color(Color.red)
    graphics.rectangle_centered("line", 0, 0, size, size)
end

function PrayerKnotChargeEffect:new(x, y)
    PrayerKnotChargeEffect.super.new(self, x, y)
    self.z_index = -2
    self:add_elapsed_time()
    self:add_elapsed_ticks()
    self.persist = true
    self.particles = {}
    self.particles_to_remove = {}
    self.irng = rng:new_instance()
    self.body_height = 0
    for i = 1, 20 do
        self:spawn_particle()
    end
end

function PrayerKnotChargeEffect:spawn_particle()
    local x, y = rng:random_vec2_times(rng:randf(0, 10))
    x = x * 0.8
    y = y - self.body_height
    local particle = {
        x = x, y = y,
        start_x = x, start_y = y,
        real_x = self.pos.x + x, real_y = self.pos.y + y,
        t = 0.0,
        angle = rng:randf(0, tau),
        random_offset = rng:randi(),
        speed = rng:randf(50, 300),
        lifetime = rng:randf(20, 200)
    }

    if rng:percent(5) then
        particle.speed = rng:randf(50, 1000)
    end
    table.insert(self.particles, particle)
end


function PrayerKnotChargeEffect:update(dt)

    if self.player then
        self.body_height = self.player.body_height
        if self.player.visible and not self.visible then
            table.clear(self.particles)
        end
        self:set_visible(self.player.visible and self.player.state ~= "Cutscene")
        -- self:set_visible(self.player.visible)
    end

    if self.player and (not self.player.prayer_knot_charged or not game_state.artefacts.prayer_knot) then
        self:unref("player")
        self:death_anim()
        return
    end

    if not self.player and not self.dying then
        self:death_anim()
        return
    end


    if not self.dying and self.is_new_tick then
        for i = 1, rng:randi(0, 2) do
            if rng:percent(35) then
                self:spawn_particle()
            end
        end
    end

    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.t = particle.t + dt / particle.lifetime
        local irng = self.irng
        irng:set_seed(particle.random_offset + self.tick)
        particle.angle = particle.angle + irng:randf(-0.7, 0.7) * dt
        local speed = 0.16
        if self.dying then
            speed = 2
            local angle = vec2_angle(particle.start_x, particle.start_y)
            particle.x = particle.x + cos(angle) * dt * speed
            particle.y = particle.y + sin(angle) * dt * speed
        end
        particle.x = particle.x + cos(particle.angle) * dt * speed
        particle.y = particle.y + sin(particle.angle) * dt * speed
        

        -- if not self.dying then
        particle.real_x, particle.real_y = splerp_vec(particle.real_x, particle.real_y, self.pos.x, self.pos.y, particle.speed, dt)
        -- end

        if particle.t >= 1 then
            table.insert(self.particles_to_remove, particle)
        end
    end

    for i = #self.particles_to_remove, 1, -1 do
        table.erase(self.particles, self.particles_to_remove[i])
    end

    table.clear(self.particles_to_remove)

end

function PrayerKnotChargeEffect:death_anim()
    if self.dying then return end
    self.dying = true
    self:start_destroy_timer(20)
    self:start_timer("dissipate", 20)
end

function PrayerKnotChargeEffect:on_level_transition()
    table.clear(self.particles)
end

function PrayerKnotChargeEffect:draw()

    if self.elapsed < 40 then
        local t = self.elapsed / 40
        if self.elapsed < 5 and iflicker(self.tick, 2, 2) then
            graphics.set_color(Color.yellow)
            local size = 40 - self.elapsed * 4
            graphics.rectangle_centered("fill", 0, 0, size, size * 5 / 7)
        end
    end
    

    graphics.set_color(iflicker(self.tick, 2, 2) and Color.cyan or Color.yellow)


    local size = 16 + 5 * sin(self.elapsed * 0.1)

    if self:is_timer_running("dissipate") then
        size = size + ((1 - self:timer_progress("dissipate"))) * 50 + 5
        graphics.set_color(Color.darkskyblue)
        if self:timer_progress("dissipate") > 0.75 then
            graphics.rectangle_centered("line", 0, 0, size, size * (5 / 7))
        end
    else
        graphics.rectangle_centered("line", 0, 0, size, size * (5 / 7))
    end


    if not self.dying then
        graphics.rectangle_centered("fill", 0, -self.body_height, 8 + sin(self.elapsed * 0.1) * 2, 12 + sin(self.elapsed * 0.1) * 2)
        graphics.set_color(Color.white)
        graphics.rectangle_centered("fill", 0, -self.body_height, 6 + sin(self.elapsed * 0.1) * 2, 10 + sin(self.elapsed * 0.1) * 2)
    end



    local len = #self.particles
    local particle_size = 1.0
    if self:is_timer_running("dissipate") then
        particle_size = self:timer_progress("dissipate")
    end
    for i=1, len do
        local particle = self.particles[i]
        local x, y = self:to_local(particle.x, particle.y)
        graphics.set_color(iflicker(particle.random_offset + self.tick, 2, 2) and Color.cyan or Color.yellow)
        local size = 4 * (1 - particle.t) * particle_size
        graphics.rectangle_centered("fill", x + particle.real_x, y + particle.real_y, size, size)
    end
    for i=1, len do
        local particle = self.particles[i]
        local x, y = self:to_local(particle.x, particle.y)
        graphics.set_color(Color.white)
        local size = 1 * (1 - particle.t) * particle_size
        graphics.rectangle_centered("fill", x + particle.real_x, y + particle.real_y, size, size)
    end
end

AutoStateMachine(PlayerCharacter, (debug.enabled and debug.skip_tutorial_sequence and "Walk") or "GameStart")

return PlayerCharacter
