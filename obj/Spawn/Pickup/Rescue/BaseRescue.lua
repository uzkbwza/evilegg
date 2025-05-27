local BaseRescue = require("obj.Spawn.Pickup.BasePickup"):extend("BaseRescue")
local BaseRescueSpawnParticle = Effect:extend("BaseRescueSpawnParticle")
local BaseRescueFloorParticle = Effect:extend("BaseRescueFloorParticle")
local BaseRescueArrowParticle = Effect:extend("BaseRescueArrowParticle")
local HurtFlashFx = Effect:extend("HurtFlashFx")
local DeathSplatter = require("fx.enemy_death_pixel_splatter")
local BaseRescuePickupParticle = Effect:extend("BaseRescuePickupParticle")
local RingOfLoyaltyBullet = require("obj.Player.Bullet.RingOfLoyaltyBullet")
local WarbellProjectile = require("obj.Player.Bullet.GreenoidSelfDefenseBullet")

local START_INVULNERABILITY = 140
local QUICK_SAVE_TIME = 200
local HIT_INVULNERABILITY = 60
local LAST_HIT_INVULNERABILITY = 70

local ENEMY_AVOID_DISTANCE = 10

BaseRescue.is_rescue = true

function BaseRescue:new(x, y)
    BaseRescue.super.new(self, x, y)
	self.team = "player"
    self.body_height = 4
    self.max_hp = self.max_hp or 4
    self.hurt_bubble_radius = self.hurt_bubble_radius or 3
    -- self.declump_radius = self.declump_radius or 20
	-- self.self_declump_modifier = self.self_declump_modifier or 0.3
    self:lazy_mixin(Mixins.Behavior.Health)
    self:lazy_mixin(Mixins.Behavior.Hittable)
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
    -- self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Fx.Rumble)
	self.avoid_enemies = true
    self.spawn_sfx = "ally_rescue_spawn"
	self.spawn_sfx_volume = 0.85
    self.spawn_cry = nil
	self.spawn_cry_volume = 0.85
	self.hurt_sfx = "ally_rescue_hurt"
    self.hurt_sfx_volume = 0.85
    self.die_sfx = "ally_rescue_death"
	self.die_sfx_volume = 0.9
	self.pickup_sfx = "ally_rescue_pickup"
    self.pickup_sfx_volume = 0.85
	self.avoid_enemies_speed = self.avoid_enemies_speed or 0.025
    self.avoid_enemies_radius = self.avoid_enemies_radius or 16
    if self.auto_state_machine then
        self:init_state_machine()
    end
	self.random_offset = rng.randi()

end

function BaseRescue:enter()
    self:add_hurt_bubble(0, 0, self.hurt_bubble_radius, "main")
    local s = self.sequencer
    s:start(function()
		for i=1, 15 do
            for j = 1, 1 do
				self:spawn_particle()
			end
			s:wait(3)
		end
    end)
	self:add_tag("ally")
    self:ref("floor_particle", self:spawn_object_relative(BaseRescueFloorParticle(0, 0, self), 0, 0))
    self:ref("arrow_particle", self:spawn_object_relative(BaseRescueArrowParticle(0, 0, self), 0, 0))
	if self.holding_pickup then
		self:play_sfx("ally_rescue_holding_pickup_spawned", 0.85)
		self:ref("pickup_particle", self:spawn_object_relative(BaseRescuePickupParticle(0, 0, self, self.holding_pickup), 0, 0))
	end
    self:play_sfx(self.spawn_sfx, self.spawn_sfx_volume)
    if self.spawn_cry then
		s:start(function()
			s:wait(30)
			self:play_sfx(self.spawn_cry, self.spawn_cry_volume)
		end)
	end
    self:start_timer("quick_save_time", QUICK_SAVE_TIME)
    self:start_timer("invulnerability", START_INVULNERABILITY)
    if self.holding_pickup then
        self:initialize_hp(self.max_hp + 1)
    end
	self:add_to_spatial_grid("rescue_grid", self.get_rescue_rect)
end

function BaseRescue:get_rescue_rect()
	local hurt_bubble = self:get_bubble("hurt", "main")
	local x, y, w, h = hurt_bubble:get_rect()
    return x, y, w, h
