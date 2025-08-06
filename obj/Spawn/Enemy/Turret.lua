local Turret = BaseEnemy:extend("Turret")
local TurretBullet = BaseEnemy:extend("TurretBullet")
local MuzzleFlashSmoke = require("fx.muzzle_flash_smoke")
Turret.shoot_speed = 3.0
Turret.shoot_delay = 240
Turret.shoot_distance = 10

Turret.spawn_cry = "enemy_turret_spawn"
Turret.spawn_cry_volume = 0.9

Turret.death_cry = "enemy_turret_death"
Turret.death_cry_volume = 0.8

Turret.max_hp = 5

function Turret:new(x, y)
	self.body_height = 6
	Turret.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self.applying_physics = false
	self.declump_radius = 16
	self.declump_mass = 1
	self.hit_bubble_radius = 4
	self.hurt_bubble_radius = 7
	self.aim_dir_x, self.aim_dir_y = rng:random_vec2()
	self.gun_angle = vec2_angle(self.aim_dir_x, self.aim_dir_y)
    self.target_aim_dir_x, self.target_aim_dir_y = 0, 0

	-- self.highlight_circle = -1

	self.hurts_allies = rng:chance(1 / 3)
end


function Turret:start_shoot_timer(time)
	time = time or Turret.shoot_delay
    self:start_tick_timer("shoot_timer", time, function()
		local s = self.sequencer
        s:start(function()
            while self.world:get_number_of_objects_with_tag("turret_shooting") >= 3 do
                s:wait(rng:randi(60, 120))
            end
            while abs(self.angle_diff) > tau / 16 do
                s:wait(1)
            end
            self:add_tag("turret_shooting")
            self.shooting = true
            for i = 1, 3 do
                self:shoot()
                s:wait(15)
            end
            while rng:percent(5) do
                s:wait(20)
            end
            self.shooting = false
			self:remove_tag("turret_shooting")
			self:start_shoot_timer()
		end)
	end)
end


local SPREAD = deg2rad(5)
function Turret:shoot()
    local shoot_x, shoot_y = vec2_rotated(self.aim_dir_x, self.aim_dir_y, rng:randfn(0, SPREAD))
    local bx, by = self:get_body_center()
	local bulletx, bullety = bx + shoot_x * self.shoot_distance, by + shoot_y * self.shoot_distance
    local bullet = self:spawn_object(TurretBullet(bulletx, bullety))
    bullet:apply_impulse(shoot_x * self.shoot_speed, shoot_y * self.shoot_speed)
	self:play_sfx("enemy_turret_shoot", 0.75)
	for i = 1, 3 do
		self:spawn_object(MuzzleFlashSmoke(bulletx, bullety, rng:randi(50, 120), abs(rng:randfn(12, 3)), Palette.muzzle_flash_smoke, rng:randf(0.15, 0.7), self.aim_dir_x, self.aim_dir_y, rng:randf(0, 60)))
	end
end

function Turret:enter()
	self:start_shoot_timer(max(1, rng:randi(60, Turret.shoot_delay)))
	self:add_hurt_bubble(0, self.body_height, self.hurt_bubble_radius, "main")
	self:add_hit_bubble(0, self.body_height, self.hit_bubble_radius, "main", 1)
	self:add_hurt_bubble(-3, self.body_height, 5, "main2")
	self:add_hurt_bubble(3, self.body_height, 5, "main3")
	self:add_hurt_bubble(0, self.body_height-4, 5, "main4")
end

function Turret:update(dt)
	if self.hurts_allies then
		self.target_aim_dir_x, self.target_aim_dir_y = self:get_body_direction_to_ally()
	else
		self.target_aim_dir_x, self.target_aim_dir_y = self:get_body_direction_to_player()
	end

    local target_angle = vec2_angle(self.target_aim_dir_x, self.target_aim_dir_y)

    local new_angle = approach_angle(self.gun_angle, target_angle, 0.1 * dt)
    
    self.aim_dir_x, self.aim_dir_y = vec2_from_angle(new_angle)

    self.gun_angle = vec2_angle(self.aim_dir_x, self.aim_dir_y)

    self.angle_diff = angle_diff(self.gun_angle, target_angle)
    
	-- if self.is_new_tick and (self.tick) % 60 == 0 then
		-- local s = self.sequencer
        -- s:start(function()
        --     s:tween_property(self, "highlight_circle", 60, 0, 40, "linear")
		-- 	self.highlight_circle = -1
		-- end)
	-- end
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

