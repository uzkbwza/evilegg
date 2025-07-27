local Cuboid = BaseEnemy:extend("Cuboid")
local CuboidBullet = BaseEnemy:extend("CuboidBullet")

local OFFSET_APPROACH_SPEED = 0.125

local SPEED = 0.055
local RETREAT_SPEED = 0.068

local BULLET_SPEED = 5.5

local short = 5
local long = 7


local cuboid_limits = {
	max_speed = 3.0,
}

local frames = {
	{short, textures.enemy_cube1},
	{short, textures.enemy_cube2},
	{short, textures.enemy_cube3},
	{long, textures.enemy_cube4},
	{short, textures.enemy_cube5},
	{short, textures.enemy_cube6},
}

local backward_frames = {}

for i=#frames, 1, -1 do
	table.insert(backward_frames, frames[i])
end

local ANIMATION = Animation.from_lengths(frames)
local BACKWARD_ANIMATION = Animation.from_lengths(backward_frames)

Cuboid.max_hp = 5

Cuboid.drag = 0.01

Cuboid.spawn_cry = "enemy_cube_spawn"
Cuboid.spawn_cry_volume = 0.6

local BODY_HEIGHT = 5

function Cuboid:new(x, y)
    self.hurt_bubble_radius = 9
    self.hit_bubble_radius = 7
    Cuboid.super.new(self, x, y)
    -- self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self:set_physics_limits(cuboid_limits)
    self.bullet_push_modifier = 2.0
    self.declump_radius = 5
    self.declump_force = 0.035
    self.declump_mass = 1
    self.body_height = BODY_HEIGHT
    self.offset_radius = 90

    self.spin_dir = rng:rand_sign()

    self.approaching = true

    self.target_x = self.pos.x
    self.target_y = self.pos.y

	self.beaming = false

    self.random_bullet_angle = rng:randf(0, tau)
	self.on_terrain_collision = self.terrain_collision_bounce
end

function Cuboid:enter()
    self.melee_attacking = false
    self.intangible = true
	self.beaming = true
	local s = self.sequencer
	s:start(function()
		self:set_body_height(300)
		s:wait(rng:randi(20))
        s:tween(function(t) self:set_body_height(lerp(300, BODY_HEIGHT, t)) end, 0, 1, rng:randf(20, 40), "outQuad")
        self.melee_attacking = true
		self.intangible = false
		self.beaming = false
		self:stop_sfx("enemy_cube_descend")
	end)
end


function Cuboid:update(dt)

	if self.beaming then
		self:play_sfx_if_stopped("enemy_cube_descend", 0.5)
	end

    if self.approaching then
        local px, py = self:closest_last_player_pos()
        local x, y = self.pos.x, self.pos.y

        local angle_offset = self.random_offset_ratio * tau


        local offset_x, offset_y = vec2_from_polar(self.offset_radius, angle_offset + self.elapsed * 0.74 / self.offset_radius * self.spin_dir)

        local target_x, target_y = vec2_add(px, py, offset_x, offset_y)
		
		self.target_x = target_x
        self.target_y = target_y
		
		self.target_player_x, self.target_player_y = px, py

        local dx, dy = vec2_direction_to(x, y, target_x, target_y)
		
		local dist_squared = vec2_distance_squared(px, py, x, y)
		if dist_squared < self.offset_radius * self.offset_radius then
			local pdx, pdy = vec2_direction_to(x, y, px, py)
			self:apply_force(vec2_mul_scalar(pdx, pdy, -RETREAT_SPEED))
		end

        self.offset_radius = approach(self.offset_radius, 6, OFFSET_APPROACH_SPEED * dt)

        self:apply_force(vec2_mul_scalar(dx, dy, SPEED))
    end
end

function Cuboid:debug_draw()
    graphics.set_color(Color.yellow)
    local tx, ty = self:to_local(self.target_x, self.target_y)
    graphics.line(0, 0, tx, ty)
    graphics.circle("line", tx, ty, 3)
    if self.target_player_x then
        local px, py = self:to_local(self.target_player_x, self.target_player_y)
        graphics.circle("line", px, py, self.offset_radius)
    end
end


function Cuboid:physics_move(dt)
	local horiz = abs(self.vel.x) > abs(self.vel.y)
	local vel_x, vel_y = horiz and self.vel.x or 0, horiz and 0 or self.vel.y
	self:move_to(self.pos.x + vel_x * dt, self.pos.y + vel_y * dt)
end

