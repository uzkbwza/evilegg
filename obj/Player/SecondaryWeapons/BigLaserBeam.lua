local BigLaserBeam = GameObject2D:extend("BigLaserBeam")

local BigLaserBeamFloor = GameObject2D:extend("BigLaserBeamFloor")

local BigLaserBeamAimingLaser = Effect:extend("BigLaserBeamAimingLaser")

local BEAM_PUSH_STRENGTH = 3

local BEAM_TARGET_DECAY = 120
local TURN_DIFF_DECAY = 20
local BEAM_TARGET_LENGTH = 512
local BEAM_HITBOX_RESOLUTION = 10
local BEAM_PARTICLE_SPEED = 16
local BEAM_PARTICLE_SIZE = 24
local BEAM_PARTICLE_DAMAGE = 1
local NUM_BEAM_PARTICLES_PER_FRAME = 2

local BeamParticle = Object:extend("BeamParticle")

function BigLaserBeam:new(x, y, dx, dy)
    BigLaserBeam.super.new(self, x, y)
	self.dx = dx
    self.dy = dy

    self.z_index = 0.5
	
	self.team = "player"

    self:lazy_mixin(Mixins.Behavior.TwinStickEntity)

	self.target_endpoint_x = x + dx * BEAM_TARGET_LENGTH
    self.target_endpoint_y = y + dy * BEAM_TARGET_LENGTH
	
	self.slow_turn_angle = vec2_angle(self.dx, self.dy)

	self.clamped_target_endpoint_x = x + dx * BEAM_TARGET_LENGTH
    self.clamped_target_endpoint_y = y + dy * BEAM_TARGET_LENGTH

	self.real_turn_endpoint_x = x + dx * BEAM_TARGET_LENGTH
    self.real_turn_endpoint_y = y + dy * BEAM_TARGET_LENGTH

	-- self.persist = true
	-- self.turn_diff_x = 0
	-- self.turn_diff_y = 0

    self.hitbox_curve_points = {}
	
	self.beam_particles = bonglewunch()
    self.beam_end_particles = bonglewunch()

    self.beam_particles_to_remove = {}
	self.beam_end_particles_to_remove = {}


    self.beam_start = 0
	
	self.instance_rng = rng:new_instance()
    self.random_offset = rng:randi()
	
	self.beam_particle_counter = 0

end

function BigLaserBeam:enter()
    self:play_sfx("player_big_laser_shoot")
	self:play_sfx("player_big_laser_loop", 0.7, 1, true)
	self:ref("floor", self:spawn_object(BigLaserBeamFloor(self.pos.x, self.pos.y))):ref("parent", self)

	for i = 1, 45 do
		self:create_beam_dust()
	end
end

function BigLaserBeam:exit()
	self:stop_sfx("player_big_laser_loop")
end

function BigLaserBeam:create_beam_dust(x, y, dx, dy, speed, spread, spread_width)
    spread = spread or deg2rad(30)
    spread_width = spread_width or 20
    local perp_x, perp_y = vec2_perpendicular(self.dx, self.dy)
    dx, dy = dx or self.dx, dy or self.dy
    dx, dy = vec2_rotated(dx, dy, rng:randf(-spread, spread))
    x, y = x or self.pos.x + dx * 10, y or self.pos.y + dy * 10
    local spread_width_amount = rng:rand_sign() * rng:randf(spread_width - 10, spread_width + 10)

    local spread_x, spread_y = vec2_mul_scalar(perp_x, perp_y, spread_width_amount)
    x, y = vec2_add(x, y, spread_x, spread_y)

    x, y = vec2_add(x, y, rng:random_vec2_times(rng:randf(0, 5)))
    speed = speed or rng:randf(0, 20)
    self.floor:create_dust_particle(x, y, dx, dy, speed)
end

BeamParticle.center_out_velocity_multiplier = 5.0

function BeamParticle:new(x, y, dx, dy, damage)
    self.pos = Vec2(x, y)
    self.dx = dx
    self.dy = dy
	
    signal.register(self, "destroyed")
	
	self.prev_x = x
	self.prev_y = y
	self.size = BEAM_PARTICLE_SIZE
	self.elapsed = 0
	self.damage = damage
	self.random_offset1 = rng:randi()
	self.random_offset2 = rng:randi()
	self.hit_objects = {}
	self.hit_something = false