function Turret:draw_aim_line()
    if self.shooting then
        return
    end
    local dx, dy = vec2_from_angle(self.gun_angle)
    dx, dy = vec2_snap_angle(dx, dy, 32, 0)
    if iflicker(self.random_offset + gametime.tick, 1, 2) then
        for j=1, 2 do
            graphics.push("all")
            graphics.translate(dx * 17, dy * 17, 0)
            graphics.set_line_width(1)
            local len = 12
            local num_squares = 4
            for i = 1, num_squares do
                local ratio = (i - 1) / num_squares

                local size = ceil(3 * (1 - ratio))
                if j == 1 then
                    graphics.set_color(Color.black)
                    graphics.rectangle_centered("fill", 0, 0, size + 2, size + 2)
                else
                    -- graphics.set_color(iflicker(self.random_offset + gametime.tick, 2, 2) and Color.red or Color.yellow)
                    graphics.set_color(Color.red)
                    graphics.rectangle_centered("fill", 0, 0, size, size)
                end
                
                local dist = 6 * ease("outCubic")(min(self.elapsed / 50, 1))
                graphics.translate(dx * dist, dy * dist, 0)
            end
            graphics.pop()
        end
    end
end

function Turret:draw()
    -- if iflicker(self.random_offset +gametime.tick, 2, 2) then

        -- local scale = 12 + sin(gametime.tick * 0.09) * 0.5
		-- graphics.set_color(Color.red)
		-- graphics.poly_regular("line", 0, 0, scale, 6, self.elapsed * 0.02)
	-- end

    local dx, dy = vec2_from_angle(self.gun_angle)


    -- Turret.super.draw(self)
    graphics.set_color(1, 1, 1, 1)
	local index, rot, y_scale = get_32_way_from_5_base_sprite(self.gun_angle)
	local gun_texture = gun_textures[index]

	local palette, offset = self:get_palette_shared()
	
	graphics.drawp_centered(textures.enemy_turret_base, palette, offset)
	

	local normal = false
	if palette == Palette[self:get_sprite()] then
		palette = Palette[gun_texture]
		offset = (self.tick + self.random_offset)
		normal = true
	end
	
    self:body_translate()
    
    
    if dy < 0 then
        self:draw_aim_line()
    end

	graphics.set_color(Color.black)
	graphics.draw_centered_outline(Color.black, gun_texture, 0, 2, rot, 1, y_scale)
	graphics.draw_centered_outline(Color.black, gun_texture, 0, 1, rot, 1, y_scale)
	graphics.draw_centered_outline(Color.black, gun_texture, 0, 0, rot, 1, y_scale)
	graphics.set_color(Color.white)
	local tick_length = normal and 4 or 1
	graphics.drawp_centered(gun_texture, palette, idiv(offset + (2), tick_length), 0, 2, rot, 1, y_scale)
	graphics.drawp_centered(gun_texture, palette, idiv(offset + 1, tick_length), 0, 1, rot, 1, y_scale)
    graphics.drawp_centered(gun_texture, palette, idiv(offset, tick_length), 0, 0, rot, 1, y_scale)
    
    if dy > 0 then
        self:draw_aim_line()
    end
end


TurretBullet.death_sfx = "enemy_turret_bullet_die"

function TurretBullet:new(x, y)
	self.max_hp = 5

    TurretBullet.super.new(self, x, y)
    self.drag = 0.005
    self.hit_bubble_radius = 5
	self.hurt_bubble_radius = 7
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.z_index = 10
end

function TurretBullet:get_sprite()
    return textures.enemy_turret_bullet
end

function TurretBullet:get_palette()
    local offset = idiv(self.tick, 3)

    return nil, offset
end


function TurretBullet:update(dt)
    if vec2_magnitude(self.vel.x, self.vel.y) < 0.05 then
        self:die()
    end
end

return Turret
