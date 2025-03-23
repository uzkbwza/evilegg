local Charger = require("obj.Spawn.Enemy.BaseEnemy"):extend("Charger")
local Chargesploder = Charger:extend("Chargesploder")
local ExplosionRadiusWarning = require("obj.ExplosionRadiusWarning")
local Explosion = require("obj.Explosion")

local CHARGE_SPEED = 0.045

local ChargerIndicator = Effect:extend("ChargerIndicator")

Charger.is_charger = true
Charger.death_cry = "enemy_charger_death"

function Charger:new(x, y)
    self.max_hp = 8
    self.hurt_bubble_radius = 6
    self.hit_bubble_radius = 4
    self.melee_both_teams = true
    Charger.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.TrackPreviousPosition2D)
    self.bullet_push_modifier = 0.75
    self.declump_radius = 8
    self.declump_force = 0.05
    self.declump_mass = 1
    self.body_height = 5
end

function Charger:state_Waiting_enter()

    -- self.pdx, self.pdy = rng.random_4_way_direction()

    -- self:start_tick_timer("warning", 5, function()
    -- end)
    self.pdx, self.pdy = self:get_body_direction_to_player()

	self:start_tick_timer("drag", 6, function()
		self.drag = 0.15
	end)

    self:start_tick_timer("effect", 20, function()
        self.pdx, self.pdy = self:get_body_direction_to_player()

        self:play_sfx("enemy_charger_warning", 0.75, 1.0)
        local bx, by = self:get_body_center()
        self:spawn_object(ChargerIndicator(bx + self.pdx * 8, by + self.pdy * 8, self.pdx, self.pdy))
    end)
    self:start_tick_timer("waiting", 25, function()
        self:change_state("Charging")
    end)
end


function Charger.try_bump_friend(other, self, bubble)
    if other.parent == self then
        return
	end
    if self.state == "Waiting" then
        return
	end
    local parent = other.parent
    if parent.is_charger and bubble:collides_with_bubble(other) then
        local my_dir_x, my_dir_y = vec2_normalized(self.vel.x, self.vel.y)
        local other_dir_x, other_dir_y = vec2_normalized(parent.vel.x, parent.vel.y)
        local dot = my_dir_x * other_dir_x + my_dir_y * other_dir_y
		local b1x, b1y = self:get_body_center()
		local b2x, b2y = parent:get_body_center()
		local dx, dy = vec2_direction_to(b1x, b1y, b2x, b2y)
        if dot < 0.5 then
            self:change_state("Waiting")
            parent:change_state("Waiting")
            self:bump_recoil(dx, dy)
			parent:bump_recoil(-dx, -dy)
        end
    end
end

function Charger:bump_recoil(dx, dy)
    local mag
	if dx and dy then
		mag = vec2_dot(self.vel.x, self.vel.y, dx, dy)
	else
		mag = vec2_magnitude(self.vel.x, self.vel.y)
	end
    local fx, fy = vec2_normalized_times(dx or self.vel.x, dy or self.vel.y, -mag  * 0.5)
	self.vel:mul_in_place(0)
	self:apply_impulse(fx, fy)
end

function Charger:state_Waiting_update(dt)
    if self.state_tick > 15 then
        self.drag = 0.5
    end

end

function Charger:exit()
	self:stop_sfx("enemy_charger_charge")
end

function Charger:state_Charging_enter()
	self:play_sfx("enemy_charger_charge", 0.5, 1.0 )
	self.drag = 0.0
end

function Charger:state_Charging_exit()
    self:stop_sfx("enemy_charger_charge")
	self:play_sfx("enemy_charger_wall_slam", 0.85, 1.0)
end

function Charger:state_Charging_update(dt)
    self:apply_force(self.pdx * CHARGE_SPEED, self.pdy * CHARGE_SPEED)

	local bx, by = self:get_body_center()
	local bubble = self:get_bubble("hurt", "main")
	local x, y, w, h = bubble:get_rect()
	self.world.hurt_bubbles.enemy:each_self(x, y, w, h, self.try_bump_friend, self, bubble)
end

function Charger:get_palette()
	local palette, offset = Charger.super.get_palette(self)
    if self.state == "Charging" then
		offset = idiv(self.state_tick, 3)
	end
	return palette, offset
