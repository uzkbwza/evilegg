local Gnome = BaseEnemy:extend("Gnome")
local GnomeBullet = BaseEnemy:extend("GnomeBullet")
local GnomeFloorParticle = Effect:extend("GnomeFloorParticle")

Gnome.spawn_cry = "enemy_gnome_spawn"

Gnome.death_cry = "enemy_gnome_death"

local SPREAD = 2
local SHOOT_SPEED = 6
local SHOOT_INVERVAL = 5

function Gnome:new(x, y)
    self.max_hp = 4

    self.body_height = 6

	BaseEnemy.new(self, x, y)
    
	self.sprite = textures.enemy_gnome1
    self.walk_speed = 1.175
	self.run_away_speed = 0.15
    self.roam_diagonals = true
	self.walk_toward_player_chance = 50
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self.declump_radius = 9
    self.declump_mass = 0.5
	-- self.declump_force = (self.declump_force or 0.005)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self:lazy_mixin(Mixins.Behavior.Roamer)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self.bullet_push_modifier = 0.8
end

function Gnome:enter()
	self:add_tag("gnome")
	self:add_hurt_bubble(0, -4, 3, "main")
	self:add_hurt_bubble(0, 0, 5, "main2")
    self:add_hurt_bubble(0, 2, 5, "main3")
	self:ref("floor_particle", self:spawn_object(GnomeFloorParticle(self.pos.x, self.pos.y, self)))
end

function Gnome:should_live()
	local staying_alive = false
	for _, gnome in self.world:get_objects_with_tag("gnome"):ipairs() do
		if gnome.state == "Normal" then
            staying_alive = true
			break
		end
	end
	return staying_alive
end

function Gnome:death_sequence(hit_by)
	
    if not self:should_live() then
        Gnome.super.death_sequence(self, hit_by)
    else
		self.started_death_sequence = false
		self:change_state("Respawning")
	end
end

function Gnome:draw()
	
end

function Gnome:state_Normal_enter()
    self:reset_physics()
	self.respawn_particles = {}
    self.applying_physics = true
    self.roaming = true
    self.sprite = textures.enemy_gnome1
    self.intangible = false
    self.melee_attacking = true
	self.running_away = false
end

function Gnome:state_Normal_update(dt)
    self.sprite = iflicker(self.tick, 6, 2) and textures.enemy_gnome2 or textures.enemy_gnome1
    local closest_player_x, closest_player_y = self:closest_last_player_body_pos()
	
    if closest_player_x then
        if self.running_away then
            local dx = closest_player_x - self.pos.x
            local dy = closest_player_y - self.pos.y
            local dist = sqrt(dx * dx + dy * dy)
            dx, dy = vec2_normalized(dx, dy)
            self:apply_force(-dx * self.run_away_speed, -dy * self.run_away_speed)
            if dist > 110 then
                self.running_away = false
                self.roaming = true
            end
        else
            local dx = closest_player_x - self.pos.x
            local dy = closest_player_y - self.pos.y
            local dist = sqrt(dx * dx + dy * dy)
            if dist < 40 then
                self.running_away = true
                self.roaming = false
            end
        end
    end
	
    if self.is_new_tick then
		if not self.preparing_to_shoot and self.state_tick > 60 and rng:percent(1.6) and self.world:get_number_of_objects_with_tag("gnome_shooting") < 2 and not self.shooting and not self.running_away and not self:is_tick_timer_running("shooting_cooldown") then

			local closest_player = self:get_closest_player()

            if closest_player and self:body_distance_to(closest_player) > 100 then
				self.preparing_to_shoot = true
				self:add_tag("gnome_shooting")
				self:play_sfx("enemy_gnome_prepare_to_shoot", 0.7, 1.0)
				self.roaming = false
				self:start_tick_timer("preparing_to_shoot", 20, function()
                    self.preparing_to_shoot = false
					self.shooting = true
					self:start_tick_timer("shooting", rng:randf(15, 30), function()
						self.shooting = false
						self:remove_tag("gnome_shooting")
						self:start_tick_timer("shooting_cooldown", rng:randf(30, 60))
						self.roaming = true
					end)
				end)
			end
        elseif self.shooting and self.state_tick % SHOOT_INVERVAL == 0 then
            local closest_player = self:get_closest_player()
			if closest_player then
				local bx, by = self:get_body_center()
				local px, py = closest_player:get_body_center()
				local dir_x, dir_y = vec2_direction_to(bx, by, px, py)
				-- dir_x, dir_y = vec2_rotated(dir_x, dir_y, rng:randfn(0, deg2rad(SPREAD)) * (rng:percent(20) and 10 or 1))
				local aim_offset_x, aim_offset_y = vec2_mul_scalar(dir_x, dir_y, 4)
				local bullet = GnomeBullet(bx + aim_offset_x, by + aim_offset_y)
				bullet:apply_impulse(dir_x * SHOOT_SPEED, dir_y * SHOOT_SPEED)
				self.world:spawn_object(bullet)
				self:play_sfx("enemy_gnome_shoot", 0.5, 1.0)
			end
		end
    end
	
	-- print(self:is_invulnerable())
end

