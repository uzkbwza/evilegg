-- i want to kill myself

local Rook = BaseEnemy:extend("Rook")

local RookProjectile = BaseEnemy:extend("RookProjectile")

function Rook:new(x, y)
	self.max_hp = 18
    BaseEnemy.new(self, x, y)
	self.roam_diagonals = true
    self:lazy_mixin(Mixins.Behavior.Roamer)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)

    self.walk_speed = 0.1
    self.declump_mass = 2
	self.bullet_push_modifier = 0.45
	self.declump_radius = 12
    self.body_height = 6
	self.terrain_collision_radius = 10
	self.hurt_bubble_radius = 12
	self.hit_bubble_radius = 8
end


local walk_sprites = {
	textures.enemy_big_monster1,
	textures.enemy_big_monster2,
	textures.enemy_big_monster3,
	textures.enemy_big_monster2,
}

function Rook:get_sprite()
    return table.get_circular(walk_sprites, self.random_offset + idiv(self.tick, 9))
end

function Rook:update(dt)
    if self.is_new_tick and not self.shooting_projectile and rng:percent(0.8) then
        self:shoot_projectile()
    end
	
	-- if self.projectile and not self.projectile.shot_yet then
		-- self.projectile:move_to(self.pos.x, self.pos.y - 28)
	-- end
end
function Rook:check_projectile()
    if not self.projectile then
        self.shooting_projectile = false
        return false
    end
    return true
end

function Rook:shoot_projectile()
    self.shooting_projectile = true
    self.shot_projectile_yet = false
    self:ref("projectile", self:spawn_object(RookProjectile(self.pos.x, self.pos.y - 28)))
    self.projectile:ref("parent", self)
    
    local s = self.sequencer
    s:start(function()
        if not self:check_projectile() then return end

        self.projectile:grow()
        
        while self.projectile and not self.projectile.done_growing do
            s:wait(1)
        end
        
        if not self:check_projectile() then return end
        s:wait(40)
        
        if not self:check_projectile() then return end
        self.projectile:shoot()
        s:wait(120)
        self.shooting_projectile = false
    end)
end

function Rook:die()
    Rook.super.die(self)
	if self.projectile then
		self.projectile:die()
	end
end

function RookProjectile:new(x, y, break_scale, shoot_dir_x, shoot_dir_y, speed)
	self.break_scale = break_scale or 1.25
	self.max_hp = min(12, max(1, floor(15 * pow(self.break_scale, 2))))
    -- self.body_height = 4 * self.break_scale
	-- self.drag = 0
	self.drag = 0.05
    
	self.speed = speed
	
    RookProjectile.super.new(self, x, y)
    -- self.drag = 0.014
	self.broken_piece = break_scale ~= nil
    self.hit_bubble_radius = 6 * self.break_scale
	self.hurt_bubble_radius = 8 * self.break_scale
	self.enemy_bullet_can_touch_walls = true
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    -- self:lazy_mixin(Mixins.Behavior.Flippable)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self.self_declump_modifier = 0.0
	self:set_flip(rng:rand_sign())
	self.bullet_push_modifier = 1.25

	self.shoot_dir_x = shoot_dir_x
	self.shoot_dir_y = shoot_dir_y

	self.z_index = 1
    self.floor_draw_color = Palette.rainbow:get_random_color()

	self.done_growing = false
    self.scale = 0
	self.grow_particles = bonglewunch()
    self.particles_to_remove = {}
	self:lazy_mixin(Mixins.Behavior.AllyFinder)


    self.rng = rng:new_instance()

	if not self.broken_piece then
        self.death_sfx = "enemy_rook_projectile_break"
		self.death_sfx_volume = 1.0
	end

end

function RookProjectile:exit()
	self:stop_sfx("enemy_rook_charge")
	self:stop_sfx("enemy_rook_projectile_noise")
	self:stop_sfx("enemy_rook_projectile_noise_small")
end

function RookProjectile:die()
    if self.done_growing then
		if self.scale > 0.5 then
			self:break_apart()
		end
    end
    RookProjectile.super.die(self)
end

local function shoot_piece(self)
    self.done_growing = true
	self.scale = self.break_scale
    self:shoot()
end

function RookProjectile:on_terrain_collision()
    if self.broken_piece and self.scale > 0.5 then
        self:play_sfx("enemy_rook_projectile_break_small")
    end
end

