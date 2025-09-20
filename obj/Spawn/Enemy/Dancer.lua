local Dancer = BaseEnemy:extend("Dancer")
local DancerBullet = BaseEnemy:extend("DancerBullet")
local DanceEffect = Effect:extend("DanceEffect")
local DanceEffect2 = Effect:extend("DanceEffect")

local HIT_BUBBLE_RADIUS = 7

Dancer.max_hp = 3
Dancer.body_height = 4
Dancer.terrain_collision_radius = 7
Dancer.hurt_bubble_radius = 10
Dancer.hit_bubble_radius = HIT_BUBBLE_RADIUS
Dancer.is_dancer = true

local anim = {
    textures.enemy_dancer1,
    textures.enemy_dancer2,
    textures.enemy_dancer3,
    textures.enemy_dancer4,
    textures.enemy_dancer5,
    textures.enemy_dancer6,
}

function Dancer:new(x, y)
    Dancer.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Fx.RetroRumble)
    self.declump_radius = 11
    self.bullet_push_modifier = 0.75
    self.step = 1
    self.power = 0
    self:ref_bongle("nearby_dancers")
    self.dancers_to_remove = {}
end

function Dancer:enter()
    self.world:add_to_spatial_grid(self,"dancer_grid", self.get_dancer_rect)
end

function Dancer:get_dancer_rect()
    local bx, by = self:get_body_center()
    return bx - self.hurt_bubble_radius, by - self.hurt_bubble_radius, self.hurt_bubble_radius * 2, self.hurt_bubble_radius * 2
end

function Dancer:get_sprite()
    return anim[self.step]
end

function Dancer:state_Walk_enter()
    self.started_walk = false
end


local SEARCH_RADIUS = 50

function Dancer:is_dancer_nearby(dancer)
    local bx, by = self:get_body_center()
    local bx2, by2 = dancer:get_body_center()
    return circle_collision(bx, by, SEARCH_RADIUS, bx2, by2, dancer.hurt_bubble_radius)
end

function Dancer:update(dt)
    self.power = 0

    for _, dancer in self.nearby_dancers:ipairs() do
        if not self:is_dancer_nearby(dancer) then
            self.dancers_to_remove[dancer] = true
        end
    end

    for dancer, _ in pairs(self.dancers_to_remove) do
        self:ref_bongle_remove("nearby_dancers", dancer)
    end

    table.clear(self.dancers_to_remove)

    local bx, by = self:get_body_center()
    local rx, ry, rw, rh = bx - SEARCH_RADIUS, by - SEARCH_RADIUS, SEARCH_RADIUS * 2, SEARCH_RADIUS * 2

    self.world.dancer_grid:each_self(rx, ry, rw, rh, self.process_nearby_dancer, self)
    self.power = self.nearby_dancers:length()
end

function Dancer:draw()
    Dancer.super.draw(self)
end

function Dancer:floor_draw()
    if self.power > 0 then
        if self.is_new_tick and rng:percent(pow(self.power * 0.35, 4)) then
            
            local offsx, offsy = rng:randfn(-16, 16), rng:randfn(-16, 16)
            local color = Palette.cmyk:random_color()
            local mod = 0.7
            graphics.set_color(color.r * mod, color.g * mod, color.b * mod)
            local scale = abs(rng:randfn(1.0, 0.25))
            graphics.rectangle_centered("fill", offsx, offsy, 3 * scale, 2 * scale)
       end
    end
end

function Dancer.process_nearby_dancer(object, self)
    if object ~= self then
        self:ref_bongle_push("nearby_dancers", object)
    end
end
function Dancer:get_palette()
    if self.attacking then
        return Palette.cmyk, idiv(self.world.timescaled.tick, 7)
    end
    -- if self.power == 0 then
    return nil, 0
    -- end
    -- return nil, idiv(self.tick + self.random_offset, max(30 - self.power * 3, 10))
    -- return nil, 0
end


local step_rumble_func = function(t)
    return 1.0 * (1 - ease("outQuad")(t))
end

