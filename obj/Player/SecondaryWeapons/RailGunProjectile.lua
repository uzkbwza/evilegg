local RailGunProjectile = GameObject2D:extend("RailGunProjectile")
local Explosion = require("obj.Explosion")

local HIT_RADIUS = 15
local DURATION = 30
local DAMAGE = 10
local HIT_TEAMS = {
	"enemy",
	"neutral",
}

local RECT_RESOLUTION = 64

RailGunProjectile.damage = DAMAGE
RailGunProjectile.center_out_velocity_multiplier = 6

function RailGunProjectile:new(x, y, dx, dy)
	dx, dy = vec2_normalized(dx, dy)
    RailGunProjectile.super.new(self, x, y)
    
	self.damage = RailGunProjectile.damage + 3 * game_state.upgrades.damage

    self:lazy_mixin(Mixins.Behavior.SimpleCustomHit)
    self.dx = dx
    self.dy = dy
    self:add_time_stuff()
	self.z_index = 1
	self.irng = rng:new_instance()
    self.random_offset = self.irng:randi()
	self:start_destroy_timer(120)
end

function RailGunProjectile:check_bubble_collision(bubble)
	return bubble:collides_with_capsule(self.start_x, self.start_y, self.end_x, self.end_y, HIT_RADIUS)
end

-- function RailGunProjectile:on_hit_something(parent, bubble)
-- end

function RailGunProjectile:get_rect()
	return get_capsule_rect(self.start_x, self.start_y, self.end_x, self.end_y, HIT_RADIUS)
end

function RailGunProjectile:enter()
	self:play_sfx("player_rail_gun_shoot")
	-- self:play_sfx("player_rail_gun_dust")
    self:defer(self.attack)

	local s = self.sequencer
end

function RailGunProjectile:update(dt)

end

function RailGunProjectile:draw_ring(start, elapsed, angle, back)
    local end_dist = vec2_distance(self.start_x, self.start_y, self.end_x, self.end_y)
	local ring_separation = 10
	local num_rings = end_dist / ring_separation
	
    for i = 1, num_rings do
		local diff_amount = (i * ring_separation) / 18
		local e = max(elapsed - start, 0)
		local e2 = max(10 + elapsed - start - diff_amount / 3, 0)
		local e3 = max(0 + elapsed - start - diff_amount / 2, 0)
		local e4 = max(0 + elapsed - start - diff_amount / 5, 0)
		local e5 = max(0 + elapsed - start - diff_amount * 0.75, 0)
		local e6 = max(0 + elapsed - start - diff_amount * 2, 0)
		local irng = self.irng
        irng:set_seed(i + self.random_offset)
		local outer_smoke_time = irng:randf(15, 20)
		local t2 = clamp(e3/outer_smoke_time, 0, 1)
		
		local t3 = t2
		t3 = t2 * irng:randf(0.9, 1.1)
			
		graphics.push("all")

		local ring_x, ring_y = vec2_lerp(self.start_x, self.start_y, self.end_x, self.end_y, i / num_rings)
		ring_x, ring_y = self:to_local(ring_x, ring_y)
        local height = 8 + logb(e4 * 1.25, 2) * 3
		local width = 2 + logb(e4 * 1.25, 2) * 0.2
		local offs_x, offs_y = vec2_mul_scalar(self.dx, self.dy, e2 * 0.2)
        offs_y = offs_y - pow(e6 * 0.15, 1.25)
        if e3 <= outer_smoke_time and e3 >= 0 then

			graphics.set_line_width(max(1 + 3 * (1 - ease("outCubic")(t3)), 1))

            graphics.set_color(Color.red)
			
            if t3 > 0.2 then
				graphics.set_color(Color.darkgrey)
			end
			if t3 > 0.6 then
				graphics.set_color(Color.darkergrey)
			end
            if t3 > 0.8 then
                graphics.set_color(Color.nearblack)
            end

            local extra = 16 * max(0, logb(e3, 10)) + 3
			
			irng:set_seed(i + self.random_offset)
            local extra2 = irng:randf(-6, 6)
			extra = max(extra + extra2 + 20 - diff_amount * 3, 0)

            if not back then
                graphics.poly_rect_sides(ring_x + offs_x, ring_y + offs_y, width + extra, height + extra, angle, 1, 1, false, false,
                    false, true)
            else
                graphics.poly_rect("line", ring_x + offs_x, ring_y + offs_y, width + extra, height + extra, angle, 1, 1)
            end
        end

		graphics.set_color(Color.white)

        if e5 > 3.1 then
            graphics.set_color(Color.yellow)
		end
		if e5 > 5.7 then
			graphics.set_color(Color.orange)
		end
        if e5 > 7.7 then
            graphics.set_color(Color.red)
        end

		

		graphics.set_line_width(max(4 - e6 * 0.85, 0))


        if not back then
			-- graphics.poly_rect_sides(ring_x + offs_x, ring_y + offs_y, width, height, angle + tau/8, 1, 1, false, false, false, true)
			-- graphics.poly_rect_sides(ring_x + offs_x, ring_y + offs_y, width, height, angle - tau/8, 1, 1, false, false, false, true)
			graphics.poly_rect_sides(ring_x + offs_x, ring_y + offs_y, width, height, angle, 1, 1, false, false, false, true)
		else
			-- graphics.poly_rect("line", ring_x + offs_x, ring_y + offs_y, width, height, angle + tau/8, 1, 1)
			-- graphics.poly_rect("line", ring_x + offs_x, ring_y + offs_y, width, height, angle - tau/8, 1, 1)
			graphics.poly_rect("line", ring_x + offs_x, ring_y + offs_y, width, height, angle, 1, 1)
		end
		graphics.pop()
	end
