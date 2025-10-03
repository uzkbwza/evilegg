local RingOfLoyaltyBurst = GameObject2D:extend("RingOfLoyaltyBurst")
local DeathFloorParticle = GameObject2D:extend("DeathFloorParticle")

local BASE_IMPULSE = 8.0
local BASE_FORCE = 0.45
local PUSH_SPEED = 10
local BASE_RADIUS = 60

local ring_of_loyalty_rumble_func = function(t)
    return 0.5 * (1 - t)
end

function RingOfLoyaltyBurst:new(x, y)
    RingOfLoyaltyBurst.super.new(self, x, y)

    self:add_time_stuff()
    self.radius = BASE_RADIUS + game_state.upgrades.range * 4
    self.damage = 1.5 + game_state.upgrades.damage * 1
    self.force_modifier = 1 + game_state.upgrades.bullet_speed * 0.15
    self.lifetime = 10 + game_state.upgrades.range * 2
    self:start_destroy_timer(self.lifetime)
    self.z_index = -10
    self.center_out_velocity_multiplier = 2.0
    self:ref_bongle("pushed_objects")
end

function RingOfLoyaltyBurst:enter()
    self:spawn_object(DeathFloorParticle(self.pos.x, self.pos.y, self:get_radius()))
    input.start_rumble(ring_of_loyalty_rumble_func, 10)
end

function RingOfLoyaltyBurst:get_radius()
    return self.radius + self.elapsed * (5.5 + game_state.upgrades.range * 0.25)
end

function RingOfLoyaltyBurst:get_death_particle_hit_velocity(other)
    local bx, by = other.pos.x, other.pos.y
    if other.get_body_center then
        bx, by = other:get_body_center()
    end
    local dx, dy = vec2_direction_to(self.pos.x, self.pos.y, bx, by)
    local dist = vec2_distance(self.pos.x, self.pos.y, bx, by)
    local dist_modifier = remap01(dist / self:get_radius(), 1, 0.75)
    local time_modifier = remap01(clamp01(self.elapsed / self.lifetime), 1.0, 0.95)
    return dx * 40 * dist_modifier * time_modifier, dy * 40 * dist_modifier * time_modifier
end

function RingOfLoyaltyBurst:get_death_particle_hit_point(other)
    local bx, by = other.pos.x, other.pos.y
    if other.get_body_center then
        bx, by = other:get_body_center()
    end
    local diff_x, diff_y = vec2_sub(bx, by, self.pos.x, self.pos.y)
    return vec2_add(bx, by, vec2_limit_length(-diff_x, -diff_y, 16))
end

function RingOfLoyaltyBurst:update(dt)
    -- if self.tick < 3 then
    local radius = self:get_radius()
    local x, y, w, h = self.pos.x - radius, self.pos.y - radius, radius * 2, radius * 2
    self.world.game_object_grid:each_self(x, y, w, h, self.affect_object, self, dt)
    -- end
end

function RingOfLoyaltyBurst:debug_draw()
    if debug:can_draw_bounds() then
        graphics.set_color(Color.red)
        graphics.circle("line", 0, 0, self:get_radius(), 32)
    end
end

function RingOfLoyaltyBurst:draw()

    if self.tick < 3 then
        graphics.set_color(Color.grey)
        graphics.poly_regular("fill", 0, 0, self:get_radius() * 0.6, 10, 0)
    end
    -- if not self.is_new_tick then
        -- return
    -- end
    -- if gametime.tick % 2 == 0 then return end
    local color_mod = remap01_lower(pow(1.0 - clamp01(self.elapsed / self.lifetime), 1.5), 0.125)
    
        local color = Color.grey
        -- graphics.rotate((self.elapsed / tau) * 0.25)
        -- graphics.set_color(Color.white)
        -- graphics.circle("line", 0, 0, self:get_radius() + self.elapsed * 2.0, 10)
        -- graphics.circle("line", 0, 0, self:get_radius() + self.elapsed * 2.0 - 2, 10)
        graphics.set_color(color.r * color_mod, color.g * color_mod, color.b * color_mod)
        graphics.set_line_width(1)
        graphics.poly_regular("line", 0, 0, self:get_radius() + self.elapsed * 2.0, 10, (self.elapsed / tau) * 0.25)
end

function RingOfLoyaltyBurst:filter_object(obj)
    if not obj.is_base_enemy then
        return false
    end

    if obj.intangible then return false end

    if obj.is_egg_boss or obj.is_egg_wrath or obj.is_egg_sentry then
        return false
    end
    return true