function Dancer:state_Walk_update(dt)
    if not self.walking and self.is_new_tick and self.tick % 7 == 0 then
        self.step = self.step + 1
        if self.step > #anim then
            self.step = 1
        end
    end

       
    if self.world.timescaled.tick % 28 == 0 and not self.started_walk then
        self.started_walk = true
        local s = self.sequencer
        if self.walk_coroutine then
            s:stop(self.walk_coroutine)
            self.walk_coroutine = nil
        end
        self.walk_coroutine = s:start(function()
            s:wait(stepify(rng:randi(7, 14), 7))


            local target_x, target_y = 0, 0


            local len = self.nearby_dancers:length()


            if len > 0 then
                local average_x, average_y = 0, 0
                
                for _, dancer in self.nearby_dancers:ipairs() do
                    local px, py = dancer.pos.x, dancer.pos.y
                    average_x = average_x + px
                    average_y = average_y + py
                end

                average_x = average_x / len
                average_y = average_y / len

                target_x, target_y = average_x, average_y

            end

            local dx, dy = vec2_direction_to(self.pos.x, self.pos.y, target_x, target_y)
            dx, dy = vec2_snap_angle(dx, dy, 45)

            self.walking = true

            self.step = stepify_ceil(self.step, 3)
            if self.step < 1 then
                self.step = 1
            end
            if self.step > #anim then
                self.step = #anim
            end
            for i = 1, stepify(rng:randi(9, 24), 3) do
                s:wait(3)
                if self.step ~= 1 and self.step ~= 4 then
                    self:play_sfx("enemy_dancer_step", 0.5)
                end
                self.step = self.step + 1
                local speed = clamp(4 - (self.power / 2), 1, 4)
                self:move(dx * speed, dy * speed)
                if self.step > #anim then
                    self.step = 1
                end
            end

            self.walking = false

            s:wait(7)

            if rng:percent(30 + self.power * 10) then
                self.leader = true
                self:change_state("Attack")
            else
                self:change_state("Walk")
            end
            self.walk_coroutine = nil
        end)
    end
end

function Dancer:state_Attack_enter()
    local s = self.sequencer
    if self.leader then
        local attack_power = rng:randi(self.power + 1, self.power * 2 + 2)
        self.attack_power = attack_power
        for _, dancer in self.nearby_dancers:ipairs() do
            if dancer.state == "Walk" then
                if dancer.walk_coroutine then
                    dancer.sequencer:stop(dancer.walk_coroutine)
                    dancer.walk_coroutine = nil
                    dancer.attack_power = attack_power
                end
                dancer:change_state("Attack")
            end
        end
    end
    self.attacking = true
    self.attack_power = self.attack_power or 1
end



local PUSH_DIST = 120

function Dancer:state_Attack_update(dt)


    if self.world.timescaled.tick % 7 == 0 and not self.started_attack then
        local s = self.sequencer

        s:start(function()
            self.started_attack = true
            self:play_sfx("enemy_dancer_telegraph", 1)
            s:wait(28)
            self:play_sfx("enemy_dancer_telegraph", 1)
            for i = 1, self.attack_power * 2 do
                s:wait(28)
                if self.step ~= 1 and self.step ~= 4 then
                    self.step = rng:coin_flip() and 1 or 4
                end
                if self.step == 1 then
                    self.step = 4
                else
                    self.step = 1
                end
                self:play_sfx("enemy_dancer_dance", 1)
                input.start_rumble(step_rumble_func, 15)
                s:start(function()
                    self:set_hit_bubble_radius("main", 18)
                    s:wait(1)
                    self:set_hit_bubble_radius("main", HIT_BUBBLE_RADIUS)
                end)

                
                for _, player in self:get_players():ipairs() do
                    local bx, by = self:get_body_center()
                    local pbx, pby = player:get_body_center()
                    local dx, dy = vec2_direction_to(bx, by, pbx, pby)
                    local dist = vec2_distance(bx, by, pbx, pby)
                    -- if dist < PUSH_DIST then
                    -- local amount = (1 - dist / PUSH_DIST) 
                    local speed = min(6500 * (1 / pow(dist, 2)), 2.5)
                    if not player:is_invulnerable() then 
                        player:apply_impulse(dx * speed, dy * speed)
                    end
                        -- player:start_rumble(3 * amount, 30 * amount, nil, true, true)
                    -- end
                end

                for _, enemy in self.world:get_objects_with_tag("twinstick_entity"):ipairs() do
                    if not enemy.is_enemy_bullet and not (enemy.is_dancer) and enemy.apply_impulse and not enemy.is_player then
                        local bx, by = self:get_body_center()
                        local ebx, eby = enemy:get_body_center()
                        local dx, dy = vec2_direction_to(bx, by, ebx, eby)
                        local dist = vec2_distance(bx, by, ebx, eby)
                        local speed = min(6500 * (1 / pow(dist, 2)), 2.5)
                        if enemy.is_rescue then speed = speed * 0.15 end
                        -- print("dancer push speed: " .. speed)
                        enemy:apply_impulse(dx * speed, dy * speed)
                    end
                end

                self:start_rumble(1, 20, nil, true, true)
                self.world.camera:start_rumble(1, 4, nil, true, true)

    
                local bx, by = self:get_body_center()
                -- local bullet = self:spawn_object(DancerBullet(bx, by))
                -- local dx, dy = rng:random_4_way_direction()
                -- dx = dx * 3.5
                -- dy = dy * 3.5
                -- bullet:apply_impulse(dx, dy)
                self:spawn_object(DanceEffect(bx, by))
                self:spawn_object(DanceEffect2(bx, by))
                -- local bullet2 = self:spawn_object(DancerBullet(bx, by))
                -- bullet2:apply_impulse(-dx, -dy)
            end
            self:change_state("Walk")
        end)
    end