end



function RailGunProjectile:draw_floor_ring(start, elapsed, angle, back)
    local end_dist = vec2_distance(self.start_x, self.start_y, self.end_x, self.end_y)
	local ring_separation = 10
	local num_rings = end_dist / ring_separation
	
    for i = 1, num_rings do
		local diff_amount = (i * ring_separation) / 18
		local e = max(elapsed - start, 0)
		local e2 = max(10 + elapsed - start - diff_amount / 3, 0)
		local e3 = max(0 + elapsed - start - diff_amount / 2, 0)
		local e4 = max(0 + elapsed - start - diff_amount / 5, 0)
		local e5 = max(0 + elapsed - start - diff_amount * 0.75, 0)
		local e6 = max(0 + elapsed - start - diff_amount * 2, 0)
		local irng = self.irng
        irng:set_seed(i + self.random_offset)
		local outer_smoke_time = irng:randf(15, 20)
		local t2 = clamp(e3/outer_smoke_time, 0, 1)
		
		local t3 = t2
		t3 = t2 * irng:randf(0.9, 1.1)
			
		graphics.push("all")

		local ring_x, ring_y = vec2_lerp(self.start_x, self.start_y, self.end_x, self.end_y, i / num_rings)
		ring_x, ring_y = self:to_local(ring_x, ring_y)
        local height = 8 + logb(e4 * 1.25, 2) * 3
		local width = 2 + logb(e4 * 1.25, 2) * 0.2
		local offs_x, offs_y = vec2_mul_scalar(self.dx, self.dy, e2 * 0.2)
        offs_y = offs_y - pow(e6 * 0.15, 1.25)
        if e3 <= outer_smoke_time and e3 >= 0 then

			graphics.set_line_width(max(2 * (1 - ease("outCubic")(t3)), 1))

            graphics.set_color(Color.darkergrey)
			
            if t3 > 0.2 then
				graphics.set_color(Color.darkgrey)
			end
            if t3 > 0.6 then
                graphics.set_color(Color.darkergrey)
            end
            
            if t3 > 0.8 then
                graphics.set_color(Color.nearblack)
            end

            local extra = 16 * max(0, logb(e3, 10)) + 3
			
			irng:set_seed(i + self.random_offset)
            local extra2 = irng:randf(-6, 6)
			extra = max(extra + extra2 + 20 - diff_amount * 3, 0)

            if not back then
                graphics.poly_rect_sides(ring_x + offs_x, ring_y + offs_y, width + extra, height + extra, angle, 1, 1, false, false,
                    false, true)
            else
                graphics.poly_rect("line", ring_x + offs_x, ring_y + offs_y, width + extra, height + extra, angle, 1, 1)
            end
        end

        graphics.set_color(Color.nearblack)


		graphics.set_line_width(max(2 - e6 * 0.85, 0))


        if not back then
			-- graphics.poly_rect_sides(ring_x + offs_x, ring_y + offs_y, width, height, angle + tau/8, 1, 1, false, false, false, true)
			-- graphics.poly_rect_sides(ring_x + offs_x, ring_y + offs_y, width, height, angle - tau/8, 1, 1, false, false, false, true)
			graphics.poly_rect_sides(ring_x + offs_x, ring_y + offs_y, width, height, angle, 1, 1, false, false, false, true)
		else
			-- graphics.poly_rect("line", ring_x + offs_x, ring_y + offs_y, width, height, angle + tau/8, 1, 1)
			-- graphics.poly_rect("line", ring_x + offs_x, ring_y + offs_y, width, height, angle - tau/8, 1, 1)
			graphics.poly_rect("line", ring_x + offs_x, ring_y + offs_y, width, height, angle, 1, 1)
		end
		graphics.pop()
	end
