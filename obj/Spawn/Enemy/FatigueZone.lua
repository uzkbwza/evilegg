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
end

function FatigueZone:update(dt)
    self:set_size(min(120, self.size + dt * 0.6))
    if not self:is_tick_timer_running("intangible") then       
        for _, player in self:get_players():ipairs() do
            if not player:is_invulnerable() then
                if player:get_hurt_bubble("main"):collides_with_aabb(self.pos.x - self.size * 0.5, self.pos.y - self.size * 0.5, self.size, self.size) then
                    player:start_tick_timer("fatigue", 1)
                end
            end
        end
    end
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
    graphics.set_color(Color.darkpurple)
    graphics.rectangle_centered("fill",0, 0, self.size, self.size)
    -- graphics.set_color(Color.grey)
    -- graphics.rectangle_centered("line",0, 0, self.size, self.size)
end

function FatigueZone:die()
    self:queue_destroy()
end

return FatigueZone
