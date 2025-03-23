local Mine = require("obj.Spawn.Enemy.BaseEnemy"):extend("Mine")
local Exploder = Mine:extend("Exploder")
local Blinker = Mine:extend("Blinker")
local Explosion = require("obj.Explosion")
local ExplosionRadiusWarning = require("obj.ExplosionRadiusWarning")

function Mine:new(x, y)
	self.max_hp = self.max_hp or 1
	self.hit_bubble_damage = self.hit_bubble_damage or 2
	self.hit_bubble_radius = self.hit_bubble_radius or 3
	self.hurt_bubble_radius = self.hurt_bubble_radius or 5
    Mine.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	-- self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    -- self.declump_radius = 10
	self.bullet_push_modifier = 1.0
	-- self.declump_mass = 10
	self.body_height = 0
	-- self.melee_both_teams = true
    self.self_declump_modifier = 0.0
	self.z_index = 0
end

function Mine:enter()
	self:hazard_init()
end

function Mine:get_palette()
	return nil, floor(self.world.tick / 3)
end

function Mine:get_sprite()
    return textures.hazard_mine
end

function Mine:normal_death_effect()
	self:flash_death_effect(1)
end

function Mine:on_landed_melee_attack()
    self:die()
end

local EXPLOSION_RADIUS = 28

function Exploder:new(x, y)
    self.max_hp = 6
    self.hit_bubble_damage = 2
    self.hit_bubble_radius = 4
    self.hurt_bubble_radius = 6
    Exploder.super.new(self, x, y)
end

function Exploder:enter()
	Exploder.super.enter(self)
	local bx, by = self:get_body_center()
	self:spawn_object(ExplosionRadiusWarning(bx, by, EXPLOSION_RADIUS, self))
end

function Exploder:get_sprite()
    return textures.hazard_exploder
end

function Exploder:die()
    Exploder.super.die(self)
    local bx, by = self:get_body_center()
	local params = {
		size = EXPLOSION_RADIUS,	
		damage = self.max_hp,
		team = "enemy",
		melee_both_teams = true,
		particle_count_modifier = 0.95,
		explode_sfx = "explosion3",
	}
    self:spawn_object(Explosion(bx, by, params))
end

function Blinker:new(x, y)
	self.hit_bubble_radius = 4
    self.hurt_bubble_radius = 5
    Blinker.super.new(self, x, y)
	self:add_time_stuff()
	self.blinked_yet = false
end

function Blinker:get_sprite()
    return textures.hazard_blinker
end


function Blinker:blink()
    self:change_state("Blinking")
end

function Blinker:state_Waiting_enter()
    self.z_index = 0
    self.vel:mul_in_place(0)
    self.applying_physics = true
    self.melee_attacking = true
    self.intangible = false
	
	local target = 120
    if not self.blinked_yet then
        target = rng.randf(60, 300)
    end
	local s = self.sequencer
	s:start(function()
		s:wait(target)
		self:change_state("Blinking")
	end)
end

function Blinker:blink_tween(t)
	self:move_to(vec2_lerp(self.start_x, self.start_y, self.blink_target_x, self.blink_target_y, t))
end

function Blinker:state_Blinking_enter()
    self.z_index = 1
	self:play_sfx("hazard_blinker_blink", 0.55)
	self.applying_physics = false
    self.melee_attacking = false
    self.intangible = true
	self.blinked_yet = true
	local s = self.sequencer
    s:start(function()
		local x = rng.randf(self.world.room.left, self.world.room.right)
        local y = rng.randf(self.world.room.top, self.world.room.bottom)
		self.start_x, self.start_y = self.pos.x, self.pos.y
        self.blink_target_x, self.blink_target_y = x, y
		s:wait(5)
		s:tween(function(t) self:blink_tween(t) end, 0, 1, 30, "inOutExpo")
		s:wait(14)
		self:play_sfx("hazard_blinker_reappear", 0.65)
        self:change_state("Waiting")

    end)
end

function Blinker:state_Waiting_update(dt)
end

function Blinker:draw()
end

function Blinker:state_Waiting_draw()
	Blinker.super.draw(self)
end

function Blinker:state_Blinking_draw()
    self:body_translate()
    -- if idivmod_eq_zero(self.tick, 1, 2) then
        graphics.set_color(Color.black)
		graphics.set_line_width(2)
		graphics.rectangle_centered("line", 0, 0, 12, 12)
		graphics.rectangle_centered("fill", 0, 0, 7, 7)
        graphics.set_color(Palette[self:get_sprite()]:tick_color(self.tick, 0, 2))
		graphics.set_line_width(1)
		graphics.rotate(self.elapsed * 0.5 + self.random_offset)
		graphics.rectangle_centered("line", 0, 0, 12, 12)
		graphics.rectangle_centered("fill", 0, 0, 5, 5)
	-- end
end

AutoStateMachine(Blinker, "Waiting")

return { Mine, Exploder, Blinker }