end

function BaseRescue:spawn_particle()
	local x, y = rng.random_vec2_times(rng.randf_range(0.5, self.hurt_bubble_radius * 3))
	self:spawn_object_relative(BaseRescueSpawnParticle(), x, y)
end

function BaseRescue:hit_by(other)
    if self:is_timer_running("invulnerability") then
        return
    end

	if self.grabbed_by_cultist then
		return
	end

    if self.world.state == "RoomClear" then
        return
	end

    self:start_rumble(2.0, 60)
    local damage = other.damage
    if other.is_bubble then
        other = other.parent
    end
    if self.hp > 1 then
        damage = min(damage, self.hp - 1)
	end
	-- dbg("damage dealt to rescue", damage)
    self:damage(damage)
    self:start_timer("invulnerability", self.hp <= 1 and LAST_HIT_INVULNERABILITY or HIT_INVULNERABILITY)


    -- local sprite = self:get_sprite()

	-- if self.hp <= 0 then
		
    -- else

end

function BaseRescue:on_damaged(damage)
    if damage > 0 then
		game_state:on_greenoid_harmed()
	end
	local bx, by = self:get_body_center()
	if self.hp > 0 and not self.grabbed_by_cultist then
		self:play_sfx(self.hurt_sfx, self.hurt_sfx_volume)
        self:spawn_object(HurtFlashFx(self, bx, by+1, 48))
    end
end

function HurtFlashFx:new(parent, x, y, size, is_death)
	HurtFlashFx.super.new(self, x, y)
	self:ref("parent", parent)
    self.size = size
    self.duration = 20
	self.thickness = 6
    self.z_index = 0
	self.is_death = is_death
end

function HurtFlashFx:update(dt)
end

function HurtFlashFx:floor_draw()
	if self.is_death and self.is_new_tick and self.tick <= 2 then
		self:draw_particle(true, self.elapsed, self.tick, self.elapsed / self.duration)
	end
end

function HurtFlashFx:draw(elapsed, tick, t)
	self:draw_particle(false, elapsed, tick, t)
end

function HurtFlashFx:draw_particle(is_floor, elapsed, tick, t)
	local color = Palette.ally_hurt:get_color(idiv(gametime.tick, 2))

	if is_floor then
		color = Palette.ally_hurt:get_color(1)
		graphics.set_color(color.r * 0.25, color.g * 0.25, color.b * 0.25)
	else
		graphics.set_color(color)
	end
    local size = self.size * ease("inCubic")(remap(1 - t, 0, 1, 0.8, 1))

	local bx, by = self.parent and self.parent:get_body_center_local() or 0, 0

    if tick > self.duration - 10 then
		if idivmod_eq_zero(gametime.tick, 2, 2) then
            return	
		end
	end
	graphics.rectangle("fill", bx - size / 2, by - size / 2, size, size)

    if self.is_death then
		size = size * 2
        -- graphics.rotate(tau / 8)
        graphics.set_line_width(self.thickness)
        graphics.line(bx + -size / 2, by + size / 2, bx + size / 2, by + -size / 2)
        graphics.line(bx + -size / 2, by + -size / 2, bx + size / 2, by + size / 2)
	end
end

function BaseRescue:register_pickup(pickup)
    self.holding_pickup = pickup
	-- if not savedata:check_codex_item(self.holding_pickup.name) then
	savedata:add_item_to_codex(self.holding_pickup.name)
	-- end
end

function BaseRescue:get_sprite()
    return idivmod_eq_zero(self.tick, 10, 2) and textures.ally_rescue1 or textures.ally_rescue2
end

function BaseRescue:get_default_palette()
    return Palette[self:get_sprite()]
end