end

function BeamParticle:get_death_particle_hit_velocity()
	return vec2_mul_scalar(self.dx, self.dy, BEAM_PARTICLE_SPEED * 25)
end

function BigLaserBeam:update(dt)
    -- self:update_points(dt)

	if not self.floor then
        self:ref("floor", self:spawn_object(BigLaserBeamFloor(self.pos.x, self.pos.y))):ref("parent", self)
		-- self:bind_destruction(self.floor)
	end


	local bounds = self.world.room.bullet_bounds
    for _, particle in self.beam_particles:ipairs() do
        self:update_beam_particle(particle, dt)
        if particle.hit_something or not bounds:contains(particle.pos.x, particle.pos.y) then
            table.insert(self.beam_particles_to_remove, particle)
        end
    end

    for _, particle_to_remove in ipairs(self.beam_particles_to_remove) do
        signal.emit(particle_to_remove, "destroyed")
		signal.cleanup(particle_to_remove)
        self:spawn_beam_end_particle(particle_to_remove)
        self.beam_particles:remove(particle_to_remove)
    end
	table.clear(self.beam_particles_to_remove)

	for _, particle in self.beam_end_particles:ipairs() do
		self:update_beam_end_particle(particle, dt)
	end

    for _, particle_to_remove in ipairs(self.beam_end_particles_to_remove) do
        self.beam_end_particles:remove(particle_to_remove)
    end
	table.clear(self.beam_end_particles_to_remove)

	
    if self.is_new_tick and not self.finished then

		if rng:percent(10) then
			for i = 1, rng:randi(1, 5) do
				self:create_beam_dust()
			end
		end
		for i = 1, NUM_BEAM_PARTICLES_PER_FRAME do
			
			local beam_particle = BeamParticle(self.pos.x, self.pos.y, self.dx, self.dy, BEAM_PARTICLE_DAMAGE / NUM_BEAM_PARTICLES_PER_FRAME)

            self.beam_particle_counter = self.beam_particle_counter + 1
			
            beam_particle.pos.x, beam_particle.pos.y = vec2_add(beam_particle.pos.x, beam_particle.pos.y,
            vec2_mul_scalar(self.dx, self.dy, 5))
            beam_particle.pos.x, beam_particle.pos.y = vec2_add(beam_particle.pos.x, beam_particle.pos.y,
            rng:random_vec2_times(rng:randf(0, 10)))
			beam_particle.radius = beam_particle.size / 2
			-- beam_particle.dx, beam_particle.dy = vec2_direction_to(beam_particle.pos.x, beam_particle.pos.y, self.target_endpoint_x, self.target_endpoint_y)

            self.beam_particles:push(beam_particle)
			
			self:update_beam_particle(beam_particle, (i - 1) / NUM_BEAM_PARTICLES_PER_FRAME + 1.1)
		end
    end

	dbg("num_beam_particles", self.beam_particles:length())

    if self.finished
		and self.beam_end_particles:is_empty()
		and self.beam_particles:is_empty()
		then
		self:queue_destroy()
	end

end

function BigLaserBeam:spawn_beam_end_particle(particle)
	local beam_end_particle = {
        pos = Vec2(particle.pos.x, particle.pos.y),
        elapsed = 0,
		size = rng:randf(32, 40),
        duration = rng:randf(20, 50),
        random_offset = rng:randi(),
		num_particles = max(rng:randi(-1, 3), 1),
    }
	
	(particle.dy < 0 and self.beam_end_under_particles or self.beam_end_particles):push(beam_end_particle)
end

function BigLaserBeam:update_beam_end_particle(particle, dt)
	particle.elapsed = particle.elapsed + dt
	if particle.elapsed > particle.duration then
		table.insert(self.beam_end_particles_to_remove, particle)
	end
end

