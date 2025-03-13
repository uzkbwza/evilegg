local Cultist = require("obj.Spawn.Enemy.BaseEnemy"):extend("Cultist")
local FloorParticle = GameObject2D:extend("FloorParticle")
local CultistGrabber = GameObject2D:extend("CultistGrabber")

local PULL_RADIUS = 32
local PULL_FORCE = 1.0255
local GRAB_SPEED = 3
local GRAB_TIME = 50
local GRAB_RADIUS = 9
local HURT_TIME = 45

function Cultist:new(x, y)
    self.body_height = 7
    self.max_hp = 4
	self.hit_bubble_radius = 4
    Cultist.super.new(self, x, y)
	self.walk_speed = 0.055
	self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AutoStateMachine, "Waiting")
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self.bullet_push_modifier = 1.0
	self.declump_radius = 7
	self.declump_mass = 2.0
	self.particles = {}
	self.nearby_rescues = {}
	self:ref_array("held_rescues")
	self.hold_positions = {}
end

function Cultist:enter()
	self:add_hurt_bubble(0, -4, 3, "main")
	self:add_hurt_bubble(0, 0, 5, "main2")
    self:add_hurt_bubble(0, 3, 5, "main3")
    self:ref("floor_particle", self:spawn_object(FloorParticle(0, 0)))
    self:add_exit_function(function()
		if self.floor_particle then
            self.floor_particle:finish()
		end
	end)
end

function Cultist:get_sprite()
	return textures.enemy_cultist
end

function Cultist:entity_declump_filter(other)
	if table.is_empty(self.hold_positions) then
		return true
	end
	return false
end

function Cultist:walk_toward_target(dt)
	local closest = nil

	local closest_dist = math.huge
	local rescue_objects = self:get_objects_with_tag("rescue_object")
	if rescue_objects then
		for _, rescue in rescue_objects:ipairs() do
			local dist = self:body_distance_to(rescue)
			if rescue.grabbed_by_cultist then
				goto continue
			end
			if dist < closest_dist then
				closest_dist = dist
				closest = rescue
			end
			::continue::
		end
	end

	if not closest then
		closest = self:get_closest_player()
	end

	if closest then
		local bx, by = self:get_body_center()
		local cx, cy = closest:get_body_center()
		local dx, dy = cx - bx, cy - by
		local direction_x, direction_y = vec2_normalized(dx, dy)
		self:apply_force(direction_x * self.walk_speed, direction_y * self.walk_speed)
	end
end

function Cultist:update(dt)
	if self.held_rescues:length() == 0 then
		self:walk_toward_target(dt)
		self.bullet_push_modifier = 1.0
	else
		self.bullet_push_modifier = 0.25
		-- self.applying_forces = false
		-- self.vel:mul_in_place(0)
	end

	self.floor_particle:move_to(self:get_body_center())
	local bx, by = self:get_body_center()
	local x, y, w, h = bx - PULL_RADIUS, by - PULL_RADIUS, PULL_RADIUS * 2, PULL_RADIUS * 2
	self.world.rescue_grid:each_self(x, y, w, h, self.gather_nearby_rescues, self)

	for _, rescue in ipairs(self.nearby_rescues) do
		local dist = self:body_distance_to(rescue)
		if dist < GRAB_RADIUS then
			if not self.hold_positions[rescue] then
				self:ref_array_push("held_rescues", rescue)
				-- self.nearby_rescues[rescue] = nil
				rescue.grabbed_by_cultist = true
				self.hold_positions[rescue] = Vec2(self:to_local(rescue.pos.x, rescue.pos.y))

				local s = self.sequencer
				local co = s:start(function()
					while rescue.hp > 0 do
						s:wait(HURT_TIME)
						if not self.hold_positions[rescue] then
							return
						end
						rescue:damage(1)
					end
				end)
				signal.connect(rescue, "destroyed", self, "on_held_rescue_destroyed", function()
					self.hold_positions[rescue] = nil
					s:stop(co)
				end, true)
			else
				local dx, dy = self:body_direction_to(rescue)
				rescue:apply_force(-dx * PULL_FORCE, -dy * PULL_FORCE)
			end
		end
	end
	table.clear(self.nearby_rescues)


	for _, rescue in self.held_rescues:ipairs() do
		local hold_pos = self.hold_positions[rescue]
		if hold_pos then
			rescue:move_to(self:to_global(hold_pos.x, hold_pos.y))
		end
	end
end