function BaseRescue:on_pickup()
	local bx, by = self:get_body_center()


    for i = 1, self.max_hp - self.hp do
        game_state:greenoid_harm_penalty()
    end
	
	if self:is_timer_running("quick_save_time") then
		game_state:level_bonus("quick_save")
	end

    if self.holding_pickup then
		local pickup_volume = 0.87
        if self.holding_pickup.sound then
            self:play_sfx(self.holding_pickup.sound, self.holding_pickup.sound_volume or 0.85)
			pickup_volume = 0.5
		end
		self:play_sfx("ally_rescue_holding_pickup_saved", pickup_volume)
        if self.holding_pickup.upgrade_type ~= nil then
            game_state:upgrade(self.holding_pickup)
        end
        if self.holding_pickup.heart_type ~= nil then
            game_state:gain_heart(self.holding_pickup)
        end
		if self.holding_pickup.subtype == "powerup" then
			game_state:gain_powerup(self.holding_pickup)
		end
		-- self:play_sfx(self.pickup_sfx, self.pickup_sfx_volume * 0.25)
	else
		self:play_sfx(self.pickup_sfx, self.pickup_sfx_volume)
	end
    self.floor_particle:on_pickup()
    BaseRescue.super.on_pickup(self)

    if game_state.artefacts.ring_of_loyalty then
		self:play_sfx("pickup_artefact_ring_of_loyalty_trigger", 0.7)
		local num_bullets = 12 + (game_state.upgrades.bullets) * 8
        for i = 1, num_bullets do
			local bullet = self:spawn_object(RingOfLoyaltyBullet(bx, by, true))
			bullet.direction = angle_to_vec2(tau / num_bullets * i)
		end
	end


	-- for i = 1, 5 do
	-- 	audio.stop_sfx_monophonic("pickup_rescue_save" .. i)
	-- end
	-- self:play_sfx("pickup_rescue_save" .. game_state.rescue_chain, 0.9)
end

function BaseRescue:get_palette_shared()
	local offset = 0

	-- local doubletick = floor(self.random_offset + self.tick / 2)
    -- if doubletick % 300 < 4 then
	-- 	return Palette.death_disintegration, doubletick
	-- end
	
	local palette, offs = self:get_palette()

	palette = palette or self:get_default_palette()
	offset = offs or 0

	if self.grabbed_by_cultist then
		palette = Palette.cultist_grab
		offset = idiv(self.tick, 2)
	end

	if self:is_timer_running("quick_save_time") and idivmod_eq_zero(self.tick, 3, 3) then
		offset = idiv(self.tick, 1)
	end

	return palette, offset
end

function BaseRescue:on_health_reached_zero()
	self:die()
	self:queue_destroy()
end

function BaseRescue:die()
	for i=1, self.max_hp do
		game_state:greenoid_harm_penalty()
	end
	local bx, by = self:get_body_center()
	local sprite = self:get_sprite()
	local flash = self:spawn_object(HurtFlashFx(self, bx, by+1, 64, true))
	flash.duration = 40
	self:spawn_object(DeathSplatter(bx, by, self.flip, sprite, Palette[sprite], 2, 0, 0))
    self:play_sfx(self.die_sfx, self.die_sfx_volume)
	self.pickupable = false
	self.floor_particle:die()
	game_state:on_rescue_failed()
	self:queue_destroy()
end

local twinkle_sounds = {
	"ally_rescue_holding_pickup_twinkle1",
	"ally_rescue_holding_pickup_twinkle2",
	"ally_rescue_holding_pickup_twinkle3",
	"ally_rescue_holding_pickup_twinkle4",
	"ally_rescue_holding_pickup_twinkle5",
	"ally_rescue_holding_pickup_twinkle6",
}

function BaseRescue:update_shared(dt)
    BaseRescue.super.update_shared(self, dt)
    if self.holding_pickup then
		if self.is_new_tick and not self:is_timer_running("twinkle_cooldown") then
			self:play_sfx(rng.choose(twinkle_sounds), abs(rng.randfn(0.0, 0.1) * rng.randfn(1.0, 2.0)))
			self:start_timer("twinkle_cooldown", 6)
		end
	end
end

local WARBELL_RADIUS = 90

