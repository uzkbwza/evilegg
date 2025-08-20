
local Eyeball = BaseEnemy:extend("Eyeball")
local Hand = BaseEnemy:extend("Hand")
local Foot = BaseEnemy:extend("Foot")
local Nose = BaseEnemy:extend("Nose")
local Mouth = BaseEnemy:extend("Mouth")
local Explosion = require("obj.Explosion")
local EyeballLaser = BaseEnemy:extend("EyeballLaser")
local EyeballLaserShadow = GameObject2D:extend("EyeballLaserShadow")

local FootShadow = GameObject2D:extend("FootShadow")
local StompExplosionFx = GameObject2D:extend("StompExplosion")
local SniffParticle = GameObject2D:extend("SniffParticle")


StompExplosionFx.duration = 30

Foot.search_speed = 0.125
Foot.spawn_cry = "enemy_foot_raise"
Foot.spawn_cry_volume = 0.9

Nose.sniff_radius = 200

EyeballLaser.accel_speed = 0.00065
EyeballLaser.no_death_splatter = true
EyeballLaser.death_flash_size_mod = 3.0

local eyeball_limits = {
	max_speed = 3,
}

Eyeball.max_hp = 3
Hand.max_hp = 10
Foot.max_hp = 4
Nose.max_hp = 4
Mouth.max_hp = 8

function Eyeball:new(x, y)
    self.body_height = 4
    self.max_hp = 3
	
	self.hit_bubble_radius = 4
	self.hurt_bubble_radius = 8
	self.roam_chance = 2
    self.walk_timer = 18
	self.drag = 0.01
    Eyeball.super.new(self, x, y)
	-- self.hit_bubble_radius = nil
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.roam_diagonals = true
    self.walk_speed = 0.1
	self.walk_toward_player_chance = 60
    self:lazy_mixin(Mixins.Behavior.Roamer)
    self.bullet_push_modifier = 2.0
	self:set_physics_limits(eyeball_limits)

    self.declump_radius = 8
    self.declump_mass = 1

    self.aim_direction = Vec2(rng:random_vec2())
	self.on_terrain_collision = self.terrain_collision_bounce
    -- self.declump_same_class_only = true
    -- self.self_declump_modifier = 1.5
end

function EyeballLaserShadow:new(x, y)
	EyeballLaserShadow.super.new(self, x, y)
	self.radius = 0
    self.start_x, self.start_y = 0, 0
	self.end_x, self.end_y = 0, 0
end

function EyeballLaserShadow:draw()
	graphics.set_color(Color.nearblack)
    graphics.set_line_width(self.radius)
	graphics.rectangle_centered("fill", self.start_x, self.start_y, self.radius, self.radius)
	graphics.line(self.start_x, self.start_y, 0, 0)
	graphics.rectangle_centered("fill", 0, 0, self.radius, self.radius)
    graphics.set_line_width(1)
end

function EyeballLaser:new(x, y)
	self.body_height = 4
	self.max_hp = 2
    EyeballLaser.super.new(self, x, y)
    self.drag = 0.01
    -- self.hit_bubble_radius = 2
	self.hurt_bubble_radius = 3
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self:lazy_mixin(Mixins.Behavior.TrackPreviousPosition2D)
    self:set_physics_limits({
		max_speed = 3
	})
    self.z_index = 10
	-- self.melee_both_teams = true
	self.floor_draw_color = Palette.rainbow:get_random_color()
	self.positions = { self.pos:clone() }
end

function EyeballLaser:enter()
    self:add_hurt_bubble(0, 0, self.hurt_bubble_radius, "main", 0, 0)
    self:add_hit_bubble(0, 0, 1, "main", 1, 0, 0)
	self:play_sfx("enemy_eyeball_laser", 0.75)
    self:ref("shadow", self:spawn_object(EyeballLaserShadow(self.pos.x, self.pos.y))).z_index = -1
	self:bind_destruction(self.shadow)
end

