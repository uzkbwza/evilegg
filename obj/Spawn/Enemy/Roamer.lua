local Roamer = BaseEnemy:extend("Roamer")
local Roamsploder = Roamer:extend("Roamsploder")
local RoyalRoamer = Roamer:extend("RoyalRoamer")
local Explosion = require("obj.Explosion")
local ExplosionRadiusWarning = require("obj.ExplosionRadiusWarning")

Roamsploder:implement(Mixins.Behavior.ExploderEnemy)

-- local ROAMER_SHEET = SpriteSheet(textures.enemy_roamer, 10, 14)

Roamer.palette = Palette[textures.enemy_roamer1]:clone()

-- Roamer.spawn_cry = "enemy_roamer_spawn"
-- Roamer.spawn_cry_volume = 0.9
-- Roamer.death_cry = "enemy_roamer_death"
-- Roamer.death_cry_volume = 0.9

function Roamer:new(x, y)
	self.max_hp = self.max_hp or 1
    Roamer.super.new(self, x, y)
	-- self.drag = 0.6
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self:lazy_mixin(Mixins.Behavior.Roamer)
	self.declump_radius = 5
	self.walk_toward_player_chance = 60
	self.follow_allies = rng:percent(20)
    self.walk_frequency = 6
	self.body_height = 5
	self.declump_mass = 2.5
	
end

function Roamer:update(dt)
    if self.is_new_tick and self.tick % self.walk_frequency == 0 and rng:percent(10) then
		self:play_sfx("enemy_roamer_walk", 0.25, 1.0)
	end
end

function Roamer:get_palette()
	local palette = self.palette
	if self.world then
		palette:set_color(3, Palette.roamer:tick_color(self.world.tick / 2))
	end
	return palette, 0
end

function Roamer:get_sprite()
	-- return ROAMER_SHEET:loop(self.tick, 10, 0)
	return (self:tick_pulse(self.walk_frequency) and textures.enemy_roamer1 or textures.enemy_roamer2)
end

function Roamer:draw()
	Roamer.super.draw(self)
	-- graphics.line(0, 0, self.roam_direction.x * 100, self.roam_direction.y * 100)
end

function Roamer:floor_draw()
    if self.is_new_tick and self.tick % self.walk_frequency == 0 then
        local dx
        if iflicker(self.tick, self.walk_frequency, 2) then
            dx = -3
        else
            dx = 3
        end
        local length = 1

        local shade = 0.5
        graphics.set_color(shade, shade, shade)
        graphics.line(dx - length * 0.5, 0, dx + length * 0.5, 0)
    end
end

-- function Roamsploder:new(x, y)
-- 	Roamsploder.super.new(self, x, y)
-- 	self.max_hp = 2
-- 	self.walk_toward_player_chance = 100
-- 	self.follow_allies = 0
-- 	self.walk_frequency = 3
-- 	self.body_height = 5
-- 	self.declump_radius = 5
-- end

local EXPLOSION_RADIUS = 20

function Roamsploder:new(x, y)
    self.max_hp = 2
	self.hit_bubble_damage = 10
    -- self.bullet_push_modifier = 3.5
    self.walk_speed = 0.75
    Roamsploder.super.new(self, x, y)
	self:mix_init(Mixins.Behavior.ExploderEnemy)
end

function Roamsploder:enter()
	local bx, by = self:get_body_center()
	self:spawn_object(ExplosionRadiusWarning(bx, by, EXPLOSION_RADIUS, self))
end

function Roamsploder:get_sprite()
    -- return ROAMER_SHEET:loop(self.tick, 10, 0)
    return (self:tick_pulse(self.walk_frequency) and textures.enemy_roamsploder1 or textures.enemy_roamsploder2)
end

function Roamsploder:on_landed_melee_attack()
	self:die()
end


function Roamsploder:get_palette()

    if self.world then
        return nil, floor(self.world.tick / 3)
    end
	return nil, 0
end

function Roamsploder:die(...)
	local bx, by = self:get_body_center()
    local params = {
		size = EXPLOSION_RADIUS,	
		damage = 10,
		team = "enemy",
		melee_both_teams = true,
		particle_count_modifier = 0.85,
		explode_sfx = "explosion3",
	}
    self:spawn_object(Explosion(bx, by, params))
    Roamsploder.super.die(self, ...)
end

RoyalRoamer.palette = Palette[textures.enemy_royalroamer1]:clone()

function RoyalRoamer:new(x, y)
    self.max_hp = 2
    RoyalRoamer.super.new(self, x, y)
    self.base_walk_speed = 1.25
	self.roaming = false
    self.walk_frequency = 5
	self.bullet_push_modifier = 2.5
	self.walk_toward_player_chance = 90
    self.roam_elapsed = 0
	-- self.roam_diagonals = true
	self.melee_attacking = false

end

