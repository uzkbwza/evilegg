local HookWorm = BaseEnemy:extend("HookWorm")
local HookWormHook = BaseEnemy:extend("HookWormHook")
local FloorPuddle = GameObject2D:extend("FloorPuddle")

HookWorm.max_hp = 3
HookWorm.body_height = 4
HookWorm.terrain_collision_radius = 4

HookWorm.walk_speed = 0.015
local HOOK_SPEED = 7

local worm_textures = {
    textures.enemy_hookworm1,
    textures.enemy_hookworm2,
    textures.enemy_hookworm3,
    textures.enemy_hookworm4,
}

local hook_textures = {
    textures.enemy_hookworm_hook1,
    textures.enemy_hookworm_hook2,
    textures.enemy_hookworm_hook3,
    textures.enemy_hookworm_hook4,
}

function HookWorm:new(x, y)
    HookWorm.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.WalkTowardPlayer)
    self:lazy_mixin(Mixins.Fx.RetroRumble)
    self.anim_state = 1
    self.hooked_object = nil
    self.hook = nil
    self.hook_target = nil
end

function HookWorm:enter()
    self:ref("floor_puddle", self:spawn_object(FloorPuddle(self.pos.x, self.pos.y))):ref("parent", self)
    self:add_hurt_bubble(0, -4, 6, "main", 0, 4)
end

function HookWorm:update(dt)
    self.floor_puddle:spawn_puddle()
end

function HookWorm:state_Walk_enter()
    self.pause_walking_toward_player = false
    self.anim_state = 1
end

function HookWorm:state_Walk_update(dt)
    if self.is_new_tick and self.tick % 10 == 0 then
        self.anim_state = self.anim_state + 1
        if self.anim_state > 2 then
            self.anim_state = 1
        end
        self:ref_closest_player("hook_target")
        if self.hook_target and self.tick > 45 then
            local bx, by = self:get_body_center()
            local htbx, htby = self.hook_target:get_body_center()
            local dist = vec2_distance(bx, by, htbx, htbx)
            if rng:percent(30) and dist < 160 and not self:is_tick_timer_running("regenerate_cooldown") then
                self.hook_target_pos_x, self.hook_target_pos_y = htbx, htby
                self:change_state("HookStart")
            end
        end
    end

    
    local pbx, pby = self:closest_last_player_pos()
    local bx, by = self:get_body_center()
    self:set_flip(sign(pbx - bx))
end

function HookWorm:state_HookStart_enter()
    self:play_sfx("enemy_hookworm_telegraph", 0.9)
    self.pause_walking_toward_player = true
    self.anim_state = 3
    local s = self.sequencer
    s:start(function()
        s:wait(16)
        self:change_state("Hook")
    end)
end

function HookWorm:state_HookStart_update(dt)
    self:set_rumble_directly(1)
end

function HookWorm:state_HookStart_exit()
    self:set_rumble_directly(0)
end

function HookWorm:state_Hook_enter()
    self:play_sfx("enemy_hookworm_shoot")
    self.retracted = false
    self.anim_state = 4
    local bx, by = self:get_body_center()

    if self.hook_target then
        local htbx, htby = self.hook_target:get_body_center()
        self.hook_target_pos_x, self.hook_target_pos_y = htbx, htby
    end

    self:ref("hook", self:spawn_object(HookWormHook(bx, by)))
    self.hook:ref("parent", self)
    
    local dx, dy = vec2_direction_to(bx, by, self.hook_target_pos_x, self.hook_target_pos_y)
    print(bx, by, self.hook_target_pos_x, self.hook_target_pos_y)
    self.hook.dx, self.hook.dy = dx, dy
    self.hook:apply_impulse(dx * HOOK_SPEED, dy * HOOK_SPEED)

    signal.connect(self.hook, "destroyed", self, "on_hook_destroyed")
end

