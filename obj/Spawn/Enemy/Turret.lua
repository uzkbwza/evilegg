local Turret = require("obj.Spawn.Enemy.BaseEnemy"):extend("Turret")
local TurretBullet = require("obj.Spawn.Enemy.BaseEnemy"):extend("TurretBullet")

Turret.shoot_speed = 2.5
Turret.shoot_delay = 240
Turret.shoot_distance = 6

function Turret:new(x, y)
	self.max_hp = 3
	Turret.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self.applying_physics = false
	self.declump_radius = 16
    self.declump_mass = 1
    self.hit_bubble_radius = 4
    self.hurt_bubble_radius = 6
	self.aim_dir_x, self.aim_dir_y = 0, 0
    self.gun_angle = 0
	self.spawn_cry = "enemy_turret_spawn"
	self.spawn_cry_volume = 0.9
	self.hurts_allies = rng.chance(1/3)
end

function Turret:start_shoot_timer(time)
	time = time or Turret.shoot_delay
    self:start_tick_timer("shoot_timer", time, function()
		local s = self.sequencer
        s:start(function()
            while self.world:get_number_of_objects_with_tag("turret_shooting") >= 2 do
                s:wait(rng.randi_range(60, 120))
            end
			self:add_tag("turret_shooting")
            for i = 1, 3 do
                self:shoot()
                s:wait(15)
            end
			while rng.percent(5) do
				s:wait(20)
			end
			self:remove_tag("turret_shooting")
			self:start_shoot_timer()
		end)
	end)
end

function Turret:shoot()
    local shoot_x, shoot_y = vec2_snap_angle(self.aim_dir_x, self.aim_dir_y, 32)
    local bx, by = self:get_body_center()
	local bulletx, bullety = bx + shoot_x * self.shoot_distance, by + shoot_y * self.shoot_distance
    local bullet = self:spawn_object(TurretBullet(bulletx, bullety))
    bullet:apply_impulse(shoot_x * self.shoot_speed, shoot_y * self.shoot_speed)
	self:play_sfx("enemy_turret_shoot", 0.75)
end

function Turret:enter()
	self:start_shoot_timer(max(1, rng.randi(60, Turret.shoot_delay)))
end

function Turret:update(dt)
	if self.hurts_allies then 
		self.aim_dir_x, self.aim_dir_y = self:get_body_direction_to_ally()
	else
		self.aim_dir_x, self.aim_dir_y = self:get_body_direction_to_player()
	end
    self.gun_angle = vec2_angle(self.aim_dir_x, self.aim_dir_y)
end

function Turret:get_sprite()
    return textures.enemy_turret_base
end

local gun_textures = {
	textures.enemy_turret_gun1,
	textures.enemy_turret_gun2,
    textures.enemy_turret_gun3,
	textures.enemy_turret_gun4,
	textures.enemy_turret_gun5,
}

function Turret:draw()
    Turret.super.draw(self)
    graphics.set_color(1, 1, 1, 1)
	local index, rot, y_scale = get_32_way_from_5_base_sprite(self.gun_angle)
	local gun_texture = gun_textures[index]

	local palette, offset = self:get_palette_shared()

    if palette == Palette[self:get_sprite()] then
		offset = idiv(self.tick, 5)
	end
	graphics.drawp_centered(gun_texture, palette, offset, 0, 0, rot, 1, y_scale)
end


function TurretBullet:new(x, y)
	self.max_hp = 4

    TurretBullet.super.new(self, x, y)
    self.drag = 0.005
    self.hit_bubble_radius = 5
	self.hurt_bubble_radius = 8
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.z_index = 10
end

function TurretBullet:get_sprite()
    return textures.enemy_turret_bullet
end

function TurretBullet:get_palette()
    local offset = idiv(self.tick, 5)

    return nil, offset
end


function TurretBullet:update(dt)
    if vec2_magnitude(self.vel.x, self.vel.y) < 0.05 then
        self:die()
    end
end

return Turret