function BaseRescue:update(dt)
    self:collide_with_terrain()
    if self.avoid_enemies then
        self.nearby_enemy_hit_bubbles = {}
        self:each_nearby_bubble_self("hit", "enemy", self.avoid_enemies_radius, self.try_avoid_enemy)
        self:each_nearby_bubble_self("hit", "neutral", self.avoid_enemies_radius, self.try_avoid_enemy)
        local average_x, average_y = 0, 0
        local num_enemies = 0
        for i = 1, #self.nearby_enemy_hit_bubbles do
            local hit_bubble = self.nearby_enemy_hit_bubbles[i]
            local bx, by = hit_bubble:get_position()
            average_x = average_x + bx
            average_y = average_y + by
            num_enemies = num_enemies + 1
        end
        if num_enemies > 0 then
            average_x = average_x / num_enemies
            average_y = average_y / num_enemies
            local bx, by = self:get_body_center()
            local dx, dy = vec2_direction_to(average_x, average_y, bx, by)
            self:apply_force(dx * self.avoid_enemies_speed, dy * self.avoid_enemies_speed)
        end
    end

    if self.is_new_tick and game_state.artefacts.warbell then
        if (self.tick + self.random_offset) % (game_state.upgrades.fire_rate and 10 or 13) == 0 then
            local bx, by = self:get_body_center()
            local x, y = bx - WARBELL_RADIUS, by - WARBELL_RADIUS
            local w, h = WARBELL_RADIUS * 2, WARBELL_RADIUS * 2
            local hurt_bubbles = self.world.hurt_bubbles.enemy:query(x, y, w, h)
            local valid = {}
            for i = 1, #hurt_bubbles do
                local bubble = hurt_bubbles[i]
                if bubble.parent and bubble.parent:has_tag("wave_enemy") then
                    table.insert(valid, bubble)
                end
            end
            local aiming_at = rng.choose(valid)
            if aiming_at then
                local bubble_x, bubble_y = aiming_at:get_position()
                local dx, dy = vec2_direction_to(bx, by, bubble_x, bubble_y)
                self:spawn_object(WarbellProjectile(bx, by)).direction = Vec2(dx, dy)
                self:play_sfx("ally_rescue_shoot", 0.35)
            end
        end
    end
	
	if self:is_timer_running("quick_save_time") then
		if self.world.state == "RoomClear" then
			self:start_timer("quick_save_time", QUICK_SAVE_TIME)
		end
	end
end


function BaseRescue.try_avoid_enemy(bubble, self)
	table.insert(self.nearby_enemy_hit_bubbles, bubble)
end

function BaseRescue:draw()
    if not (self:is_timer_running("invulnerability") and (gametime.tick % 2 == 0)) then
		graphics.push()
		BaseRescue.super.draw(self)
		graphics.pop()
    end
end

function BaseRescueArrowParticle:new(x, y, target)
    BaseRescueArrowParticle.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self.duration = 0
	self:ref("target", target)
	self.z_index = 10
	self.random_offset = rng.randi(0, 100)
end

function BaseRescueArrowParticle:update(dt)
    if self.target then
        local bx, by = self.target:get_body_center()
        self:move_to(splerp_vec(self.pos.x, self.pos.y, bx, by - self.target.hurt_bubble_radius * 2, 600, dt))
    else
        self:queue_destroy()
    end
    local almost_dead = false
    if self.target then
        almost_dead = self.target.hp <= 1 and self.target.max_hp > 1
        if almost_dead and self.is_new_tick and self.tick % 20 == 0 then
            self:play_sfx("ally_rescue_almost_dead_beep", 0.45)
        end
    end
end


local arrow_points = {}
function BaseRescueArrowParticle:draw_arrow_line(line_start_x, line_start_y, line_end_x, line_end_y, width, height, cap_size, dash, dash_gap)
    graphics.push()
    -- local gx, gy = self:to_global(line_start_x, line_start_y)
	-- gx = stepify(gx, width)
	-- gy = stepify(gy, height)
	-- graphics.translate(self:to_local(gx, gy))
    -- graphics.axis_quantized_line(0, 0, line_end_x - line_start_x, line_end_y - line_start_y, width, height, false, cap_size, dash, dash_gap, arrow_points)
	graphics.axis_quantized_line(line_start_x, line_start_y, line_end_x, line_end_y, width, height, false, cap_size, dash, dash_gap, arrow_points)
	table.clear(arrow_points)
	graphics.pop()
end