function BigLaserBeam:draw_beam_start()
	graphics.push("all")
	local start_x, start_y = self.dx * 18, self.dy * 18
	self.instance_rng:set_seed(self.random_offset + self.tick)
	local size = self.instance_rng:randf(10, 30)
	size = size * (1 + (1 - ease("outSine")(clamp01(self.elapsed / 25))) * 1.05)
    graphics.set_color(Palette.big_laser:tick_color(self.elapsed))
	graphics.rectangle_centered("fill", start_x, start_y, size + 4, size + 4)
	graphics.set_line_width(2)
	graphics.rectangle_centered("line", start_x, start_y, size + 8, size + 8)
	graphics.rectangle_centered("line", start_x, start_y, size + 16, size + 16)
	graphics.set_color(Color.white)
	graphics.rectangle_centered("fill", start_x, start_y, size, size)
	graphics.pop()
end

function BigLaserBeam:draw_beam_end_particle(particle, layer)
    graphics.push("all")
    local num_particles = particle.num_particles
	local t = clamp01(particle.elapsed / particle.duration)
	local irng = self.instance_rng
	
    for i = 1, num_particles do
        irng:set_seed(particle.random_offset + i)
		local center = i == 1
		local t2 = remap01(t, 0, irng:randf(center and 0.8 or 0.1, 1))
        local x, y = particle.pos.x, particle.pos.y
		local size = particle.size
		
		local travel_distance = irng:randf(2, 32)
        
        if center then
            travel_distance = travel_distance * 0.25
        else
            size = irng:randf(particle.size * 0.05, particle.size * 0.25)
            x, y = vec2_add(x, y, irng:random_vec2_times(irng:randf(0, 16)))
        end

		size = size * (1 - ease("outExpo")(t2))
		
        y = y - travel_distance * ease("outExpo")(t2)
		
		x, y = self:to_local(x, y)


		if layer == 2 then
			graphics.set_color(Palette.big_laser_beam_end_particle_fill:interpolate_clamped(t2))
		elseif layer == 1 then
			local line_width = max(round(size / 10), 1)
            graphics.set_line_width(line_width)
            size = size + line_width * 2
            if center and t2 < 0.5 then
                local center_scale = 1 + (ease("linear")(t2)) * irng:randf(5, 24)
				graphics.set_line_width(irng:randf(1, 3))
				graphics.set_color(Palette.big_laser_beam_end_particle_outline:interpolate_clamped(t2 * 3))
				graphics.rectangle_centered("line", x, y, size * center_scale, size * center_scale)
			end
			graphics.set_color(Palette.big_laser_beam_end_particle_outline:interpolate_clamped(t2))
		end

		

		graphics.rectangle_centered(layer == 2 and "fill" or "line", x, y, size, size)
	end
    graphics.pop()
	irng:set_seed(rng:randi())
end
function BigLaserBeam:draw()


	for _, particle in self.beam_end_particles:ipairs() do
		self:draw_beam_end_particle(particle, 1)
	end
	for _, particle in self.beam_end_particles:ipairs() do
		self:draw_beam_end_particle(particle, 2)
	end

    for _, particle in self.beam_particles:ipairs() do
        self:draw_beam_particle(particle, 1)
    end

	
    if not self.finished then
        self:draw_beam_start()
    end

    for _, particle in self.beam_particles:ipairs() do
        self:draw_beam_particle(particle, 2)
    end

	
    -- for _, particle in self.beam_particles:ipairs() do
    --     self:draw_beam_particle(particle, 2)
    -- end

	-- graphics.push("all")
	-- graphics.set_color(Color.green)
    -- graphics.set_line_width(1)

	-- local num_points = 50 * self:get_line_length_ratio()

	-- local period = 3

    -- for i = remap(self.beam_start, 0, 1, 1, num_points - 1), num_points - 1 do
	-- 	local offset = (self.elapsed % period) / period / num_points
	-- 	local x, y = self:to_local(self:interpolate_curve(i / num_points + offset))
	-- 	graphics.rectangle_centered("fill", x, y, 18, 18)
	-- end

	-- graphics.pop()
end