function EyeballLaser:update(dt)
    if self.is_new_tick then
        table.insert(self.positions, self.pos:clone())
        while #self.positions > 10 do
			table.remove(self.positions, 1)
		end
	end

	
	local start_x,start_y = self.positions[1].x, self.positions[1].y
	self:set_bubble_capsule_end_points("hurt", "main", self:to_local(start_x, start_y))
	self:set_bubble_capsule_end_points("hit", "main", self:to_local(start_x, start_y))


	local accel_speed = self.accel_speed + (self.tick / 700)
	self:apply_force(self.direction.x * accel_speed, self.direction.y * accel_speed)
end

function EyeballLaser:get_death_flash_position()
	local bx, by = self:get_body_center_local()
	local start_x, start_y = self.positions[1].x, self.positions[1].y
	local end_x, end_y = self.pos.x, self.pos.y

	local middle_x, middle_y = vec2_lerp(start_x, start_y, end_x, end_y, 0.5)
	return middle_x + bx, middle_y + by
end

function EyeballLaser:draw()

    local start_x, start_y = self:to_local(self.positions[1].x, self.positions[1].y)
    local rad = self.hurt_bubble_radius
	if self.shadow then
        self.shadow.start_x, self.shadow.start_y = start_x, start_y
        self.shadow.end_x, self.shadow.end_y = 0, 0
        self.shadow.radius = rad
		self.shadow:move_to(self.pos.x, self.pos.y)
	end

    self:body_translate()
	
	graphics.set_color(iflicker(self.tick, 4, 2) and Color.black or Color.darkgrey)
    graphics.set_line_width(rad + 2)
	graphics.rectangle_centered("fill", start_x, start_y, rad + 2, rad + 2)
	graphics.line(start_x, start_y, 0, 0)
	graphics.rectangle_centered("fill", 0, 0, rad + 2, rad + 2)


	graphics.set_color(Palette.rainbow:tick_color(self.tick, 0, 0.8))
    graphics.set_line_width(rad)
	graphics.rectangle_centered("fill", start_x, start_y, rad, rad)
	graphics.line(start_x, start_y, 0, 0)
	graphics.rectangle_centered("fill", 0, 0, rad, rad)
    graphics.set_line_width(1)

end


function EyeballLaser:get_sprite()
	return textures.enemy_eyeball_laser
end


function Eyeball:get_sprite()
    local y = self.aim_direction.y
	
	local step = 1/4

	if y < -step * 3.5 then
		return textures.enemy_eyeball5
	elseif y < -step then
		return textures.enemy_eyeball4
	elseif y >= step and y < step * 3.5 then
		return textures.enemy_eyeball2
	elseif y >= step * 3.5 then
		return textures.enemy_eyeball1
	else
		return textures.enemy_eyeball3
	end
end

function Eyeball:get_sprite_flip()
	local h_flip = sign(self.aim_direction.x)
	return h_flip, 1
end

function Eyeball:update(dt)
	
    if self.is_new_tick and not self:is_tick_timer_running("aim_update") then
        local dist = max(self:get_body_distance_to_player(), 1)
        local percent = clamp(remap_pow(dist, 1, 200, 100, 1, 1/4), 1, 100)
		-- print(percent)
		if rng:percent(percent) then
			if rng:percent(20 + percent * 1.5) then
				local dx, dy = self:get_body_direction_to_player()
				self.aim_direction.x, self.aim_direction.y = dx, dy
			else
				self.aim_direction.x, self.aim_direction.y = rng:random_vec2()
			end
			self:start_tick_timer("aim_update", max(rng:randi(50, 60) - percent, 1))
		end
	end
	
	self:set_body_height(4 + sin(self.tick * 0.05 + self.random_offset_ratio * 255) * 2)

	Eyeball.super.update(self, dt)

    if self.is_new_tick and rng:percent(0.8) and not self:is_tick_timer_running("laser_cooldown") then
		local offset_x, offset_y = vec2_mul_scalar(self.aim_direction.x, self.aim_direction.y, 6)
		local laser = self:spawn_object(EyeballLaser(self.pos.x + offset_x, self.pos.y + offset_y))
		laser.direction = Vec2(vec2_snap_angle(self.aim_direction.x, self.aim_direction.y, 8))
		self:start_tick_timer("laser_cooldown", 50)
	end