function HookWorm:state_Hook_update(dt)
    local bx, by = self:get_body_center()
    if self.hook then
        local htbx, htby = self.hook:get_body_center()
        self:set_flip(sign(htbx - bx))
    end
end

function HookWorm:on_hook_destroyed()
    local s = self.sequencer
    s:start(function()
        if not self.retracted then
            self:start_tick_timer("regenerate_cooldown", 120)
            s:wait(10)
        end
        if self.state == "Hook" then
            self:change_state("Walk")
        end
    end)
end

function HookWorm:get_palette()
    return nil, idiv(self.tick, 6)
end

function HookWorm:get_sprite()
    return worm_textures[self.anim_state]
end

function HookWorm:draw()
    graphics.push("all")
    HookWorm.super.draw(self)
    graphics.pop()
end

HookWormHook.max_hp = 3
HookWormHook.enemy_bullet_can_touch_walls = true
HookWormHook.hit_bubble_radius = 6
HookWormHook.hurt_bubble_radius = 8
HookWormHook.lifetime = math.huge

HookWormHook.hurt_sfx = "enemy_hookworm_hook_hit"

HookWormHook.death_sfx = "enemy_hookworm_hook_death"
HookWormHook.bullet_passthrough = true

function HookWormHook:new(x, y)
    HookWormHook.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self.bullet_push_modifier = 1.5
    self.z_index = 1
    self.drag = 0.015
    self.hit_bubble_damage = 0
end

function HookWormHook:enter()
    self:add_hurt_bubble(0, 0, 6, "main", 0, 0)
    self:add_hit_bubble(0, 0, 3, "main2", 0, 0, 0)
end

function HookWormHook:update(dt)

    if not self.parent then
        self:die()
        return
    end

    local parent_bx, parent_by = self.parent:get_body_center()
    
    if not self.retracting and not self.attached_to and self.vel:magnitude() < 0.25 then
        self.retracting = true
        -- self.melee_attacking = false
    end
    
    if self.attached_to then
        local bx, by = self.attached_to:get_body_center()

        self:move_to(splerp_vec(self.pos.x, self.pos.y, bx, by, 60, dt))
    end
    
    self:set_hurt_bubble_capsule_end_points("main", self:to_local(parent_bx, parent_by))
    self:set_hit_bubble_capsule_end_points("main2", self:to_local(parent_bx, parent_by))

    if self.retracting then
        local bx, by = self:get_body_center()
        local dx, dy = vec2_direction_to(bx, by, parent_bx, parent_by)
        local speed = 3
        if self.attached_to then
            speed = 2.6
            self.attached_to:move(dx * speed * dt, dy * speed * dt)
        else
            self:move(dx * speed * dt, dy * speed * dt)
        end
        if vec2_distance(bx, by, parent_bx, parent_by) < 8 then
            self.parent.retracted = true
            self:queue_destroy()
        end
    end 
end

function HookWormHook:get_sprite()
    return textures.enemy_hookworm_chain
end

local RESOLUTION = 8

function HookWormHook:get_palette()
    return nil, idiv(self.tick, 3)
end

function HookWormHook:draw()
    local bx, by = self:get_body_center()
    local palette, palette_offset = self:get_palette_shared()
    if self.parent then
        local pbx, pby = self.parent:get_body_center()
        local dist = vec2_distance(bx, by, pbx, pby)
        -- local num_segments = math.floor(dist / RESOLUTION)
        local dx, dy = vec2_direction_to(pbx, pby, bx, by)
        local dist_covered = 0
        local c = 0
        while dist_covered < dist - 9 do
            local x, y = vec2_mul_scalar(dx, dy, dist_covered)
            c = c + 1
            dist_covered = dist_covered + RESOLUTION
            x = x + pbx
            y = y + pby
            x, y = self:to_local(x, y)
            -- if (c + idiv(gametime.tick, 3)) % 3 ~= 0 then
            if dist_covered > 10 then
                graphics.drawp_centered(textures.enemy_hookworm_chain, palette, palette_offset + c, x, y)
            end
            -- end
        end
    end

    if not self.attached_to then

        local dx, dy = self.dx, self.dy
        if self.parent then
            local pbx, pby = self.parent:get_body_center()
            dx, dy = vec2_direction_to(pbx, pby, bx, by)
        end

        local texture_index, rotation = get_16_way_from_4_base_sprite_no_flip(vec2_angle(dx, dy))

        graphics.drawp_centered(hook_textures[texture_index], palette, palette_offset, 0, 0, rotation)
    else
        if self.attached_to.attached_to_hookworm_hook ~= self then
            self:die()
        end
    end