function BigLaserBeam:debug_draw()
    if not debug.can_draw_bounds() then
        return
    end
	
	for _, particle in self.beam_particles:ipairs() do
        local x, y = self:to_local(particle.pos.x, particle.pos.y)
		local old_x, old_y = self:to_local(particle.prev_x, particle.prev_y)
		graphics.set_color(Color.magenta)
		graphics.debug_capsule(old_x, old_y, x, y, particle.radius, true)
		-- graphics.set_color(Color.green)
	end
end

function BigLaserBeam:update_beam_particle(particle, dt)
	local bounds = self.world.room.bullet_bounds
	particle.prev_x = particle.pos.x
    particle.prev_y = particle.pos.y
	
	particle.pos.x, particle.pos.y = bounds:clamp_circle(particle.pos.x, particle.pos.y, particle.radius)
    particle.pos.x, particle.pos.y = vec2_add(particle.pos.x, particle.pos.y, particle.dx * dt * BEAM_PARTICLE_SPEED,
        particle.dy * dt * BEAM_PARTICLE_SPEED)

    particle.elapsed = particle.elapsed + dt

	self:check_hit_objects(particle, dt)

    if self.is_new_tick and rng:percent(5) then
		local dir = rng:rand_sign()
        local outside_x, outside_y = vec2_perpendicular_normalized_times(particle.dx, particle.dy,
            dir * rng:randf(particle.radius - 10, particle.radius + 10))
		local dx, dy = vec2_rotated(particle.dx, particle.dy, -dir * rng:randf(deg2rad(1), deg2rad(30)))
		self.floor:create_dust_particle(particle.pos.x + outside_x, particle.pos.y + outside_y, dx, dy, rng:randf(BEAM_PARTICLE_SPEED - 10, BEAM_PARTICLE_SPEED + 10) / 3)
	end
end

local HIT_TEAMS = {
	"enemy",
    "neutral",
	-- "player",
}

HIT_TEAMS[0] = #HIT_TEAMS

function BigLaserBeam:check_hit_objects(particle, dt)
	local x1, y1 = particle.prev_x, particle.prev_y
	local x2, y2 = particle.pos.x, particle.pos.y
	
	local rx = min(x1, x2) - particle.radius
	local ry = min(y1, y2) - particle.radius
	local rw = max(x1, x2) + particle.radius - rx
    local rh = max(y1, y2) + particle.radius - ry

    for i = 1, HIT_TEAMS[0] do
		local hurt_bubbles = self.world.hurt_bubbles[HIT_TEAMS[i]]
		hurt_bubbles:each_self(rx, ry, rw, rh, self.try_hit, self, particle, dt)
	end
end

function BigLaserBeam.try_hit(bubble, self, particle, dt)
    local parent = bubble.parent
	
    if particle.hit_objects[parent.id] then return end

	if parent.intangible then return end

	if bubble:collides_with_capsule(particle.prev_x, particle.prev_y, particle.pos.x, particle.pos.y, particle.radius) then
		parent:hit_by(particle)


		particle.hit_objects[parent.id] = true
		if not parent.bullet_passthrough then
			particle.hit_something = true
			self:play_sfx("player_big_laser_beam_hit", 0.55)
		end
		if parent.is_simple_physics_object then
			local force_x, force_y = vec2_normalized_times(particle.dx, particle.dy, BEAM_PUSH_STRENGTH * max(0.05, parent.bullet_push_modifier or 1))
			-- parent:get_pushed_by_bullet(force_x, force_y)
			parent:apply_force(force_x, force_y)
		end
	end
end
function BigLaserBeam:update_dust_particle(particle, dt)
	local bounds = self.world.room.bullet_bounds
	particle.pos.x, particle.pos.y = bounds:clamp_circle(particle.pos.x, particle.pos.y, particle.radius)
	
    particle.pos.x, particle.pos.y = particle.pos.x + particle.vel.x * dt, particle.pos.y + particle.vel.y * dt
end

function BigLaserBeam:floor_draw()

	if not self.is_new_tick then
		return
	end

    -- for _, particle in self.beam_particles:ipairs() do
	-- 	if rng:percent(30) then
	-- 		self:draw_beam_particle(particle, -2)
	-- 	end
    -- end

    -- for _, particle in self.beam_particles:ipairs() do
	-- 	if rng:percent(30) then
	-- 		self:draw_beam_particle(particle, -1)
	-- 	end
    -- end

    for _, particle in self.beam_particles:ipairs() do
		if rng:percent(90) then
			self:draw_beam_particle(particle, 0)
		end
    end