function Gnome:state_Respawning_enter()
    self:play_sfx("enemy_gnome_respawn_enter", 0.75, 1.0)
    self:reset_physics()
    self.shooting = false
    self.preparing_to_shoot = false
	if self:has_tag("gnome_shooting") then
		self:remove_tag("gnome_shooting")
	end
    self.roaming = false
    self.applying_physics = false
    self.sprite = textures.enemy_gnome3
    self.intangible = true
    self.melee_attacking = false
end


function Gnome:get_sprite()
	return self.sprite
end

function Gnome:state_Normal_draw()
    Gnome.super.draw(self)
end

function Gnome:state_Respawning_update(dt)
    if not self:should_live() then
        self:die(self:get_closest_player())
        return
    end
	
    local num_other_gnomes = (self.world:get_number_of_objects_with_tag("gnome") - 1)


	local base = 1.01
	local mul = 1.3
    local offs = -0.4
    local t = 0.4
	local p = 80
	local g = num_other_gnomes * 80
	
	local goal_tick = max(round(lerp(logb(num_other_gnomes * mul + offs, base), g, t)), p)
	
    if debug.enabled then
		dbg("gnome_respawn_goal_tick", goal_tick)
	end

	if self.state_tick > goal_tick then
		self:play_sfx("enemy_gnome_respawn_exit", 0.75, 1.0)
		self.number_of_revives = (self.number_of_revives or 0) + 1
		self:set_hp(self.max_hp - self.number_of_revives)
		self:change_state("Normal")
		return
	end

    if self.is_new_tick and self.tick % 3 == 0 then
        local particle = {}
        particle.elapsed = 0
		particle.x = rng:randf(-6, 6)
        particle.y = rng:randf(-2, 2)
		particle.t = 0
		self.respawn_particles[particle] = true
	end

	local particle_time = 20
	local to_remove = {}
	for particle in pairs(self.respawn_particles) do
        
		particle.elapsed = particle.elapsed + dt
		particle.t = particle.elapsed / particle_time

		if particle.elapsed > particle_time then
			table.insert(to_remove, particle)
		end
	end

	for _, particle in ipairs(to_remove) do
		self.respawn_particles[particle] = nil
	end
end


function Gnome:state_Respawning_draw()

    if iflicker(gametime.tick, 2, 2) then
        Gnome.super.draw(self)
    else
        self:body_translate()
    end
	
	graphics.set_color(Color.magenta)
	if self.state_tick < 3 then
		graphics.rectangle_centered("fill", 0, 0, 18 + self.state_tick, 23 + self.state_tick)
	end
		

	graphics.set_color(Color.magenta)
	for particle in pairs(self.respawn_particles) do
        local x, y = particle.x, particle.y
        local base_line_length = 40
        local line_length = base_line_length * (ease("inCubic")(particle.t))
        y = y - base_line_length + 4
		local size = 4 * (ease("inCubic")(particle.t))
		graphics.rectangle_centered("fill", x, y + line_length, size, size)
	end
end

function Gnome:get_palette()
	local offset = 0

	if self.preparing_to_shoot then
		offset = idiv(self.tick, 3)
	end

	return nil, offset
end


function GnomeBullet:new(x, y)
	self.max_hp = 1

    GnomeBullet.super.new(self, x, y)
    self.drag = 0.00
    self.hit_bubble_radius = 2
	self.hurt_bubble_radius = 4
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self.bullet_push_modifier = 5.0
    self.z_index = 10
end

local bullet_textures = {
	textures.enemy_gnome_bullet1,
	textures.enemy_gnome_bullet2,
	textures.enemy_gnome_bullet3,
}

function GnomeBullet:get_sprite()
    return textures.enemy_gnome_bullet4
end

function GnomeBullet:draw()
    local index, rotation, y_scale = get_16_way_from_3_base_sprite(self.vel:angle())
	local palette, offset = self:get_palette_shared()
	graphics.drawp_centered(bullet_textures[index], palette, offset, 0, 0, rotation, 1, y_scale)
	local scale = 16 - ((self.tick - 1) * 4)
	if scale > 0 then
		graphics.set_color(palette:tick_color(self.tick + self.random_offset))
		graphics.rotate(deg2rad(45))
		graphics.rectangle_centered("fill", 0, 0, scale, scale)
	end
end

function GnomeBullet:get_palette()
	local palette, offset = GnomeBullet.super.get_palette(self)

	offset = idiv(self.tick, 2)

	return palette, offset
end

function GnomeBullet:update(dt)
	if self.vel:magnitude() < 0.05 then
		self:die()
	end
end

function GnomeFloorParticle:new(x, y, parent)
    self:ref("parent", parent)
    GnomeFloorParticle.super.new(self, x, y)
    self.z_index = -1
	self.duration = 0
end

function GnomeFloorParticle:update(dt)
    if not self.parent then
        self:queue_destroy()
        return	
	end
    self:move_to(self.parent.pos.x, self.parent.pos.y)
end

function GnomeFloorParticle:draw()
	graphics.set_line_width(2)
	graphics.set_color(iflicker(self.tick, 2, 3) and Color.transparent or (iflicker(self.tick, 2, 2) and Color.magenta or Color.white))
	graphics.rectangle_centered("line", 0, 0, 16, 10)
end

AutoStateMachine(Gnome, "Normal")

return Gnome
