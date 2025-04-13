local RocketBullet = require("obj.Player.Bullet.BasePlayerBullet"):extend("RocketBullet")
local Explosion = require("obj.Explosion")

RocketBullet.cooldown = 15
RocketBullet.spread = 9
RocketBullet.shoot_sfx = "player_rocket_shoot"
RocketBullet.shoot_sfx_volume = 0.5
RocketBullet.num_bullets_modifier = 0
RocketBullet.h_offset = 2
local PARTICLE_LIFETIME = 30

function RocketBullet:new(x, y, extra_bullet)
    RocketBullet.super.new(self, x, y, extra_bullet)
	self.hit_vel_multip = 40
	self.explosion_damage = self.damage * 2.5
    self.damage = 1
    -- self.random_offset = rng.randi(1, 100)
	self.center_out_velocity_multiplier = 6
    self.particles = {}
    if extra_bullet then
		self.speed = self.speed * 0.9
	end
end

local sprites = {
	textures.player_rocket1,
	textures.player_rocket2,
	textures.player_rocket3,
}

function RocketBullet:draw()
	for i = 1, #self.particles do
		local particle = self.particles[i]
		local x, y = self:to_local(particle.pos.x, particle.pos.y)
		local color = Palette.explosion:interpolate_clamped(particle.t)
		graphics.set_color(color)
        local size = (1 - particle.t) * 8
		if self.extra_bullet then
			size = size * 0.4
		end
		graphics.rectangle_centered(particle.t < 0.25 and "fill" or "line", x, y, size, size)
	end
	if self.stop_drawing then
		return
	end
	local index, rotation, y_scale = get_16_way_from_3_base_sprite(self.direction:angle())
    self.sprite = sprites[index]
    graphics.drawp_centered(self.sprite, nil, idiv(self.tick, 2), 0, 0, rotation, 1, y_scale)
	-- RocketBullet.super.draw(self)
end


function RocketBullet:enter()
	local size = 18 + game_state.upgrades.damage * 5
    if self.extra_bullet then
        size = size * 0.7
    end
    size = size * 0.25
    local params = {
		damage = self.explosion_damage,
		team = "player",
		melee_both_teams = false,
		particle_count_modifier = 0.25,
		-- explode_sfx = "explosion",
        explode_sfx_volume = 0.0,
		size = size,
	}
	self:spawn_object(Explosion(self.pos.x, self.pos.y, params))

end

function RocketBullet:update(dt)
    RocketBullet.super.update(self, dt)
	if self.is_new_tick and not self.stop_drawing then
        local particle = {}
		particle.pos = self.pos:clone()
		particle.t = 0
		table.insert(self.particles, particle)
	end

	for i = #self.particles, 1, -1 do
		local particle = self.particles[i]
        particle.t = particle.t + dt / PARTICLE_LIFETIME 
        if particle.t > 1 then
			table.remove(self.particles, i)
		end
	end
end

function RocketBullet:die()
    -- self:spawn_object(Explosion, self.pos:clone(), self.explosion_damage)
	local size = 18 + game_state.upgrades.damage * 5
    if self.extra_bullet then
        size = size * 0.7
    end
	
	local params = {
		damage = self.explosion_damage,
		team = "player",
		melee_both_teams = false,
		particle_count_modifier = 0.25,
		explode_sfx = "explosion2",
		explode_sfx_volume = 0.9,
		size = size,
	}
	self:spawn_object(Explosion(self.pos.x, self.pos.y, params))
	self.dead_position = self.pos:clone()
	self:start_destroy_timer(PARTICLE_LIFETIME)
	self.stop_drawing = true
end

return RocketBullet

