local Penitent = BaseEnemy:extend("Penitent")
local PenitentSoul = BaseEnemy:extend("PenitentSoul")
local PenitentTrailEffect = GameObject2D:extend("PenitentTrailEffect")

Penitent.max_hp = 1
PenitentSoul.max_hp = 3

local PENITENT_SPEED = 0.32
local BACK_AWAY_SPEED = 0.07

local PENITENT_SOUL_SPEED = 0.04

local SPEECH_FONT = fonts.depalettized.egglanguage

Penitent.death_sfx = "enemy_penitent_death"
Penitent.death_sfx_volume = 0.7
Penitent.hurt_sfx = "silence"

function Penitent:new(x, y)
    Penitent.super.new(self, x, y)
    self.body_height = 2
    self.drag = 0.1
    self.target_distance = max(rng:randfn(80, 15), 48)
    self.hurt_bubble_radius = 6
    self.bullet_passthrough = true
    -- self.melee_attacking = false
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.declump_radius = 12
    self.text_amount = 0
    self.irng = rng:new_instance()

end

function Penitent:enter()
    self.harboring_soul = rng:percent(5) and self.world:get_number_of_objects_with_tag("penitent_soul") < 10
    self:add_tag("penitent")
    if self.harboring_soul then
        self:add_tag("penitent_soul")
    end
    
    self:add_tag("artefact_kill_fx")
end

function Penitent:update(dt)
    local player = self:get_closest_player()
    if player then
        local px, py = player.pos.x, player.pos.y
        local dx, dy = px - self.pos.x, py - self.pos.y
        local dist = vec2_magnitude_squared(dx, dy)
        local dirx, diry = vec2_normalized(dx, dy)
        if dist > (self.target_distance * self.target_distance) then
            self:apply_force(dirx * PENITENT_SPEED, diry * PENITENT_SPEED)
        elseif dist < (self.target_distance * self.target_distance) then
            self:apply_force(dirx * -BACK_AWAY_SPEED, diry * -BACK_AWAY_SPEED)
        end
        
        if self.tick > 300 and self.is_new_tick and rng:percent(0.5 + max(0, self.tick - 300) / 60) and not self.is_speaking then
            self:die()
        end
    end

    self.target_distance = self.target_distance - 0.06 * dt

    if not self.is_speaking and not self.spoke and self.is_new_tick and rng:percent(0.15) then
        self:speak()
    end
end

local TEXT = {
    "sorry",
    "sorry",
    "imsorry",
    "forgiveme",
}

function Penitent:die(...)
    Penitent.super.die(self, ...)
    if self.harboring_soul then
        self:spawn_object(PenitentSoul(self.pos.x, self.pos.y))
    end
end

function Penitent:speak()
    self.is_speaking = true
    self.spoke = true
    local s = self.sequencer
    self:play_sfx("enemy_evil_egg_speech" .. rng:randi(1, 5), 0.6)
    s:start(function()
        self.text = rng:choose(TEXT)
        local _new = ""

        for i = 1, #self.text do
            local c = self.text:sub(i, i)
            _new = _new .. c
            if rng:percent(5) then
                local j = rng:randi(1, 26)
                _new = _new .. string.sub("abcdefghijklmnopqrstuvwxyz", j, j)
            end
        end

        self.text = _new
        

        s:tween_property(self, "text_amount", 0.0, 1.0, 10, "linear")
        s:wait(rng:randi(30, 90))
        s:tween_property(self, "text_amount", 1.0, 0.0, 10, "linear")
        s:wait(10)
        self.is_speaking = false
    end, 1)
end

function Penitent:hit_by(other)
    self.death_sfx = "enemy_penitent_death2"
    -- self.harboring_soul = false
    Penitent.super.hit_by(self, other)
end

