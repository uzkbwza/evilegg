local EggWrath = BaseEnemy:extend("EggWrath")
local EggWrathParticle = GameObject2D:extend("EggWrathParticle")

local WRATH_RADIUS = 35

local STARTUP_TIME = 40

local LIGHTNING_HEIGHT = 500
local LIGHTNING_RESOLUTION = 100

local INDICATOR_HEIGHT_RATIO = 1

EggWrath.is_egg_wrath = true


function EggWrath:new(x, y)
    EggWrath.super.new(self, x, y)
    self.intangible = true
    self.applying_physics = false
    self.melee_both_teams = true
    self.body_height = 0
    -- self.hit_bubble_radius = WRATH_RADIUS
    self.melee_attacking = false
    self.beam_width_t = 0
    self.hit_bubble_radius = 0
    self.hit_bubble_damage = 10
    self.startup = true
    self:add_tag_on_enter("egg_wrath")
    self.lightning_line = {}
    self.z_index = 2
    local x_offs = 0
    local y_offs = 0
    for i = 1, LIGHTNING_RESOLUTION do
        table.insert(self.lightning_line,
            x_offs
        )
        table.insert(self.lightning_line,
            y_offs
        )
        if i % 2 == 0 then
            x_offs = stepify(rng:randfn(0, WRATH_RADIUS / 2), 8.0)
        else
            y_offs = -(i - 1) * (LIGHTNING_HEIGHT / LIGHTNING_RESOLUTION)
        end
    end
    self.lightning_line_size = LIGHTNING_RESOLUTION * 2
    self:start_destroy_timer(400)
end

function EggWrath:enter()
    self:play_sfx("enemy_egg_wrath_startup", 0.7)
    self:interpolate_property_between_times("beam_width_t", 0, 1, 0, STARTUP_TIME)
    self:start_tick_timer("startup", STARTUP_TIME, function()
        self.melee_attacking = true
        local height = WRATH_RADIUS * INDICATOR_HEIGHT_RATIO
        local dist = WRATH_RADIUS - height
        if dist > 0 then
            self:add_hit_bubble(-dist / 2, 0, height, "main", self.hit_bubble_damage, dist / 2, 0)
        else
            self:add_hit_bubble(0, 0, height, "main", self.hit_bubble_damage)
        end
        self.startup = false
        self:start_stopwatch("lightning")
        self:spawn_object(EggWrathParticle(self.pos.x, self.pos.y))
        self.world.camera:start_rumble(4, 30, nil, false, true)
        self:play_sfx("enemy_egg_wrath_blast", 1)
        self:stop_sfx("enemy_egg_wrath_startup")
    end)
    self:start_tick_timer("hurt_bubble", STARTUP_TIME + 2, function()
        self:remove_hit_bubble("main")
        self.melee_attacking = false
    end)
    
end

function EggWrath:update(dt)
    local stopwatch = self:get_stopwatch("lightning")
    if stopwatch then
        for i=1, self.lightning_line_size, 2 do
            local sign = sign1(self.lightning_line[i])
            self.lightning_line[i] = self.lightning_line[i] + sign * dt * max(0.7 - stopwatch.elapsed * 0.02, 0.1)
        end
    end
end

function EggWrath:filter_melee_attack(bubble)
    if bubble.parent.is_egg_tree then
        return false
    end
    if bubble.parent.is_egg_sentry then
        return false
    end
    return true
    -- return EggWrath.super.filter_melee_attack(self, bubble)

end

function EggWrath:die()
    self:queue_destroy()
end

local INDICATOR_SIDES = 6