function BaseRescueArrowParticle:draw(elapsed, tick, t)
	local almost_dead = false
	if self.target then
		almost_dead = self.target.hp <= 1 and self.target.max_hp > 1
	end
    if not idivmod_eq_zero(gametime.tick + self.random_offset, 4, 2) then        
	
		graphics.set_color(Color.white)
		local palette_offset = almost_dead and idiv(gametime.tick + self.random_offset, 3) or 0
		graphics.drawp_centered(almost_dead and textures.ally_rescue_arrow_almost_dead or textures.ally_rescue_arrow, nil, palette_offset, sin(elapsed * 0.05) * 0.5)
    end

	if (self.world and self.world.state == "RoomClear") then
		return
	end

	if self.target and (almost_dead or gametime.tick % 2 == 0) then
		local player = self:get_closest_player()
		if player then
			local bx, by = self:to_local(self.target:get_body_center())
            local px, py = self:to_local(player:get_body_center())
			local start_x, start_y = point_along_line_segment(bx, by, px, py, 8)
            local end_x, end_y = point_along_line_segment(px, py, bx, by, 8)
            
            local line_length = almost_dead and 128 or 90

            local line_t = fposmod(elapsed / (almost_dead and 4 or 12), almost_dead and 4 or 7)
            local line_middle_x, line_middle_y = vec2_lerp(start_x, start_y, end_x, end_y, 2 - line_t)
			local line_start_x, line_start_y = point_along_line_segment_clamped(line_middle_x, line_middle_y, start_x, start_y, line_length / 2)
			local line_end_x, line_end_y = point_along_line_segment_clamped(line_middle_x, line_middle_y, end_x, end_y, line_length / 2)
			
            if vec2_distance_squared(line_start_x, line_start_y, line_end_x, line_end_y) > 1 then
				local quantize_width = almost_dead and 24 or 16
				
				self.arrow_points = self.arrow_points or {}
				graphics.set_line_width(3 + (almost_dead and 1 or 0))
				if almost_dead then
                    graphics.set_color(idivmod_eq_zero(gametime.tick, 3, 2) and Color.green or Color.blue)
				else
					graphics.set_color(Color.black)
				end
				self:draw_arrow_line(line_start_x, line_start_y, line_end_x, line_end_y, quantize_width, quantize_width, almost_dead and 2 or 3, nil, nil)
                graphics.set_line_width(1 + (almost_dead and 1 or 0))
                local color = Palette.rescue_line:tick_color(gametime.tick + self.random_offset, 0, 3)
                if almost_dead then
                    color = Palette.rescue_danger_line:tick_color(gametime.tick + self.random_offset, 0, 3)
                end
                local palette, offset = self.target:get_palette()
				if palette then
					color = palette:get_color(offset)
				end
                graphics.set_color(color)
				self:draw_arrow_line(line_start_x, line_start_y, line_end_x, line_end_y, quantize_width, quantize_width, almost_dead and 2 or 3, 2, 1)
			end
		end
	end
end


function BaseRescueFloorParticle:new(x, y, target)
    BaseRescueFloorParticle.super.new(self, x, y)
    self:add_sequencer()
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.duration = 0
    self:ref("target", target)
	self.z_index = -1
	self.size = target.hurt_bubble_radius * 3
	self.random_offset = rng.randi(0, 100)
end

function BaseRescueFloorParticle:update(dt)
	if self.target then
        self:move_to(splerp_vec(self.pos.x, self.pos.y, self.target.pos.x, self.target.pos.y, 60, dt))
	end
end

function BaseRescueFloorParticle:on_pickup()
    local s = self.sequencer
	self.z_index = 1
    self.size = self.size * 1.5
	self.laser_amount = 0
    self.picked_up = true

    s:start(function()
        s:tween_property(self, "laser_amount", 0, 1, 20, "linear")
    end)
    s:start(function()
        s:tween_property(self, "size", self.size, self.size * 4, 20, "linear")
        self:queue_destroy()
    end)

end

function BaseRescueFloorParticle:die()
    local s = self.sequencer
    self.dead = true
	self.size = self.size * 2.5
    s:start(function()
        s:tween_property(self, "size", self.size, self.size * 4, 20, "linear")
        self:queue_destroy()
    end)