function Penitent:draw()

    self:body_translate()

    local h_flip, v_flip = self:get_sprite_flip()

    local irng = self.irng



    local palette, palette_index

    for i=1, 1 do

        irng:set_seed(idiv(self.tick, 4) + self.random_offset)

        if self.harboring_soul then
            palette, palette_index = Palette.cmyk, irng:randi() * i
        else
            palette, palette_index = Palette.cmyk, self.tick / 10
        end
        irng:set_seed(self.tick + self.random_offset)


        local offx, offy = irng:random_vec2_times(irng:randf(0, 1) * (self.harboring_soul and 4 or 1))

	    graphics.drawp_centered(self:get_sprite(), palette, palette_index, offx, offy, 0, h_flip, v_flip)

    end

	-- palette, palette_index = self:get_palette_shared()

    -- if self.tick % 3 == 0 then

	    -- graphics.drawp_centered(self:get_sprite(), palette, palette_index, 0, 0, 0, h_flip, v_flip)

    -- end

    graphics.set_color(Color.white)

    if self.text then
        graphics.translate(irng:randf(-2, 2), irng:randf(-2, 2))
        local text = utf8.sub(self.text, 1, math.floor(self.text_amount * #self.text))
        graphics.set_font(SPEECH_FONT)
        graphics.set_color(Color.black)
        graphics.print_centered(text, SPEECH_FONT, 0, -13)
        graphics.set_color(Palette.penitent_speech:tick_color(self.tick, 2))
        -- graphics.set_color(Color.black)
        graphics.print_outline_centered(Color.black,text, SPEECH_FONT, 0, -14)
    end

end

function Penitent:get_sprite()
    return textures.enemy_penitent
end

-- function Penitent:get_palette()
    -- return nil, 0
-- end

local PENITENT_SOUL_PHYSICS_LIMITS = {
    max_speed = 3
}

function PenitentSoul:new(x, y)
    PenitentSoul.super.new(self, x, y)
    self.body_height = 5
    self.emerge_time = 25
    self.drag = 0.005
    self.hurt_bubble_radius = 10
    self.hit_bubble_radius = 6
    -- self.melee_attacking = false
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self.bullet_push_modifier = 3.0
    self.declump_radius = 12
    self.melee_attacking = false
    self.text_amount = 0
    self.intangible = true
    self.speed = PENITENT_SOUL_SPEED
    self:start_tick_timer("vulnerable", 10, function()
        self.intangible = false
        self.melee_attacking = true
    end)
    self.z_index = 0.0
    self:set_physics_limits(PENITENT_SOUL_PHYSICS_LIMITS)
    self.start_x, self.start_y = self.pos.x, self.pos.y
    self:add_tag_on_enter("penitent_soul")
end

function PenitentSoul:enter()
    self:play_sfx("enemy_penitent_soul_spawn", 0.9)
    local dx, dy = self:get_body_direction_to_player()
    self:apply_impulse(-dx * 3, -dy * 3)
    local trail = self:spawn_object(PenitentTrailEffect(self.pos.x, self.pos.y))
    trail:follow_movement(self)
    trail:ref("parent", self)
    self:add_hurt_bubble(0, 0, 5, "main")

    -- if self.world.room.curse_penitence then
    if true then
        -- self.max_hp = 3
        self.drag = 0.01
        self.speed = PENITENT_SOUL_SPEED * 2
        self.emerge_time = 35
    end

    self:start_tick_timer("hurt_bubble", self.emerge_time, function()
        self.emerged = true
        self:play_sfx("enemy_penitent_soul_emerge", 0.9)
        self:set_hurt_bubble_radius(10)
    end)

    self:add_tag("artefact_kill_fx")
end

function PenitentSoul:update(dt)
    local dx, dy = self:get_body_direction_to_player()
    self:apply_force(dx * self.speed, dy * self.speed)
end

function PenitentSoul:die(...)
    PenitentSoul.super.die(self, ...)
    self:stop_sfx("enemy_penitent_soul_spawn")
end

function PenitentSoul:get_sprite()
    return self.tick > self.emerge_time and textures.enemy_penitent_soul1 or textures.enemy_penitent_soul2
end

function PenitentSoul:get_palette()
    return nil, self.tick / 4
end

function PenitentSoul:draw()
    if self.tick <= 4 then
        graphics.push("all")
        graphics.set_color(Color.skyblue)
        -- graphics.rotate(tau / 8)
        local x, y = self:to_local(self.start_x, self.start_y)
        local scale = 40 + 2 * (self.elapsed)
        graphics.set_line_width(2)
        -- graphics.rectangle_centered("fill", x, y, scale, scale)
        graphics.rectangle_centered("line", x, y, scale + 3, scale + 3)
        graphics.pop()
    end
    graphics.push("all")
    graphics.set_color(Color.skyblue)
    self:body_translate()
    graphics.set_line_width(1)
    graphics.poly_regular("line", 0, 0, (16), 5, self.elapsed * 0.125)
    graphics.poly_regular("line", 0, 0, inradius(16, 5), 4, -self.elapsed * 0.125)
    graphics.pop()
    PenitentSoul.super.draw(self)
end

function PenitentTrailEffect:new(x, y)
    PenitentTrailEffect.super.new(self, x, y)
    self:add_time_stuff()
    self.z_index = -0.01
    self.particles = batch_remove_list()
end

function PenitentTrailEffect:update(dt)
    if self.is_new_tick and self.tick % 5 == 0 and self.parent then
        local particle = {
            x = self.parent.pos.x,
            y = self.parent.pos.y,
            t = 0,
            elapsed = 0,
        }
        self.particles:push(particle)
    end

    for _, particle in self.particles:ipairs() do
        particle.t = particle.t + dt * 0.01
        particle.elapsed = particle.elapsed + dt
        if particle.t > 1 then
            self.particles:queue_remove(particle)
        end
    end

    self.particles:apply_removals()

    if self.parent == nil and self.particles:is_empty() and self.tick > 10 then
        self:queue_destroy()
    end
end

function PenitentTrailEffect:draw() 
    for _, particle in self.particles:ipairs() do
        if floor(particle.elapsed) % 2 == 0 then
            if particle.t < 0.1 then
                graphics.set_color(Color.cyan)
            elseif particle.t < 0.25 then
                graphics.set_color(Color.skyblue)
            else
                graphics.set_color(Color.blue)
            end
            local x, y = self:to_local(particle.x, particle.y)
            local scale = 10 * (1 - ease("outCubic")(particle.t))
            graphics.rectangle_centered(particle.t < 0.125 and "fill" or "line", x, y, scale, scale)
        end
    end
end

return { Penitent, PenitentSoul }