end

function HookWormHook:on_terrain_collision(normal_x, normal_y)
    self:terrain_collision_bounce(normal_x, normal_y)
    self.retracting = true
    -- self.melee_attacking = false
end

function HookWormHook:hit_other(other, bubble)
    if other.is_base_enemy then return end
    self:ref("attached_to", other)
    other:ref("attached_to_hookworm_hook", self)
    self.melee_attacking = false
    -- self.intangible = true
    self.retracting = true
end

function FloorPuddle:new(x, y)
    FloorPuddle.super.new(self, x, y)
    self:add_elapsed_ticks()
    self.z_index = -1
    self.floor_puddles = batch_remove_list()
end

function FloorPuddle:enter()
    self:follow_movement(self.parent)
end

function FloorPuddle:update(dt)
    for i, puddle in self.floor_puddles:ipairs() do
        puddle.t = puddle.t + dt
        if puddle.t > puddle.lifetime then
            self.floor_puddles:queue_remove(puddle)
        end
    end
    self.floor_puddles:apply_removals()

    if not self.parent and self.floor_puddles:is_empty() then
        self:queue_destroy()
    end
end

function FloorPuddle:spawn_puddle() 
        local offsx, offsy = rng:random_vec2_times(rng:randfn(0, 5))
        offsx = offsx * 1.25
        local width, height = rng:randfn(2, 3), rng:randfn(2, 3)
        width = abs(width)
        height = abs(height)
        width = width * 1.25
        -- offsx = clamp(offsx, -width / 2, width / 2)
        -- offsy = clamp(offsy, -height / 2, height / 2)
        if rng:percent(5) then
            offsx = offsx * 5
            offsy = offsy * 5
            width = width / 3
            height = height / 3
        end
        local puddle = {
            x = self.pos.x + offsx,
            y = self.pos.y + offsy,
            width = width,
            height = height,
            t = 0,
            lifetime = rng:randfn(1, 60),
            fill = rng:percent(50) and "fill" or "line",
            color = rng:percent(90) and Color.darkmagenta or Color.darkred,
        }
        self.floor_puddles:push(puddle)
end

function FloorPuddle:floor_draw()
    if not self.is_new_tick then return end

    for i, puddle in self.floor_puddles:ipairs() do
        graphics.set_color(puddle.color)
        local r, g, b = puddle.color.r, puddle.color.g, puddle.color.b
        local mod = 0.5
        r = r * mod
        g = g * mod
        b = b * mod
        graphics.set_color(r, g, b)

        local x, y = self:to_local(puddle.x, puddle.y)
        graphics.rectangle_centered(puddle.fill, x, y, puddle.width * puddle.t / puddle.lifetime,
            puddle.height * puddle.t / puddle.lifetime)
    end
    
    if self.parent then

        local r, g, b = Color.darkred.r, Color.darkred.g, Color.darkred.b
        local mod = 0.5
        r = r * mod
        g = g * mod
        b = b * mod
        graphics.set_color(r, g, b)


        local scale = clamp(self.elapsed * 0.01, 0, 1)

        graphics.rectangle_centered("fill", 0, 2, 10 * scale, 7 * scale)
    end

end

AutoStateMachine(HookWorm, "Walk")

return HookWorm