end


function RailGunProjectile:draw()
    local tick = self.tick
    local elapsed = self.elapsed
	local angle = vec2_angle(self.dx, self.dy)
    -- local t = clamp01(self.elapsed / DURATION)
    -- local t2 = (ease("outExpo")(t))
	
	local ring_start = 6
    

	if elapsed >= ring_start then
		self:draw_ring(ring_start, elapsed, angle, true)
	end

    if elapsed >= 1 and elapsed <= 3 then
        graphics.push("all")
        local t = remap(elapsed, 1, 3, 0, 1)
        graphics.set_color(Color.white)
        graphics.set_line_width(HIT_RADIUS * 2 * (1 - ease("inExpo")(t)))
        local x, y = self:to_local(self.end_x, self.end_y)
        graphics.line(0, 0, x, y)
        graphics.pop()
    end

    if elapsed >= 1 and elapsed <= 15 then
        graphics.push("all")
		graphics.translate(self.dx * 10, self.dy * 10)
		local t = remap(elapsed, 1, 15, 0, 1)
		local radius = 20
        local scale = lerp(radius, radius * 3, ease("outCubic")(t))

		local line_width = 4 - ease("inExpo")(t) * 3
		scale = scale + (radius * 3 * remap_clamp(t, 0.0, 0.1, 1, 0))
		self.muzzle_flash_scale = scale - line_width

        local color = Color.white
        if elapsed > 3 then
			color = Color.yellow
        end
        if elapsed > 6 then
			color = Color.orange
        end
        if elapsed > 9 then
			color = Color.red
        end

		if elapsed > 12 then
			color = Color.darkgrey
		end
		graphics.set_color(color)
		graphics.set_line_width(line_width)
        graphics.rectangle_centered(t < 0.4 and "fill" or "line", 0, 0, scale, scale)
		graphics.pop()
	end


		
	if elapsed >= 3 and elapsed <= 12 then
        graphics.push("all")
        local t = remap(elapsed, 3, 12, 0, 1)
        local x, y = self:to_local(self.end_x, self.end_y)
        -- local start_x, start_y = line_rect_intersection(0, 0, x, y, -self.muzzle_flash_scale,
		-- -self.muzzle_flash_scale, self.muzzle_flash_scale * 2, self.muzzle_flash_scale * 2)
		local start_x, start_y = vec2_lerp(self.dx * 10, self.dy * 10, x, y, ease("inExpo")(t))
		-- print(line_rect_intersection(0, 0, x * 100, y * 100, - self.muzzle_flash_scale / 2, - self.muzzle_flash_scale / 2, self.muzzle_flash_scale, self.muzzle_flash_scale))
        -- graphics.set_color(Color.red)
        -- graphics.set_line_width(max(15 - (ease("inOutExpo")(t)) * 7 - t * 7, 0))
        -- graphics.line(start_x, start_y, x, y)
        graphics.set_color(Color.yellow)
        graphics.set_line_width(max(17 - (ease("outExpo")(t)) * 4 - t * 4, 0))
        graphics.line(start_x, start_y, x, y)
        graphics.pop()
    end

	if elapsed >= ring_start then
		self:draw_ring(ring_start, elapsed, angle, false)
	end

	-- love.graphics.set_line_width(HIT_RADIUS * 2 * (1 - t2))
	-- 
	-- love.graphics.line(0, 0, x, y)
    -- love.graphics.setColor(1, 1, 1)
	
