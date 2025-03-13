local BaseRescue = require("obj.Spawn.Pickup.BasePickup"):extend("BaseRescue")
local BaseRescueSpawnParticle = Effect:extend("BaseRescueSpawnParticle")
local BaseRescueFloorParticle = Effect:extend("BaseRescueFloorParticle")
local BaseRescueArrowParticle = Effect:extend("BaseRescueArrowParticle")
local HurtFlashFx = Effect:extend("HurtFlashFx")
local DeathSplatter = require("fx.enemy_death_pixel_splatter")
local BaseRescuePickupParticle = Effect:extend("BaseRescuePickupParticle")

local START_INVULNERABILITY = 120
local HIT_INVULNERABILITY = 60
local LAST_HIT_INVULNERABILITY = 70

local ENEMY_AVOID_DISTANCE = 10

function BaseRescue:new(x, y)
    BaseRescue.super.new(self, x, y)
	self.team = "player"
    self.body_height = 4
    self.max_hp = self.max_hp or 4
    self.hurt_bubble_radius = self.hurt_bubble_radius or 3
    self.declump_radius = self.declump_radius or 20
	self.self_declump_modifier = self.self_declump_modifier or 0.3
    self:lazy_mixin(Mixins.Behavior.Health)
    self:lazy_mixin(Mixins.Behavior.Hittable)
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Fx.Rumble)
    self:lazy_mixin(Mixins.Behavior.Flippable)
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

    if self.world.state == "RoomClear" then
        return
	end

    self:start_rumble(2.0, 60)
    local damage = other.damage
    if other.is_bubble then
        other = other.parent
    end
    self:damage(damage)
    self:start_timer("invulnerability", self.hp <= 1 and LAST_HIT_INVULNERABILITY or HIT_INVULNERABILITY)


    -- local sprite = self:get_sprite()

	-- if self.hp <= 0 then
		
    -- else

end

function BaseRescue:on_damaged(damage)
	local bx, by = self:get_body_center()
	if self.hp > 0 then
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
end

function BaseRescue:get_sprite()
    return idivmod_eq_zero(self.tick, 10, 2) and textures.ally_rescue1 or textures.ally_rescue2
end

function BaseRescue:get_default_palette()
    return Palette[self:get_sprite()]
end

function BaseRescue:on_pickup()
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
		-- self:play_sfx(self.pickup_sfx, self.pickup_sfx_volume * 0.25)
	else
		self:play_sfx(self.pickup_sfx, self.pickup_sfx_volume)
	end
    self.floor_particle:on_pickup()
    BaseRescue.super.on_pickup(self)
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

	return palette, offset
end

function BaseRescue:on_health_reached_zero()
	self:die()
	self:queue_destroy()
end

function BaseRescue:die()
	local bx, by = self:get_body_center()
	local sprite = self:get_sprite()
	local flash = self:spawn_object(HurtFlashFx(self, bx, by+1, 64, true))
	flash.duration = 40
	self:spawn_object(DeathSplatter(bx, by, self.flip, sprite, Palette[sprite], 2, 0, 0))
	self:play_sfx(self.die_sfx, self.die_sfx_volume)
	self.pickupable = false
	self.floor_particle:die()
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

function BaseRescue:update(dt)
	self:collide_with_terrain()
    if self.avoid_enemies then
		self.nearby_enemy_hit_bubbles = {}
        self:each_nearby_bubble_self("hit", "enemy", self.avoid_enemies_radius, self.try_avoid_enemy)
        self:each_nearby_bubble_self("hit", "neutral", self.avoid_enemies_radius, self.try_avoid_enemy)
		local average_x, average_y = 0, 0
		local num_enemies = 0
		for i=1, #self.nearby_enemy_hit_bubbles do
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
	self.duration = 0
	self:ref("target", target)
	self.z_index = 1
	self.random_offset = rng.randi(0, 100)
end

function BaseRescueArrowParticle:update(dt)
    if self.target then
		local bx, by = self.target:get_body_center()
        self:move_to(splerp_vec(self.pos.x, self.pos.y, bx, by - self.target.hurt_bubble_radius * 2, dt, 600))
    else
		self:queue_destroy()
    end
end

function BaseRescueArrowParticle:draw(elapsed, tick, t)
    if idivmod_eq_zero(gametime.tick + self.random_offset, 4, 2) then
        return
    end
    local almost_dead = false
	if self.target then
		almost_dead = self.target.hp <= 1 and self.target.max_hp > 1
	end

    graphics.set_color(Color.white)
	local palette_offset = almost_dead and idiv(gametime.tick + self.random_offset, 3) or 0
	graphics.drawp_centered(almost_dead and textures.ally_rescue_arrow_almost_dead or textures.ally_rescue_arrow, nil, palette_offset, sin(elapsed * 0.05) * 0.5)
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
        self:move_to(splerp_vec(self.pos.x, self.pos.y, self.target.pos.x, self.target.pos.y, dt, 60))
	end
end

function BaseRescueFloorParticle:on_pickup()
    local s = self.sequencer
	self.z_index = 1
	self.size = self.size * 1.5
	self:start_timer("on_pickup", 10)
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
    local size = max(self.size + sin(elapsed * 0.05) * (self.size * (self.target and 0.2 or 0)), self.size + 20 - elapsed * 2)
    graphics.set_color(color)
	graphics.set_line_width(2)
	-- if almost_dead then
	-- end
    graphics.rectangle(self:is_timer_running("on_pickup") and "fill" or "line", -size / 2, -size * 0.33, size, size * 0.66)
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
end

function BaseRescuePickupParticle:update(dt)
    if self.target then
		local bx, by = self.target:get_body_center()
        local elapsed = self.elapsed
        self:move_to(splerp_vec(self.pos.x, self.pos.y, bx + cos(elapsed * 0.045) * 3,
        by - self.target.hurt_bubble_radius + sin(elapsed * 0.045) * 1.5 * (0.667) - 7, dt, 60))
        if self.is_new_tick and rng.percent(80) then
			local s = self.sequencer
            s:start(function()
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
                s:tween_property(line, "t", 0, 1, 30, "linear")
				self.pointing_lines[line] = nil
			end)
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

	
    local textures = self.pickup.textures
    local index = idivmod(gametime.tick, 10, 3) + 1
    local texture = textures[index]
    graphics.drawp_centered(texture, nil, 0, 0, 0)

end

return BaseRescue