function EggWrath:draw()
    graphics.push("all")
    -- local indicator_rotation = self.random_offset - self.elapsed * 0.165 * (self.random_offset % 2 == 0 and 1 or -1)
    local indicator_rotation = 0
    local wrath_color = Palette.egg_wrath_shine:tick_color(self.tick, 0, 1)
    local wrath_color2 = Palette.egg_wrath_shine2:tick_color(self.tick, 0, 1)
    -- local indicator_radius = WRATH_RADIUS
    local indicator_radius = lerp(inradius(WRATH_RADIUS, INDICATOR_SIDES), WRATH_RADIUS, 0.5)
    if self.startup then
        local floor_indicator_width = indicator_radius * 2 * (ease("outExpo")(self.beam_width_t)) * 1.2
        if gametime.tick % 2 == 0 then
            for i=1, 1 do
            graphics.set_color(Color.black)
            graphics.set_line_width(6)
            graphics.poly_regular("line", 0, 0, floor_indicator_width/2 - ((i) * 1), INDICATOR_SIDES, indicator_rotation, 1, INDICATOR_HEIGHT_RATIO)
            graphics.set_color(wrath_color2)
            graphics.set_line_width(4)
            graphics.poly_regular("line", 0, 0, floor_indicator_width/2 - ((i) * 1), INDICATOR_SIDES, indicator_rotation, 1, INDICATOR_HEIGHT_RATIO)
            end
        end
        local beam_width = WRATH_RADIUS * (1 - ease("inOutCubic")(self.beam_width_t)) * 2 + 2
        graphics.set_color(wrath_color)
        -- graphics.circle("fill", 0, 0, beam_width / 2)
        local height = 1000 * (ease("inOutCubic")(self.beam_width_t))
        if (self.random_offset + gametime.tick) % 2 == 0 then
            graphics.rectangle("fill", -beam_width / 2, -height, beam_width, height)
        end
    else
        local stopwatch = self:get_stopwatch("lightning")
        if stopwatch then
            local elapsed = stopwatch.elapsed
            local extra_t = 1 - ease("outCubic")(clamp(elapsed / 30, 0, 1))

            if elapsed < 15 or floor(elapsed) % 2 == 0 then
                graphics.set_color(wrath_color)
                if elapsed < 6 then
                    local floor_indicator_width = indicator_radius * 2 + elapsed
                    graphics.set_line_width(2)
                    graphics.rectangle_centered(elapsed < 4 and "fill" or "line", 0, 0, floor_indicator_width, floor_indicator_width * INDICATOR_HEIGHT_RATIO)
                end

                graphics.set_color(wrath_color2)
                graphics.set_line_width(round(max(elapsed < 30 and 1 or 0, 6 - elapsed * 0.35 + extra_t * 15)))
                graphics.line(self.lightning_line)
                graphics.set_color(wrath_color)
                graphics.set_line_width(round(max(0, 3 - elapsed * 0.42 + extra_t * 18)))
                graphics.line(self.lightning_line)
            end
        end
    end
    graphics.pop()
end

function EggWrathParticle:new(x, y)
    EggWrathParticle.super.new(self, x, y)
    self.z_index = -1
    self.particles = batch_remove_list()
    for i = 1, 100 do
        local x, y = rng:randf(-WRATH_RADIUS, WRATH_RADIUS), rng:randf(-WRATH_RADIUS, WRATH_RADIUS)
        y = y * INDICATOR_HEIGHT_RATIO
        local dx, dy = vec2_normalized(x, y)
        local speed = rng:randf(1, 3)
        local particle = {
            x = x,
            y = y,
            vel_x = dx * speed,
            vel_y = dy * speed,
            speed = speed,
            color = Palette.egg_wrath_shine2:get_color(rng:randi()),
            size = rng:randi(1, 4),
        }
        self.particles:push(particle)
    end
    self:add_elapsed_ticks()
end

function EggWrathParticle:update(dt)
    for _, particle in self.particles:ipairs() do
        particle.vel_x, particle.vel_y = vec2_drag(particle.vel_x, particle.vel_y, 0.05, dt)
        particle.x = particle.x + particle.vel_x * dt
        particle.y = particle.y + particle.vel_y * dt
        if vec2_magnitude_squared(particle.vel_x, particle.vel_y) < 0.01 then
            self.particles:queue_remove(particle)
        end
    end

    self.particles:apply_removals()

    if self.particles:is_empty() then
        self:queue_destroy()
    end

end

function EggWrathParticle:draw()
    for _, particle in self.particles:ipairs() do
        graphics.set_color(particle.color)
        local scale = ceil(particle.size * (vec2_magnitude(particle.vel_x, particle.vel_y) / particle.speed))

        graphics.rectangle_centered("fill", particle.x, particle.y, scale, scale)
    end
end

function EggWrathParticle:floor_draw()
    if self.is_new_tick then
        if self.tick == 1 then
            graphics.set_color(Color.black)
            graphics.rectangle_centered("fill", 0, 0, WRATH_RADIUS * 2, WRATH_RADIUS * 2 * INDICATOR_HEIGHT_RATIO)
        end
        for _, particle in self.particles:ipairs() do
            local mod = 0.25
            graphics.set_color(particle.color.r * mod, particle.color.g * mod, particle.color.b * mod)
            local scale = ceil(particle.size * (vec2_magnitude(particle.vel_x, particle.vel_y) / particle.speed))
            graphics.rectangle_centered("fill", particle.x, particle.y, scale, scale)
        end
    end
end



return EggWrath
