local PrayerKnotChargeBullet = require("obj.Player.Bullet.BasePlayerBullet"):extend("PrayerKnotChargeBullet")

local PrayerKnotChargeBulletDeathEffect = Effect:extend("PrayerKnotChargeBulletDeathEffect")

PrayerKnotChargeBullet.h_offset = 18
PrayerKnotChargeBullet.shoot_sfx = "player_prayer_knot_shoot"
PrayerKnotChargeBullet.shoot_sfx_volume = 0.8

function PrayerKnotChargeBullet:new(x, y, extra_bullet)
    self.use_artefacts = true
    self.use_upgrades = true

    self.radius = 10
    self.hit_vel_multip = 100
    self.push_modifier = 2.35
    -- self.die_on_hit = false
    PrayerKnotChargeBullet.super.new(self, x, y)
    
    self.speed = self.speed * 1.25
    -- self.lifetime = self.lifetime / (1.25)

    self.damage = 6 + game_state.upgrades.damage
    if extra_bullet then
        self.radius = 5
        self.damage = 1.5 + game_state.upgrades.damage * 0.5
    end
 
    self.hp = 1 + min(1, game_state.upgrades.range)
    self.trail_particles = {}
    self.trail_particles_to_remove = {}
end

function PrayerKnotChargeBullet:enter()
   if self.extra_bullet then
      self:move(self.direction.x * 10, self.direction.y * 10)
   end
   self.start_x, self.start_y = self.pos.x, self.pos.y
end

function PrayerKnotChargeBullet:on_hit_blocking_objects_this_frame()
    self.hp = self.hp - 1
    if self.hp <= 0 then
        if not self:is_timer_running("stop_hitting") then
            self:start_timer("stop_hitting", 3, function()
                self:die()
            end)
        end
    end
end

function PrayerKnotChargeBullet:update(dt)
    PrayerKnotChargeBullet.super.update(self, dt)
    if self.dead then
        if table.is_empty(self.trail_particles) then
            self:queue_destroy()
            return
        end
    end

    if self.is_new_tick and rng:percent(self.radius * 10) and not self.dead then
        -- for i =  do
        local x, y = rng:random_vec2_times(rng:randf(0, self.radius))
        local particle = {
            x = self.pos.x + x,
            y = self.pos.y + y,
            dx = self.direction.x,
            dy = self.direction.y,
            random_offset = rng:randi(),
            lifetime = rng:randf(10, 50),
            t = 0.0,
        }
        table.insert(self.trail_particles, particle)
        -- end
    end

    for i = #self.trail_particles, 1, -1 do
        local particle = self.trail_particles[i]
        local speed = self.speed * 0.15
        particle.x = particle.x + particle.dx * dt * speed
        particle.y = particle.y + particle.dy * dt * speed
        particle.t = particle.t + dt / particle.lifetime
        if particle.t >= 1 then
            table.insert(self.trail_particles_to_remove, particle)
        end
    end

    for i = #self.trail_particles_to_remove, 1, -1 do
        local particle = self.trail_particles_to_remove[i]
        table.erase(self.trail_particles, particle)
    end

    table.clear(self.trail_particles_to_remove)
end

function PrayerKnotChargeBullet:die()
    self.dead = true
    self:spawn_object(PrayerKnotChargeBulletDeathEffect(self.pos.x, self.pos.y, self.radius))
    self:play_sfx("player_prayer_knot_bullet_die", 0.8)
end

function PrayerKnotChargeBullet:draw()
    if self.tick < 5 then
        graphics.set_color(Color.white)
        local size = self.radius * (4 - self.elapsed * 0.25)
        local x, y = self:to_local(self.start_x, self.start_y)
        graphics.rectangle_centered("fill", x, y, size, size)
        -- graphics.translate(self.direction.x * size, self.direction.y * size)
        -- graphics.rectangle_centered("fill", 0, 0, size, size)
    end

    if not self.dead then
        local color = iflicker(self.tick, 2, 2) and Color.cyan or Color.yellow
        graphics.set_color(color)
        local sqrt2 = sqrt(2)
        graphics.push("all")
        graphics.rectangle_centered("line", 0, 0, self.radius * 2 + 3, self.radius * 2 + 3)
        graphics.rectangle_centered("fill", 0, 0, self.radius * 2, self.radius * 2)
        graphics.translate(-self.direction.x * self.radius, -self.direction.y * self.radius)
        graphics.rectangle_centered("fill", 0, 0, self.radius * 2 * 1 / sqrt2, self.radius * 2 * 1 / sqrt2)
        graphics.pop()
        graphics.set_color(Color.white)
        graphics.push("all")
        graphics.rectangle_centered("fill", 0, 0, self.radius * 2 - 4, self.radius * 2 - 4)
        graphics.translate(-self.direction.x * self.radius, -self.direction.y * self.radius)
        graphics.rectangle_centered("fill", 0, 0, self.radius * 2 * 1 / sqrt2 - 4, self.radius * 2 * 1 / sqrt2 - 4)
        -- graphics.rotate(tau / 8)
        graphics.pop()
    end
    for _, particle in ipairs(self.trail_particles) do
        local color = iflicker(self.tick + particle.random_offset, 2, 2) and Color.cyan or Color.yellow
        graphics.set_color(color)
        local x, y = self:to_local(particle.x, particle.y)
        local size = self.radius * 0.85 * (1 - particle.t)
        graphics.rectangle_centered("fill", x, y, size, size)
    end
end

function PrayerKnotChargeBulletDeathEffect:new(x, y, radius)
    PrayerKnotChargeBulletDeathEffect.super.new(self, x, y)
    self.radius = radius
    self.duration = 6
end

function PrayerKnotChargeBulletDeathEffect:draw(elapsed, tick, t)
    if tick < 5 then
        graphics.set_color(Color.white)
        local size = self.radius * (4 - elapsed * 0.25)
        graphics.rectangle_centered("fill", 0, 0, size, size)
        -- graphics.translate(self.direction.x * size, self.direction.y * size)
        -- graphics.rectangle_centered("fill", 0, 0, size, size)
    end

    local color = iflicker(tick, 2, 2) and Color.cyan or Color.yellow
    graphics.set_color(color)
    local size = self.radius * 2 + 3 + 64 * ease("outCubic")(t) * (self.radius / 10)
    graphics.rectangle_centered("line", 0, 0, size, size)

end


return PrayerKnotChargeBullet