end

function Charger:on_terrain_collision(normal_x, normal_y)
	if self.state == "Charging" and self.state_tick > 3 then
        self:change_state("Waiting")
		self:bump_recoil(normal_x, normal_y)
	end
	self:terrain_collision_bounce(normal_x, normal_y)
end

function Charger:get_sprite()
	return self.state == "Waiting" and textures.enemy_charger1 or textures.enemy_charger2
end

function Charger:floor_draw()
    local prev_x, prev_y = self.prev_pos.x, self.prev_pos.y
	local SIZE = 8
    for x, y in bresenham_line_iter(prev_x, prev_y, self.pos.x, self.pos.y) do
        local bx, by = self:get_body_center_local()
		local px, py = self:to_local(bx + x, by + y)
		graphics.set_color(Color.darkred)
		graphics.rectangle("line", px - SIZE / 2, py - SIZE / 2, SIZE, SIZE)
		graphics.set_color(Color.black)
		graphics.rectangle("fill", px - SIZE / 2 - self.pdx, py - SIZE / 2 - self.pdy, SIZE, SIZE)
    end
end

function Charger:filter_melee_attack(bubble)
	if bubble.parent.is_charger then
		return false
	end
	return true
end

local INDICATOR_SEPARATION = 7
local NUM_INDICATORS = 2

function ChargerIndicator:new(x, y, dx, dy)
    ChargerIndicator.super.new(self, x, y)
    self.dx = dx
    self.dy = dy
    self.duration = 32
	self.z_index = 1
end

function ChargerIndicator:enter()
	self:start_tick_timer("effect", 1, function()
        local new_x, new_y = self.pos.x + self.dx * INDICATOR_SEPARATION * NUM_INDICATORS, self.pos.y + self.dy * INDICATOR_SEPARATION * NUM_INDICATORS
		if self.world:point_is_in_bounds(new_x, new_y) then
			self:spawn_object(ChargerIndicator(new_x, new_y, self.dx, self.dy))
		end
	end)
end
function ChargerIndicator:draw(elapsed, tick, t)
	-- if idivmod_eq_zero(gametime.tick, 2, 2) then
	-- 	return
	-- end

	
	
	for i=1, NUM_INDICATORS do
		local size = 3
		graphics.set_color(Color.black)
		graphics.rectangle("fill", -size / 2 + (i * self.dx) * INDICATOR_SEPARATION - 1, -size / 2 + (i * self.dy) * INDICATOR_SEPARATION - 1, size + 2, size + 2)
	end
	for i=1, NUM_INDICATORS do
		local size = 2
		graphics.set_color(idivmod_eq_zero(gametime.tick, 3, 2) and Color.red or Color.yellow)
		graphics.rectangle("fill", -size / 2 + (i * self.dx) * INDICATOR_SEPARATION, -size / 2 + (i * self.dy) * INDICATOR_SEPARATION, size, size)
	end
end

local EXPLOSION_RADIUS = 24

function Chargesploder:new(x, y)
    -- self.max_hp = 8
    self.bullet_push_modifier = 3.5
    self.walk_speed = 0.5
    Chargesploder.super.new(self, x, y)
end

function Chargesploder:enter()
	local bx, by = self:get_body_center()
	self:spawn_object(ExplosionRadiusWarning(bx, by, EXPLOSION_RADIUS, self))
end

function Chargesploder:get_sprite()
	return self.state == "Waiting" and textures.enemy_chargesploder1 or textures.enemy_chargesploder2
end

-- function Chargesploder:on_landed_melee_attack()
	-- self:die()
-- end


function Chargesploder:get_palette()
    if self.world then
        return nil, floor(self.world.tick / 3)
    end
	return Chargesploder.super.get_palette(self)
end

function Chargesploder:die(...)
	local bx, by = self:get_body_center()
    local params = {
		size = EXPLOSION_RADIUS,	
		damage = self.max_hp,
		team = "enemy",
		melee_both_teams = true,
		particle_count_modifier = 0.85,
		explode_sfx = "explosion3",
	}
    self:spawn_object(Explosion(bx, by, params))
    Chargesploder.super.die(self, ...)
end

AutoStateMachine(Charger, "Waiting")

return { Charger, Chargesploder }
