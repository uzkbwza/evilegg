local FatigueZone = BaseEnemy:extend("FatigueZone")

function FatigueZone:new(x, y)
    FatigueZone.super.new(self, x, y)
    self:add_tag_on_enter("fatigue_zone")
    self.applying_physics = false
    self.melee_attacking = false
    self.size = 1
    self.terrain_collision_radius = 1
    self.z_index = -1000
    self.intangible = true
    self.bullet_passthrough = true
    self:start_tick_timer("intangible", 60, function()
        self.intangible = false
    end)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.damage_taken = 0
    self.particles = batch_remove_list()
end


function FatigueZone:collide_with_terrain()
end

function FatigueZone:update(dt)


    for _, particle in self.particles:ipairs() do
        particle.angle = particle.angle
        local movex, movey = vec2_from_polar(dt * particle.speed, particle.angle)
        particle.x, particle.y = vec2_add(particle.x, particle.y, movex, movey)
        if self.is_new_tick and floor(particle.elapsed) % 10 == 0 then
            particle.target_angle = particle.target_angle + rng:randfn(0, tau / 16)
        end
        particle.angle = splerp_angle(particle.angle, particle.target_angle, 120, dt)
        particle.elapsed = particle.elapsed + dt
        if particle.elapsed > particle.lifetime then
            self.particles:queue_remove(particle)
        end
    end

    self.particles:apply_removals()

    
    if self.dead then
        if self.particles:is_empty() then self:queue_destroy() end
    else
        self:tick_frequency_callback(self.size * 4 * 0.02, self.spawn_particle)
        self:set_size(min(120, self.size + dt * 0.6))
        if not self:is_tick_timer_running("intangible") then
            for _, ally in self:get_allies():ipairs() do
                if not (ally.is_invulnerable and ally:is_invulnerable()) then
                    if ally:get_hurt_bubble("main"):collides_with_aabb(self.pos.x - self.size * 0.5, self.pos.y - self.size * 0.5, self.size, self.size) then
                        ally:start_tick_timer("fatigue", 2)
                        self:start_tick_timer("fatiguing", 2)
                    end
                end
            end
        end
    end

    -- dbg("particles", self.particles:length())
end

function FatigueZone:spawn_particle()
    local x, y = rng:random_point_on_centered_rect_perimeter(0, 0, self.size, self.size)
    local particle = {
        x = x + self.pos.x,
        y = y + self.pos.y,
        angle = vec2_angle(x, y),
        lifetime = rng:randf(10, 40),
        elapsed = 0,
        size = rng:randf(5, 8),
        speed = rng:randf(0.1, 0.25),
        random_offset = rng:randi()
    }
    particle.target_angle = particle.angle
    self.particles:push(particle)
end

function FatigueZone:enter()
    self:add_hurt_bubble(0, 0, self.size, "main", self.size)
end

function FatigueZone:hit_by(object)
    local damage = 0

    if object.is_bubble then
        local bubble = object
        object = object.parent
        damage = (object.get_damage and object:get_damage(self)) or bubble.damage
    else
        damage = (object.get_damage and object:get_damage(self)) or object.damage
    end

    self.damage_taken = self.damage_taken + damage

    -- if damage > 0 then
    --     self:start_timer("damage_flash", 12)
    -- end

    self:set_size(self.size - damage * (1 + self.damage_taken * 0.2))
end

function FatigueZone:on_damaged(amount)
end

function FatigueZone:set_size(size)
    self.size = size
    self:set_hurt_bubble_rect_width_height("main", size, size)
    self.terrain_collision_radius = size * 0.5
    if size <= 0 then 
        self:die()
    end
end

function FatigueZone:draw()
    if gametime.tick % 2 ~= 0 then return end
    graphics.set_color(Color.darkblue)
    -- if self:is_timer_running("damage_flash") then
    --     graphics.set_color(Palette.fatigue_damaged:tick_color(self.tick, 0, 1))
    -- end
    if not self.dead then
        graphics.rectangle_centered("fill", 0, 0, self.size, self.size)
    end
    
    for _, particle in self.particles:ipairs() do
        local x, y = self:to_local(particle.x, particle.y)
        local scale = inverse_lerp(particle.lifetime, 0, particle.elapsed) * particle.size
        graphics.rectangle_centered("fill", x, y, scale, scale)
    end
    -- graphics.set_color(Color.grey)
    -- graphics.rectangle_centered("line",0, 0, self.size, self.size)
end


function FatigueZone:floor_draw()
    if gametime.tick % 2 ~= 0 then return end
    -- if self:is_timer_running("damage_flash") then
    --     graphics.set_color(Palette.fatigue_damaged:tick_color(self.tick, 0, 1))
    -- end
    if not self.dead then
        -- graphics.rectangle_centered("fill", 0, 0, self.size, self.size)
    end
    local mod = 0.6
    
    graphics.set_color(Color.darkblue.r * mod, Color.darkblue.g * mod, Color.darkblue.b * mod)
    
    for _, particle in self.particles:ipairs() do
        if self.is_new_tick and rng:percent(0.5) then
            local x, y = self:to_local(particle.x, particle.y)
            local scale = inverse_lerp(particle.lifetime, 0, particle.elapsed) * particle.size
            graphics.rectangle_centered("fill", x, y, scale, scale)
        end
    end
    -- graphics.set_color(Color.grey)
    -- graphics.rectangle_centered("line",0, 0, self.size, self.size)
end

function FatigueZone:die()
    self:remove_tag("enemy")
    self.dead = true
end

return FatigueZone
