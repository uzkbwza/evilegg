local EggBoss = BaseEnemy:extend("EggBoss")
local BloodSpawner = GameObject2D:extend("BloodSpawner")
local BloodShadow = GameObject2D:extend("BloodShadow")
local CrackFragment = GameObject2D:extend("CrackFragment")
local Bouncer = require("obj.Spawn.Enemy.Hazard.Bouncer")[2]

local QUAD_SIZE = 10

local SHELL_HP = 400
local BASE_HP = 100
local NUM_SHELL_CRACKS = 27
local SHELL_DAMAGE_PER_CRACK = SHELL_HP / NUM_SHELL_CRACKS

local DIALOGUE = [[please come back. where have you gone? my baby. where are you child?
]]

function EggBoss:new(x, y)
	self:add_signal("cracked")
	self.body_height = 80
	self.z_index = 0
	self.base_body_height = self.body_height
	self.terrain_collision_radius = 40
	-- self.hurt_bubble_radius = 60
	-- self.hit_bubble_radius = 55

	self.shell_hp = SHELL_HP
	self.max_hp = BASE_HP
	self.shell_fragment_locations = {}

	self.walk_speed = 0.15
	self.walk_timer = 180

    self.crack_centers = {}
	
	self.bullet_push_modifier = 0.05

	
	EggBoss.super.new(self, x, y)

	self:lazy_mixin(Mixins.Behavior.Roamer)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)

	self.roaming = false

	self.melee_attacking = false

	self.crack_points = {}

	for i = 1, NUM_SHELL_CRACKS do
		-- Distribute crack points with better balance between high and low HP
		local max_hp = SHELL_HP - 10
		local normalized = (NUM_SHELL_CRACKS - i + 1) / NUM_SHELL_CRACKS
		
		-- Use a power function with lower exponent to create more cracks at higher HP
		-- while still maintaining higher density at lower HP
		local power = 0.7 -- Less than 1 gives more cracks at high HP compared to sqrt (0.5)
		local base_value = max_hp * (1 - normalized^power)
		
		-- Add randomness within a controlled range
		local variance = max_hp * 0.08 * normalized -- variance decreases as HP gets lower
		self.crack_points[i] = base_value + rng.randf_range(-variance, variance)
	end
	
	table.insert(self.crack_points, SHELL_HP - 10)

	-- table.remove(self.crack_points)

	table.insert(self.crack_points, 0)

	table.sort(self.crack_points, function(a, b) return a > b end)

	local image_data = graphics.texture_data[textures.enemy_egg_boss1]
	local width, height = image_data:getWidth(), image_data:getHeight()
	self.num_shell_fragments = 0

	local x_fragments = floor(width-1 / QUAD_SIZE)
	local y_fragments = floor(height-1 / QUAD_SIZE)

	for qx = 0, x_fragments do
		for qy = 0, y_fragments do
			-- Check if coordinates are within image bounds before getting pixel
			local a1 = 0
			if qx * QUAD_SIZE < width and qy * QUAD_SIZE < height then
				local _, _, _, alpha = image_data:getPixel(qx * QUAD_SIZE, qy * QUAD_SIZE)
				a1 = alpha
			end

			-- Check if all four corners of the quad are transparent
			local x1, y1 = qx * QUAD_SIZE, qy * QUAD_SIZE
			local x2, y2 = qx * QUAD_SIZE + QUAD_SIZE, qy * QUAD_SIZE + QUAD_SIZE

			-- Check if coordinates are within image bounds
			local in_bounds1 = x1 >= 0 and x1 < width and y1 >= 0 and y1 < height
			local in_bounds2 = x2 >= 0 and x2 < width and y1 >= 0 and y1 < height
			local in_bounds3 = x1 >= 0 and x1 < width and y2 >= 0 and y2 < height
			local in_bounds4 = x2 >= 0 and x2 < width and y2 >= 0 and y2 < height

			local a1 = in_bounds1 and select(4, image_data:getPixel(x1, y1)) or 0
			local a2 = in_bounds2 and select(4, image_data:getPixel(x2, y1)) or 0
			local a3 = in_bounds3 and select(4, image_data:getPixel(x1, y2)) or 0
			local a4 = in_bounds4 and select(4, image_data:getPixel(x2, y2)) or 0

			if a1 == 0 and a2 == 0 and a3 == 0 and a4 == 0 then
				goto continue
			end

			local id = xy_to_id(qx, qy, x_fragments)

			local fragment = {
				x = qx * QUAD_SIZE - width * 0.5,
				y = qy * QUAD_SIZE - height * 0.5,
				width = QUAD_SIZE,
				height = QUAD_SIZE,
				id = xy_to_id(qx, qy, x_fragments)
			}
			local quad = graphics.new_quad(qx * QUAD_SIZE, qy * QUAD_SIZE, QUAD_SIZE, QUAD_SIZE, width, height)
			local quad_table = graphics.get_quad_table(textures.enemy_egg_boss1, quad, QUAD_SIZE, QUAD_SIZE)

			fragment.quad = quad
			fragment.quad_table = quad_table
			if self.shell_fragment_locations[id] == nil then
				self.shell_fragment_locations[id] = fragment
				self.num_shell_fragments = self.num_shell_fragments + 1
			else
				print("duplicate fragment")
			end
			::continue::
		end
	end