end

function Hand:new(x, y)
    self.body_height = 8
	self.hurt_bubble_radius = 12
    Hand.super.new(self, x, y)
	self.hit_bubble_radius = nil
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.WalkTowardPlayer)
    self.walk_speed = 0.31
	self.bullet_push_modifier = 0.5
    self.declump_radius = 16
    self.declump_mass = 2
end

function Hand:get_sprite()
	return self.state == "Holding" and textures.enemy_hand2 or textures.enemy_hand1
end

function Hand:state_Searching_update(dt)
    self:set_body_height(8 + sin(self.tick * 0.045 + self.random_offset_ratio * 255) * 2)
    self:set_flip(self.walk_toward_player_dir.x)
	local player = self:get_closest_player()
    if player and not player.held_by_hand then
        local bx, by = self:get_body_center()
		local px, py = player:get_body_center()
		local dist = vec2_distance(bx, by, px, py)
        if dist < 10 then
			self:ref("held_object", player)
			self:change_state("Holding")
		end
	end
    Hand.super.update(self, dt)
end

function Hand:state_Searching_enter()
	self.bullet_push_modifier = 3.0
	self.z_index = 0
    self.pause_walking_toward_player = false
end

function Hand:state_Searching_exit()
end

function Hand:state_Holding_enter()
    self:play_sfx("enemy_hand_grab")
	self.held_object.held_by_hand = true
	self.bullet_push_modifier = 0.0
	self.z_index = 1
    self.pause_walking_toward_player = true
end

function Hand:state_Holding_update(dt)
    if self.held_object == nil then
        self:change_state("Searching")
    else
        local ox, oy = self.held_object:get_body_center_local()
        local bx, by = self:get_body_center()
        local hold_x, hold_y = bx, by + 8
        local target_x, target_y = hold_x - ox, hold_y - oy
		local new_x, new_y = splerp_vec(self.held_object.pos.x, self.held_object.pos.y, target_x, target_y, 100, dt)
        self.held_object:move_to(new_x, new_y)
        -- local local_x, local_y = self:get_body_center_local()
        local diff_x, diff_y = vec2_direction_to(target_x, target_y, new_x, new_y)
		local speed = 0.1
		self:apply_force(diff_x * speed, diff_y * speed)

		-- self:move_to(my_x, my_y)
	end
end

function Hand:state_Holding_exit()
	if self.held_object then
		self.held_object.held_by_hand = nil
		self.held_object = nil
	end
end

function Hand:exit()
	if self.held_object then
		self.held_object.held_by_hand = nil
	end
end

function StompExplosionFx:new(x, y, flip)
    StompExplosionFx.super.new(self, x, y)
    self:add_time_stuff()
	self.flip = flip
	self.z_index = -1
end

function StompExplosionFx:process_explosion(explosion)
end

function StompExplosionFx:update(dt)
	if self.tick > self.duration then
		self:queue_destroy()
	end
end

function StompExplosionFx:floor_draw()
    if self.is_new_tick and self.tick == 2 then
		graphics.draw_centered(textures.enemy_footprint, 0, -2, 0, self.flip, 1)
	end
end

function FootShadow:draw()
    local radius = remap_clamp(self.radius and self.radius or 1, 0.3, 1, 0.0, 1.0)
    -- local radius = 1
    -- if (self.radius or 1) <= 0 then
        -- radius = 0
    -- end
    local fill = "fill"
	if radius > 0.3 then
        graphics.set_color(Color.nearblack)
        if self.parent then
            if self.parent.state == "Stomp" and self.parent.searching and iflicker(self.parent.tick, 2, 2) then
                graphics.set_color(iflicker(self.parent.tick, 4, 2) and Color.red or Color.yellow)
                self.radius = 1
                fill = "line"
                graphics.set_line_width(2)
            end
        end
		graphics.rectangle_centered(fill, 0, 0, 10 * radius * 2, 6 * radius * 2)
		-- graphics.set_color(Color.darkergrey)
		-- graphics.ellipse("line", 0, 0, 10 * radius, 6 * radius)
	end
