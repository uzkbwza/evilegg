local Evader = BaseEnemy:extend("Evader")
local EvaderParticle = GameObject2D:extend("EvaderParticle")
local EvaderBullet = BaseEnemy:extend("EvaderBullet")
local HeavyEvader = Evader:extend("HeavyEvader")
local HeavyEvaderDeathBullet = EvaderBullet:extend("HeavyEvaderDeathBullet")

Evader.max_hp = 1
HeavyEvader.max_hp = 2

HeavyEvader.trail_color = Color.red
HeavyEvader.heavy_evader = true

local EVADE_SPEED = 2.0
local SEARCH_RADIUS = 48
local DASH_SPEED = 0.5
local RETREAT_SPEED = 0.25
local BULLET_SPEED = 2.5
local BULLET_COUNT = 7
local DEATH_BULLET_SPEED = 1.0
local SHOOT_FREQUENCY = 3

local physics_limits = {
    max_speed = 3,
}

function Evader:new(x, y)
    Evader.super.new(self, x, y)

    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.hurt_bubble_radius = 6
    self.declump_radius = 6
    self.bullet_push_modifier = 1.5
    self.walk_speed = 0.01
    self.drag = 0.05
    self.walk_frequency = 1
    self.roam_chance = 0
    self.back_away_distance = 100
    self.any_bullets_nearby = false
    self.dash_direction = 1
    self.average_bullet_dx = 0
    self.average_bullet_dy = 0
    self.average_bullet_x = 0
    self.average_bullet_y = 0
    self.shoot_chance = 2
    self.num_bullets = 0
    self:make_bouncy()
    self:set_physics_limits(physics_limits)
    self:start_tick_timer("shoot_cooldown", rng:randf(60, 180))
end

function Evader:enter()
    local object = self:spawn_object(EvaderParticle(self.pos.x, self.pos.y, self.trail_color)):ref("parent", self)

end

function Evader:update(dt)
    Evader.super.update(self, dt)
    local pbx, pby = self:closest_last_player_body_pos()
    local bx, by = self:get_body_center()
    local dx, dy = vec2_direction_to(bx, by, pbx, pby)

    local backing_away = false

    if vec2_distance(bx, by, pbx, pby) < 48 then
        self:apply_force(dx * -RETREAT_SPEED, dy * -RETREAT_SPEED)
        backing_away = true
    else
        self:apply_force(dx * self.walk_speed, dy * self.walk_speed)
    end

    self.num_bullets = 0
    self.average_bullet_x = 0
    self.average_bullet_y = 0
    self.average_bullet_dx = 0
    self.average_bullet_dy = 0

    local rx, ry, rw, rh = bx - SEARCH_RADIUS, by - SEARCH_RADIUS, SEARCH_RADIUS * 2, SEARCH_RADIUS * 2
    self.world.bullet_grid:each_self(rx, ry, rw, rh, self.process_nearby_bullets, self)


    local num_bullets = self.num_bullets
    local center_x = self.average_bullet_x / num_bullets
    local center_y = self.average_bullet_y / num_bullets
    local average_dx = self.average_bullet_dx / num_bullets
    local average_dy = self.average_bullet_dy / num_bullets

    if num_bullets > 0 then
        if not (center_x == bx and center_y == by) then
            local cdx, cdy = vec2_direction_to(bx, by, center_x, center_y)
            local ratio = (1 - min(1, vec2_distance(bx, by, center_x, center_y) / SEARCH_RADIUS))
            local speed = EVADE_SPEED * pow(ratio, 3)
            local dash_dx, dash_dy = vec2_rotated(average_dx, average_dy, rng:rand_sign() * tau / 4)
            if vec2_dot(dash_dx, dash_dy, cdx, cdy) < 0 then
                dash_dx = -dash_dx
                dash_dy = -dash_dy
            end

            -- print(ratio)
            if not self:is_tick_timer_running("dash_cooldown") then
                self:apply_impulse(dash_dx * -DASH_SPEED, dash_dy * -DASH_SPEED)
                -- self:apply_impulse(dx * -DASH_SPEED, dy * -DASH_SPEED)
                self:play_sfx("enemy_evader_evade", 0.7)
                self:start_tick_timer("dash_cooldown", rng:randf(10, 25))
            end
            self:apply_force(dash_dx * -speed, dash_dy * -speed)
        end
    end

    self.any_bullets_nearby = num_bullets > 0

    self:ref_bongle_clear("nearby_bullets")

    if self.tick > 60 and self.world.timescaled.is_new_tick and rng:percent(self.shoot_chance) and self:can_shoot() and self.world.timescaled.tick % SHOOT_FREQUENCY == 0 and not self:is_tick_timer_running("dash_cooldown") then
        self:shoot(dx, dy)
        self:start_tick_timer("shoot_cooldown", 120)
    end
end

function Evader:can_shoot(allow_backing_away)
    return self.heavy_evader or (not self:is_tick_timer_running("shoot_cooldown") and (allow_backing_away or not self.backing_away))
end

function Evader:shoot(dx, dy)
    local s = self.sequencer
    local bx, by = self:get_body_center()

    s:start(function()
    for i = 1, BULLET_COUNT do
        if not self:can_shoot(true) then return end
            self:play_sfx("enemy_evader_shoot", 0.5)
            local bullet = self:spawn_object(EvaderBullet(bx, by))
            bullet:apply_impulse(dx * BULLET_SPEED, dy * BULLET_SPEED)
            s:wait(SHOOT_FREQUENCY)
            bullet.heavy = self.heavy_evader
        end
    end)
