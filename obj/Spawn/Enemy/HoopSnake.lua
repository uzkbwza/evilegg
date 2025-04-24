local HoopSnake = BaseEnemy:extend("HoopSnake")
local HoopSnakeSegmentProjectile = BaseEnemy:extend("HoopSnakeSegmentProjectile")

HoopSnake.base_radius = 7
HoopSnake.base_segments = 7
HoopSnake.segment_hp = 2
HoopSnake.spawn_cry = "enemy_hoop_snake_spawn"
HoopSnake.spawn_cry_volume = 1.0
HoopSnake.death_cry = "enemy_hoop_snake_death"
HoopSnake.death_cry_volume = 1.0

HoopSnake._min_speed = 0.02
HoopSnake._max_speed = 0.1

HoopSnake.bullet_speed = 11.5
HoopSnake.bullet_angle_min_speed = 0.005
HoopSnake.bullet_angle_max_speed = 0.05

HoopSnake.max_angular_vel = 1
HoopSnake.life_flash_size_mod = 2.0

HoopSnake.physics_limits = {
	max_speed = 3.5
}

function HoopSnake:new(x, y)
    self.max_hp = self.base_segments * self.segment_hp
	self.drag = 0.01
    HoopSnake.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.declump_radius = self.base_radius
    self.segments_left = self.base_segments
    self.segment_ratio = 1.0
    self.bullet_push_modifier = self:get_bullet_push_modifier()
    self.angle_offset = 0.0
    self.segment_damage_accumulator = 0
	self.angular_vel = 0.0
    self.angular_accel = 0.0
	self.bullet_angle = 0
	self.bullet_angle_offset = rng.random_angle()
    -- self.bullet_angle = rng.coin_flip() and (tau / 8) or 0
	-- self.bullet_angle = 0
	self.bullet_angle_dir = rng.rand_sign()
	self.on_terrain_collision = self.terrain_collision_bounce
	self:set_physics_limits(HoopSnake.physics_limits)
    self.telegraphing_vecs = {
		[Vec2.UP] = 0,
		[Vec2.DOWN] = 0,
		[Vec2.LEFT] = 0,
		[Vec2.RIGHT] = 0,
	}

	self.segment_shots_left = self.segments_left
end

function HoopSnake:get_bullet_push_modifier()
	return lerp(2.2, 1.35, self.segment_ratio)
end

function HoopSnake:enter()
    self:add_hurt_bubble(0, 0, 1, "main")
	self:add_hit_bubble(0, 0, 1, "main")
    self:update_size()

end

function HoopSnake:update_size()
	self:set_hurt_bubble_radius("main", (self.base_radius) * self.segment_ratio + (self.segments_left > 1 and 10 or 6))
	self:set_hit_bubble_radius("main", self.base_radius * self.segment_ratio + 3)
	self:set_body_height((self.base_radius + 16) * self.segment_ratio * 0.5 - 5)
end

function HoopSnake:on_damaged(damage)
    self.segment_damage_accumulator = self.segment_damage_accumulator + damage
    if self.segments_left > 1 and self.segment_damage_accumulator >= self.segment_hp and self.segment_shots_left > 0 then
        self:play_sfx("enemy_hoop_snake_telegraph_shoot")
        for i = 1, min(self.segments_left, floor(self.segment_damage_accumulator / self.segment_hp)) do
            self.segment_shots_left = self.segment_shots_left - 1
            self.segment_damage_accumulator = self.segment_damage_accumulator - self.segment_hp
            local dx, dy = 0, 0
            -- if abs(diff_x) > abs(diff_y) then
            -- 	dx = rng.rand_sign()
            -- else
            -- 	dy = rng.rand_sign()
            -- end
            while dx == 0 and dy == 0 do
                if rng.percent(50) then
                    dx = rng.rand_sign()
                else
                    dy = rng.rand_sign()
                    -- else
                    -- dy = 0
                end
            end

            local s = self.sequencer
            s:start(function()
                local vec
                if dx == 0 and dy == 1 then
                    vec = Vec2.DOWN
                elseif dx == 0 and dy == -1 then
                    vec = Vec2.UP
                elseif dx == 1 and dy == 0 then
                    vec = Vec2.RIGHT
                elseif dx == -1 and dy == 0 then
                    vec = Vec2.LEFT
                end
                self.telegraphing_vecs = self.telegraphing_vecs or {}
                self.telegraphing_vecs[vec] = self.telegraphing_vecs[vec] or 0
                self.telegraphing_vecs[vec] = self.telegraphing_vecs[vec] + 1
                s:wait(15)
                self.segments_left = self.segments_left - 1
                self.segment_ratio = self.segments_left / self.base_segments
                self.radius = self.base_radius * self.segment_ratio
                local bx, by = self:get_body_center()
                -- local cbx, cby = self:closest_ally_body_pos()

                -- local diff_x, diff_y = vec2_sub(cbx, cby, bx, by)



                -- if rng.percent(50) then
                -- else
                -- end
                if rng.percent(20) then
                    self.bullet_angle_dir = -self.bullet_angle_dir
                end
                local new_dx, new_dy = dx, dy
                new_dx, new_dy = vec2_normalized(new_dx, new_dy)
                new_dx, new_dy = vec2_rotated(new_dx, new_dy, self.bullet_angle)
                self.telegraphing_vecs = self.telegraphing_vecs or {}
                local bullet = self:spawn_object(HoopSnakeSegmentProjectile(bx, by))
                bullet:apply_impulse(vec2_mul_scalar(new_dx, new_dy, HoopSnake.bullet_speed))
                bullet:move(new_dx * self.radius, new_dy * self.radius)
                self:play_sfx("enemy_hoop_snake_segment_lost")
                self.telegraphing_vecs[vec] = self.telegraphing_vecs[vec] - 1
                self.bullet_push_modifier = self:get_bullet_push_modifier()
                self:update_size()
            end)
        end
    end
