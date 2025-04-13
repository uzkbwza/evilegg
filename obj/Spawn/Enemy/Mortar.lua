local Mortar = BaseEnemy:extend("Mortar")
local MortarProjectile = GameObject2D:extend("MortarProjectile")
local MortarShadow = GameObject2D:extend("MortarShadow")
local MortarFireSmoke = Effect:extend("MortarFireSmoke")
local Explosion = require("obj.Explosion")
local MortarProjectileSmoke = Effect:extend("MortarProjectileSmoke")
local MortarProjectileRing = Effect:extend("MortarProjectileRing")

function Mortar:new(x, y)
	self.max_hp = 6
    Mortar.super.new(self, x, y)
    self.hurt_bubble_radius = 6
	self.hit_bubble_radius = 4
    self.body_height = 6
	self.walk_speed = 0
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.Roamer)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self.bullet_push_modifier = 0.5
	self.declump_radius = 7

	self.declump_mass = 2.5
end

local walk_sprites = {
	textures.enemy_mortar2,
	textures.enemy_mortar3,
	textures.enemy_mortar4,
}

function Mortar:get_sprite()
    if self.state == "Normal" then
        return walk_sprites[floor(self.tick / 10) % #walk_sprites + 1]
    end
    if self.state == "Shoot" and self.state_tick < 10 then
        return textures.enemy_mortar5
    end
    return textures.enemy_mortar1
end

function Mortar:state_Normal_enter()
    self.walk_speed = 0.2
    local s = self.sequencer
    s:start(function()
        if self.shot_yet then
            s:wait(rng.randi(120, 500))
        else
            s:wait(60)
        end
		
		-- s:start(function()
		while self.world:get_number_of_objects_with_tag("shooting_mortar") > 0 do
			s:wait(1)
		end

		self:add_tag("shooting_mortar")

        local ally = self:get_random_player()
		while ally == nil do
			s:wait(30)
			ally = self:get_random_player()
		end
		self:change_state("Shoot")
	end)
end

function Mortar:state_Shoot_enter()
	self.shot_yet = true
    self.walk_speed = 0.0
	self:play_sfx("enemy_mortar_launch", 0.80)
    self:spawn_object(MortarProjectile(self.pos.x, self.pos.y - 18))
end

function Mortar:state_Shoot_exit()
	self:remove_tag("shooting_mortar")
end

function Mortar:state_Shoot_update(dt)
    if self.state_tick > 40 then
        self:change_state("Normal")
    end
end

function MortarProjectile:new(x, y)
    MortarProjectile.super.new(self, x, y)
	self:add_elapsed_ticks()
    self:add_sequencer()
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.sprite_y = 0
    self.random_offset = rng.randf(0, 1)
	self.z_index = 2
end

local SPRITE_Y = -700
local SPRITE_Y2 = -550

function MortarProjectile:update_shared(dt)
	local time_scale = BaseEnemy.get_time_scale(self)
	MortarProjectile.super.update_shared(self, dt * time_scale)
end

function MortarProjectile:enter()
    self:add_tag("enemy")
	self.go_time = 0
    local s = self.sequencer
	
    for i = 1, 20 do
		local x, y = self.pos.x, self.pos.y
		local dx, dy = rng.random_vec2_times(rng.randf(0, 16))
        local obj = self:spawn_object(MortarProjectileSmoke(x + dx, y + dy, rng.randfn(-6, 3)))
		obj.duration = obj.duration * rng.randfn(1, 0.15)
	end

	s:start(function()
        self.sprite_y = 0
        self.state = "Up"
		self.max_height = SPRITE_Y
		s:start(function()
            while true do
				self:play_sfx("enemy_mortar_missile_idle", 0.15)
				s:wait(30)
			end
		end)

        s:tween_property(self, "sprite_y", 0, SPRITE_Y, 120.0, "inCubic")
		local ally
        if rng.percent(25) then
            ally = self:get_random_ally()
        else
            ally = self:get_random_player()
        end

        while ally == nil do
            s:wait(1)
            if rng.percent(25) then
                ally = self:get_random_ally()
            else
                ally = self:get_random_player()
            end
        end
		
		local pos = Vec2(ally:get_body_center())
        self.state = "Down"
        self:movev_to(pos, 60.0)
        self:ref("shadow", self:spawn_object(MortarShadow(self.pos.x, self.pos.y)))
        self:bind_destruction(self.shadow)
        self.max_height = SPRITE_Y2
		self.go_time = 0
        self.descend_time = 60.0
        if not ally.is_player then
            self.max_height = self.max_height * 3
            self.descend_time = self.descend_time * 3
        end
		
		s:start(function()
            s:wait(self.descend_time - 60)
			self:stop_sfx("enemy_mortar_missile_idle")
			self:play_sfx("enemy_mortar_incoming", 0.55)
        end)
		

        s:tween_property(self, "sprite_y", self.max_height, -8, self.descend_time)
		self:stop_sfx("enemy_mortar_incoming")
		self:explode()
		
	end)
end

function MortarProjectile:explode()
	local params = {
		size = 32,	
		damage = 8,
		team = "enemy",
		melee_both_teams = true,
		-- particle_count_modifier = 0.95,
		-- explode_sfx = "explosion3",
	}
    self:spawn_object(Explosion(self.pos.x, self.pos.y, params))
	self:die()
end

function MortarProjectile:update(dt)
    if self.shadow then
        if self.go_time < self.descend_time - 45 or idivmod_eq_zero(gametime.tick, 3, 2) then
            self.shadow.radius = ease("outSine")(1 - abs(self.sprite_y / self.max_height)) * 35
        else
            self.shadow.radius = 0
        end
    end
    if self.state == "Up" then
        if self.is_new_tick and self.tick % 3 == 0 and self.go_time < 90 then
            local x, y = self.pos.x, self.pos.y
            local dx, dy = rng.random_vec2_times(rng.randf(0, 3))
            self:spawn_object(MortarProjectileSmoke(x + dx, y + dy, self.sprite_y))
        end
		if self.is_new_tick and self.tick % 10 == 0 and self.go_time < 90 and self.go_time > 10 then
			self:spawn_object(MortarProjectileRing(self.pos.x, self.pos.y, self.sprite_y))
		end
		-- else
	end
	if self.is_new_tick and self.tick % 20 == 0 then
		self:play_sfx("enemy_mortar_missile_beep", remap_clamp(self.tick / 120, 0, 1, 0, 0.5))
	end
    self.go_time = self.go_time + dt
end

function MortarProjectileSmoke:new(x, y, sprite_y)
    MortarProjectileSmoke.super.new(self, x, y)
    self.duration = 20
    self.z_index = 2
    self.size_mod = rng.randfn(1, 0.1)
    self.sprite_y = sprite_y
end

function MortarProjectileRing:new(x, y, sprite_y)
    MortarProjectileSmoke.super.new(self, x, y)
    self.duration = 30
    self.z_index = 1
    self.sprite_y = sprite_y
end

function MortarProjectileRing:draw(elapsed, tick, t)
    if not idivmod_eq_zero(self.tick, 3, 3) then
		return
	end
	local size = t * 15 + 5
    graphics.set_color(Color.black)
	graphics.set_line_width(4)
	graphics.ellipse("line", 0, self.sprite_y - 7, size, size * 0.66)
    graphics.set_color(idivmod_eq_zero(gametime.tick, 4, 2) and Color.red or Color.yellow)
	graphics.set_line_width(2)
	graphics.ellipse("line", 0, self.sprite_y - 7, size, size * 0.66)
end

function MortarProjectileSmoke:draw(elapsed, tick, t)
    graphics.set_color(Palette.explosion:get_color_clamped(floor(tick / 2)))
	local size = remap(ease("inCubic")(1 - t), 0, 1, 2, 10) * self.size_mod
	graphics.rectangle(tick < 3 and "fill" or "line", -size / 2, -size / 2 + self.sprite_y + self.tick * 0.04 + 8, size, size)
end

function MortarProjectile:draw()
    local sprite
    if self.state == "Up" then
        sprite = idivmod_eq_zero(self.tick, 4, 2) and textures.enemy_mortar_missile1 or textures.enemy_mortar_missile2
    elseif self.state == "Down" then
        sprite = idivmod_eq_zero(self.tick, 4, 2) and textures.enemy_mortar_missile3 or textures.enemy_mortar_missile4
		local rad = remap((abs(self.sprite_y / self.max_height)), 0, 1, 20, 60)
        local line_length = (1 - abs(self.sprite_y / self.max_height)) * 40

		graphics.push()
        graphics.scale(1, 1)
		if self.go_time < self.descend_time - 45 or idivmod_eq_zero(gametime.tick, 3, 2) then
			for i = 1, 4 do
				graphics.push()
                graphics.rotate(-self.elapsed * 0.15 + (self.random_offset * tau) + (tau / 4) * i)
				graphics.set_color(Color.black)
				graphics.set_line_width(4)
				graphics.line(rad * -0.5, 0, rad * -0.5-line_length, 0)
				graphics.set_color(idivmod_eq_zero(gametime.tick, 4, 2) and Color.red or Color.yellow)

				graphics.set_line_width(2)
				graphics.line(rad * -0.5, 0, rad * -0.5-line_length, 0)
				graphics.pop()
			end
		end
		graphics.pop()
    end

	graphics.set_color(Color.white)
	graphics.drawp_centered(sprite, nil, 0, 0, self.sprite_y, 0, 1, 1)
end

function MortarProjectile:die()
	self:queue_destroy()
end


function MortarShadow:new(x, y)
	MortarShadow.super.new(self, x, y)
	self:add_elapsed_time()
	-- self.z_index = -1
	self.z_index = 1
	self.radius = 0
end

function MortarShadow:draw()
	graphics.rotate(self.elapsed * 0.05)
    self:draw_circ(self.radius, 2)
    self:draw_circ(self.radius * 0.85, 1)
	-- self:draw_circ(self.radius * 0.125, 1)
end

function MortarShadow:draw_circ(radius, thickness)
	if radius < 1 then return end
	graphics.set_line_width(thickness * 2)
    graphics.set_color(Color.black)
	graphics.ellipse("line", 0, 0, radius, radius * 1, 10)
	graphics.set_line_width(thickness)
    graphics.set_color(idivmod_eq_zero(gametime.tick, 4, 2) and Color.red or Color.yellow)
	graphics.ellipse("line", 0, 0, radius, radius * 1, 10)
end

AutoStateMachine(Mortar, "Normal")

return Mortar