end


function RailGunProjectile:floor_draw()
    local tick = self.tick
    local elapsed = self.elapsed
	local angle = vec2_angle(self.dx, self.dy)
    -- local t = clamp01(self.elapsed / DURATION)
    -- local t2 = (ease("outExpo")(t))
	
	
    if elapsed >= 1 and elapsed <= 3 then
        
        self:draw_floor_ring(1, elapsed, angle, true)
    
        graphics.push("all")
        local t = remap(elapsed, 1, 3, 0, 1)
        graphics.set_color(Color.nearblack)
        graphics.set_line_width(HIT_RADIUS * 2 * (1 - ease("inExpo")(t)))
        local x, y = self:to_local(self.end_x, self.end_y)
        graphics.line(0, 0, x, y)
        graphics.pop()
    end

    -- if elapsed >= 1 and elapsed <= 15 then
    --     graphics.push("all")
	-- 	graphics.translate(self.dx * 10, self.dy * 10)
	-- 	local t = remap(elapsed, 1, 15, 0, 1)
	-- 	local radius = 20
    --     local scale = lerp(radius, radius * 3, ease("outCubic")(t))

	-- 	local line_width = 4 - ease("inExpo")(t) * 3
	-- 	scale = scale + (radius * 3 * remap_clamp(t, 0.0, 0.1, 1, 0))
	-- 	self.muzzle_flash_scale = scale - line_width

    --     local color = Color.white
    --     if elapsed > 3 then
	-- 		color = Color.yellow
    --     end
    --     if elapsed > 6 then
	-- 		color = Color.orange
    --     end
    --     if elapsed > 9 then
	-- 		color = Color.red
    --     end

	-- 	if elapsed > 12 then
	-- 		color = Color.darkgrey
	-- 	end
	-- 	graphics.set_color(color)
	-- 	graphics.set_line_width(line_width)
    --     graphics.rectangle_centered(t < 0.4 and "fill" or "line", 0, 0, scale, scale)
	-- 	graphics.pop()
	-- end


		
	if elapsed >= 3 and elapsed <= 12 then
        graphics.push("all")
        local t = remap(elapsed, 3, 12, 0, 1)
        local x, y = self:to_local(self.end_x, self.end_y)
        -- local start_x, start_y = line_rect_intersection(0, 0, x, y, -self.muzzle_flash_scale,
		-- -self.muzzle_flash_scale, self.muzzle_flash_scale * 2, self.muzzle_flash_scale * 2)
		local start_x, start_y = vec2_lerp(self.dx, self.dy, x, y, ease("inExpo")(t))
		-- print(line_rect_intersection(0, 0, x * 100, y * 100, - self.muzzle_flash_scale / 2, - self.muzzle_flash_scale / 2, self.muzzle_flash_scale, self.muzzle_flash_scale))
        -- graphics.set_color(Color.red)
        -- graphics.set_line_width(max(15 - (ease("inOutExpo")(t)) * 7 - t * 7, 0))
        -- graphics.line(start_x, start_y, x, y)
        graphics.set_color(Color.black)
        graphics.set_line_width(max(17 - (ease("outExpo")(t)) * 4 - t * 4, 0))
        graphics.line(start_x, start_y, x, y)
        graphics.pop()
    end

	-- if elapsed >= ring_start then
	-- 	self:draw_ring(ring_start, elapsed, angle, false)
	-- end

	-- love.graphics.set_line_width(HIT_RADIUS * 2 * (1 - t2))
	-- 
	-- love.graphics.line(0, 0, x, y)
    -- love.graphics.setColor(1, 1, 1)
	