end

function HoopSnake:death_sequence()
    if self.segments_left > 1 then
		local s = self.sequencer
        s:start(function()
			while self.segments_left > 1 do
				s:wait(15)
			end
			HoopSnake.super.death_sequence(self)
		end)
    else
		HoopSnake.super.death_sequence(self)
	end
end

function HoopSnake:get_speed()
	return lerp(self._max_speed, self._min_speed, self.segment_ratio)
end

local sprites = {
	textures.enemy_hoop_snake3,
	textures.enemy_hoop_snake4,
	textures.enemy_hoop_snake5,
	textures.enemy_hoop_snake2,
}

function HoopSnake:get_sprite()
	local offset = stepify((self.angle_offset / tau) * 4 - 0.5, 1) % 4 + 1
    local sprite = sprites[offset]
	return sprite
end

function HoopSnake:draw()
	local palette, offset = self:get_palette_shared()
    self:body_translate()
	
    if self.segments_left > 1 then
        local radius = self.base_radius * self.segment_ratio + 5
        for i = 1, self.segments_left do
            local angle = (i / self.segments_left) * 2 * pi + self.angle_offset
            local x = radius * cos(angle)
            local y = radius * sin(angle)
            graphics.drawp_centered(i == self.segments_left and self:get_sprite() or textures.enemy_hoop_snake1, palette,
                offset, x, y)
        end
        if idivmod_eq_zero(gametime.tick, 3, 2) then
			-- graphics.rotate(self.angle_offset, 0, 0)
			local radius2 = self.base_radius * self.segment_ratio + 16
			
            for i, vec in ipairs(CARDINAL_DIRECTIONS) do
				graphics.push("all")
                local x, y = vec2_rotated(vec.x, vec.y, self.bullet_angle)
                local line_length = 2
				graphics.set_color(idivmod_eq_zero(gametime.tick, 2, 2) and Color.red or Color.white)
				if self.telegraphing_vecs[vec] > 0 then
                    line_length = 80
					graphics.set_line_width(6)
				end
				graphics.rectangle_centered("fill", x * radius2, y * radius2, 3, 3)
				graphics.rectangle_centered("fill", x * (radius2 + 4), y * (radius2 + 4), 2, 2)
				graphics.line(x * (radius2 + 8), y * (radius2 + 8), x * (radius2 + 8 + line_length), y * (radius2 + 8 + line_length))
				graphics.pop()
            end
		end
    else
        graphics.drawp_centered(self:get_sprite(), palette, offset, 0, 0)
    end
end

function HoopSnake:update(dt)
    if self.target == nil or (self.is_new_tick and rng.percent(0.5)) then
        self:ref("target", rng.percent(75) and self:get_random_player() or self:get_random_ally())
    end

    if self.target ~= nil then
        local bx, by = self:get_body_center()
        local abx, aby = self.target:get_body_center()
        local dx, dy = vec2_direction_to(bx, by, abx, aby)
        self:apply_force(vec2_mul_scalar(dx, dy, self:get_speed()))
    end

    local direction = (self.vel.x > 0) and 1 or -1
    self.angular_accel = self.angular_accel + self.vel:magnitude() * 0.05 * direction * (1 + (1 - self.segment_ratio))
    local max_angular_vel = HoopSnake.max_angular_vel * dt
	self.angular_vel = clamp(self.angular_vel + self.angular_accel, -max_angular_vel, max_angular_vel)
    self.angle_offset = self.angle_offset + self.angular_vel * dt
    self.angular_accel = 0
    self.angular_vel = drag(self.angular_vel, 0.95, dt)
	-- self.bullet_angle = self.bullet_angle - dt * lerp(self.bullet_angle_min_speed, self.bullet_angle_max_speed, 1 - self.segment_ratio) * self.bullet_angle_dir
	self.bullet_angle = self.bullet_angle_offset + self.angle_offset * 0.1

	if self.is_new_tick and rng.percent(3 + 30 * (1 - self.segment_ratio)) then
		self:play_sfx("enemy_hoop_snake_hiss", 0.5)
	end
end

function HoopSnakeSegmentProjectile:get_sprite()
	return textures.enemy_hoop_snake1
end

function HoopSnakeSegmentProjectile:get_palette()
	return nil, idiv(self.tick, 3)
end

function HoopSnakeSegmentProjectile:new(x, y)
	self.drag = 0.1
    self.max_hp = 4
    self.hurt_bubble_radius = 5
	self.hit_bubble_radius = 4
    HoopSnakeSegmentProjectile.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
end

function HoopSnakeSegmentProjectile:floor_draw()
    if self.is_new_tick then
		graphics.drawp_centered(textures.enemy_hoop_snake_bullet_floor, nil, 0, 0, 0)
	end
end

function HoopSnakeSegmentProjectile:update(dt)
	if self.vel:magnitude() < 0.2 then
		self:die()
	end
end


return HoopSnake