end

local FLOOR_PARTICLE_ARROW_LENGTH = 5

function BaseRescueFloorParticle:draw(elapsed)
    local almost_dead = false
	if not self.target then
        if idivmod_eq_zero(self.random_offset + gametime.tick, 2, 2) then
            return
        end
    elseif idivmod_eq_zero(self.random_offset + gametime.tick, 1, 3) then
		return
    else
		almost_dead = self.target.hp <= 1 and self.target.max_hp > 1 and idivmod_eq_zero(gametime.tick, 5, 2)
	end
	

    local color = self.dead and Color.red or (idivmod_eq_zero(gametime.tick, 4, 2) and (almost_dead and Color.red or Color.white) or (almost_dead and Color.yellow or Color.green))
    local size = max(self.size + sin(elapsed * 0.05) * (self.size * (self.target and 0.2 or 0)), self.size + 80 - elapsed * 7)
    graphics.set_color(color)
	graphics.set_line_width(2)
	-- if almost_dead then
	-- end
    graphics.rectangle(self:is_timer_running("on_pickup") and "fill" or "line", -size / 2, -size * 0.33, size, size * 0.66)
	
    if self.laser_amount then
		local laser_width = 10 * (1 - ease("inOutCubic")(self.laser_amount))
        local laser_end = -400 * ease("inCubic")(self.laser_amount)
		local laser_start = -400 * ease("outCubic")(self.laser_amount)
		local laser_x = -laser_width / 2
		local laser_y = laser_start
		graphics.rectangle("fill", laser_x, laser_y, laser_width, laser_end - laser_start)
	end
	-- graphics.rotate(elapsed * 0.05)
	-- graphics.ellipse("line", 0, 0, size, size * 0.5, 6)
	
	-- graphics.set_line_width(1)
	-- if self.target then
	-- 	local px, py = self:closest_last_player_body_pos()
	-- 	px, py = self:to_local(px, py)
    --     local bx, by = self.target:get_body_center()
    --     bx, by = self:to_local(bx, by)

	-- 	local offset_x, offset_y = vec2_sub(px, py, bx, by)
		
    --     local t = ease("linear")(fposmod(elapsed * 0.08, 1))
    --     local distance = vec2_magnitude(offset_x, offset_y)

    --     local start_offset = clamp(t - (FLOOR_PARTICLE_ARROW_LENGTH / distance), 0, 1)
	-- 	local end_offset = clamp(t + (FLOOR_PARTICLE_ARROW_LENGTH / distance), 0, 1)
    --     local start_x, start_y = vec2_mul_scalar(offset_x, offset_y, t)

	-- 	graphics.circle("line", start_x, start_y, 2)
	-- end
end

function BaseRescueSpawnParticle:new(x, y)
    BaseRescueSpawnParticle.super.new(self, x, y)
    self.duration = rng.randf_range(30, 45)
	self.size = clamp(rng.randfn(4, 0.25), 1, 8)
end

function BaseRescueSpawnParticle:update(dt)
	self:move(0, dt * -0.5)
end

function BaseRescueSpawnParticle:draw(elapsed, tick, t)
    local color = idivmod_eq_zero(gametime.tick, 2, 2) and Color.white or Color.green
    local size = self.size * (1 - t)
    graphics.set_color(color)
    graphics.rectangle("fill", -size / 2, -size / 2, size, size)
end