end

function RailGunProjectile:attack()
	self.start_x, self.start_y = self.pos.x + self.dx * 10, self.pos.y + self.dy * 10
    self.end_x, self.end_y = self.world.room.bullet_bounds:get_line_intersection(self.pos.x, self.pos.y,
        self.pos.x + self.dx * 10000, self.pos.y + self.dy * 10000)
	if self.end_x == nil or self.end_y == nil then
		self.end_x = self.pos.x + self.dx * 1
		self.end_y = self.pos.y + self.dy * 1
	end
    -- local rx, ry, rw, rh = get_capsule_rect(self.start_x, self.start_y, self.end_x, self.end_y, HIT_RADIUS)

	local dist = vec2_distance(self.start_x, self.start_y, self.end_x, self.end_y)
	local rect_count = dist / RECT_RESOLUTION

    for _, hit_team in ipairs(HIT_TEAMS) do
        local hurt_bubbles = self.world.hurt_bubbles[hit_team]
        for i = 0, rect_count - 1 do
            local x1, y1 = vec2_lerp(self.start_x, self.start_y, self.end_x, self.end_y, i / rect_count)
			local x2, y2 = vec2_lerp(self.start_x, self.start_y, self.end_x, self.end_y, (i + 1) / rect_count)
			local x, y, w, h = get_capsule_rect(x1, y1, x2, y2, HIT_RADIUS)
			hurt_bubbles:each(x, y, w, h, self.try_hit, self)
		end
    end


	local explosion = self:spawn_object(Explosion(self.end_x, self.end_y, {
		damage = 10,
		size = 35,
		-- draw_scale = 1.0,
		team = "player",
		-- melee_both_teams = false,
		particle_count_modifier = 0.5,
		-- explode_sfx = "explosion",
		explode_sfx_volume = 0.0,
		-- explode_vfx = nil,
		-- ignore_explosion_force = {},
		force_modifier = 3.0,
	}))
		

end

function RailGunProjectile:before_hit(bubble)
    local x, y = bubble:get_position()
	x, y = vec2_sub(x, y, self.dx * 5, self.dy * 5)
	self.particle_hit_point_x, self.particle_hit_point_y = x, y
end

function RailGunProjectile:get_death_particle_hit_point(parent)
	return self.particle_hit_point_x, self.particle_hit_point_y
end

function RailGunProjectile:get_death_particle_hit_velocity()
	return vec2_normalized_times(self.dx, self.dy, 10)
end
function RailGunProjectile:on_hit_something(parent, bubble)
    local bubx, buby = bubble:get_position()
    local x, y = clamp_point_to_capsule(bubx, buby, self.start_x, self.start_y, self.end_x, self.end_y, HIT_RADIUS)
    if x == nil or y == nil then
        x, y = bubx, buby
        x = x - self.dx
        y = y - self.dy
    end
	
    -- if not parent.is_enemy_bullet and not (parent.is_fungus and rng:percent(60)) then
        -- local explosion = self:spawn_object(Explosion(x, y, {
        --     damage = 5,
        --     size = 25,
        --     -- draw_scale = 1.0,
        --     team = "player",
        --     -- melee_both_teams = false,
        --     -- particle_count_modifier = 1,
        --     -- explode_sfx = "explosion",
        --     explode_sfx_volume = 0.0,
        --     -- explode_vfx = nil,
        --     ignore_explosion_force = { parent },
        --     force_modifier = 3.0,
        -- }))
    -- end
	
    if parent.is_simple_physics_object then
        local speed = 10 * (parent.bullet_push_modifier or 1)
		parent:apply_impulse(self.dx * speed, self.dy * speed)
	end
end

return RailGunProjectile