end


function BigLaserBeam:draw_beam_particle(particle, layer)
	graphics.push("all")
    local x, y = self:to_local(particle.pos.x, particle.pos.y)
    local scale = 1 + (1 - ease("outExpo")(clamp01(particle.elapsed / 20))) * 0.15
    graphics.translate(x, y)
    if particle.random_offset1 % 3 == 0 then
		local irng = self.instance_rng
		irng:set_seed(particle.random_offset2)
		local angle = stepify(irng:randf(0, tau), tau / 16)
		graphics.rotate(angle)
	end
    local size = particle.size * scale
	
	if layer == 2 then
		graphics.set_color(Color.white)
		graphics.rectangle_centered("fill", 0, 0, size * 0.75, size * 0.75)
	elseif layer == 1 then
		graphics.set_color(Palette.big_laser:tick_color(self.elapsed + particle.elapsed * 0.2))
		graphics.set_line_width(2)
		graphics.rectangle_centered("fill", 0, 0, size, size)
        graphics.rectangle_centered("line", 0, 0, size + 5, size + 5)
	elseif layer == 0 then

        for i = 1, rng:randi(-1, 1) do
			graphics.set_line_width(rng:percent(40) and rng:randi(1, 3) or 1)
            graphics.set_color(rng:percent(50) and (rng:percent(10) and Color.grey or Color.darkgrey) or Color
            .darkergrey)
            if rng:percent(10) then
				graphics.set_color(Color.black)
			end
			local outside_x, outside_y = vec2_perpendicular_normalized_times(particle.dx, particle.dy, rng:randfn(size * 0.75, size * 0.25) * rng:rand_sign())
            local length = rng:randf(size * 0.1, size * 0.60)
            local offset = rng:randf(-length / 2, length / 2)
			local start_x, start_y = vec2_add(outside_x, outside_y, vec2_mul_scalar(particle.dx, particle.dy, offset))
			local end_x, end_y = vec2_add(outside_x, outside_y, vec2_mul_scalar(particle.dx, particle.dy, length))
			graphics.line(start_x, start_y, end_x, end_y)
		end
        graphics.set_color(Color.black)
        local square_scale = rng:randf(0.125, 0.175)
		for i=1, 5 do
        	local x,y = rng:random_vec2_times(rng:randf(0, size * 0.2))
			graphics.rectangle_centered("fill", 0, 0, size * square_scale, size * square_scale)
		end

	elseif layer == -1 then
        graphics.set_color(Color.darkergrey)
		local square_scale = 0.85
        graphics.rectangle_centered("fill", 0, 0, size * square_scale, size * square_scale)
	elseif layer == -2 then
        graphics.set_color(Color.black)
		local square_scale = 1.85
        graphics.rectangle_centered("fill", 0, 0, size * square_scale, size * square_scale)
	end
	-- end
	-- graphics.set_color(Color.yellow)
	-- graphics.rectangle_centered("fill", 0, 0, size * 0.8, size *0.8)
	-- graphics.rotate(-vec2_angle(particle.dx, particle.dy))
	-- graphics.translate(-x, -y)
	graphics.pop()
end



