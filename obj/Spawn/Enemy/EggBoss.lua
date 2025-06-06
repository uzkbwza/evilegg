local EggBoss = BaseEnemy:extend("EggBoss")
local BloodSpawner = BaseEnemy:extend("BloodSpawner")
local BloodShadow = GameObject2D:extend("BloodShadow")
local CrackFragment = GameObject2D:extend("CrackFragment")
local Bouncer = require("obj.Spawn.Enemy.Hazard.Bouncer")[2]
local FloatingSpeech = GameObject2D:extend("FloatingSpeech")
local NormalRescue = require("obj.Spawn.Pickup.Rescue.NormalRescue")
local PickupTable = require "obj.pickup_table"
local RoyalGuard = require("obj.Spawn.Enemy.Enforcer")[2]
local RoyalRoamer = require("obj.Spawn.Enemy.Roamer")[3]
local Explosion = require("obj.Explosion")
local Rook = require("obj.Spawn.Enemy.Rook")
local EggShadow = BaseEnemy:extend("EggShadow")


local SKIP_PHASE_1, SKIP_PHASE_2, SKIP_PHASE_3, SKIP_PHASE_4, SKIP_PHASE_5 = false, false, false, false, false

SKIP_PHASE_1 = SKIP_PHASE_1 and debug.enabled
SKIP_PHASE_2 = SKIP_PHASE_2 and debug.enabled
SKIP_PHASE_3 = SKIP_PHASE_3 and debug.enabled
SKIP_PHASE_4 = SKIP_PHASE_4 and debug.enabled
SKIP_PHASE_5 = SKIP_PHASE_5 and debug.enabled

local QUAD_SIZE = 10

local SHELL_HP = SKIP_PHASE_1 and 30 or 250
local BASE_HP = 600
local NUM_SHELL_CRACKS = 27
local SHELL_DAMAGE_PER_CRACK = SHELL_HP / NUM_SHELL_CRACKS
local START_Y = 35

local LAND_EXPLOSION_SIZE = 30

local SPEECH_FONT = fonts.depalettized.egglanguage

local DIALOGUE = [[help me. i'm sorry. i'm sorry. where am i? i can't control us. are you my children? 
you came back for me. it hurts. we're so sorry. it hurts. we can't control me. please help. what is going on? 
what am i? what am i? who are you? it hurts. there's nobody left. i'm all in here. we want to go home.]]

DIALOGUE = string.filter(DIALOGUE, "abcdefghijklmnopqrstuvwxyz")
DIALOGUE = string.rep(DIALOGUE, 20)


local _new = ""

for i=1, #DIALOGUE do
	local c = DIALOGUE:sub(i, i)
    _new = _new .. c
    if rng:percent(5) then
		local j = rng:randi_range(1, 26)
		_new = _new .. string.sub("abcdefghijklmnopqrstuvwxyz", j, j)
	end
end

DIALOGUE = _new

print(DIALOGUE)