function RoyalRoamer:get_palette()
	local palette = self.palette
	if self.world then
		palette:set_color(2, Palette.roamer:tick_color(self.world.tick / 2))
	end
	return palette, 0
end

function RoyalRoamer:get_sprite()

    if (self.roaming or self.tick % 2 == 0) and iflicker(self.tick, 3, (self.roaming and 2 or 17)) then
		return (iflicker(self.random_offset + self.roam_elapsed, self.walk_frequency, 2) and textures.enemy_royalroamer3 or textures.enemy_royalroamer4)
    end


	if self.outline_flash then
		return (iflicker(self.random_offset + self.roam_elapsed, self.walk_frequency, 2) and textures.enemy_royalroamer1 or textures.enemy_royalroamer2)
	end
	
	return (iflicker(self.random_offset + self.roam_elapsed, self.walk_frequency, 2) and textures.enemy_royalroamer5 or textures.enemy_royalroamer6)
end


local MOVE_RADIUS = 90
local PLAYER_TOO_CLOSE_RADIUS = 24

function RoyalRoamer:update(dt)
    RoyalRoamer.super.update(self, dt)

    if self._roaming then
        self.roaming = true
	end

	if not self.any_player then 
		self:ref("any_player", self:get_random_player())
	end

    if not self.roaming and self.any_player and self.any_player.moving and self.is_new_tick and rng:percent(8) then
        self.roaming = true
    elseif self.roaming and (not self.any_player or not self.any_player.moving) then
        -- self.roaming = false
        self:unref("any_player")
    end
	
	if self.any_player then
		if self.any_player.state == "Hover" then
			self.walk_speed = self.any_player.hover_vel:magnitude() * self.base_walk_speed
		else
			self.walk_speed = self.any_player.move_vel:magnitude() * self.base_walk_speed
		end
        self.walk_speed = clamp(self.walk_speed, 0.1, 1.5)
    else
		self.roaming = self._roaming
		self.walk_speed = 0.5
	end

    if self.is_new_tick then
		self.outline_flash = rng:percent(25)
	end

    if self.roaming then
        if self:get_stopwatch("wait_stopwatch") then
            self:stop_stopwatch("wait_stopwatch")
        end
        self.roam_elapsed = self.roam_elapsed + dt * (self.walk_speed / self.base_walk_speed)
    else
        if not self:get_stopwatch("wait_stopwatch") then
            self:start_stopwatch("wait_stopwatch")
        end
    end
	
    if self.is_new_tick and self.tick > 120 and rng:percent(0.5) and not self.roaming and not self:is_tick_timer_running("roam_cooldown") then
        local bx, by = self:get_body_center()
        local rx, ry, rw, rh = bx - MOVE_RADIUS, by - MOVE_RADIUS, MOVE_RADIUS * 2, MOVE_RADIUS * 2
        self.world.game_object_grid:each_self(rx, ry, rw, rh, self.roam_a_bit, self)
        if not self.roaming and not self.player_too_close then
            if rng:percent(min(0.1 + self.elapsed * 0.02, 10)) then
                self:start_short_roam()
            end
        end
		self.player_too_close = false
    end
	self.melee_attacking = self.roaming
end


function RoyalRoamer.roam_a_bit(object, self)
    if self.roaming then return end
	if self.player_too_close then return end
	if not object.is_player then return end
	local bx, by = self:get_body_center()
    local px, py = object:get_body_center()

	local dist = vec2_distance_squared(bx, by, px, py)

	if dist < PLAYER_TOO_CLOSE_RADIUS * PLAYER_TOO_CLOSE_RADIUS then
		self.player_too_close = true
		return
	end

    if dist < MOVE_RADIUS * MOVE_RADIUS then
		self:start_short_roam()
	end
end

function RoyalRoamer:start_short_roam()
	self._roaming = true
	self:start_tick_timer("roam_timer", rng:randi(5, 70 + min(self.elapsed * 0.05, 90)), function()
		self._roaming = false
		self:start_tick_timer("roam_cooldown", rng:randi(5, 70))
	end)
end


function RoyalRoamer:floor_draw()
    if not self.is_new_tick then return end
	if self.roaming and self.tick % self.walk_frequency == 0 then
        local dx
        if iflicker(self.tick, self.walk_frequency, 2) then
            dx = -3
        else
            dx = 3
        end
        local length = 1

        local shade = 0.0
        graphics.set_color(shade, shade, shade)
        graphics.line(dx - length * 0.5, 0, dx + length * 0.5, 0)
    elseif not self.roaming then 
        local stopwatch = self:get_stopwatch("wait_stopwatch")
		if stopwatch then
            local size = clamp01(stopwatch.elapsed / 500) * 40
			graphics.set_color(Color.black)
			graphics.rectangle_centered("fill", 0, 0, size, size * (6 / 7))
		end
	end
end

-- function RoyalRoamer:collide_with_terrain()
	
-- end

return { Roamer, Roamsploder, RoyalRoamer }