function BigLaserBeam:update_points(dt)

	-- endpoints
	self.target_endpoint_x = self.pos.x + self.dx * BEAM_TARGET_LENGTH
    self.target_endpoint_y = self.pos.y + self.dy * BEAM_TARGET_LENGTH

	self.target_angle = vec2_angle(self.dx, self.dy)

	self.slow_turn_angle = splerp_angle(self.slow_turn_angle, self.target_angle, BEAM_TARGET_DECAY, dt)

    local slow_turn_endpoint_x, slow_turn_endpoint_y = vec2_from_polar(BEAM_TARGET_LENGTH, self.slow_turn_angle)

    local ex, ey = slow_turn_endpoint_x - self.pos.x, slow_turn_endpoint_y - self.pos.y
	
	if vec2_magnitude(ex, ey) < BEAM_TARGET_LENGTH then
		ex, ey = vec2_normalized_times(ex, ey, BEAM_TARGET_LENGTH)
	end

	local ix, iy = self.world.room.bullet_bounds:get_line_intersection(self.pos.x, self.pos.y, self.pos.x + ex, self.pos.y + ey)

	self.slow_turn_endpoint_x, self.slow_turn_endpoint_y = slow_turn_endpoint_x, slow_turn_endpoint_y

    self.real_turn_endpoint_x, self.real_turn_endpoint_y = ix, iy

    self.clamped_target_endpoint_x, self.clamped_target_endpoint_y = self.world.room.bullet_bounds:get_line_intersection(
    self.pos.x, self.pos.y, self.target_endpoint_x, self.target_endpoint_y)
	

	
	-- local diff_x, diff_y = vec2_sub(self.clamped_target_endpoint_x, self.clamped_target_endpoint_y, self.real_turn_endpoint_x, self.real_turn_endpoint_y)
	-- self.turn_diff_x, self.turn_diff_y = splerp_vec(self.turn_diff_x, self.turn_diff_y, diff_x * 2, diff_y * 2, TURN_DIFF_DECAY, dt)
	

    -- curve
    for i = 1, ((BEAM_HITBOX_RESOLUTION) * 2), 2 do
        local t = (i / (BEAM_HITBOX_RESOLUTION * 2))
        local x, y = self:interpolate_curve(t)
        self.hitbox_curve_points[i] = x
        self.hitbox_curve_points[i + 1] = y
    end

	self.hitbox_curve_points[BEAM_HITBOX_RESOLUTION * 2 + 1] = self.real_turn_endpoint_x
    self.hitbox_curve_points[BEAM_HITBOX_RESOLUTION * 2 + 2] = self.real_turn_endpoint_y
end

function BigLaserBeam:interpolate_curve(t)
    local t2 = 0.5 * self:get_line_length_ratio()
	local midpoint1_x, midpoint1_y = lerp(self.pos.x, self.clamped_target_endpoint_x, 0.5), lerp(self.pos.y, self.clamped_target_endpoint_y, 0.5)
    local midpoint2_x, midpoint2_y = lerp(self.pos.x, self.real_turn_endpoint_x, 0.5), lerp(self.pos.y, self.real_turn_endpoint_y, 0.5)
	
	local midpoint_x, midpoint_y = lerp(midpoint1_x, midpoint2_x, t2), lerp(midpoint1_y, midpoint2_y, t2)

	-- print(t2)


	return bezier_quad(
		self.pos.x, self.pos.y,
		midpoint_x, midpoint_y,
		self.real_turn_endpoint_x, self.real_turn_endpoint_y,
		t)
end

function BigLaserBeam:debug_draw_old()
    if debug.can_draw_bounds then
		graphics.set_color(Color.grey)
		for i = 1, (BEAM_HITBOX_RESOLUTION + 1) * 2, 2 do

			local x, y = self.hitbox_curve_points[i], self.hitbox_curve_points[i + 1]
			x, y = self:to_local(x, y)
			graphics.circle("line", x, y, 3)
		end

		graphics.set_color(Color.red)
		graphics.line(0, 0, self:to_local(self.target_endpoint_x, self.target_endpoint_y))
		local clamped_x, clamped_y = self:to_local(self.clamped_target_endpoint_x, self.clamped_target_endpoint_y)
		graphics.circle("line", clamped_x, clamped_y, 5)
		graphics.set_color(Color.cyan)
		graphics.line(0, 0, self:to_local(self.slow_turn_endpoint_x, self.slow_turn_endpoint_y))

		graphics.set_color(Color.green)
		local x, y = self:to_local(self.real_turn_endpoint_x, self.real_turn_endpoint_y)
        graphics.line(0, 0, x, y)
		graphics.circle("line", x, y, 5)

		-- graphics.set_color(Color.blue)
        -- local x, y = self:to_local(self.turn_diff_x, self.turn_diff_y)
		-- graphics.line(0, 0, x, y)
		-- graphics.circle("line", x, y, 5)
	end
end