end

function Foot:new(x, y)
    self.body_height = 4

	self.drag = 0.036
    Foot.super.new(self, x, y)
    self.hurt_bubble_radius = 12
    self.hit_bubble_radius = nil
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)

    self.declump_radius = 8
	self.bullet_push_modifier = 0.15
	self.self_declump_modifier = 0.25
    self.declump_mass = 1

	self.melee_attacking = false
	self.melee_both_teams = true

    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:set_flip(rng:coin_flip() and 1 or -1)
	self.intangible = true

end


function Foot:enter()
    self:ref("shadow", self:spawn_object(FootShadow(self.pos.x, self.pos.y))).z_index = -1
    self.shadow:ref("parent", self)
    self:bind_destruction(self.shadow)
	self:add_hit_bubble(-5, 4, 5, "main", 1)
	self:add_hit_bubble(5, 4, 5, "main2", 1)
	-- self:add_hit_bubble(0, 4, 5, "main3", 1)
    self:add_hit_bubble(0, 6, 7, "main3", 1)
	
	self:add_hurt_bubble(-5, 4, 6, "main")
	self:add_hurt_bubble(-5, -4, 5, "main2")
	self:add_hurt_bubble(5, 4, 6, "main3")
    self:start_tick_timer("stomp_cooldown", rng:randi(40, 120))
end

function Foot:get_sprite()
	return textures.enemy_foot1
end


function Foot:update(dt)
    -- self:set_body_height(24 + sin(self.tick * 0.045 + self.random_offset_ratio * 255) * 2)
    if self.shadow then
		self.shadow.radius = self.body_height / 24
		self.shadow:movev_to(self.pos)
	end
    Foot.super.update(self, dt)
end

function Foot:draw()

    if self.intangible and iflicker(self.tick, 1, 2) then
		return
	end
	Foot.super.draw(self)
end

function Foot:state_Idle_enter()
	-- self.intangible = true
end

function Foot:state_Idle_update(dt)
	self:set_body_height(splerp(self.body_height, 24 + sin(self.tick * 0.045 + self.random_offset_ratio * 255) * 2, 200, dt))
    -- if self.is_new_tick and rng:percent(2) then
    if self.is_new_tick and rng:percent(2) or not self:is_tick_timer_running("stomp_cooldown") then
        self:start_tick_timer("stomp_cooldown", rng:randi(40, 70))
        self:change_state("Stomp")
    end
end

function Foot:state_Stomp_enter()
	self.searching = false
    self.intangible = true

	
	self:unref("target")
	local s = self.sequencer
    s:start(function()
		local height = 24
        self:set_body_height(height)
        local func = function(height)
            self:set_body_height(height)
        end
		self:play_sfx("enemy_foot_raise", 0.9)
		self.searching = true
        s:tween(func, height, height + 10, 10, "outSine")
		self:start_timer("fall_sfx", 25, function()
			self:play_sfx("enemy_foot_fall", 0.9)
        end)
		s:start(function()
			s:wait(30)
            self.intangible = false
		end)
        s:tween(func, self.body_height, 10, 45, "inExpo")
        self.searching = false
		-- self.applying_physics = false
        self.vel:mul_in_place(0.15)
		self:stop_sfx("enemy_foot_raise")
        self:play_sfx("enemy_foot_stomp", 0.9)
        self:spawn_object(StompExplosionFx(self.pos.x, self.pos.y, self.flip))
		
		-- local params = {
        --     size = 10,
		-- 	damage = 1,
        --     explode_sfx = "enemy_foot_stomp",
        --     ignore_explosion_force = { self },
		-- 	explode_vfx = StompExplosionFx(self.pos.x, self.pos.y, self.flip),
		-- 	-- explode_sfx_volume = 0.5,
        -- }
        -- self:spawn_object(Explosion(self.pos.x, self.pos.y, params))

        s:wait(1)
		self.melee_attacking = true
		s:wait(5)
		self.melee_attacking = false
        -- self.applying_physics = true
		s:start(function()
			s:wait(45)
            self.intangible = true
		end)
        s:tween(func, self.body_height, height, 60, "inOutQuad")
		
		self.intangible = true
		self:change_state("Idle")
	end, 100)