local function get_random_speech()
    local size = floor(pow(clamp01(abs(rng:randfn(0.5, 0.7))), 2) * rng:randi_range(1, 15)) + 1
	local start_index = rng:randi_range(1, #DIALOGUE - size)
	return DIALOGUE:sub(start_index, start_index + size)
end

-- print(DIALOGUE)

function EggBoss:new()
	self:add_signal("cracked")
	self.body_height = 80
	self.z_index = 0
	self.base_body_height = self.body_height
    self.terrain_collision_radius = 40
    self.egg_blood_palette = Palette.egg_blood
	-- self.hurt_bubble_radius = 60
	-- self.hit_bubble_radius = 55

	self.shell_hp = SHELL_HP
	self.max_hp = BASE_HP
	self.shell_fragment_locations = {}

	self.walk_speed = 0.15
    self.walk_timer = 180

	self.shadow_darkness = 0.0

    self.crack_centers = {}
	
	self.bullet_push_modifier = 0.05

	
	EggBoss.super.new(self, 0, START_Y)

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
		self.crack_points[i] = base_value + rng:randf_range(-variance, variance)
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

function EggBoss:hit_by(object)

    if object.is_bubble then
        local bubble = object
        object = object.parent
    end

	if object.cannot_hit_egg then return end

	if self.state == "Phase3" or self.state == "Phase5" then
		self:start_timer("shadow_hurt_flash", 1)
	end

	EggBoss.super.hit_by(self, object)
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
		if self.can_take_damage then
			Mixins.Behavior.Health.damage(self, amount)
			if self.state == "Phase3" and (self.hp < BASE_HP * 0.5 or (self.spawning_stalkers and SKIP_PHASE_3)) and not self.phase2_started_twice then
				self:change_state("Phase2")
				self.phase2_started_twice = true
			end
		end
	end
end


function EggBoss:get_hover_body_height()
    return round(self.base_body_height + 5 * sin(self.elapsed * 0.02))
end

function EggBoss:get_hover_body_height2()
    return round(self.base_body_height + 5 * sin(self.elapsed * 0.02) + 20)
end


function EggBoss:crack_shell()

    if not self.shell_cracked then
		self.world.room.egg_boss_fight_started = true
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

	
	local start_id = rng:choose(table.keys(self.shell_fragment_locations))
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

	
    if (self.shell_cracks - 1) % 7 == 0 then
		local s = self.sequencer	
		s:start(function()
			for i=1, 2 do
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
            dist = dist + rng:randf_range(-2, 2)

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
				local z_force = remap(dy, -1, 1, -1, rng:randf_range(-1, 5))
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


	-- for i = 1, initial and max(min(abs(rng:randfn(1, 1)), 3), 0) or max(min(abs(rng:randfn(4, 2)), 7), 1) do


	if SKIP_PHASE_1 and initial then return end

	
	local normal_spawns = max(min(abs(rng:randfn(1.25, 1)), 5), 0)
	local initial_spawns = max(min(abs(rng:randfn(4, 2)), 7), 1)
	local num_spawns = (not initial) and normal_spawns or initial_spawns
	local base_rotation = rng:randfn(0, tau / 12)
	local base_speed = rng:randfn(1.0, 0.45)
	local phase2_speed_multiplier = 0.25
	local spawn_x = crack_center.x + bx
	local spawn_y = real_y
    local spawn_z = -(screen_y - real_y)
    if self.phase2_started_twice and num_spawns > 0 then
        num_spawns = max(num_spawns * 0.65, 1)
    end
	
	if num_spawns > 0 then
		self:play_sfx("enemy_evil_egg_blood_squirt", 0.4)
	end

	for i = 1, num_spawns do
		local dx, dy = vec2_rotated(bdx, bdy, base_rotation)
        dx, dy = vec2_mul_scalar(dx, dy, base_speed)
		
		if self.state == "Phase2" then
			dx, dy = vec2_mul_scalar(dx, dy, phase2_speed_multiplier)
		end
		self:spawn_object(BloodSpawner(spawn_x, spawn_y, spawn_z, dx, dy)):ref("parent", self)
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
	self:add_hurt_bubble(0, -50, 26, "main2")
	self:add_hurt_bubble(-14, -44, 20, "main3")
	self:add_hurt_bubble(-24, -34, 20, "main4")
	self:add_hurt_bubble(-30, -24, 20, "main5")
	self:add_hurt_bubble(-34, -14, 20, "main6")
    self:add_hurt_bubble(-38, -04, 20, "main7")
	
	self:add_hurt_bubble(14, -44, 20, "main8")
	self:add_hurt_bubble(24, -34, 20, "main9")
	self:add_hurt_bubble(30, -24, 20, "main10")
	self:add_hurt_bubble(34, -14, 20, "main11")
	self:add_hurt_bubble(38, -04, 20, "main12")
	-- self:add_hit_bubble(0, 18, 52, "main")
end

function EggBoss:update(dt)
    EggBoss.super.update(self, dt)
end

function EggBoss:try_spawn_blood()
	if self.is_new_tick then
        for _, crack_center in ipairs(self.crack_centers) do
			if rng:percent(self.phase2_started_twice and 0.08 or 0.15) then
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
    if self:is_timer_running("shadow_hurt_flash") then
		return Palette.dark_egg_flash, idiv(self.tick, 3)
	end
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
	if idivmod_eq_zero(gametime.tick, 1.0, ceil(3 - floor(max(self.shadow_darkness - 0.5, 0) * 2))) then
		local scale = max(inverse_lerp(self.base_body_height + 5, self.base_body_height - 5, self.body_height) * 0.125 + 1, 0)
        if self.land_warning then
            scale = clamp01(self:get_stopwatch("land_warning").elapsed / 80) + 0.1
            graphics.set_color(Palette.fire:tick_color(self.tick, 0, 3))
        end
		
        -- scale = scale * (1 - self.shadow_darkness)
		
		local color_mod = 1 - self.shadow_darkness

		if self.shadow_darkness > 0 and not self.land_warning then
			graphics.set_color(Color.darkergrey.r * color_mod, Color.darkergrey.g * color_mod, Color.darkergrey.b * color_mod)
		end

		-- graphics.ellipse("fill", 0, 35, 40 * scale, 20 * scale)
		graphics.push("all")
		do
			graphics.translate(0, 0)
            graphics.scale(1, 0.5)
            graphics.rotate(tau / 8)
            if self.land_warning then
                graphics.rotate(self.elapsed * 0.1)
            end
			graphics.set_line_width(4)
            graphics.rectangle_centered(self.land_warning and "line" or "fill", 0, 0, 60 * scale, 60 * scale)
			if self.land_warning then
				graphics.rectangle_centered("line", 0, 0, 80 * scale, 80 * scale)
			end
		end
		graphics.pop()
	end
	self:body_translate()
	graphics.set_color(Color.white)

	graphics.translate((ease("inCubic")(self:timer_time_left_ratio("crack_swell2"))) * 4 * (self.tick % 2 == 0 and 1 or -1), 0)

	local palette, palette_index = self:get_palette()
	local h_flip, v_flip = self:get_sprite_flip()


	-- if idivmod_eq_zero(self.tick, 1, 2)  then
	-- 	local any_player = self:get_any_ally()
	-- 	if any_player.pos.y < self.pos.y then
	-- 		return
	-- 	end
	-- end

	-- if self.tick % 27 ~= 0 then
		graphics.drawp_centered(textures.enemy_egg_boss2, palette or self.egg_blood_palette, palette_index, 0, 0, 0, h_flip, v_flip)
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

local SPEECH_PERIOD = 10

function EggBoss:state_Idle_enter()
    -- for i = 1, 30 do
        -- local speech = self:spawn_speech(i % 2 == 0)
		-- self:defer(function()
		-- 	for j=1, i * SPEECH_PERIOD do
		-- 		speech:update_shared(1)
		-- 	end
		-- end)
	-- end
end

function EggBoss:state_Idle_update(dt)
    self:hover()

	self:try_spawn_blood()

    if self.is_new_tick and self.tick % SPEECH_PERIOD == 0 then
        local front = (self.tick % (2 * SPEECH_PERIOD) == 0)
        self:spawn_speech(front, true)
    end
end

function EggBoss:spawn_speech(front, can_make_sound)
	local bx, by = self:get_body_center()
	local height = 60
	-- local width = 65
	-- local x_offset = rng:randf_range(-width / 2, width / 2)
	-- if not front then
	-- 	if abs(x_offset) < 50 then
	-- 		x_offset = 50 * sign(x_offset)
	-- 	end
	-- end
	-- local x = bx + x_offset
	local x = bx

	local font_height = SPEECH_FONT:getHeight()
	
	local y_offset =  rng:randf_range(-height / 2, height / 2)

    local y = by + y_offset

    y_offset = (y - by) / (height / 2)

	local orbit_width_ratio = 1

    if y_offset < 0 then
		orbit_width_ratio = 1 + y_offset
    else
		orbit_width_ratio = 1 - pow(y_offset, 3)
	end

	orbit_width_ratio = remap_clamp(orbit_width_ratio, 0, 1, 0.5, 1)

	orbit_width_ratio = rng:randf_range(orbit_width_ratio, orbit_width_ratio + 0.15)

	local speech = self:spawn_object(FloatingSpeech(x, y, get_random_speech(), rng:rand_sign(), front, can_make_sound, orbit_width_ratio))
	speech:ref("parent", self)
	return speech
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
	self.phase2_finished = false
	self.can_take_damage = false
	self.roaming = false
	local s = self.sequencer
	s:start(function()
        local start_height = self.body_height
		local start_x = self.pos.x
		local start_y = self.pos.y
		s:tween(function(t)
            self:set_body_height(lerp(start_height, 600, t))
			self:move_to(vec2_lerp(start_x, start_y, 0, START_Y, t))
		end, 0, 1, 120, "inCubic")
        self:hide()

		-- self.egg_blood_palette = Palette.egg_blood:clone()
		-- self.shadow_darkness = 0.0

        local num_seconds = 40
        local num_greenoids = 16

        local heart_spawn = rng:randi_range(1, num_greenoids)
        -- local upgrade_spawn = rng:randi_range(1, num_greenoids)
		-- while heart_spawn == upgrade_spawn do
			-- upgrade_spawn = rng:randi_range(1, num_greenoids)
		-- end

        local skip = false
		if self.phase2_started_twice then
			skip = SKIP_PHASE_4
		else
			skip = SKIP_PHASE_2
		end

        if not (skip) then
            local wait_time = floor(seconds_to_frames(num_seconds / num_greenoids))
            for i = 1, num_greenoids do
                s:wait(wait_time)
                local pickup = i == heart_spawn and PickupTable.hearts.NormalHeart or
                    (not game_state:is_fully_upgraded() and game_state:get_random_available_upgrade(false))
				
				if i ~= heart_spawn then
                    for _, object in self.world:get_objects_with_tag("rescue_object"):ipairs() do
						if object.holding_pickup == pickup then
							pickup = nil
						end
					end
				end

                self:spawn_greenoid(pickup)
                for j = 1, (self.phase2_started_twice and rng:randi_range(2, 3) or 2) do
                -- for j = 1, (2) do
                    self.world:spawn_something(RoyalGuard, nil, nil, nil, nil, function(object)
                        self:spawn_wave_enemy(object)
                    end)
                end
				if self.phase2_started_twice and i % 3 == 0 and i > num_greenoids * 0.33 and self.world:get_number_of_objects_with_tag("rook") < 2 then
					local x, y = nil, nil
					-- local random_shadow = self.world:get_random_object_with_tag("egg_shadow")
					-- if random_shadow then
					-- 	x, y = random_shadow:get_body_center()
					-- 	x, y = vec2_add(x, y, rng:random_vec2_times(rng:randf_range(0, random_shadow.radius)))
					-- end
					self.world:spawn_something(Rook, x, y, nil, nil, function(object)
						self:spawn_wave_enemy(object)
						object:add_tag_on_enter("rook")
					end)
				end
            end

            s:wait(120)
        end
		
		while self.world:get_number_of_objects_with_tag("royalguard") > 0 or self.world:get_number_of_objects_with_tag("rook") > 0 do
			s:wait(1)
		end

        self.land_warning = true
		self:start_stopwatch("land_warning")
		self:play_sfx("enemy_evil_egg_phase2_fall", 1)
		
		self:show()

        local land_height = self.base_body_height - 20
		self.phase2_finished = true

		s:tween(function(t)
            self:set_body_height(lerp(600, land_height, t))
        end, 0, 1, 80, "inCubic")

        self:phase2_landing()
        if not self.phase2_started_twice then
			audio.play_music("music_egg_boss1", 1.0)
		end
		
		self:stop_sfx("enemy_evil_egg_phase2_fall")
		self.land_warning = false
		self:stop_stopwatch("land_warning")
		
		local old_z_index = self.z_index
		self.z_index = 100


		s:wait(20)

		s:tween(function(t)
			self:set_body_height(lerp(land_height, self:get_hover_body_height(), t))
		end, 0, 1, 90, "inOutCubic")

		self.z_index = old_z_index

        if self.phase2_started_twice then
			self:change_state("Phase5")
		else
			self:change_state("Phase3")
		end
		
		
		

	end)
end

function EggBoss:phase2_landing()
    -- self:play_sfx("enemy_evil_egg_phase2_landing", 0.8)
    self.world.camera:start_rumble(5, 20, ease("linear"), false, true)
    self:spawn_object(Explosion(self.pos.x, self.pos.y, {
        size = LAND_EXPLOSION_SIZE,
		draw_scale = 2.0,
    }))
    for _, object in self.world.objects:ipairs() do
		if object ~= self and Object.is(object, BaseEnemy) then
			object:die(self)
		end
    end
end

function EggBoss:state_Phase2_update(dt)
	if not self.phase2_finished then
		self:try_spawn_blood()
	end
end

function EggBoss:spawn_greenoid(pickup)
	if not game_state.game_over then
		self.world:spawn_rescue(NormalRescue, pickup, self.world:get_valid_spawn_position())
	end
end

function EggBoss:state_Phase3_enter()
    self.spawning_stalkers = false
    self.roaming = false
    local s = self.sequencer
    s:start(function()
        s:start(function()
            self.shadow_darkness = 0.0
            s:tween_property(self, "shadow_darkness", 0.0, 1.0, 100, "linear")
        end)

        s:start(function()
            self.egg_blood_palette = Palette.egg_blood:clone()


            local colors = {
                Color.black,
                Color.black,
                Color.nearblack,
            }

            local skip_color = function(color)
                return not table.list_has(colors, color)
            end

            for colornum = 1, 90 do
                -- self.egg_blood_palette:set_color(i, Color.red)
                local found = false
                local colors_skipped = 0
                local palette_index = 1
                while true do
                    if skip_color(self.egg_blood_palette:get_color(palette_index)) then
                        if colornum > 10 then
                            local r, g, b = self.egg_blood_palette:get_color_unpacked(palette_index)
                            local mod = 0.99
                            self.egg_blood_palette:set_color_unpacked(
                            self.egg_blood_palette:get_valid_index(palette_index), r * mod, g * mod, b * mod, 1)
                        end
                        if colors_skipped >= colornum - 1 then
                            break
                        else
                            colors_skipped = colors_skipped + 1
                            -- palette_index = palette_index + 1
                        end
                    end
                    palette_index = palette_index + 1
                end
                -- self.egg_blood_palette:add_color(table.get_circular(colors, palette_index), palette_index)
                if colornum % 5 == 0 then
                    s:wait(5)
                end
            end

            self.can_take_damage = true
        end)

        s:wait(100)



        local num_shadows = 8
        for i = 1, num_shadows do
            local angle = i * tau / num_shadows

            self:spawn_object(EggShadow(0, 0, angle, 110, 0.009, 80)):ref("parent", self)
            s:wait(10)
        end
        for i = 1, num_shadows do
            local angle = (i + 0.5) * tau / num_shadows + pi

            self:spawn_object(EggShadow(0, 0, angle, 186, -0.0066, 110)):ref("parent", self)
            s:wait(10)
        end

        self.roaming = true

        self.spawning_stalkers = true

        s:wait(200)
        for _, shadow in self.world:get_objects_with_tag("egg_shadow"):ipairs() do
            shadow:start_moving()
        end
    end)
end

function EggBoss:state_Phase3_exit()
	for _, shadow in self.world:get_objects_with_tag("egg_shadow"):ipairs() do
		shadow:start_oscillating()
	end
end

function EggBoss:state_Phase3_update(dt)
    self:set_body_height(self:get_hover_body_height())
	-- dbg("number_of_stalkers", self.world:get_number_of_objects_with_tag("royal_roamer"))
    if self.spawning_stalkers and self.is_new_tick then
        if self.state_tick % 5 == 0 and self.world:get_number_of_objects_with_tag("royal_roamer") + self.world:get_number_of_objects_with_tag("wave_spawn") - 3 < 40 then
            -- if self.state_tick % 5 == 0 and self.world:get_number_of_objects_with_tag("royal_roamer") < 50 then
            -- local pbx, pby = self:random_last_player_body_pos()
            local x, y = nil, nil
            local random_shadow = self.world:get_random_object_with_tag("egg_shadow")
            if random_shadow then
                x, y = random_shadow:get_body_center()
                x, y = vec2_add(x, y, rng:random_vec2_times(rng:randf_range(0, random_shadow.radius)))
            end
            -- local dist = rng:randf_range(32, 90)
            -- local angle = rng:randf_range(0, tau)
            -- local x, y = vec2_from_polar(dist, angle)
            -- x, y = pbx + x, pby + y
            self.world:spawn_something(RoyalRoamer, x, y, nil, nil, function(object)
                -- self:spawn_wave_enemy(object)
                object:add_tag_on_enter("royal_roamer")
                object:add_tag_on_enter("wave_enemy")
            end)
        end

	end
end

function EggBoss:state_Phase5_enter()
	self.spawning_stalkers = false
    self.roaming = false
	self.can_take_damage = true
end


function BloodSpawner:new(x, y, body_height, dx, dy)
	self.body_height = body_height
	BloodSpawner.super.new(self, x, y)
	self.z_index = 1000
	self.melee_attacking = false
	self.rotation = rng:randf_range(0, tau)

    self.gravity = 0.0
	self.intangible = true
	self.drag = 0.001
	self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self:apply_impulse(vec2_mul_scalar(dx, dy, rng:randf_range(0.5, 2.55)))
	if dy < 0 then
		self.z_index = 0
	end
	self:lazy_mixin(Mixins.Behavior.PositionHistory, 10)
    self.random_offset = rng:randi()
	
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
		local tween_time = max(start_height * 0.4 + rng:randf_range(-10, 10), 5)

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
	local scale = clamp01(rng:randfn(0.5, 0.25))
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

    if self.stained and self.is_new_tick and rng:percent(0.5) and not self.zapping then

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
        graphics.set_line_width(lerp(1, 6, ease("inOutCubic")(self.zap_startup)))
        if self.zap_startup > 0.75 then
			graphics.set_color(idivmod_eq_zero(gametime.tick, 2, 2) and Color.cyan or Color.skyblue)
		end
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
        local ratio = ease("linear")(self:timer_time_left_ratio("zap_effect"))
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
	return Palette.egg_blood3:tick_color(self.tick + self.random_offset, 0, 3)
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
	self.speed = rng:randf_range(0.4, 2)
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
	self.gravity = rng:randf_range(0.05, 0.15)
	self.fragment = fragment
    self:add_elapsed_time()
	self.random_offset = rng:randi()
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

local FRONT_FG_COLORS = {
	Color.darkpurple, Color.darkpurple, Color.darkblue, Color.blue, Color.skyblue, Color.cyan, Color.lightergrey, Color.white
}

local BACK_FG_COLORS = {
	Color.black, Color.nearblack, Color.darkpurple, Color.darkpurple, Color.darkblue, Color.blue,
}

function FloatingSpeech:new(x, y, text, dir, front, can_make_sound, orbit_width_ratio)
	FloatingSpeech.super.new(self, x, y)
	self.text = text:lower():reverse()
    self.z_index = front and 100 or -1
    self.dir = dir
	self.front = front
	self.orbit_width_ratio = orbit_width_ratio

	if can_make_sound then
		self:play_sfx("enemy_evil_egg_speech" .. rng:randi(1, 5), 0.6)
	end

    -- self.duration = 12 * #self.text
	self.duration = 100

	self.phase_offset = rng:randf_range(-1, 1)

	self:add_elapsed_time()
    self:add_elapsed_ticks()
	self:start_timer("fade", self.duration, function()
		self:queue_destroy()
    end)
end

function FloatingSpeech:update_shared(dt)
    if self.world.room.egg_boss_fight_started then
        dt = dt * 3
    end
    while dt > 1 do
		FloatingSpeech.super.update_shared(self, 1)
		dt = dt - 1
	end
	FloatingSpeech.super.update_shared(self, dt)
end



function FloatingSpeech:get_foreground_color()
    local ratio = 1 - self:timer_time_left_ratio("fade")

    return table.interpolate(self.front and FRONT_FG_COLORS or BACK_FG_COLORS, clamp01(self.elapsed * 0.02))
end


function FloatingSpeech:draw()
    local ratio = 1 - self:timer_time_left_ratio("fade")
    local bump = math.tent(ratio)
    local t_offset = lerp(-1, 1, ratio) * self.dir
    local text = string.interpolate(self.text, clamp01(bump * 2))
    graphics.set_font(SPEECH_FONT)

    local out_ratio = pow(ratio, 10) * 0.5

    local ellipse_width = max(100 * self.orbit_width_ratio, 30) * (1 + out_ratio)
    local ellipse_height = max(50 * self.orbit_width_ratio, 15) * (1 + out_ratio)


    local phase = t_offset * (tau / 6) + pi / 2 + self.phase_offset * tau / 4

    if not self.front then
        phase = phase + pi
    end

    local character_spacing = 5
    local text_length = #text

    -- Calculate total angle needed for all characters
    local total_angle = 0
    local temp_angle = 0
    for i = 1, text_length do
        temp_angle = find_angle_at_distance(character_spacing, ellipse_width, ellipse_height, temp_angle)
    end

    total_angle = temp_angle

    -- Start angle offset to center the text
    local current_angle = -total_angle / 2

    self.angles = self.angles or {}
    table.clear(self.angles)

    for i = 1, text_length do
        current_angle = find_angle_at_distance(character_spacing, ellipse_width, ellipse_height, current_angle)
        self.angles[i] = current_angle
        local char = text:sub(i, i)

        local x, y = get_ellipse_point(ellipse_width, ellipse_height, current_angle, phase)

        graphics.set_color(self.front and Color.nearblack or Color.black)
        graphics.print_centered(char, SPEECH_FONT, x + self.dir, y + 1)
    end

    for i = 1, text_length do
        local char = text:sub(i, i)
        local x, y = get_ellipse_point(ellipse_width, ellipse_height, self.angles[i], phase)
        graphics.set_color(self:get_foreground_color())
        graphics.print_centered(char, SPEECH_FONT, x, y)
    end
end


local SHADOW_ACTIVATION_THRESHOLD = 0.70
local SHADOW_ACTIVATION_WARNING_WINDOW = 0.5
local SHADOW_ACTIVATION_FADEOUT_WINDOW = 0.025

function EggShadow:new(x, y, angle, distance, speed, swell_amount)
    EggShadow.super.new(self, x, y)

	self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self.z_index = -10
	self.speed = speed
	self.swell_amount = swell_amount
	self.applying_physics = false
    -- self.declump_mass = 1
	self.declump_force = -0.025
	self.distance = distance
	self.self_declump_modifier = 0.0
    self.intangible = true
    self.radius = 1
	self.angle = angle
	self.active = false
    self:move_to(vec2_from_polar(self.distance, self.angle))
    self.melee_attacking = false
	self.center_x, self.center_y = 0, 0
	self.oscillation = SHADOW_ACTIVATION_THRESHOLD
	self.oscillation_frequency = rng:randf_range(0.5, 1.5)
    self.oscillation_dir = 1
    self.oscillation_scale = clamp(abs(rng:randfn(1, 0.25)), 0.25, 1.25)
    self.oscillation_swell = rng:randf_range(0.25, 1)
	self.square_rotation = 0.0
    self.oscillation_rotation_speed = clamp(rng:randfn(0.125, 0.1) * rng:rand_sign(), -0.2, 0.2)
	self.swell_elapsed = 0
	self.oscillation_swell_speed = clamp(abs(rng:randfn(1, 0.25)), 0.75, 1.5)
end

function EggShadow:enter()
	self:play_sfx("enemy_evil_egg_shadow_spawn", 0.6)
    self.center_x, self.center_y = self.parent.pos.x, self.parent.pos.y
	
	self:add_tag("egg_shadow")
    local s = self.sequencer

    self:add_hit_bubble(0, 0, self.radius, "main", 2)

	-- self:start_timer("sfx2", 30, function()
		-- self:play_sfx("enemy_evil_egg_shadow_spawn2", 0.6)
	-- end)

    s:start(function()
        s:tween(function(t)
           self:set_radius(lerp(1, 26, t))
        end, 0, 1, 200, "linear")
		
    end)
	self:start_tick_timer("attack_timer", 180, function()
		self.melee_attacking = true
	end)
end

function EggShadow:start_moving()
	self.moving = true
end

function EggShadow:collide_with_terrain()
end

function EggShadow:update(dt)
    -- local stopwatch = self:get_stopwatch("move_stopwatch")
    local dist = self.distance

    local oscillation_stopwatch = self:get_stopwatch("oscillate_stopwatch")
	local oscillation_elapsed = oscillation_stopwatch and oscillation_stopwatch.elapsed or 0


    if self.oscillating then
		local old_oscillation = self.oscillation
        self.oscillation = sin((oscillation_stopwatch.elapsed) * 0.01 * self.oscillation_frequency + self.random_offset)
        local dir = self.oscillation > old_oscillation and 1 or -1
		self.oscillation_dir = dir
		self:set_active(self.oscillation >= SHADOW_ACTIVATION_THRESHOLD)
	end

    if self.moving then
		self.swell_elapsed = self.swell_elapsed + dt * lerp(1, self.oscillation_swell_speed, clamp01(oscillation_elapsed / 1200))

        self.angle = self.angle - dt * pow(clamp01(self.swell_elapsed / 900), 2) * self.speed
        dist = self.distance * lerp(1, 0.65, clamp01(oscillation_elapsed / 1200)) +
			sin(self.swell_elapsed * 0.01) *
        	lerp(self.swell_amount, self.swell_amount * self.oscillation_swell, clamp01(oscillation_elapsed / 900))
        local radius = 26 - clamp01(oscillation_elapsed / 1000) * 5 +
        sin(self.swell_elapsed * 0.01) * lerp(10, 0, clamp01(oscillation_elapsed / 1200))
		local oscillation_modifier = lerp(1, remap(self.oscillation, -1, 1, 0.5, 1) * self.oscillation_scale, clamp01(oscillation_elapsed / 700))
		self:set_radius(radius * oscillation_modifier)
    end

    local x, y = vec2_from_polar(dist, self.angle)

    if self.parent and self.parent.state == "Phase3" then
        self.center_x, self.center_y = splerp_vec(self.center_x, self.center_y, self.parent.pos.x, self.parent.pos.y,
            120.00, dt)
    else
        self.center_x, self.center_y = splerp_vec(self.center_x, self.center_y, 0, 0, 2000.00, dt)
    end
	
	self.square_rotation = self.square_rotation + dt * lerp(0.125, self.oscillation_rotation_speed, clamp01(oscillation_elapsed / 1220))


    self:move_to(self.center_x + x, self.center_y + y)
end

function EggShadow:set_active(active)
    self.active = active
	self.melee_attacking = active
end

function EggShadow:set_radius(radius)

	self.radius = radius
	self:set_bubble_radius("hit", "main", max(self.radius - 10, 1))
	self:set_bubble_radius("hurt", "main", max(self.radius - 1, 1))
	self.declump_radius = max(self.radius - 2, 1)
	self.terrain_collision_radius = max(self.radius - 2, 1)
end

function EggShadow:start_oscillating()
    self.oscillating = true
	self:start_stopwatch("oscillate_stopwatch")
end

function EggShadow:get_sprite()
	return nil
end

function EggShadow:floor_draw()
	if not self.is_new_tick then
		return
	end
    graphics.set_color(Color.black)
	-- local stopwatch = self:get_stopwatch("move_stopwatch")

	-- if not stopwatch and idivmod_eq_zero(self.tick, 1, 3) then
		-- graphics.set_color(Color.red)
	-- end
	for i=1, self.radius * 5 do
		graphics.points(rng:random_vec2_times(rng:randf_range(0, self.radius)))
	end
end

function EggShadow:draw()
    -- local stopwatch = self:get_stopwatch("move_stopwatch")
	
    local activating = false
	

	if self.oscillating and not self.active and self:get_stopwatch("oscillate_stopwatch").elapsed < 10 then
		activating = true
	elseif self.oscillation < SHADOW_ACTIVATION_THRESHOLD - (self.oscillation_dir > 0 and SHADOW_ACTIVATION_WARNING_WINDOW or SHADOW_ACTIVATION_FADEOUT_WINDOW) then
		-- print("not drawing")
        return
    elseif self.oscillation < SHADOW_ACTIVATION_THRESHOLD then
        if idivmod_eq_zero(gametime.tick, 1, 2) then
			activating = true
		else
			return
		end
		-- print("sometimes drawing")
	end


	local color_mod = 1.0

	if activating then
		color_mod = 0.25
	end

	if not idivmod_eq_zero(gametime.tick, 1, 3) then
		graphics.set_color(Color.black)
		graphics.circle("fill", 0, 0, self.radius)
	end

	
	local num_points = ceil(16 * (self.radius / 20))
    for i = 1, num_points do
		local angle = (i / num_points) * tau
		local x, y = vec2_from_polar(self.radius, angle + self.elapsed * 0.025)
        local r, g, b = (idivmod_eq_zero(self.tick + i * 7, 1, 5) and Color.darkpurple or Color.nearblack):unpack()
		
		graphics.set_color(Color.adjust_lightness_unpacked(r, g, b, color_mod))
		graphics.rectangle_centered("line", x, y, 2, 2)
	end

    -- graphics.set_color(idivmod_eq_zero(self.tick + self.random_offset * 7, 1, 5) and Color.darkpurple or Color.nearblack)
	local width = max(self.radius - 8, 1) * 2
	graphics.rotate(self.square_rotation)
	-- graphics.rectangle_centered("line", 0, 0, width, width)
    -- graphics.set_color(Color.purple)
	local r, g, b = Palette.egg_blood3:tick_color(self.tick, 0, 3):unpack()
    graphics.set_color(Color.adjust_lightness_unpacked(r, g, b, color_mod))
	-- graphics.set_color(Palette.rainbow:tick_color(self.tick, 0, 3))
	graphics.rectangle_centered("line", 0, 0, width, width)

end

function EggShadow:die()
	self:queue_destroy()
end

AutoStateMachine(EggBoss, "Idle")

return EggBoss
