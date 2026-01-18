local Disc = BaseEnemy:extend("Disc")

local RADIUS = 28

local START_HURT_BUBBLE_RADIUS = 7

Disc.max_hp = 13.0
Disc.avoid_player_bullets = true
Disc.is_disc = true
Disc.hurt_sfx = "pickup_barrier_hurt"
Disc.hurt_sfx_volume = 0.25
Disc.death_sfx = "pickup_barrier_death"
Disc.death_sfx_volume = 0.7

function Disc:new(x, y, disc_id, num_discs)
    -- self.max_hp = 1
    Disc.super.new(self, x, y)
    self.team = "player"
    self.radius = 10
    self.speed = 10
    -- self.damage = 1
    self.lifetime = 10
    self.hit_bubble_damage = 1
    self.hit_cooldown = 5
    self.hurt_bubble_radius = 1
    self.hit_bubble_radius = 1
    self.persist = true
    self.disc_id = disc_id
    self.num_discs = num_discs
    self.hitbox_team = "player"
    self.damage_taken = 0
    self.player_distance = 0
end

function Disc:enter_shared(...)
    Disc.super.enter_shared(self, ...)
    self:remove_tag("enemy")
    self:add_tag("move_with_level_transition")

end

function Disc:collide_with_terrain()
    return
end

function Disc:damage(amount, passive)
    if amount > (self.max_hp / 2) then
        amount = self.max_hp / 2
    end
    if self.hp > 1 and self.hp - amount < 1 then
        amount = self.hp - 1
    end
	Mixins.Behavior.Health.damage(self, amount)
end

function Disc:on_damaged(by)
    self:start_tick_timer("invulnerability", 20)
end

function Disc:is_invulnerable()
    return self:is_tick_timer_running("invulnerability") or Disc.super.is_invulnerable(self)
end

function Disc:die(...)
    if self.tick > 2 then
        Disc.super.die(self, ...)
    end
end

function Disc:update(dt)
    local damage_taken = self.max_hp - self.hp
    self.damage_taken = damage_taken

    self.hurt_bubble_radius = START_HURT_BUBBLE_RADIUS
    
    if self.damage_taken >= self.max_hp - 1 then
        self.hurt_bubble_radius = START_HURT_BUBBLE_RADIUS - 2
    end

    self.hit_bubble_radius = self.hurt_bubble_radius - 2
    
    self:set_hurt_bubble_radius("main", self.hurt_bubble_radius)
    self:set_hit_bubble_radius("main", self.hit_bubble_radius)

    self.player_distance = splerp(self.player_distance, RADIUS, 300, dt)

    -- if self.is_new_tick and self.world.draining_bullet_powerup then
        -- if self.hp > 1 then
            -- self:damage((1/seconds_to_frames(15)) * self.max_hp)
        -- end
    -- end

    if self.player then
        -- print("here")
        local can_melee_attack = self.player.state ~= "Cutscene"
        self.melee_attacking = self.player.state ~= "Cutscene"
        self:set_visible(can_melee_attack)
        local bx, by = self.player:get_body_center()
        local ox, oy = vec2_from_polar(self.player_distance, (self.elapsed * 0.12) + ((tau / self.num_discs) * (self.disc_id)))
        -- self:move_to(splerp_vec(self.pos.x, self.pos.y, bx + ox, by + oy, 40, dt))
        self:move_to(bx + ox, by + oy)
    else
        self:queue_destroy()
    end
end

function Disc:get_sprite()
    -- return iflicker(self.tick, 5, 2) and textures.pickup_disc1 or textures.pickup_disc2
    if self.damage_taken >= self.max_hp - 1 then
        return textures.pickup_disc2
    end
    return textures.pickup_disc1
end

function Disc:filter_melee_attack(bubble)
    if not bubble.parent.is_base_enemy then
        return false
    end
    return true
end

function Disc:get_palette()
    -- if self.damage_taken < self.max_hp - 1 and iflicker(gametime.tick + self.disc_id * 10, 10, 2) then
        return nil, floor(self.tick / 3)
    -- end
    -- return nil, 0
end

function Disc:draw()
    -- if (gametime.tick + self.disc_id) % 2 == 0 then
    -- if self:is_tick_timer_running("invulnerability") and (gametime.tick + self.disc_id) % 2 == 0 then
        -- return
    -- end

    -- local r = self.hurt_bubble_radius


    -- -- graphics.rotate(self.elapsed * -0.24)
    -- graphics.set_color(Color.black)
    -- graphics.set_line_width(1)
    -- graphics.rectangle_centered("fill", 0, 0, r + 5, r + 5)
    -- -- graphics.set_line_width(1)
    -- graphics.set_color(Color.cyan)
    -- if self.damage_taken >= self.max_hp - 1 then
    --     graphics.set_color(Color.blue)
    -- end
    -- graphics.rectangle_centered("line", 0, 0, r + 4, r + 4 )
    -- -- graphics.rotate(tau * 0.125)
    
    -- -- if r > START_HURT_BUBBLE_RADIUS - 3 then
    --     -- graphics.rectangle_centered("line", 0, 0, r + 4, r + 4)
    -- -- end
    -- graphics.rectangle_centered("fill", 0, 0, r, r )
    -- -- graphics.set_color(Color.yellow)
    -- -- graphics.rectangle_centered("fill", 0, 0, r - 4, r - 4 )

    
    -- if self.player and (gametime.tick + self.disc_id) % 3 == 0 then
    --     graphics.push("all")
    --     local color = Palette[self:get_sprite()]:tick_color(self.tick, self.disc_id, 3)
    
    --     graphics.set_color(color)
    --     local pbx, pby = self:to_local(self.player:get_body_center())
    --     graphics.axis_quantized_line(0, 0, pbx, pby, 10, 10, false, 3)
    --     graphics.pop()
    -- end

    Disc.super.draw(self)
end

function Disc:on_landed_melee_attack()
    self:play_sfx("pickup_barrier_hit", 0.5)
    self:damage(0.25)
end

return Disc