end

function Foot:state_Stomp_update(dt)
    if self.searching then
        if not self.target then
            self:ref("target", self:get_random_ally())
        else
            local bx, by = self.pos.x, self.pos.y
            local px, py = self.target:get_body_center()
			local dist = vec2_distance(bx, by, px, py)
			if dist > 1 then
				local dx, dy = vec2_direction_to(bx, by, px, py)
				self:apply_force(dx * self.search_speed, dy * self.search_speed)
			end
        end
    end
    if not self.applying_physics then
        self.vel:mul_in_place(0.0)
    end
	-- print(self.vel.x, self.vel.y)
end

function Foot:state_Stomp_exit()
    self.searching = false
    self.applying_physics = true
    self:unref("target")
end

function Nose:new(x, y)
    self.body_height = 5

    self.hit_bubble_radius = 5

    Nose.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)

    self.declump_radius = 7
    self.declump_mass = 3
	self.sprite = textures.enemy_nose1
end

function Nose:enter()
    self:add_hurt_bubble(0, -4, 4, "main")
    self:add_hurt_bubble(0, 2, 5, "main2")
	self:ref("sniff_particle", self:spawn_object(SniffParticle(self.pos.x, self.pos.y)))
	self:bind_destruction(self.sniff_particle)
end

function SniffParticle:new(x, y)
	SniffParticle.super.new(self, x, y)
	self.z_index = 1
    self.particles = {}
	self:add_time_stuff()
end

function SniffParticle:spawn_particle(radius_mod)
	local s = self.sequencer
	s:start(function()
        local rand_x, rand_y = rng:random_vec2_times(rng:randf(Nose.sniff_radius / 4, Nose.sniff_radius) * (radius_mod or 1))
        local dx, dy = vec2_normalized(rand_x, rand_y)
		
		local size = max(abs(rng:randfn(2, 1.5)), 0.5)
		local particle = {
			x = rand_x,
			y = rand_y,
            size = 0,
		}
        self.particles[particle] = true
		
        local func = function(t)
            particle.size = size * (t)
			particle.x = remap_lower(rand_x * (1 - t), 0, rand_x, dx * 5)
            particle.y = remap_lower(rand_y * (1 - t), 0, rand_y, dy * 2)

		end
        s:tween(func, 0, 1, 15 * (radius_mod or 1), "linear")
		self.particles[particle] = nil
	end)
end




function SniffParticle:draw()
	for particle, _ in pairs(self.particles) do
		graphics.rectangle_centered("fill", particle.x, particle.y, particle.size, particle.size)
	end
end


local SNIFF_OFFSET = 7

function Nose:update(dt)
    self:set_body_height(5 + sin(self.tick * 0.055 + self.random_offset_ratio * 255) * 2)
    if self.sniff_particle then
		local bx, by = self:get_body_center()
		self.sniff_particle:move_to(bx, by + SNIFF_OFFSET)
	end
	Nose.super.update(self, dt)
end

function Nose:get_sprite()
    return self.sprite
end

function Nose:get_palette()
	local palette, offset = Nose.super.get_palette(self)
	if self.sniffing then
		offset = idiv(self.tick, 3)
	end
	return palette, offset
end

function Nose:state_Idle_update(dt)
	if self.is_new_tick and rng:percent(0.5) then
		self:change_state("Sniff")
	end
end