function RookProjectile:break_apart()

	local speed = self.broken_piece and self.vel:magnitude() or 3.2
    local num_pieces = floor(rng:randf_range(6, 8) * self.scale)
	for i = 1, num_pieces do
        local angle = rng:random_angle() + (tau / num_pieces) * i
		local dx, dy = vec2_from_angle(angle)
		local piece = self:spawn_object(RookProjectile(self.pos.x + dx * 3, self.pos.y + dy * 3, self.break_scale * rng:randf_range(0.4, 0.6), dx, dy, speed * 0.8))
        piece:add_enter_function(shoot_piece)
	end
end


function RookProjectile:grow()
    local s = self.sequencer
    s:start(function()
		self:play_sfx("enemy_rook_charge")
        s:tween_property(self, "scale", 0, self.break_scale, 60, "outCubic")
        self.done_growing = true
        self.grow_particles:clear()
    end)
end

function RookProjectile:hit_other(other)
	if not other:has_tag("fungus") then
		self:die()
	end
end

function RookProjectile:shoot()
	if not self.broken_piece then
		self:play_sfx("enemy_rook_shoot")
		self:play_sfx("enemy_rook_projectile_noise", 0.5, 1.0, true)
    else
		self:play_sfx("enemy_rook_projectile_noise_small", 0.25, 1.0)
	end


	self:stop_sfx("enemy_rook_charge")
	self.bullet_push_modifier = 0.65 / self.break_scale
	self.drag = self.broken_piece and (0.005 / self.break_scale) or 0.0000
	self.vel:mul_in_place(0.4)
	self.melee_attacking = true
    local dx, dy
    if self.shoot_dir_x and self.shoot_dir_y then
        dx, dy = self.shoot_dir_x, self.shoot_dir_y
    else
        if rng:percent(75) then
            dx, dy = self:get_body_direction_to_player()
        else
            dx, dy = self:get_body_direction_to_ally()
        end
    end
    local speed = 3.25
	if self.broken_piece then
        speed = rng:randfn(self.speed, self.speed * 0.05)
		self:add_terrain_collision_death()
    else
		self:start_tick_timer("touch_walls", 10, function()
			self:add_terrain_collision_death()
		end)
	end
	self:apply_impulse(vec2_mul_scalar(dx, dy, speed))
	self.shot_yet = true
end

function RookProjectile:update(dt)

    if not self.shot_yet and not self.parent then
        self:die()
        return
    end
	
    if not self.shot_yet then
		local target_x, target_y = self.parent.pos.x, self.parent.pos.y - 28
		local dx, dy = target_x - self.pos.x, target_y - self.pos.y
		local mag = vec2_magnitude(dx, dy)
		if mag > 1 then
			self:apply_force(vec2_mul_scalar(dx, dy, 0.1 / mag))
		end
	end

	if self.is_new_tick and not self.shot_yet then
        local particle = {
            angle = stepify(rng:random_angle(), tau / 4) + tau / 8,
			speed = rng:randf_range(0.1, 0.2),
            distance = rng:randf_range(16, 128),
        }
        self.grow_particles:push(particle)
    end
	
	table.clear(self.particles_to_remove)

	for i, particle in self.grow_particles:ipairs() do
		particle.distance = particle.distance - dt * particle.speed
		if particle.distance <= 1 then
			table.insert(self.particles_to_remove, particle)
		end
	end

    for i, particle in ipairs(self.particles_to_remove) do
        self.grow_particles:remove(particle)
    end

	-- if self.vel:magnitude() < 1.5 then
	-- 	self:stop_sfx("enemy_rook_projectile_noise_small")
	-- end

	if self.shot_yet and self.vel:magnitude() < 0.2 then
		self:die()
	end
end

function RookProjectile:floor_draw()
	self:draw(true)
end

