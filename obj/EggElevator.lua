local EggElevator = GameObject2D:extend("EggElevator")
local XpPickup = require("obj.XpPickup")

local XP_AMOUNT = 1500
local PILLAR_HEIGHT = 400

local SKIP_SHOOTING = true

function EggElevator:new(x, y)
	-- self.max_hp = debug.enabled and 3 or 20
    self.max_hp = 60
    if debug.enabled and SKIP_SHOOTING then
        self.max_hp = 20
    end
	self.body_height = 3
    EggElevator.super.new(self, x, y)
	self.team = "enemy"
    self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.Health)
    self.rings = {}
	self.ring_id = 0
    self.pillars = {}
	self.floor_particles = {}
	self.dead_time = 0
	self.z_index = 0.1
    self.showing_shadow = true
	self:add_signal("player_choice_made")
end

function EggElevator:enter()
	self:add_tag("egg_elevator")
    if not self.back then
        self:add_hurt_bubble(0, 0, 6, "main")
        self:ref("back_object", self:spawn_object(EggElevator(self.pos.x, self.pos.y))).back = true
        self.back_object.z_index = 0
    end 
	
    if self.back then
		self:play_sfx("object_egg_elevator_spawn", 0.8)
		self:play_sfx("object_egg_elevator_spawn2")
    end
	
end

local RING_TIME = 250
local RING_HEIGHT = 400

local pillar_spawn_sfx = {
	"object_egg_elevator_pillar_spawn1",
	"object_egg_elevator_pillar_spawn2",
	"object_egg_elevator_pillar_spawn3",
	"object_egg_elevator_pillar_spawn4",
	"object_egg_elevator_pillar_spawn5",
	"object_egg_elevator_pillar_spawn6",
	"object_egg_elevator_pillar_spawn7",
	"object_egg_elevator_pillar_spawn8",
	"object_egg_elevator_pillar_spawn9",
}