function Nose:sniff_anim(time_on, time_off)
    local s = self.sequencer
	self.sprite = textures.enemy_nose2
    self:play_sfx("enemy_nose_sniff", 0.85)
	if self.sniff_particle then
		for i = 1, rng:randi(10, 20) do
			self.sniff_particle:spawn_particle(0.5)
		end
	end
	s:wait(time_on)
	self.sprite = textures.enemy_nose1
	s:wait(time_off)
end

function Nose:state_Sniff_enter()
    local s = self.sequencer
    s:start(function()
		self.sprite = textures.enemy_nose1
        while self.world:get_number_of_objects_with_tag("sniffing_noses") > 0 do
            s:wait(rng:randi(120, 240))
        end
        self:add_tag("sniffing_noses")
		self:sniff_anim(5, 3)
		self:sniff_anim(5, 15)
        self:sniff_anim(5, 15)
		s:wait(20)
		self.sprite = textures.enemy_nose3
		self.sniffing = true
		self:play_sfx("enemy_nose_sniff2", 0.85)
        s:wait(30)
		self:stop_sfx("enemy_nose_sniff2")
		self.sniffing = false
        s:wait(10)

		self.sprite = textures.enemy_nose1
		self:remove_tag("sniffing_noses")
        self:change_state("Idle")
    end)
end

function Nose:state_Sniff_exit()
    self.sniffing = false	
	self:remove_tag("sniffing_noses")
	self:stop_sfx("enemy_nose_sniff2")

	self.sprite = textures.enemy_nose1

end

function Nose:exit()
	self:stop_sfx("enemy_nose_sniff2")
end


function Nose:state_Sniff_update(dt)
    if self.sniffing then
        local bx, by = self:get_body_center()
        local rx, ry, rw, rh = bx - self.sniff_radius, by - self.sniff_radius, self.sniff_radius * 2, self.sniff_radius * 2
        self.world.game_object_grid:each_self(rx, ry + SNIFF_OFFSET, rw, rh, self.do_sniff, self, dt)
        if self.sniff_particle then
			if self.is_new_tick and rng:percent(90) then
				for _=1, rng:randi(1, 3) do
                    self.sniff_particle:spawn_particle()
				end
			end
		end
    end
end

local SNIFF_FORCE = 1.3

function Nose.do_sniff(object, self, dt)
	local bx, by = self:get_body_center()
	local px, py = object:get_body_center()
	local dist = vec2_distance_squared(bx, by, px, py)
	if dist < self.sniff_radius * self.sniff_radius then
        local dx, dy = vec2_direction_to(bx, by, px, py)
		-- if object.is_simple_physics_object then
			object:move(-dx * SNIFF_FORCE * dt, -dy * SNIFF_FORCE * dt)
		-- end
	end
end




-- Mouth.follow_allies = true

function Mouth:new(x, y)
    self.body_height = 4
    self.max_hp = 8
	self.follow_allies = rng:coin_flip()

    self.hurt_bubble_radius = 8
    self.hit_bubble_radius = 7
	self.drag = 0.5

    Mouth.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self.bullet_push_modifier = 5.0
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.WalkTowardPlayer)
    self.walk_speed = 1.85

    self.declump_radius = 8
    self.declump_mass = 4
	self.pause_walking_toward_player = true
end

function Mouth:update(dt)
    if self.tick > 40 and self.pause_walking_toward_player and self.is_new_tick and rng:percent(0.90) and not self:is_tick_timer_running("walk_cooldown") then
        self.pause_walking_toward_player = false
		self:play_sfx("enemy_mouth_skitter", 0.9)
		self:start_tick_timer("pause_walking_toward_player", 30, function()
            self.pause_walking_toward_player = true
			self:start_tick_timer("walk_cooldown", 15)
		end)
	end
end

function Mouth:get_sprite()
	return iflicker(self.tick, (self.pause_walking_toward_player and 10 or 3), 2) and textures.enemy_mouth1 or textures.enemy_mouth2
end


AutoStateMachine(Hand, "Searching")
AutoStateMachine(Foot, "Idle")
AutoStateMachine(Nose, "Idle")

return { Eyeball, Hand, Foot, Nose, Mouth }