function BigLaserBeam:get_line_length_ratio()
    return clamp01(vec2_distance(self.pos.x, self.pos.y, self.real_turn_endpoint_x, self.real_turn_endpoint_y) /
    BEAM_TARGET_LENGTH)
end

function BigLaserBeam:set_direction(dx, dy)
    self.dx = dx
    self.dy = dy
end

function BigLaserBeam:finish()
    self.persist = false
    self.melee_attacking = false
    self.finished = true
    self:stop_sfx("player_big_laser_loop")

    -- local s = self.sequencer
    -- s:start(function()
    -- s:tween_property(self, "beam_start", 0, 1, 4)
    -- self:queue_destroy()
    -- end)
end



function BigLaserBeamFloor:new(x, y)
	BigLaserBeamFloor.super.new(self, x, y)
	self.z_index = -1
	self.dust_particles = makelist()
    self.dust_particles_to_remove = {}
	self:add_elapsed_time()
	self:add_elapsed_ticks()
end

function BigLaserBeamFloor:draw()
    for _, particle in self.dust_particles:ipairs() do
		local color = particle.color
		graphics.set_color(color)
		if vec2_magnitude_squared(particle.vel_x, particle.vel_y) < 0.05 * 0.05 then
			local color_mod = 0.4
			graphics.set_color(color.r * color_mod, color.g * color_mod, color.b * color_mod) 
		end
		local x, y = self:to_local(particle.pos.x, particle.pos.y)
		graphics.rectangle_centered("fill", x, y, particle.size, particle.size)
	end
end

function BigLaserBeamFloor:floor_draw()
    for _, particle in self.dust_particles:ipairs() do
		
		local mag_squared = vec2_magnitude_squared(particle.vel_x, particle.vel_y)
		local color = particle.color

		if mag_squared < 0.05 * 0.05 then
			local color_mod = 0.4
            color = Color(color.r * color_mod, color.g * color_mod, color.b * color_mod)
			graphics.set_color(color)
			local x, y = self:to_local(particle.pos.x, particle.pos.y)
			graphics.rectangle_centered("fill", x, y, particle.size, particle.size)
		end
		
		if mag_squared < 0.25 * 0.25 then
			goto continue
		end
        local color = particle.floor_color
		if color then
			graphics.set_color(color)
			local old_x, old_y = self:to_local(particle.old_x, particle.old_y)
            local x, y = self:to_local(particle.pos.x, particle.pos.y)
			graphics.set_line_width(particle.size)
			graphics.line(old_x, old_y, x, y)
		end
		::continue::
	end
end

local DUST_PARTICLE_COLORS = {
	Color.cyan,
	Color.cyan,
	Color.cyan,
	Color.blue,
	Color.blue,
	Color.white,
	Color.darkblue,
	Color.darkblue,
}


local DUST_PARTICLE_FLOOR_COLORS = {
	Color.darkergrey,
	Color.darkergrey,
	Color.darkergrey,
	Color.darkergrey,
	Color.nearblack,
	Color.nearblack,
	Color.nearblack,
	Color.black,
	Color.black,
	Color.darkblue,
}


function BigLaserBeamFloor:create_dust_particle(x, y, dx, dy, speed)
    dx, dy = vec2_normalized(dx, dy)
	
	local particle = {
		pos = Vec2(x, y),
		size = floor(max(abs(rng:randfn(1, 1)), 1)),
		old_x = x,
		old_y = y,
		dx = dx,
		dy = dy,
		vel_x = dx * speed,
		vel_y = dy * speed,
        drag = rng:randf(0.1, 0.5),
        elapsed = 0,
        color = rng:choose(DUST_PARTICLE_COLORS),
		floor_color = rng:percent(15) and rng:choose(DUST_PARTICLE_FLOOR_COLORS),
	}

	particle.gravity_x, particle.gravity_y = rng:random_vec2_times(rng:randf(0, 0.05))

	self.dust_particles:push(particle)
end

function BigLaserBeamFloor:update(dt)

    for _, particle in self.dust_particles:ipairs() do
		self:update_dust_particle(particle, dt)
	end

	for _, particle_to_remove in ipairs(self.dust_particles_to_remove) do
		self.dust_particles:remove(particle_to_remove)
    end
	
	table.clear(self.dust_particles_to_remove)

	
	if self:done() then
		self:queue_destroy()
	end
