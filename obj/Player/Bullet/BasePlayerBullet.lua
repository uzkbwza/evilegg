local BasePlayerBullet = GameObject2D:extend("BasePlayerBullet")
local BasePlayerBulletDieFx = Effect:extend("BasePlayerBulletDieFx")

local TwinStickNormalBullet = Mixins.Behavior.TwinStickNormalBullet

BasePlayerBullet:implement(TwinStickNormalBullet)
BasePlayerBullet.death_spawns = {}
BasePlayerBullet.cooldown = 8
BasePlayerBullet.spread = 0
BasePlayerBullet.h_offset = 6.5
BasePlayerBullet.is_player_bullet = true

function BasePlayerBullet:new(x, y, extra_bullet)
	BasePlayerBullet.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.TrackPreviousPosition2D)
	self.radius = self.radius or 5
	self:add_elapsed_ticks()
    self.speed = self.speed or 6
	self.sprite = self.sprite or textures.bullet_player_base
	self.distance_travelled = 0
    self.trail_distance = 0
	self.start_palette_offset = self.start_palette_offset or gametime.tick * 4
    self.hit_vel_multip = self.hit_vel_multip or 30
    self.push_modifier = self.push_modifier or 0.75
	self.z_index = 1

	if self.use_artefacts == nil then
		self.use_artefacts = true
	end
    if self.use_upgrades == nil then
        self.use_upgrades = true
    end
	
    self.damage = self.damage or 1
	self.lifetime = self.lifetime or 16

	self:mix_init(TwinStickNormalBullet)
	

    self.extra_bullet = extra_bullet
	if self.extra_bullet then
		self.lifetime = self.lifetime * 0.9
	end
	
    if self.use_upgrades then
        -- self.radius = self.radius * (1 + (game_state.upgrades.range) * 0.15)
        if extra_bullet then
            self.damage = self.damage * 0.2
            self.hit_vel_multip = self.hit_vel_multip * 0.2
            self.push_modifier = self.push_modifier * 0.1
            self.radius = self.radius * 0.5
        end
        self.damage = self.damage * (1 + (game_state.upgrades.damage) * 0.2)
        self.push_modifier = self.push_modifier * (1 + (game_state.upgrades.bullet_speed) * 0.4)
        self.hit_vel_multip = self.hit_vel_multip * (1 + (game_state.upgrades.bullet_speed) * 0.4)
        local base_speed = self.speed
        -- self.speed = self.speed * (1 + (game_state.upgrades.bullet_speed) * 0.25)
        self.speed = self.speed * (1 + (game_state.upgrades.bullet_speed) * 0.5)
        -- if game_state.upgrades.range == 1 then
        --     self.lifetime = self.lifetime * (26 / 16)
        -- elseif game_state.upgrades.range >= 2 then
        --     self.lifetime = self.lifetime * ((36 / 16) + ((game_state.upgrades.range - 2) * 10))
        -- end
        if game_state.upgrades.range == 1 then
            self.lifetime = self.lifetime * (26 / 16)
        elseif game_state.upgrades.range >= 2 then
            self.lifetime = self.lifetime * ((36 / 16) + ((game_state.upgrades.range - 2) * 10))
        end
        self.lifetime = self.lifetime * (base_speed / self.speed)
    end

    if self.use_artefacts then
        if game_state.artefacts.ricochet then
            self.ricochet_count = 3
            self.ricochet = true
        end
    end
	
	self.base_lifetime = self.lifetime
end

function BasePlayerBullet:draw()
    local palette_offset = floor((self.tick)) / 4
    if floor(self.tick / 2) % 2 == 0 then
        palette_offset = palette_offset + 5
    end
    local trail_dist = 4
    local max_bullets = 10
    local num_trail_bullets = min(max(floor(self.trail_distance / trail_dist), 1), max_bullets)
    local start, stop, step = -1, 1, 2
	-- local extra_damage = self:get_damage() - self.damage
    local bullet_scale = 1 + max((self:get_damage() - 1) * 1.5, 0)
	if self.extra_bullet then
		bullet_scale = max(bullet_scale * 0.5, 0.75)
	end
	if self.extra_bullet then
		start, stop, step = 0, 0, 1
	else
		start, stop, step = -1, 1, 2
	end
    for i = num_trail_bullets - 1, 0, -1 do
        local x, y = self.direction.x * -i * trail_dist, self.direction.y * -i * trail_dist
        if self.dead_position then
            local x_global, y_global = self:to_global(x, y)
            local dx, dy = x_global - self.dead_position.x, y_global - self.dead_position.y
            if vec2_dot(dx, dy, self.direction.x, self.direction.y) > 0 then
                break
            end
        end
        local color = Palette.rainbow:tick_color(self.start_palette_offset + palette_offset + i)
        local scale = pow(lerp(0.25, 1, 1 - (i / (max_bullets - 1))), 2) * bullet_scale

        -- if self.dead then
        -- 	scale = pow(scale, 2)
        -- end
        graphics.set_color(color)


        for j = start, stop, step do
            local rot_x, rot_y = vec2_rotated(self.direction.x, self.direction.y, tau / 4 * j)
            rot_x, rot_y = vec2_normalized(rot_x, rot_y)
            graphics.draw_centered(self.sprite, x + rot_x * 2, y + rot_y * 2, 0, scale, scale)
        end
    end