end

function RingOfLoyaltyBurst:exit()
    self:spawn_object(DeathFloorParticle(self.pos.x, self.pos.y, self:get_radius(), false))
end

function RingOfLoyaltyBurst.affect_object(obj, self, dt)
    if self:filter_object(obj) then
        local radius = self:get_radius()
        local x, y = obj.pos.x, obj.pos.y
        if obj.get_body_center then
            x, y = obj:get_body_center()
        end
        local dist = vec2_distance_squared(self.pos.x, self.pos.y, x, y)
        if dist <= radius * radius then
            dist = sqrt(dist)
            local dx, dy = vec2_direction_to(self.pos.x, self.pos.y, x, y)

            local min_dist = radius * 0.8

            if dist < min_dist then
                local diff = min_dist - dist
                local mod = max(0.5, obj.bullet_push_modifier or 1)
                local push_speed = PUSH_SPEED * (1 - self.elapsed / (self.lifetime)) * mod
                -- obj:move_to(splerp_vec(obj.pos.x, obj.pos.y, x + dx * diff, y + dy * diff, 30, dt))
                if not obj.is_fungus then
                    obj:move(dx * min(push_speed * dt, diff), dy * min(push_speed * dt, diff))
                    if obj.apply_force then
                        obj:apply_force(dx * BASE_FORCE, dy * BASE_FORCE)
                    end
                end
            end

            if not self.pushed_objects:has(obj) and self.tick <= 10 then
                self:ref_bongle_push("pushed_objects", obj)
                local dist_modifier = remap01(dist / radius, 1, 0.5)
                local time_modifier = remap01(clamp01(self.elapsed / self.lifetime), 1.0, 0.25)
                local mod = BASE_IMPULSE * self.force_modifier * dist_modifier * time_modifier
                if obj.apply_impulse then
                    obj:apply_impulse(dx * mod, dy * mod)
                end
                obj:hit_by(self)
            end
        end
    end
end

function RingOfLoyaltyBurst:get_damage(target)
    -- local dist = vec2_distance(self.pos.x, self.pos.y, target.pos.x, target.pos.y)
    -- local dist_modifier = remap_clamp((dist / BASE_RADIUS), 0, 1, 1, 0.5)
    dist_modifier = 1
    local damage = (self.damage * dist_modifier)
    -- print("burst damage", damage)
    return damage
end

function DeathFloorParticle:new(x, y, radius, draw_circle)
    DeathFloorParticle.super.new(self, x, y)
    self:add_time_stuff()
    self.particles = {}
    self.draw_circle = truthy_nil(draw_circle)
    self.radius = radius
    for i = 1, 0.1 * (tau * radius) do
        local x, y = rng:random_vec2_times(radius)
        local vel_x, vel_y = vec2_normalized_times(x, y, rng:randf(1, 10))
        local particle = {
            x = x,
            y = y,
            vel_x = vel_x,
            vel_y = vel_y,
            prev_x = x,
            prev_y = y,
        }
        table.insert(self.particles, particle)
    end
end

function DeathFloorParticle:update(dt)
    local any_have_vel = false
    for i, particle in ipairs(self.particles) do
        particle.prev_x, particle.prev_y = particle.x, particle.y
        particle.x = particle.x + particle.vel_x * dt
        particle.y = particle.y + particle.vel_y * dt
        particle.vel_x, particle.vel_y = vec2_drag(particle.vel_x, particle.vel_y, 0.3, dt)
        if vec2_magnitude_squared(particle.vel_x, particle.vel_y) > (0.1 * 0.1) then
            any_have_vel = true
        end
    end
    if not any_have_vel then
        self:queue_destroy()
    end
end

function DeathFloorParticle:floor_draw()
    -- graphics.set_color(Color.darkergrey)
    graphics.set_color(Color.darkergrey)
    if self.draw_circle and self.tick == 2 and self.is_new_tick then
        graphics.circle("line", 0, 0, self.radius - 2, 16)
    end
    -- if not self.is_new_tick then return end
    for i, particle in ipairs(self.particles) do
        if vec2_magnitude_squared(particle.vel_x, particle.vel_y) > (0.1 * 0.1) then
            graphics.line(particle.prev_x, particle.prev_y, particle.x, particle.y)
        end
    end
end


return RingOfLoyaltyBurst