end
function Dancer:state_Attack_exit()
    self.leader = false
    self.attacking = false
    self.started_attack = false
end

DancerBullet.max_hp = 2

function DancerBullet:new(x, y)
    DancerBullet.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.PositionHistory, 6)
    self.bullet_push_modifier = 1
    self.z_index = 1
    self.floor_draw_color = Palette.rainbow:get_random_color()
    self.drag = 0.04
    self.hit_bubble_radius = 3
    self.hurt_bubble_radius = 5
    self.start_pos_x, self.start_pos_y = x, y
end

local MIN_VEL = 0.1

function DancerBullet:update(dt)
    if self.vel:magnitude_squared() < (MIN_VEL * MIN_VEL) then
        self:die()
    end
end

function DancerBullet:get_sprite()
    return textures.enemy_dancer_bullet
end

function DancerBullet:draw()

    local x, y = self:to_local(self.start_pos_x, self.start_pos_y)
    if self.tick <= 3 then
        graphics.set_color(Color.white)
        graphics.rectangle_centered("fill", x, y, 20, 20)
    end

    local palette = Palette[self:get_sprite()]

    for i = 1, #self.position_history, 1 do
        local pos = self.position_history[i]
        local x, y = self:to_local(pos.x, pos.y)
        graphics.set_color(palette:get_color(i + idiv(self.tick, 3)))
        if (i + self.tick) % 2 == 0 then
            graphics.drawp_centered(self:get_sprite(), palette, idiv(self.tick + i, 3), x, y)
        end
    end
    graphics.drawp_centered(self:get_sprite(), palette, idiv(self.tick, 3), 0, 0)
end

function DanceEffect:new(x, y)
    DanceEffect.super.new(self, x, y)
    self.duration = 28
    self.z_index = -1
end

function DanceEffect:draw()
    local x, y = 0, 0

    if self.tick <= 28 and self.tick % 2 == 0 then 
        graphics.set_color(Color.grey)
        if self.tick > 14 then
            graphics.set_color(Color.darkgrey)
        end
        if self.tick > 21 then
            graphics.set_color(Color.darkergrey)
        end

        local extra_size = self.tick * 6 - 4

        graphics.rectangle_centered("line", x, y, 23 + extra_size, 23 + extra_size)
        graphics.rectangle_centered("line", x, y, 27 + extra_size, 27 + extra_size)
        graphics.rectangle_centered("line", x, y, 31 + extra_size, 31 + extra_size)
    end
end

function DanceEffect2:new(x, y)
    DanceEffect2.super.new(self, x, y)
    self.duration = 5
    self.z_index = 1
end

function DanceEffect2:draw()
    graphics.set_color(Color.white)
    graphics.rectangle_centered("fill", 0, 0, 24, 24)
end


AutoStateMachine(Dancer, "Walk")

return Dancer
