local Shielder = BaseEnemy:extend("Shielder")

local SEARCH_RADIUS = 100
local PUSH_FORCE = 0.005
local MAX_SHIELD_RADIUS = 48
local SHIELD_RADIUS_GROWTH = 0.1
local HEALTH_REGEN = 0.0067
local MAX_HP = 3
local MIN_SHIELD_HP = 0.5

Shielder.death_cry = "enemy_shielder_die"
Shielder.death_cry_volume = 0.8

function Shielder:new(x, y)
	self.max_hp = MIN_SHIELD_HP
	self.hurt_bubble_radius = 6
    Shielder.super.new(self, x, y)
	self:set_max_hp(MAX_HP)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self.bullet_push_modifier = 1.7
    self.drag = 0.02
	self.declump_radius = 32
	self.declump_mass = 1
    self.shield_radius = 10

    self.declump_force = 0.1
    self.nearby_enemies = {}
    self.killed_bullets = {}
	self.z_index = 1


	self.on_terrain_collision = self.terrain_collision_bounce
end

function Shielder:update(dt)
    local x, y, w, h = self.pos.x - SEARCH_RADIUS, self.pos.y - SEARCH_RADIUS, SEARCH_RADIUS * 2, SEARCH_RADIUS * 2
    table.clear(self.nearby_enemies)
    self.num_nearby_enemies = 0
	if self.shielding then
    self.world.game_object_grid:each_self(x, y, w, h, self.process_nearby_object, self)
	end
    
    local average_x, average_y = 0, 0
	local num_enemies = 0
    for enemy in pairs(self.nearby_enemies) do
        local dx, dy = enemy:get_body_center()
        -- self:apply_force(dx * PUSH_FORCE, dy * PUSH_FORCE)
        average_x = average_x + dx
        average_y = average_y + dy
        num_enemies = num_enemies + 1
    end
	
	if num_enemies > 0 then
		average_x = average_x / num_enemies
        average_y = average_y / num_enemies
		local bx, by = self:get_body_center()
		local dx, dy = vec2_direction_to(bx, by, average_x, average_y)

		self:apply_force(dx * PUSH_FORCE, dy * PUSH_FORCE)
	end
	

	local player = self:get_closest_player()
    if player then
		if vec2_distance_squared(self.pos.x, self.pos.y, player.pos.x, player.pos.y) < SEARCH_RADIUS * SEARCH_RADIUS then
			local dx, dy = vec2_direction_to(self.pos.x, self.pos.y, player.pos.x, player.pos.y)
			self:apply_force(-dx * PUSH_FORCE * 4.5, -dy * PUSH_FORCE * 4.5)
		end
	end

    -- local bullet_grid = self.world.bullet_grid
    -- local shield_x, shield_y, shield_w, shield_h = self:get_shield_rect()
    -- bullet_grid:each_self(shield_x, shield_y, shield_w, shield_h, self.shield_bullet, self)
	if not self:is_tick_timer_running("shield_broken") then
		self:heal(HEALTH_REGEN * dt)
	end
    self.shield_radius = remap(self.hp, MIN_SHIELD_HP, self.max_hp, 0, MAX_SHIELD_RADIUS)
	self.shield_radius = max(self.shield_radius, 10)
	self.shielding = self.hp > MIN_SHIELD_HP
end

function Shielder:damage(amount)
	self:start_tick_timer("shield_broken", 50)

    local new_hp = self.hp - amount
    if self.shielding then
        new_hp = max(new_hp, 0.001)
		if new_hp <= MIN_SHIELD_HP then
			self:start_tick_timer("hit_invuln_tick", 1)
		end
    else
		new_hp = 0
	end
	self:set_hp(new_hp)
end

function Shielder.shield_bullet(other, self)
    if self.killed_bullets[other] then return end
	local dist_squared = other.pos:distance_squared(self.pos)
	if dist_squared > (self.shield_radius * self.shield_radius) then return end

    local spawn_position = other.spawn_position
	if spawn_position:distance_squared(self.pos) < (self.shield_radius * self.shield_radius) then return end

    self.killed_bullets[other] = true
	if other.try_push then other:try_push(self, 0.1) end
	other:die()
end

function Shielder:entity_declump_filter(other)
	return Object.is(other, Shielder)
end

function Shielder.process_nearby_object(object, self)
    if object == self then return end
	if Object.is(object, Shielder) then return end
	if object:has_tag("hazard") then return end

    if object:has_tag("enemy") then
        local obj_bx, obj_by = object:get_body_center()
		local bx, by = self:get_body_center()
        local dist_squared = vec2_distance_squared(bx, by, obj_bx, obj_by)
        if dist_squared < SEARCH_RADIUS * SEARCH_RADIUS then
            self.nearby_enemies[object] = true
            self.num_nearby_enemies = self.num_nearby_enemies + 1
        end
		local rs = self.shield_radius + (object.hurt_bubble_radius or 0)
        if dist_squared < rs * rs then
			object:start_tick_timer("shield_invuln", 2)
		end
    end
end

function Shielder:get_sprite()
	return idivmod_eq_zero(self.tick + self.random_offset, 3, 2) and textures.enemy_shielder1 or textures.enemy_shielder2
end

function Shielder:get_shield_rect()
    return self.pos.x - self.shield_radius, self.pos.y - self.shield_radius, self.shield_radius * 2,
    self.shield_radius * 2
end

function Shielder:draw()
	    
    graphics.set_color("002dff")
	local line_offset_size = 2
    
	if self.shielding then
		if idivmod_eq_zero(gametime.tick, 1, 2) then
			graphics.push("all") 
				graphics.set_stencil_mode("draw", 1)
				graphics.circle("fill", 0, 0, self.shield_radius)
				graphics.set_stencil_mode("test", 1)
				local offset = idivmod_eq_zero(gametime.tick, 5, line_offset_size) and 1 or 0
				for i = -self.shield_radius, self.shield_radius, line_offset_size do
					graphics.line(-self.shield_radius, i + offset, self.shield_radius, i + offset)
				end
			graphics.pop()
			graphics.circle("line", 0, 0, self.shield_radius)
		end
	end
	-- end
	graphics.set_color(1, 1, 1, 1)
	
    Shielder.super.draw(self)
    local resolution = 32
    local palette = Palette[textures.enemy_shielder_particle]

	if self.shielding then
		local palette_size = palette.length
		for i = 1, resolution do
			local angle = tau * (i / resolution) + self.elapsed * 0.01
			local x, y = vec2_from_polar(self.shield_radius, angle)
			-- graphics.set_color(1, 1, 1, 1)
			-- -- graphics.circle("fill", x, y, 1)
			-- graphics.points(x-1, y-1)
			-- graphics.points(x+1, y-1)
			-- graphics.points(x+1, y+1)
			-- graphics.points(x-1, y+1)
			-- graphics.points(x+1, y)
			-- graphics.points(x-1, y)
			-- graphics.points(x, y+1)
			-- graphics.points(x, y-1)
			-- graphics.set_color(Palette.rainbow:get_color(14))
			-- graphics.points(x, y)
			graphics.drawp_centered(textures.enemy_shielder_particle, nil, (((i / resolution) * palette_size) + idiv(self.tick, 5)), x, y)
		end
	end
end

function Shielder:floor_draw()
    if self.is_new_tick and idivmod_eq_zero(self.tick, 1, 2) then
		
	end
end

graphics.set_color(1, 1, 1, 1)

return Shielder