end

function BasePlayerBullet:enter()
	self:spawn_object_relative(BasePlayerBulletDieFx())
	-- print(self:get_damage())
end
 
function BasePlayerBullet:die()
	self.dead_position = self.pos:clone()
	self:start_destroy_timer(30)
    self:spawn_object_relative(BasePlayerBulletDieFx())
	-- self:spawn_object_relative(require("obj.Explosion")(self.pos.x, self.pos.y, 18, self.damage, "player", false))
end 

function BasePlayerBullet:on_terrain_collision(normal_x, normal_y)
    if self.ricochet and self.ricochet_count > 0 then
		self.trail_distance = 0
		self:play_sfx("player_ricochet", 0.5)
        self.ricochet_count = self.ricochet_count - 1
		local bounce_x, bounce_y = vec2_bounce(self.direction.x, self.direction.y, normal_x, normal_y)
		self.direction.x = bounce_x
		self.direction.y = bounce_y
        self:move(bounce_x * self.speed, bounce_y * self.speed)
		self.num_ricochets = self.num_ricochets and self.num_ricochets + 1 or 1
        self.lifetime = self.elapsed + (self.base_lifetime / (self.num_ricochets + 1))
	else
		self:defer(function() self:die() end)
	end
end

function BasePlayerBullet:get_death_particle_hit_velocity()
	return self.direction.x * self.hit_vel_multip, self.direction.y * self.hit_vel_multip
end

function BasePlayerBullet:update(dt)
	local move_x, move_y = self.direction.x * dt * self.speed, self.direction.y * dt * self.speed
	if self.dead then
		move_x = move_x * 0.45
		move_y = move_y * 0.45
	end
	local dist = vec2_magnitude(move_x, move_y)
	self.distance_travelled = self.distance_travelled + dist
	self.trail_distance = self.trail_distance + dist
	self:move(move_x, move_y)

	-- if self.use_artefacts then
		-- if game_state.artefacts.damage_over_distance then
        	-- self.extra_damage = self.damage * (self.distance_travelled / 100)
        -- end
	-- end
	
    if not self.dead then
        -- print(self.extra_damage)
        self:try_hit_nearby_anyone()
    end
	
end

local GRAPPLING_HOOK_IMPULSE = 0.95

function BasePlayerBullet.try_hit(bubble, self)
    local parent = bubble.parent
	if parent.is_player then
        return
    elseif parent.is_rescue then
		if self.hit_objects[parent.id] then
			return
		end
		if self.use_artefacts and game_state.artefacts.grappling_hook then
            local impulse = GRAPPLING_HOOK_IMPULSE
			if self.extra_bullet then
				impulse = impulse * 0.5
			end
			parent:apply_impulse(-self.direction.x * impulse, -self.direction.y * impulse)
            -- self:die()

			self:add_to_hit_objects(parent)
		end
		return
	end

	TwinStickNormalBullet.try_hit(bubble, self)
end

local AMULET_OF_RAGE_DAMAGE_MULTIPLIER = 0.4
local AMULET_OF_RAGE_DISTANCE = 40

function BasePlayerBullet:get_damage()
	local extra = 0
	if self.use_artefacts then
		if game_state.artefacts.amulet_of_rage and self.distance_travelled < AMULET_OF_RAGE_DISTANCE then
			extra = self.damage * stepify_ceil_safe((extra + smoothstep(1, 0, self.distance_travelled / AMULET_OF_RAGE_DISTANCE) * AMULET_OF_RAGE_DAMAGE_MULTIPLIER), 0.25)
		end
	end
	return self.damage + extra
end

function BasePlayerBullet:on_hit_something(parent, bubble)
    -- self:spawn_object_relative(BasePlayerBulletDieFx())
	self:play_sfx("player_bullethit", 0.8)

	self:try_push(parent, self.push_modifier)
end

function BasePlayerBullet:on_hit_blocking_objects_this_frame()
	if not self:is_timer_running("stop_hitting") then
		self:start_timer("stop_hitting", 1, function()
			self:die()
		end)
	end
end

function BasePlayerBulletDieFx:new(x, y)

	BasePlayerBulletDieFx.super.new(self, x, y)

	self.z_index = 1
	self.duration = 4
end

function BasePlayerBulletDieFx:draw(elapsed, tick, t)
    graphics.set_color(Palette.rainbow:tick_color(self.world.tick * 4))
	local size = 8 + game_state.upgrades.damage * 1
	graphics.rectangle_centered("fill", 0, 0, size, size)
end


return BasePlayerBullet