end

function BigLaserBeamFloor:update_dust_particle(particle, dt)
	particle.old_x = particle.pos.x
    particle.old_y = particle.pos.y
	particle.elapsed = particle.elapsed + dt
	local gravity_scale = 1 - clamp01(particle.elapsed / 90)
	particle.vel_x, particle.vel_y = vec2_add(particle.vel_x, particle.vel_y, particle.gravity_x * dt * gravity_scale, particle.gravity_y * dt * gravity_scale)
	particle.pos.x, particle.pos.y = particle.pos.x + particle.vel_x * dt, particle.pos.y + particle.vel_y * dt
    particle.vel_x, particle.vel_y = vec2_drag(particle.vel_x, particle.vel_y, particle.drag, dt)
	if vec2_magnitude(particle.vel_x, particle.vel_y) < 0.1 and self.is_new_tick and rng:percent(1) then
		table.insert(self.dust_particles_to_remove, particle)
	end
end

function BigLaserBeamFloor:done()
    if self.parent then
        return false
    end
	
	if not self.dust_particles:is_empty() then
		return false
	end
	
	return true
end

function BigLaserBeamAimingLaser:new(x, y, dx, dy, duration)
	BigLaserBeamAimingLaser.super.new(self, x, y)
    self.duration = duration
	self.persist = true
    self:set_direction(dx, dy)
	self.z_index = 0.4
end

function BigLaserBeamAimingLaser:enter()
    self:play_sfx("player_big_laser_charge")
end

function BigLaserBeamAimingLaser:exit()
	self:stop_sfx("player_big_laser_charge")
	self:stop_sfx("player_big_laser_charge2")
end

function BigLaserBeamAimingLaser:set_direction(dx, dy)
    self.dx = dx * BEAM_TARGET_LENGTH
    self.dy = dy * BEAM_TARGET_LENGTH
end

function BigLaserBeamAimingLaser:update(dt)
	if self.is_new_tick and self.tick == floor(self.duration - 16) then
		self:play_sfx("player_big_laser_charge2")
	end
end

function BigLaserBeamAimingLaser:draw(elapsed, tick, t)

    local start_x, start_y = vec2_normalized_times(self.dx, self.dy, 13)

	graphics.set_color(self.tick < 3 and Color.orange or Color.red)
    graphics.set_line_width(1 + ease("inCubic")(ease("inCubic")(clamp01(t))) * 7)

	local t4 = ease("outCubic")(clamp01(t))
    local end_x1, end_y1 = self.pos.x + self.dx * t4, self.pos.y + self.dy * t4

    local end_x2, end_y2 = self.world.room.bullet_bounds:get_line_intersection(self.pos.x, self.pos.y, end_x1, end_y1)

	if end_x2 == nil or end_y2 == nil then
		end_x2, end_y2 = end_x1, end_y1
	end

    end_x2, end_y2 = self:to_local(end_x2, end_y2)


	if t < 0.35 or iflicker(tick, 2, 2) then 
		graphics.line(start_x, start_y, end_x2, end_y2)
	end
	
	local t2 = remap_clamp(t, 0.05, 1, 0, 1)
	local t3 = remap_clamp(t, 0.35, 1, 0, 1)

    if t2 > 0 then
		local size = 20 * ease("inCubic")(t2)
		graphics.rectangle_centered("fill", start_x, start_y, size, size)
	end

    if t3 > 0 then
		graphics.push("all")
        graphics.translate(start_x, start_y)
        graphics.rotate(vec2_angle(self.dx, self.dy))
		-- graphics.scale(0.5, 1)
        graphics.set_line_width(2)
		local size = 40 * (ease("inSine")(math.bump(t3)))
		graphics.rectangle_centered("line", 0, 0, size * 0.5, size)
		graphics.pop()
	end


end

function BigLaserBeamAimingLaser:finish()
	self.persist = false
    self:queue_destroy()
end



return {BigLaserBeam, BigLaserBeamAimingLaser}
