-- i want to kill myself

local Rook = BaseEnemy:extend("Rook")

local RookProjectile = BaseEnemy:extend("RookProjectile")

function Rook:new(x, y)
	self.max_hp = 13
    BaseEnemy.new(self, x, y)
	self.roam_diagonals = true
    self:lazy_mixin(Mixins.Behavior.Roamer)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)

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
    if self.is_new_tick and not self.shooting_projectile and rng.percent(0.4) then
        self:shoot_projectile()
    end
	
	if self.projectile and not self.shot_projectile_yet then
		self.projectile:move_to(self.pos.x, self.pos.y)
	end
end

function Rook:shoot_projectile()
	self.shooting_projectile = true
	self.shot_projectile_yet = false
    self:ref("projectile", self:spawn_object(RookProjectile(self.pos.x, self.pos.y)))
	local s = self.sequencer
    s:start(function()
		self.projectile:grow()
        s:wait_until_truthy(self.projectile, "done_growing")
		s:wait(20)
		-- s:wait(120)
		-- self.shooting_projectile = false
	end)
end

function RookProjectile:new(x, y)
	self.max_hp = 5
    RookProjectile.super.new(self, x, y)
    -- self.drag = 0.014
    self.hit_bubble_radius = 8
	self.hurt_bubble_radius = 6
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    -- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
    self.z_index = 1
	self.body_height = 12
    self.floor_draw_color = Palette.rainbow:get_random_color()
    self.intangible = true
	self.melee_attacking = false
    self.done_growing = false
    self.scale = 0
	self.grow_particles = bonglewunch()
    self.particles_to_remove = {}

end


function RookProjectile:grow()
	local s = self.sequencer
	s:start(function()
        s:tween_property(self, "scale", 0, 1, 90, "linear")
        self.done_growing = true
		self.grow_particles:clear()
	end)
end

function RookProjectile:update(dt)
    if self.is_new_tick and not self.done_growing then
        local particle = {
            t = 0,
            angle = stepify(rng.random_angle(), tau / 4) + tau / 8,
			speed = rng.randf_range(0.1, 0.2),
            distance = rng.randf_range(1, 3),
        }
        self.grow_particles:push(particle)
    end
	
	table.clear(self.particles_to_remove)

	for i, particle in self.grow_particles:ipairs() do
		particle.t = particle.t + dt
		particle.distance = particle.distance - dt * particle.speed
		if particle.distance <= 1 then
			table.insert(self.particles_to_remove, particle)
		end
	end

    for i, particle in ipairs(self.particles_to_remove) do
        self.grow_particles:remove(particle)
    end
end

function RookProjectile:draw()
	local center_x, center_y = rng.random_vec2_times(rng.randfn(0, 1))
    local stroke_x, stroke_y = rng.random_vec2_times(rng.randfn(0, 2))
	
    local rect_size = self.scale * 18

	graphics.set_color(Color.yellow)
	love.graphics.rectangle("fill", center_x, center_y, rect_size, rect_size)
	graphics.set_color(Color.blue)
	love.graphics.rectangle("line", stroke_x, stroke_y, rect_size, rect_size)
end

function RookProjectile:get_sprite()
	return textures.enemy_rook_projectile
end

return Rook