function Cultist:exit()
	for _, rescue in self.held_rescues:ipairs() do
		rescue.grabbed_by_cultist = nil
	end
end

function Cultist:filter_melee_attack(bubble)
	if bubble.parent:has_tag("rescue_object") then
		return false
	end
	return true
end

function Cultist.gather_nearby_rescues(other, self)
	if other.grabbed_by_cultist then
		return
	end
	local dist = self:body_distance_to(other)

	if dist < PULL_RADIUS then
		table.insert(self.nearby_rescues, other)
	end
end

function FloorParticle:new(x, y)
    FloorParticle.super.new(self, x, y)
    self:add_time_stuff()
	self.particles = {}
	self.z_index = -1
end

function FloorParticle:finish()
	self.done = true
	for particle, _ in pairs(self.particles) do
		particle.outward_speed = abs(rng.randfn(2, 0.5))
	end
end

function FloorParticle:update(dt)
    if self.is_new_tick and not self.done and rng.percent(40) then
        local particle = {}
        particle.dist = rng.randf_range(12, 64)
        particle.start_angle = rng.randf_range(0, tau)
        particle.t = 0
		particle.visible = rng.percent(25)
        particle.angle_offset = 0
        particle.elapsed = 0
        particle.outward_offset = 0
		particle.outward_speed = 0
        particle.final_offset = rng.randf(-1, 1) * tau
        particle.size = rng.randf_range(0.25, 1) * 4
        particle.offset = rng.randf(0, tau)
		self.particles[particle] = true
    end
    if self.done and table.is_empty(self.particles) then
        print("here")
        self:queue_destroy()
    end
    for particle, _ in pairs(self.particles) do
        particle.elapsed = particle.elapsed + dt
		particle.t = particle.elapsed / 190
        particle.angle_offset = particle.angle_offset + dt * (1 / 190) * (self.done and 0.15 or 1)
        if particle.t >= 1 then
            self.particles[particle] = nil
        end
        particle.outward_offset = particle.outward_offset + particle.outward_speed * dt
		particle.outward_speed = drag(particle.outward_speed, 0.1, dt)
		
	end
end

function FloorParticle:get_particle_position(particle)
    local dist = particle.dist * (1 - particle.angle_offset)
	dist = remap_lower(dist, 0, particle.dist, 10)
	local angle = particle.start_angle + particle.offset + particle.angle_offset * particle.final_offset
	local vx, vy = polar_to_cartesian(dist + particle.outward_offset, angle)
	return vx, vy
end

function FloorParticle:draw()

	-- graphics.set_color(1, 1, 1, 1)
    for particle, _ in pairs(self.particles) do
		if not particle.visible then goto continue end

        local size = particle.size * (particle.angle_offset)

		local vx, vy = self:get_particle_position(particle)
		local color = Color.red
		if idivmod_eq_zero(particle.elapsed, 6, 2) then
			color = Color.blue
		end
        graphics.set_color(color)
		-- if size >= 0.1 then
		graphics.rectangle_centered("fill", vx, vy, size, size)
        -- elseif idivmod_eq_zero(particle.elapsed, 1, max(1, floor(10 - particle.elapsed / 4))) then
			-- graphics.points(vx, vy)
		-- end
		::continue::
    end

end

function FloorParticle:floor_draw()
    if not self.is_new_tick then
        return
    end

	if not self.done then
		graphics.set_color(0, 0, 0, 1)
		
		for i = 1, rng.randi_range(1, 3) do
			local size = rng.randf_range(2, 5)
			local vx, vy = rng.random_vec2_times(rng.randfn(0, 3))
			graphics.rectangle_centered("fill", vx, vy, size, size)
		end
	end
	
    for particle, _ in pairs(self.particles) do

		if rng.percent(60) then goto continue end
		local alpha = abs(rng.randfn(0.35, 0.055)) * particle.angle_offset
		graphics.set_color(alpha * 1, alpha * 0.1, 0)
		local size = particle.size * (particle.angle_offset)
		local vx, vy = self:get_particle_position(particle)
		graphics.rectangle_centered("fill", vx, vy, size, size)
		::continue::
	end
end

function Cultist:draw()
	self:body_translate()

	local palette, offset = self:get_palette_shared()

	graphics.drawp_centered(self:get_sprite(), palette, offset, 0, 0, 0, self.flip, 1)

	if debug.can_draw_bounds() then
		graphics.set_color(Color.green)
		graphics.circle("line", 0, 0, PULL_RADIUS)
	end

end

return Cultist