end

function Evader.process_nearby_bullets(bullet, self)
    if self:bullet_in_search(bullet) and not bullet.dead then
       self.num_bullets = self.num_bullets + 1
       self.average_bullet_x = self.average_bullet_x + bullet.pos.x
       self.average_bullet_y = self.average_bullet_y + bullet.pos.y
       self.average_bullet_dx = self.average_bullet_dx + bullet.direction.x
       self.average_bullet_dy = self.average_bullet_dy + bullet.direction.y
    end
end

function Evader:get_palette()
    return nil, self:is_tick_timer_running("dash_cooldown") and self.tick / 2 or 0
end


function Evader:bullet_in_search(bullet)
    local bx, by = self:get_body_center()
    local bullet_x1, bullet_y1, bullet_x2, bullet_y2, bullet_r = bullet:get_capsule()
    if circle_capsule_collision(bx, by, SEARCH_RADIUS, bullet_x1, bullet_y1, bullet_x2, bullet_y2, bullet_r) then
        return true
    end
    return false
end
function Evader:get_sprite()
    return iflicker(self.tick, 5, 2) and textures.enemy_evader1 or textures.enemy_evader2
end

function EvaderParticle:new(x, y, color)
    EvaderParticle.super.new(self, x, y)
    -- self:set_sprite(textures.enemy_evader_particle)
    self:add_elapsed_ticks()
    self.particles = batch_remove_list()
    self.z_index = -1
    self.color = color
end


function EvaderParticle:update(dt)
    EvaderParticle.super.update(self, dt)
    for i, particle in (self.particles:ipairs()) do
        particle.elapsed = particle.elapsed + dt
        if particle.elapsed > particle.lifetime then
            self.particles:queue_remove(particle)
        end
    end
    self.particles:apply_removals()

    if self.parent then 
        self:move_to(self.parent.pos.x, self.parent.pos.y)
    elseif self.particles:is_empty() then
        self:queue_destroy()
    end

    if self.is_new_tick and self.tick % 5 == 0 and self.parent then
        local particle = {
            x = self.pos.x,
            y = self.pos.y,
            elapsed = 0,
            lifetime = 30,
        }
        self.particles:push(particle)
    end

end

function EvaderParticle:draw()
    for i, particle in (self.particles:ipairs()) do
        if (gametime.tick + i) % 2 == 0 then
            local scale = 1 - particle.elapsed / particle.lifetime
            local size = 8 * scale
            local x, y = self:to_local(particle.x, particle.y)
            graphics.set_color(self.color or Color.magenta)
            graphics.rectangle_centered("line", x, y, size, size)
        end
    end
end


function EvaderBullet:new(x, y)
	self.max_hp = 1

    EvaderBullet.super.new(self, x, y)
    self.enemy_bullet_can_touch_walls = true
    self.drag = 0.0
    self.hit_bubble_radius = 1
	self.hurt_bubble_radius = 3
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self.z_index = 10
    self.bounces_left = 2

end


function EvaderBullet:on_terrain_collision(normal_x, normal_y)
    if self.bounces_left > 0 then
        self:terrain_collision_bounce(normal_x, normal_y)
    else
        self:die()
    end
    self.bounces_left = self.bounces_left - 1
end

function EvaderBullet:get_sprite()
    -- if self.heavy then
    --     return iflicker(self.tick, 3, 2) and textures.enemy_heavy_evader_bullet1 or textures.enemy_heavy_evader_bullet2
    -- end
    return iflicker(self.tick, 3, 2) and textures.enemy_evader_bullet1 or textures.enemy_evader_bullet2
end

function EvaderBullet:get_palette()
	return nil, self.tick / 3
end

function EvaderBullet:update(dt)
end

function HeavyEvader:new(x, y)
    HeavyEvader.super.new(self, x, y)
    self.hit_bubble_radius = 7
    self.shoot_chance = 4
    self.walk_speed = 0.06
end

function HeavyEvader:get_sprite()
    return iflicker(self.tick, 5, 2) and textures.enemy_heavy_evader1 or textures.enemy_heavy_evader2
end

function HeavyEvader:die()
    -- local NUM_BULLETS = 24
    -- for i = 1, NUM_BULLETS do
    --     local bx, by = self:get_body_center()
    --     local bullet = self:spawn_object(HeavyEvaderDeathBullet(bx, by))
    --     local dx, dy = vec2_from_polar(DEATH_BULLET_SPEED, i / NUM_BULLETS * tau)
    --     bullet:apply_impulse(dx, dy)
    -- end
    HeavyEvader.super.die(self)
end

function HeavyEvaderDeathBullet:new(x, y)
    HeavyEvaderDeathBullet.super.new(self, x, y)
    self.intangible = true
    self.melee_attacking = false
    self:start_tick_timer("intangible_cooldown", 3, function()
        self.intangible = false
        self.melee_attacking = true
    end)
    self.hurt_bubble_radius = 4
    self.hit_bubble_radius = 3
end

function HeavyEvaderDeathBullet:get_sprite()
    return textures.enemy_heavy_evader_death_bullet
end



-- function HeavyEvader:get_palette()
--     return nil, self.tick / 3
-- end


return { Evader, HeavyEvader }