function RookProjectile:draw(floor_draw)

    if floor_draw and not (self.is_new_tick and rng:percent(max(6, 70 * self.scale))) then
        return
    end
	
	
	if floor_draw then 
        -- graphics.translate(0, 24)
		-- graphics.scale(0.75, 0.375)
    else
		self:body_translate()
		
	end
	
    local period = 2
	local slow_period = 30


	local crng = self.rng

	local num_squares = max(1, floor(16 * self.break_scale))

	for layer = 1, 2 do
		for i=1, num_squares do
			local tick = self.tick + self.random_offset

			local tick1 = idiv(tick, period) + i
			local tick2 = tick1 + 1

			local t = inverse_lerp(tick1, tick2, tick / period + i)

			local slowtick = self.tick + self.random_offset
			local slowtick1 = idiv(slowtick, slow_period) + i
			local slowtick2 = slowtick1 + 1

			local slow_t = inverse_lerp(slowtick1, slowtick2, slowtick / slow_period + i)
			
			local center = i == floor(num_squares / 2)

			crng:set_seed(self.random_offset + i)
			
			crng:set_seed(slowtick1)
			local size1 = crng:randf_range(center and 10.0 or 1.0, center and 24.0 or 4.0)
			local base_x1, base_y1 = crng:random_vec2_times(crng:randf_range(0.5, center and 1.0 or 24.5) * self.scale)
			crng:set_seed(slowtick2)
			local size2 = crng:randf_range(center and 10.0 or 1.0, center and 24.0 or 4.0)
			local base_x2, base_y2 = crng:random_vec2_times(crng:randf_range(0.5, center and 1.0 or 24.5) * self.scale)


			crng:set_seed(tick1)
			local center_x1, center_y1 = crng:random_vec2_times(crng:randf_range(0, 2))
			crng:set_seed(tick2)
			local center_x2, center_y2 = crng:random_vec2_times(crng:randf_range(0, 2))
			
			crng:set_seed(tick1 + self.random_offset)
			local stroke_x1, stroke_y1 = crng:random_vec2_times(crng:randf_range(0, 2))
			crng:set_seed(tick2 + self.random_offset)
			local stroke_x2, stroke_y2 = crng:random_vec2_times(crng:randf_range(0, 2))
			
			local base_x, base_y = vec2_lerp(base_x1, base_y1, base_x2, base_y2, slow_t)

			local stroke_x, stroke_y = vec2_lerp(stroke_x1, stroke_y1, stroke_x2, stroke_y2, t)
			local center_x, center_y = vec2_lerp(center_x1, center_y1, center_x2, center_y2, t)

			stroke_x, stroke_y = vec2_add(base_x, base_y, stroke_x, stroke_y)
			center_x, center_y = vec2_add(base_x, base_y, center_x, center_y)
			
            local rect_size = floor(self.scale * lerp(size1, size2, slow_t))

			if layer == 1 then
				rect_size = rect_size + 1
			end

			if center or rect_size >= 1 then
				
				crng:set_seed(self.random_offset + i)
				local rotate_dir = crng:randf_range(-1, 1)
				
				stroke_x, stroke_y = vec2_rotated(stroke_x, stroke_y, rotate_dir * self.elapsed * 0.15)
				center_x, center_y = vec2_rotated(center_x, center_y, rotate_dir * self.elapsed * 0.15)


				local stroke_bg_x, stroke_bg_y = vec2_sign(stroke_x, stroke_y)

				local fill_color = Palette.rook_projectile_fill:tick_color(self.tick + self.random_offset * i, 0, 2)

				graphics.set_color(layer == 1 and Color.black or fill_color)
				if not floor_draw then
					graphics.rectangle_centered("fill", center_x, center_y, rect_size, rect_size)
				end
				if rect_size >= 2 then
				
					graphics.set_line_width(clamp(ceil(rect_size * 0.125), 1, 3))

					if rect_size >= 3 then
						graphics.set_color(Color.black)
						graphics.rectangle_centered("line", stroke_x + stroke_bg_x, stroke_y + stroke_bg_y, rect_size * 1.25, rect_size * 1.25)
					end
					

					local stroke_color = Palette.rook_projectile_stroke:tick_color(self.tick + self.random_offset, 0, 2)
                    local color_mod = 0.3
					if layer == 1 then
						graphics.set_color(Color.black)
					else
						if floor_draw then
							graphics.set_color(stroke_color.r * color_mod, stroke_color.g * color_mod, stroke_color.b * color_mod)
						else
							graphics.set_color(stroke_color)
						end
					end
					graphics.rectangle_centered("line", stroke_x, stroke_y, rect_size * 1.25, rect_size * 1.25)
				end
			end
		end
	end

    for i, particle in self.grow_particles:ipairs() do
		graphics.set_color(Palette.rook_projectile_fill:tick_color(self.tick + self.random_offset * i, 0, 2))
		local x, y = vec2_from_polar(particle.distance, particle.angle)
		graphics.circle("fill", x, y, 1, 1)
	end
end

function RookProjectile:get_sprite()
	if self.broken_piece then
		return textures.enemy_rook_projectile_small
	end
	return textures.enemy_rook_projectile
end

return Rook