function EggElevator:update(dt)
    if self.dead then
        self.dead_time = self.dead_time + dt
    end
	
	for i=#self.pillars, 1, -1 do
		local pillar = self.pillars[i]
        pillar.elapsed = pillar.elapsed + dt
	end

    self.floor_particles_to_remove = self.floor_particles_to_remove or {}
	table.clear(self.floor_particles_to_remove)
	for floor_particle in pairs(self.floor_particles) do
        floor_particle.elapsed = floor_particle.elapsed + dt
		floor_particle.t = floor_particle.elapsed / floor_particle.lifetime
		if floor_particle.elapsed > floor_particle.lifetime then
			self.floor_particles_to_remove[floor_particle] = true
		end
	end

	for floor_particle in pairs(self.floor_particles_to_remove) do
		self.floor_particles[floor_particle] = nil
	end

	if not self.dead and self.is_new_tick then
		if self.tick % 120 == 0 and self.tick > 1 and self.back then
			self:play_sfx("object_egg_elevator_moan", 0.5)
		end

		if self.tick % 32 == 0 and self.tick > 1 and self.back then
			self:play_sfx("object_egg_elevator_pulse", 0.7)
		end

		if self.tick > 5 and self.tick % 6 == 0 and not self.stop_rings and self.accepting_player then
			local ring = {
				t = 0.0,
				-- id = self.ring_id,
			}
			-- self.ring_id = self.ring_id + 1

			local s = self.sequencer
			table.insert(self.rings, ring)
			s:start(function()
				s:tween_property(ring, "t", 0, 1, RING_TIME, "linear")
				table.erase(self.rings, ring)
			end)
		end

		if self.back and ((not self:is_tick_timer_running("pillar_cooldown")) or #self.pillars == 0) and not self.stop_pillars then
			if rng:percent(90) then
				self:play_sfx(rng:choose(pillar_spawn_sfx), 0.23)
			end
			self:start_tick_timer("pillar_cooldown", rng:randi(5, 40))
			local start_offset_x, start_offset_y = rng:random_vec2_times(rng:randfn(rng:randf(-3, 3), 7))
			start_offset_y = start_offset_y * 0.65
			local pillar = {
				start_offset_x = start_offset_x,
				start_offset_y = start_offset_y,
				width = abs(rng:randfn(10, 6)),
				shine_x_offset = rng:randfn(0, 5),
				-- shine_angle_offset = rng:randfn(0, 0.1),
				t = 0.0,
				elapsed = 0.0,
				lifetime = rng:randi(90, 450),
				random_offset = rng:randi(),
				random_offset2 = rng:randi(),
			}
			table.insert(self.pillars, pillar)
			local s = self.sequencer
			s:start(function()
				s:tween_property(pillar, "t", 0, 1, pillar.lifetime, "linear")
				table.erase(self.pillars, pillar)
			end)
		end
	end
	
	local force_elevator = debug.enabled and debug.fast_forward
	-- local force_elevator = debug.enabled
    -- local force_elevator = false

	-- local force_no_elevator = not debug.enabled
	-- local force_no_elevator = true
	local force_no_elevator = false

    if not (force_no_elevator) and ((not self.back and not self.elevator_started) and ((not self.dead and self.tick > 20 and self.accepting_player) or force_elevator)) then
        local closest_player = self:get_closest_player()
        if closest_player and self.pos:distance_to(closest_player.pos) < 16 or force_elevator then
			self:ref("elevator_player", closest_player)
            self.intangible = true
			self:start_stopwatch("elevator_started")
			self.back_object:start_stopwatch("elevator_started")
			self.elevator_started = true
            self.elevator_player:change_state("Cutscene")
            local s = self.sequencer
            s:start(function()
				local x, y = self.elevator_player.pos.x, self.elevator_player.pos.y
                local tween_function = function(t)
					local pos_x, pos_y = vec2_lerp(x, y, self.pos.x, self.pos.y + 0.001, t)
					self.elevator_player:move_to(pos_x, pos_y)
				end
                s:tween(tween_function, 0, 1, 60, "linear")
                s:wait(10)

				self:play_sfx("object_egg_elevator_ascend", 0.45, 1, true)
				local tween_function2 = function(t)
					self.elevator_player:set_body_height(lerp(self.elevator_player.base_body_height, PILLAR_HEIGHT, t))
				end

				self.back_object.showing_shadow = false
                s:start(function()
                    s:wait(50)
					self.back_object.stop_rings =  true
					self.stop_rings = true
                    self.back_object.stop_pillars = true
					self:start_stopwatch("elevator_dissipate_started")
                    self.back_object:start_stopwatch("elevator_dissipate_started")
					s:wait(200)
					self:stop_sfx("object_egg_elevator_ascend")
                    self:queue_destroy()
					self.back_object:queue_destroy()
                    self:emit_signal("player_choice_made", "kill_egg", self.elevator_player)
					-- self.elevator_player:hide()
					-- self.elevator_player:set_body_height(self.elevator_player.base_body_height)
                    -- self.elevator_player:change_state("EggRoomStart")
					-- self.elevator_player:show()
					
                end)
                s:tween(tween_function2, 0, 1, 100, "inCubic")
					
                -- closest_player:change_state("Idle")
            end)
        end
    end
end

function EggElevator:floor_rect(r, g, b, fill, scale, time_mod)

	graphics.push("all")
    graphics.set_line_width(2)
	

	time_mod = time_mod or 1
	
    local scale_mod = scale + (ease("outCubic")(clamp01(self.dead_time / 30))) * 30
    local stopwatch = self:get_stopwatch("elevator_dissipate_started")
    if stopwatch then
        local t = stopwatch.elapsed * 0.01
		t = ease("inCubic")(clamp01(t))
		scale_mod = max(scale_mod * (1 - t), 0)
	end

    local left_x, top_y = -scale_mod / 2, -scale_mod / 2
    local right_x, bottom_y = scale_mod / 2, scale_mod / 2
	
	local x1, y1 = left_x, top_y
	local x2, y2 = right_x, top_y
	local x3, y3 = right_x, bottom_y
	local x4, y4 = left_x, bottom_y

	local angle = -self.elapsed / 100 * time_mod

	x1, y1 = vec2_rotated(x1, y1, angle)
	x2, y2 = vec2_rotated(x2, y2, angle)
	x3, y3 = vec2_rotated(x3, y3, angle)
	x4, y4 = vec2_rotated(x4, y4, angle)

	local ratio = 5 / 7

	y1 = y1 * ratio
	y2 = y2 * ratio
	y3 = y3 * ratio
	y4 = y4 * ratio

    -- local bx, by = self:get_body_center_local()
	
    -- graphics.translate(bx, by)
    local mod = 1 - ease("outCubic")(clamp01(self.dead_time / 30))
	if mod <= 0 then 
		graphics.pop()
		return
	end
	
    graphics.set_color(r * mod, g * mod, b * mod)
	
	graphics.polygon(fill, x1, y1, x2, y2, x3, y3, x4, y4)
	graphics.pop()
end

function EggElevator:draw()
    -- table.sort(self.rings, ring_sort)


    if self.back then
		local scale = lerp(1, ease("outCubic")(clamp01(self.elapsed / 60)), 1.0) * 46 + 4 * sin(self.elapsed / 40)
		local color = Palette.egg_elevator_floor:tick_color(self.elapsed, 0, 1)

        -- graphics.push("all")
        -- graphics.rotate(self.elapsed / 100)

        if gametime.tick % 2 == 0 then
            local fill = "line"
			local dead_time = self:get_stopwatch("elevator_dead_time")
			local flash_time = 10
            if dead_time and dead_time.elapsed < flash_time then
				fill = "fill"
			end
            self:floor_rect(color.r * 0.3, color.g * 0.3, color.b * 0.3, fill, scale * 3.5, 0.5)
            self:floor_rect(color.r * 0.6, color.g * 0.6, color.b * 0.6, fill, scale * 2.25, 0.75)
            self:floor_rect(color.r * 0.8, color.g * 0.8, color.b * 0.8, fill, scale * 1.5)
            self:floor_rect(color.r, color.g, color.b, "fill", scale)
        end
		
        if gametime.tick % 3 ~= 0 then
            local color2 = Color.white
			if self:is_timer_running("hurt_flash") then
				color2 = Palette.cmy:tick_color(self.elapsed, 0, 2)
			end

			if self.dead then
				color2 = Color.black
			end
			self:floor_rect(color2.r, color2.g, color2.b, "fill", scale * 0.9)
		end

		-- graphics.pop()
	end


    for i = #self.rings, 1, -1 do
		local ring = self.rings[i]
        local elapsed = ring.t * RING_TIME
        local tick = floor(elapsed)
		local color = Palette.egg_elevator_ring:tick_color(tick + self.elapsed * 1.2, 0, 2)
        -- if self:is_timer_running("hurt_flash") or self.dead then
			-- color = Palette.cmyk:tick_color(elapsed * 2, 0, 2)
        -- end
        local r, g, b = color.r, color.g, color.b
        local mod = clamp01(elapsed / 30 - self.dead_time * 0.5)
        graphics.set_color(r * mod, g * mod, b * mod)



        local t = ring.t

        local y = -t * RING_HEIGHT

        local scale = 1 + ((1 - t) ^ 4) * 1.35 + (1 + sin(t * 40 - self.elapsed * 0.1) * 0.45)

        local extra = (1 - clamp01(elapsed / 50)) ^ 3 * 55 + (clamp01(self.dead_time / 30) ^ 0.5) * 300.0 * clamp01(elapsed / 90) + 4 * sin(self.elapsed / 40)

        local width = 18 * scale + extra
        local height = width * 2 / 3

		-- local line_width = ceil(clamp(elapsed / 120, 1, 5))
		local line_width = 2

        local x1 = round(-width / 2)
        local y1 = round(-height / 2 + y)
        local x2 = round(width / 2)
        local y2 = round(height / 2 + y)
        local ymid = round((y1 + y2) / 2)

		graphics.push("all")
		graphics.set_line_width(line_width)

        if (mod > 0) and (r > 0 or g > 0 or b > 0) then
            if self.back then
                graphics.line(x1 - line_width / 2, y1, x2 + line_width / 2, y1)
                graphics.line(x1, y1, x1, ymid)
                graphics.line(x2, y1, x2, ymid)
            else
                graphics.line(x1, ymid, x1, y2)
                graphics.line(x2, ymid, x2, y2)
                graphics.line(x1 - line_width / 2, y2, x2 + line_width / 2, y2)
            end
        end
		graphics.pop()
    end
	

    if not self.dead then
        for i = #self.pillars, 1, -1 do
            local pillar = self.pillars[i]
            if floor(pillar.elapsed + pillar.random_offset) % (pillar.random_offset2 % 2 + 2) == 0 then
                goto continue
            end

            local t = pillar.t
            local x1, y1 = pillar.start_offset_x, pillar.start_offset_y
            -- local theta = angle_diff(-tau / 4, vec2_angle_to(x1, y1, 0, -PILLAR_HEIGHT))



            local x2, y2 = 0, -PILLAR_HEIGHT

            local width = lerp(pillar.width, pillar.width * math.bump(t), 0.9)

			local stopwatch = self:get_stopwatch("elevator_dissipate_started")

			if stopwatch then
				local t2 = stopwatch.elapsed * 0.01
				t2 = ease("inCubic")(clamp01(t2))
				width = width * (1 - t2)
			end
		

            local height_ratio = ease("outSine")(t)
            local color = Palette.egg_elevator_pillar_back:tick_color(pillar.elapsed + pillar.random_offset, 0, 2)
            if self:is_timer_running("hurt_flash") or self.dead then
                color = Palette.cmy:tick_color(pillar.elapsed + pillar.random_offset, 0, 2)
            end
            -- graphics.push("all")
            graphics.set_color(color)
            -- graphics.rectangle_centered("fill", x1, y1, max(width * 1.4, 9), 10 * (1 - t))
            -- graphics.translate(lerp(x1, x2, 0.5), lerp(y1, y2, 0.5))
            -- graphics.rotate(theta)
            graphics.push("all")
            -- graphics.translate(x1, y1)
            -- graphics.rotate(angle_diff(-tau / 4, vec2_angle_to(x1, y1, 0, -PILLAR_HEIGHT)))
            graphics.set_line_width(width)
            graphics.line(x1, y1, vec2_lerp(x1, y1, x2, y2, height_ratio))
            graphics.pop()
            -- graphics.set_color(Palette.egg_elevator_pillar_front:tick_color(pillar.elapsed + pillar.random_offset2, 0, 2))

            -- graphics.set_line_width(width * 0.35)
            -- local shine_x1, shine_x2 = x1 + pillar.shine_x_offset * (1 - t), x2 + pillar.shine_x_offset * (1 - t)
            -- graphics.line(shine_x1, y1, vec2_lerp(shine_x1, y1, shine_x2, y2, height_ratio))

            ::continue::
        end

        if self.back and self.accepting_player then
            if iflicker(self.tick, 1, 2) and self.tick > 5 then
                graphics.set_color(Color.black)

                -- local bx, by = self:get_body_center_local()
                local size = max(7 + min(-7 + self.elapsed * 0.2, 0), 1)
                -- graphics.set_color(color)
                graphics.set_line_width(1)
                -- if almost_dead then
                -- end
                graphics.rectangle_centered("line", 0, 0, size, size * 0.75)
                graphics.rectangle_centered("line", 0, 0, size + 4, size * 0.75 + 4)
                -- graphics.pop()
            end
            if self.tick % 3 ~= 0 and self.showing_shadow then
                graphics.set_color(Color.white)
                graphics.drawp_centered(textures.object_egg_elevator_hole, nil, 0, self:get_body_center_local())
            end
        end
    end

end

function EggElevator:hit_by(bubble)
    if not self:is_tick_timer_running("hit_cooldown") then
        self:damage(1)
        self:start_tick_timer("hit_cooldown", 2)
    end
end

function EggElevator:on_damaged(amount)
    self:start_timer("hurt_flash", 10)
	self:play_sfx("object_egg_elevator_hurt", 0.7)
	if self.hp <= self.max_hp - 10 then
        if not self.accepting_player then
            input.start_rumble(function(t)
                return 0.35 * (1 - t)
            end, 10)
			self:on_door_opened()
		end
	end
	if self.back_object then 
		self.back_object:on_damaged(amount)
	end
end

function EggElevator:on_door_opened()
	self.accepting_player = true
	if self.back_object then
		self.back_object.accepting_player = true
	end
	self:play_sfx("object_egg_elevator_door_open", 1)
end


function EggElevator:on_health_reached_zero()
	self:die()
end

function EggElevator:die(killed)

    input.start_rumble(function(t)
        return 0.4 * (1 - t)
    end, 15)

    if killed == nil then
        killed = true
	end

	self.intangible = true
	local s = self.sequencer
    self.dead = true
    if self.back_object then
        self.back_object:die(killed)
		if killed then
			self:play_sfx("object_egg_elevator_die", 1.0)
		end
    end
	self:stop_sfx("object_egg_elevator_moan")
	self:stop_sfx("object_egg_elevator_pulse")
	self:start_stopwatch("elevator_dead_time")
	
    s:start(function()
        if killed and not self.back then
			local closest_player = self:get_closest_player()
			while not closest_player do
				s:wait(1)
				closest_player = self:get_closest_player()
			end
			self:emit_signal("player_choice_made", "kill_elevator", closest_player)
            -- self:spawn_object(XpPickup(self.pos.x, self.pos.y, XP_AMOUNT))
        end

		-- s:wait(1)
		-- self.world:soft_room_clear()

        while self.rings[1] do
            s:wait(1)
        end
        while self.pillars[1] do
            s:wait(1)
        end
		
        self:queue_destroy()

    end)
end
function EggElevator:exit()
	self:stop_sfx("object_egg_elevator_moan")
	self:stop_sfx("object_egg_elevator_pulse")
	self:stop_sfx("object_egg_elevator_ascend")
end

return EggElevator