end

function EggBoss:damage(amount)
	if self.shell_hp > 0 then
		self.shell_hp = self.shell_hp - amount
		if self.shell_hp < 0 then
			self.shell_hp = 0
		end
		if debug.enabled then
			print("shell hp: " .. self.shell_hp)
		end
		while self.crack_points[1] and self.shell_hp <= self.crack_points[1] do
			self:crack_shell()
			table.remove(self.crack_points, 1)
		end
		if self.shell_hp <= 0 or table.is_empty(self.shell_fragment_locations) then
			self.shell_hp = 0
			self:change_state("Phase2")
		end
	else

	end
end


function EggBoss:get_hover_body_height()
	return round(self.base_body_height + 5 * sin(self.elapsed * 0.02))
end


function EggBoss:crack_shell()

    if not self.shell_cracked then
        self:change_state("Phase1")
    end
	
	self.shell_cracks = self.shell_cracks or 0
	self.shell_cracks = self.shell_cracks + 1

	self.shell_cracked = true
	
	--
	
    if table.is_empty(self.shell_fragment_locations) then
        return
    end
	
	self:play_sfx("enemy_evil_egg_crack")

	self.world.camera:start_rumble(3, 15, ease("linear"), true, false)

	
	local start_id = rng.choose(table.keys(self.shell_fragment_locations))
	local start_x, start_y = id_to_xy(start_id, QUAD_SIZE)
	local center_fragment = self.shell_fragment_locations[start_id]
	
	
	local crack_center = Vec2(
		center_fragment.x,
		center_fragment.y
	)
	
	self.crack_centers[self.shell_cracks] = crack_center


	local bx, by = self:get_body_center()


    local bdx, bdy = vec2_direction_to(bx, by, crack_center.x + bx, crack_center.y + by)
	
	self:spawn_blood(crack_center, true)
	
	self:apply_impulse(vec2_mul_scalar(bdx, bdy, -1))


	self:start_timer("crack_swell", 20)
	self:start_timer("crack_swell2", 40)

	
    if (self.shell_cracks - 1) % 5 == 0 then
		local s = self.sequencer	
		s:start(function()
			for i=1, 3 do
				self.world:spawn_something(Bouncer, nil, nil, nil, "hazard")
				s:wait(5)
			end
		end)
	end

	self:emit_signal("cracked")
end

