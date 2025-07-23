local Penitent = BaseEnemy:extend("Penitent")

Penitent.max_hp = 1

local PENITENT_SPEED = 0.3
local BACK_AWAY_SPEED = 0.07

local SPEECH_FONT = fonts.depalettized.egglanguage

Penitent.death_sfx = "enemy_penitent_death"
Penitent.death_sfx_volume = 0.7
Penitent.hurt_sfx = "silence"

function Penitent:new(x, y)
    Penitent.super.new(self, x, y)
    self.body_height = 2
    self.drag = 0.1
    self.target_distance = rng:randfn(80, 10)
    self.hurt_bubble_radius = 6
    -- self.melee_attacking = false
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.declump_radius = 12
    self.text_amount = 0
    self.irng = rng:new_instance()
end

function Penitent:enter()
    self:add_tag("penitent")
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
    Penitent.super.hit_by(self, other)
end

function Penitent:draw()

    self:body_translate()

    local h_flip, v_flip = self:get_sprite_flip()

    local irng = self.irng

    irng:set_seed(self.tick + self.random_offset)

    local palette, palette_index

    for i=1, 1 do

        palette, palette_index = Palette.cmyk, idiv(irng:randi() * i, 4)


        local offx, offy = irng:random_vec2_times(irng:randf(1, 3))

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

function Penitent:get_palette()
    return nil, 0
end



return Penitent