function Cuboid:death_sequence()
    local s = self.sequencer
    self.approaching = false
    self.exploding = true
	self.melee_attacking = false
	self.z_index = 0.1
    -- self.melee_attacking = false
    -- self.bullet_push_modifier = self.bullet_push_modifier * 0.75
    self.bullet_push_modifier = 0
	self.drag = 0.1
	self:play_sfx("enemy_cube_die", 0.6)
	-- self.invulnerable = true
	local time = 35
	s:start(function()
		self:start_timer("explode", time)
		s:wait(time)
        self:spawn_bullet(1, 0)
        self:spawn_bullet(-1, 0)
        self:spawn_bullet(0, 1)
        self:spawn_bullet(0, -1)
        self:spawn_bullet(1, 1)
        self:spawn_bullet(-1, -1)
        self:spawn_bullet(1, -1)
        self:spawn_bullet(-1, 1)
		self:play_sfx("enemy_cube_explode", 0.6)
        self:die()
	end)
end

function Cuboid:spawn_bullet(direction_x, direction_y)
	local dx, dy = vec2_normalized_times(direction_x, direction_y, BULLET_SPEED)
	-- dx, dy = vec2_rotated(dx, dy, self.random_bullet_angle)
    local bullet = CuboidBullet(self.pos.x, self.pos.y)
    bullet:apply_impulse(dx, dy)
    self:spawn_object(bullet)
end

function Cuboid:get_sprite()
	if self.exploding then
		return self:tick_pulse(4) and textures.enemy_cube7 or textures.enemy_cube8
	end
    return (self.spin_dir > 0 and ANIMATION or BACKWARD_ANIMATION):loop(self.tick + self.random_offset, 6)
end

function Cuboid:draw()
	if self.beaming and iflicker(self.tick, 2, 2) then
		graphics.push("all")
		graphics.set_color(self:tick_pulse(1) and Color.purple or Color.red)
		local scale = 1 - (inverse_lerp_clamp(BODY_HEIGHT, 200, self.body_height))
		local rect_scale = remap01(scale, 0.5, 1.0)
		graphics.rectangle_centered("fill", 0, 0, 16 * rect_scale, 10 * rect_scale)
		local offset = 1
		local height = self.body_height - offset
		local width = min(10, 16 * rect_scale) * scale

		if scale > 0.0 then
			graphics.rectangle("fill", -width / 2, -height + offset / 2, width, max(height - offset, 0))
		end
		graphics.pop()
	end
	
	if self.intangible and self:tick_pulse(1) then
		return
	end




	
	if self.exploding and iflicker(gametime.tick, 1, 2) then
		-- if self:tick_pulse(4) then
			graphics.push("all")
			self:body_translate()
			-- graphics.rotate(tau / 8)
			local col = iflicker(self.tick, 2, 2) and Color.red or Color.yellow
			graphics.set_color(Color.black)
			graphics.rectangle_centered("fill", 0, 0, 34, 34)
			graphics.set_line_width(12)
			local dist = self:is_timer_running("explode") and (100 * (1 - self:timer_progress("explode"))) or 0
			graphics.set_color(Color.black)
			for i = 1, #ALL_DIRECTIONS do
				local direction = ALL_DIRECTIONS[i]
				local dx, dy = vec2_normalized_times(direction.x, direction.y, dist + 1)
				graphics.line(0, 0, dx, dy)
			end
			graphics.set_color(col)
			graphics.rectangle_centered("fill", 0, 0, 32, 32)
			graphics.set_line_width(10)
			for i = 1, #ALL_DIRECTIONS do
				local direction = ALL_DIRECTIONS[i]
				local dx, dy = vec2_normalized_times(direction.x, direction.y, dist)
				graphics.line(0, 0, dx, dy)
			end
			graphics.pop()
		-- end
	end



	Cuboid.super.draw(self)
end

function Cuboid:exit()
	self:stop_sfx("enemy_cube_descend")
end

CuboidBullet.death_sfx = "enemy_cube_bullet_die"
CuboidBullet.death_sfx_volume = 0.6
CuboidBullet.is_cuboid_bullet = true

function CuboidBullet:new(x, y)
	self.max_hp = 9
    self.team = "neutral"
	self.melee_both_teams = true
	CuboidBullet.super.new(self, x, y)
    self.drag = 0.0
    self.hit_bubble_radius = 5
	self.hurt_bubble_radius = 10
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self.z_index = 10
end

function CuboidBullet:filter_melee_attack(bubble)
	if bubble.parent and bubble.parent.is_cuboid_bullet then
		return false
	end
	return true
end

function CuboidBullet:get_sprite()
    return self:tick_pulse(2) and textures.enemy_cube_bullet1 or textures.enemy_cube_bullet2
end

return Cuboid