function BaseRescuePickupParticle:new(x, y, target, pickup)
    BaseRescuePickupParticle.super.new(self, x, y)
    self:ref("target", target)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self:add_sequencer()
	self.duration = 0
    self.pickup = pickup
    self.pointing_lines = {}
    self.z_index = 0.5
	self.line_id = 0
    self.particle_function = function()
        if not self.target then
            return
        end
		if self.target.is_destroyed then
			return
		end
		local bx, by = self.target:get_body_center()
		local angle = stepify(rng.random_angle(), tau / 16)
		local size = rng.randfn(24, 12)
		-- local to_player = false
		local is_line = rng.percent(10)
		local max_resolution = rng.randi(2, 5)

		if rng.percent(20) then
			local px, py = self:closest_last_player_body_pos()
			angle = (atan2(py - self.pos.y, px - self.pos.x)) + rng.randfn(0, tau / 128)
			size = vec2_distance(px, py, bx, by) * 0.7
			-- to_player = true
		end

		size = clamp(size, 8, max(rng.randfn(48, 10), 1))
		-- twinkle sound?
		local line = { angle = angle, t = 0, size = size, rect_color = Palette.pickup_line:random_color(), id = self.line_id, is_line = is_line, max_resolution = max_resolution }
		self.line_id = self.line_id + 1
		self.pointing_lines[line] = true
		self.sequencer:tween_property(line, "t", 0, 1, 30, "linear")
		self.pointing_lines[line] = nil
	end
end

function BaseRescuePickupParticle:update(dt)
    if self.target then
        local elapsed = self.elapsed
		local bx, by = self.target:get_body_center()
        self:move_to(splerp_vec(self.pos.x, self.pos.y, bx + cos(elapsed * 0.045) * 3,
        by - self.target.hurt_bubble_radius + sin(elapsed * 0.045) * 1.5 * (0.667) - 7, 60, dt))
        if self.is_new_tick and rng.percent(80) then
			self.sequencer:start(self.particle_function)
		end
    else
        self:queue_destroy()
    end
end


local pickup_line_temp_points = {}

function BaseRescuePickupParticle:draw(elapsed, tick, t)

    for line in pairs(self.pointing_lines) do
		local rect_size = 16

        local start_x, start_y = cos(line.angle), sin(line.angle)
        local finish_x, finish_y = start_x * rect_size, start_y * rect_size
        start_x = start_x * max(line.size, rect_size)
        start_y = start_y * max(line.size, rect_size)
		
		local t = line.t
		local t1 = ease("inOutExpo")(clamp(remap(line.t, 0, 1, 0.1, 1), 0, 1))
		local t2 = ease("inOutExpo")(clamp(remap(line.t, 0, 1, -0.05, 1), 0, 1))

		graphics.set_color(Palette.pickup_line:interpolate_clamped(t1))
		
        local line_x1 = lerp(start_x, finish_x, t1)
        local line_y1 = lerp(start_y, finish_y, t1)
        local line_x2 = lerp(start_x, finish_x, t2)
        local line_y2 = lerp(start_y, finish_y, t2)

        -- if vec2_distance_squared(line_x1, line_y1, line_x2, line_y2) <= 1 then
		-- 	graphics.points(line_x1, line_y1)
        -- end

        -- graphics.line(line_x1, line_y1, line_x2, line_y2)

        if not line.is_line then
			local resolution = round((remap(t1, 0, 1, line.max_resolution, 1)))

			table.clear(pickup_line_temp_points)
			for x, y in bresenham_line_iter(round(line_x1 / resolution), round(line_y1 / resolution), round(line_x2 / resolution), round(line_y2 / resolution)) do
				table.insert(pickup_line_temp_points, {x * resolution, y * resolution})
			end

			for i=1, #pickup_line_temp_points - 1 do
				local p1 = pickup_line_temp_points[i]
				local p2 = pickup_line_temp_points[i + 1]
				graphics.rectangle("line", p1[1], p1[2], p2[1] - p1[1], p2[2] - p1[2])
			end

			if t2 >= 0.9 and idivmod_eq_zero(gametime.tick + line.id, 2, 2) then
				local size = rect_size + sin((line.id + elapsed) * 0.05) * rect_size * 0.2 + rect_size * 0.2
				graphics.set_color(line.rect_color)
				graphics.rectangle("line", -size * 0.5, -size * 0.5, size, size)
			end
        else
			graphics.line(line_x1, line_y1, line_x2, line_y2)
		end

    end

	graphics.set_color(Color.white)

	
	if not idivmod_eq_zero(gametime.tick, 2, 3) then
		local textures = self.pickup.textures
		local index = idivmod(gametime.tick, 8, #textures) + 1
		local texture = textures[index]
		graphics.drawp_centered(texture, nil, 0, 0, 0)
	end

end

return BaseRescue