function EggBoss:spawn_blood(crack_center, initial)
    local bx, by = self:get_body_center()
    local bdx, bdy = vec2_direction_to(bx, by, crack_center.x + bx, crack_center.y + by)
	
	local real_y = self:get_ground_y()

    if initial then
        local fragment_distances = {}
        for id, fragment in pairs(self.shell_fragment_locations) do
            local dist = vec2_distance(fragment.x, fragment.y, crack_center.x, crack_center.y)
            dist = dist + rng.randf_range(-2, 2)

            table.insert(fragment_distances, {
                id = id,
                fragment = fragment,
                distance = dist
            })
        end


        table.sort(fragment_distances, function(a, b)
            return a.distance < b.distance
        end)

        local fragments_per_crack = ceil(self.num_shell_fragments / NUM_SHELL_CRACKS)

        local fragments_to_remove = min(fragments_per_crack, #fragment_distances)

        for i = 1, fragments_to_remove do
            local fragment = fragment_distances[i].fragment
            local screen_y = fragment.y + by
            local dx, dy = vec2_direction_to(bx, by, fragment.x + bx, fragment.y + by)
            if dx ~= 0 or dy ~= 0 then
				local z_force = remap(dy, -1, 1, -1, rng.randf_range(-1, 5))
                self:spawn_object(CrackFragment(bx + fragment.x, real_y,  -(screen_y - real_y), dx, dy, z_force, fragment))
            end
            self:remove_shell_fragment(fragment)
        end


        if debug.enabled then
            print("Cracked " .. fragments_to_remove .. " fragments out of " .. self.num_shell_fragments .. " total")
        end
    end
	
	local screen_y = crack_center.y + by
	
    -- if debug.enabled then
        -- print("real_y: " .. real_y)
        -- print("screen_y: " .. screen_y)
    -- end


	-- for i = 1, initial and max(min(abs(rng.randfn(1, 1)), 3), 0) or max(min(abs(rng.randfn(4, 2)), 7), 1) do
	self:play_sfx("enemy_evil_egg_blood_squirt", 0.4)
	for i = 1, (not initial) and max(min(abs(rng.randfn(2, 2)), 5), 0) or max(min(abs(rng.randfn(4, 2)), 7), 1) do
		local dx, dy = vec2_rotated(bdx, bdy, rng.randfn(0, tau / 12))
        dx, dy = vec2_mul_scalar(dx, dy, rng.randfn(1.0, 0.45))
		
		if self.state == "Phase2" then
			dx, dy = vec2_mul_scalar(dx, dy, 0.25)
		end
		local blood_spawner = self:spawn_object(BloodSpawner(crack_center.x + bx, real_y, -(screen_y - real_y), dx, dy))
		blood_spawner:ref("parent", self)
	end
end

function EggBoss:get_ground_y()
	return self.pos.y
end

function EggBoss:remove_shell_fragment(fragment)
	self.shell_fragment_locations[fragment.id] = nil
end


function EggBoss:enter()
	self:add_hurt_bubble(0, 18, 60, "main")
	-- self:add_hit_bubble(0, 18, 52, "main")
end

function EggBoss:update(dt)
    EggBoss.super.update(self, dt)
	if self.is_new_tick then
        for _, crack_center in ipairs(self.crack_centers) do
			if rng.percent(0.1) then
				self:spawn_blood(crack_center)
			end
		end
	end

end

function EggBoss:normal_death_effect(hit_by)

end

function EggBoss:get_sprite()
	return textures.enemy_egg_boss2
end


function EggBoss:get_palette()
	return nil, idiv(self.tick, 4)
end

function EggBoss:get_palette_shared()
	local offset = 0

    if self:is_timer_running("damage_flash") and self.no_shell then
        offset = self.tick / 3
        return Palette.cmyk, offset
    end

	if self:is_tick_timer_running("shield_invuln") then
		offset = idiv(self.tick, 2)
		return Palette.shielded, offset
	end

	-- local doubletick = floor(self.random_offset + self.tick / 2)
    -- if doubletick % 300 < 4 then
	-- 	return Palette.death_disintegration, doubletick
	-- end
	
	local palette, offs = self:get_palette()

	palette = palette or self:get_default_palette()
	offset = offs or 0

	return palette, offset
end

function EggBoss:draw()
	-- if true then return end
	graphics.set_color(Color.darkergrey)
	if idivmod_eq_zero(gametime.tick, 1.01, 3) then
		local scale = max(inverse_lerp(self.base_body_height + 5, self.base_body_height - 5, self.body_height) * 0.125 + 1, 0)
		-- graphics.ellipse("fill", 0, 35, 40 * scale, 20 * scale)
		graphics.push("all")
		do
			graphics.translate(0, 0)
			graphics.scale(1, 0.5)
			graphics.rotate(tau / 8)
			graphics.rectangle_centered("fill", 0, 0, 60 * scale, 60 * scale)
		end
		graphics.pop()
	end
	self:body_translate()
	graphics.set_color(Color.white)

	graphics.translate((ease("inCubic")(self:timer_time_left_ratio("crack_swell2"))) * 4 * (self.tick % 2 == 0 and 1 or -1), 0)

	local palette, palette_index = self:get_palette_shared()
	local h_flip, v_flip = self:get_sprite_flip()


	-- if idivmod_eq_zero(self.tick, 1, 2)  then
	-- 	local any_player = self:get_any_ally()
	-- 	if any_player.pos.y < self.pos.y then
	-- 		return
	-- 	end
	-- end

	-- if self.tick % 27 ~= 0 then
		graphics.drawp_centered(textures.enemy_egg_boss2, Palette.egg_blood, palette_index, 0, 0, 0, h_flip, v_flip)
	-- end

	for _, fragment in pairs(self.shell_fragment_locations) do
		local fragment_x, fragment_y = fragment.x, fragment.y

		local swell = 1
		if self.shell_cracked and self:is_timer_running("crack_swell") then
			swell = 1 - 0.05 * (ease("inExpo")(self:timer_time_left_ratio("crack_swell")))
		end
		fragment_x = fragment_x * swell
		fragment_y = fragment_y * swell

		-- graphics.set_color(Color.black)
		graphics.draw_quad_table(fragment.quad_table, fragment_x, fragment_y)

		if debug.can_draw_bounds() then
			graphics.rectangle("line", fragment_x, fragment_y, QUAD_SIZE, QUAD_SIZE)
		end
	end
end

function EggBoss:state_Idle_enter()
	
end

function EggBoss:state_Idle_update(dt)
	self:hover()
end

function EggBoss:state_Phase1_enter()
	self.roaming = true
end

function EggBoss:state_Phase1_update(dt)
	if self.roaming then
		if self.pos.y < -10 then
			self.roam_direction.y = 1
			self:start_timer("walk_timer", self.walk_timer)
		end
	end
	self:hover()
end

function EggBoss:hover()
	self:set_body_height(self:get_hover_body_height())
end

function EggBoss:state_Phase2_enter()
	self.roaming = false
	local s = self.sequencer
	s:start(function()
        local start_height = self.body_height
		local start_x = self.pos.x
		local start_y = self.pos.y
		s:tween(function(t)
            self:set_body_height(lerp(start_height, 600, t))
			self:move_to(vec2_lerp(start_x, start_y, 0, 0, t))
		end, 0, 1, 120, "inCubic")
		self:hide()
		-- s:wait(100)
		-- self:change_state("Phase3")
	end)
end

function BloodSpawner:new(x, y, body_height, dx, dy)
	self.body_height = body_height
	BloodSpawner.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
	self.z_index = 1000
	self.melee_attacking = false
	self.rotation = rng.randf_range(0, tau)

	self.gravity = 0.0
	self.drag = 0.001
	self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self:apply_impulse(vec2_mul_scalar(dx, dy, rng.randf_range(0.5, 2.55)))
	if dy < 0 then
		self.z_index = 0
	end
	self:lazy_mixin(Mixins.Behavior.PositionHistory, 10)
    self.random_offset = rng.randi()
	
end

function BloodSpawner:enter()
	self:add_tag("egg_boss_blood")
	self:ref("shadow", self:spawn_object(BloodShadow(self.pos.x, self.pos.y))):ref("parent", self)
	self:bind_destruction(self.shadow)
	self:add_move_function(function()
		if self.shadow then
			self.shadow:move_to(self.pos.x, self.pos.y)
		end
	end)
	local s = self.sequencer
	s:start(function()
		local start_height = self.body_height
		local tween_time = max(start_height * 0.4 + rng.randf_range(-10, 10), 5)

		s:tween(function(t)
			self:set_body_height(lerp(start_height, 0, t))
		end, 0, 1, tween_time, "inCubic")
		self:bloodstain()
		if self.shadow then
			self.shadow:queue_destroy()
		end
		s:wait(60)
		self.melee_attacking = true
	end)
end


function BloodSpawner:die()
	self:queue_destroy()
end



function BloodSpawner:bloodstain()
	local scale = clamp01(rng.randfn(0.5, 0.25))
    self.scale = scale
	self.drag = lerp(0.04, 0.06, scale)

	self.z_index = 0
    self.stained = true
	self:play_sfx("enemy_evil_egg_blood_splatter", 0.5)
	local player_body_height = 3
	local x1, y1 = vec2_rotated(0, 1, self.rotation)
	self:add_hit_bubble(x1 * 1.35, y1 / 2 - player_body_height, 1, "main1")
	local x2, y2 = vec2_rotated(1, 0, self.rotation)
	self:add_hit_bubble(x2 * 1.35, y2 / 2 - player_body_height, 1, "main2")
	local x3, y3 = vec2_rotated(-1, 0, self.rotation)
	self:add_hit_bubble(x3 * 1.35, y3 / 2 - player_body_height, 1, "main3")
	local x4, y4 = vec2_rotated(0, -1, self.rotation)
	self:add_hit_bubble(x4 * 1.35, y4 / 2 - player_body_height, 1, "main4")
	self:start_stopwatch("bloodstain")

	local s = self.sequencer
	s:start(function()
		local size = lerp(1, 6, scale)
		local bloodstain_draw_size = (size + 1) * 4
		s:tween(function(t)
			local coord = lerp(0, size, t)
			local r = lerp(1, size, t)
			self.bloodstain_draw_size = lerp(1, bloodstain_draw_size, t)
			local x1, y1 = vec2_rotated(0, coord, self.rotation)
			self:set_hit_bubble_position("main1", x1 * 1.35, y1 / 2 - player_body_height)
			local x2, y2 = vec2_rotated(coord, 0, self.rotation)
			self:set_hit_bubble_position("main2", x2 * 1.35, y2 / 2 - player_body_height)
			local x3, y3 = vec2_rotated(-coord, 0, self.rotation)
			self:set_hit_bubble_position("main3", x3 * 1.35, y3 / 2 - player_body_height)
			local x4, y4 = vec2_rotated(0, -coord, self.rotation)
			self:set_hit_bubble_position("main4", x4 * 1.35, y4 / 2 - player_body_height)
			self:set_hit_bubble_radius("main1", r)
			self:set_hit_bubble_radius("main2", r)
			self:set_hit_bubble_radius("main3", r)
			self:set_hit_bubble_radius("main4", r)
		end, 0, 1, lerp(90, 190, scale), "linear")
		-- s:wait(400)
		-- self:start_destroy_timer(220)
	end)
end



function BloodSpawner:update(dt)
	self:collide_with_terrain(0)

    if self.zapping and not self.zap_target then
		self:end_zap_sequence()
	end

    if self.stained and self.is_new_tick and rng.percent(0.5) and not self.zapping then

        if self.world:get_number_of_objects_with_tag("egg_boss_blood") < 1 then
            goto nevermind
        end
		
        local random_blood = self.world:get_random_object_with_tag("egg_boss_blood")
        
        local attempts = 0
		local valid = true
        while not (random_blood and random_blood ~= self and random_blood.stained) do
			attempts = attempts + 1
			if attempts > 10 then
				valid = false
				break
			end
			random_blood = self.world:get_random_object_with_tag("egg_boss_blood")
		end

        if random_blood and random_blood == self and self.tick > 240 then
            self:zap(self)
            goto nevermind
		elseif not valid then
			goto nevermind
		end
		
        -- local bx, by = self:get_body_center()
        -- local tx, ty = random_blood:get_body_center()
		
        -- local middle_x, middle_y = vec2_lerp(bx, by, tx, ty, 0.5)
		

        -- local closest_player = self.world:get_closest_object_with_tag("player", middle_x, middle_y)
		
		-- if not closest_player then
		-- 	goto nevermind
		-- end

        -- local pbx, pby = closest_player:get_body_center()
		
		
        -- local distance = vec2_distance(middle_x, middle_y, pbx, pby)
		
        -- if not (self.parent and self.parent.state == "Phase2" and self.parent.state_tick and self.parent.state_tick > 90) and distance > vec2_distance(bx, by, tx, ty) * 0.5 then
            -- goto nevermind
        -- end
		
		self:ref("zap_target", random_blood)
		
        self.zapping = true
        local s = self.sequencer
        self.zap_startup = 0
        self.zap_sequence = s:start(function()
			self:play_sfx("enemy_evil_egg_zap_charge", 0.8)
            s:tween_property(self, "zap_startup", 0, 1, 70, "linear")

            self:zap(self.zap_target)
            self:end_zap_sequence()
        end, 10)

        ::nevermind::
	end
end

function BloodSpawner:exit()
	self:stop_sfx("enemy_evil_egg_zap_charge")
end

function BloodSpawner:end_zap_sequence()
	if self.zap_sequence then
		self.sequencer:stop(self.zap_sequence)
		self.zap_sequence = nil
	end
    self.zapping = false
	self.zap_startup = nil

end

function BloodSpawner:zap(target)
	
	local s = self.sequencer
	
	self:stop_sfx("enemy_evil_egg_zap_charge")
    self:play_sfx("enemy_evil_egg_blood_zap", 0.8)
	
	s:start(function()
		self:unref("zap_target")
        if target == nil then return end
        if target.is_destroyed then return end
		if target.is_queued_for_destruction then return end
		local start_x, start_y = self:get_body_center_local()
		local end_x, end_y = self:to_local(target:get_body_center())
		self.zap_end_x, self.zap_end_y = end_x - start_x, end_y - start_y
        self:add_hit_bubble(start_x, start_y, 3, "zap", 1, end_x, end_y)
        self:start_timer("zap_effect", 4, function()
			self:queue_destroy()
		end)
		s:wait(1)
		if self:get_bubble("hit", "zap") then
            self:remove_bubble("hit", "zap")
		end
	end)
end

function BloodSpawner:draw()

	local pos = self:get_position_for_history()
	
    if self.zapping and self.zap_target and self.zap_startup then
        local start_x, start_y = self:get_body_center_local()
        local end_x, end_y = self:to_local(self.zap_target:get_body_center())
        graphics.push("all")
		graphics.set_color(self:get_color())
		graphics.set_line_width(lerp(1, 3, ease("inOutCubic")(self.zap_startup)))
		graphics.line(end_x, end_y, vec2_lerp(end_x, end_y, start_x, start_y, ease("inOutCubic")(remap_clamp(self.zap_startup, 0, 0.5, 0, 1))))
		graphics.pop()
    end
	
    if not (self.stained and not self.melee_attacking) or idivmod_eq_zero(gametime.tick, 1, 2) then
        local position_history = self.position_history
        for i = 1, #position_history do
            local pos = position_history[i]


            if not pos.stained then
                self:draw_drop(pos, i / self.position_history_size * 0.7)
                if i > 1 then
                    self:draw_line(position_history[i - 1], pos, i / self.position_history_size * 0.3)
                end
            end
        end
        self:draw_drop(pos, 1, true)
    end

	if self.zap_end_x and self.zap_end_y and self:is_timer_running("zap_effect") then
		local start_x, start_y = self:get_body_center_local()
        local ratio = ease("inCubic")(self:timer_time_left_ratio("zap_effect"))
		graphics.set_color(Color.white)
        graphics.push("all")
		graphics.set_line_width(lerp(1, 10, ratio))
		graphics.line(start_x, start_y, start_x + self.zap_end_x, start_y + self.zap_end_y)
        graphics.pop()
		self:draw_drop(pos, 2, false, Color.white)
	end
end

function BloodSpawner:draw_line(pos1, pos2, size_multiplier)
	graphics.set_color(self:get_color())
	local size = max((pos1.bloodstain_draw_size or 0), 8) * size_multiplier

	local x1, y1 = self:to_local(pos1.x, pos1.y)
	local x2, y2 = self:to_local(pos2.x, pos2.y)
	graphics.push("all")
	graphics.set_line_width(size)
	graphics.line(x1, y1, x2, y2)
	graphics.pop()
end

function BloodSpawner:draw_drop(pos, size_multiplier, draw_hazard, color)
	graphics.set_color(color or self:get_color())
	local x, y = self:to_local(pos.x, pos.y)

	graphics.push("all")
	graphics.translate(x, y)
	graphics.scale(1, pos.stained and 0.5 or 1)
	graphics.rotate(pos.stained and (tau / 8 + self.rotation) or 0)
	local size = max((pos.bloodstain_draw_size or 0), 8) * size_multiplier

	graphics.rectangle_centered("fill", 0, 0, size, size)
	graphics.pop()

	if draw_hazard then
		local stopwatch = self:get_stopwatch("bloodstain")
		if stopwatch then
			local elapsed = stopwatch.elapsed
			local num_rectangles = 4
			graphics.set_line_width(1)
			for i=1, num_rectangles do
				graphics.set_color(Palette.egg_blood3:tick_color(self.tick + self.random_offset + i, 0, 3))
				local rx, ry = x, y - i * (self.scale * 4.2 * clamp01(elapsed / 200)) * (1 + sin(elapsed * 0.02) * 0.25)
				local rotation = (tau / 8 + self.rotation) + ((i - 1) * elapsed * 0.02)
				local scale_x, scale_y = 1, 0.5
				local size = max((pos.bloodstain_draw_size or 0), 8) * size_multiplier * lerp(1, 0.35, i / num_rectangles)
				
				graphics.poly_rect("line", rx, ry, size, size, rotation, scale_x, scale_y)
			end
		end
	end
end

function BloodSpawner:get_color()
	return Palette.egg_blood2:tick_color(self.tick + self.random_offset, 0, 3)
end

function BloodSpawner:get_position_for_history()
	local bx, by = self:get_body_center()
	return
	{
		x = bx,
		y = by,
		stained = self.stained,
		bloodstain_draw_size = self.bloodstain_draw_size
	}
end

function BloodSpawner:floor_draw()
	if self.stained and self.is_new_tick then
		graphics.set_color(0, 0, 0.25)

		self:body_translate()
		graphics.scale(1, 0.5)
		graphics.rotate(tau / 8 + self.rotation)
		local size = max((self.bloodstain_draw_size or 0), 8) * 1.25
		graphics.rectangle_centered("fill", 0, 0, size, size)
	end
end


function BloodShadow:new(x, y)
	BloodShadow.super.new(self, x, y)
	self:add_elapsed_time()
	self:add_elapsed_ticks()
	self.z_index = -11
end

function BloodShadow:draw()
	if idivmod_eq_zero(self.tick, 1.01, 2) then
		graphics.set_color(Color.darkgrey)
		graphics.scale(1, 0.5)
		-- graphics.rotate(tau / 8)
		local size = 8 * remap_clamp(self.parent.body_height, 500, 150, 0.0, 1)
		graphics.rectangle_centered("fill", 0, 0, size, size)
	end
end


function CrackFragment:new(x, y, height, dx, dy, z_force, fragment)
	self.speed = rng.randf_range(0.4, 2)
	CrackFragment.super.new(self, x, y)
    self.dx = dx
    if dy < 0 then
		z_force = -z_force * 2
	end
    self.dy = abs(dy)
    self.z_index = 1
    self.z = height
    self.z_vel = -z_force
	self.z_acc = 0.0
	self.gravity = rng.randf_range(0.05, 0.15)
	self.fragment = fragment
    self:add_elapsed_time()
	self.random_offset = rng.randi()
	self:add_elapsed_ticks()
end

function CrackFragment:update(dt)
    self.z_acc = self.z_acc + self.gravity
    self.z_vel = self.z_vel + self.z_acc * dt
    self.z = self.z - self.z_vel * dt
    self.z_acc = self.z_acc * 0.0

    if self.z < 0 then
        self.z = 0
        if abs(self.z_vel) > 0.4 then
            self.z_vel = -self.z_vel * 0.485
            self.bounced = true
			self:play_sfx("enemy_evil_egg_shell_fragment_bounce", 0.25)
        else
            self.z_vel = 0.0
            if not self:is_timer_running("destroy_timer") then
				self.grounded = true
				self:start_destroy_timer(46)
            end
        end
    end

    local x, y = vec2_mul_scalar(self.dx, self.dy, dt * self.speed)
	
    self:move(x, y)
	
	self.speed = drag(self.speed, self.grounded and 0.05 or 0.001, dt)
end

function CrackFragment:draw()
    -- graphics.set_color(Color.white)
    if (self.tick + self.random_offset) % 2 == 0 or not self.bounced then
        if self.bounced then
			graphics.scale(1, 0.5)
		end
		graphics.draw_centered(self.fragment.quad_table, 0, 0 - self.z)
	end
end

AutoStateMachine(EggBoss, "Idle")

return EggBoss
