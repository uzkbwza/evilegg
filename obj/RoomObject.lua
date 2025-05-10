local RoomObject = GameObject2D:extend("RoomObject")
local RoomFloorObject = GameObject2D:extend("RoomFloorObject")

local PLAYER_DISTANCE = 16
local LINE_HEIGHT = 8
local ICON_SIZE = 12
local LINE_TIME = 2

local RECT_LINE_WIDTH = 1
local RECT_WIDTH = 55
local EGG_ROOM_WIDTH = 41
local PADDING = 1

function RoomObject:new(x, y, room)
    self.direction = Vec2(0, 0)
    RoomObject.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
	self.random_offset = rng(0, tau)
    self.stored_room = room
    self:add_signal("room_chosen")
    self:add_elapsed_ticks()
    self.lines = {}
	self:add_sequencer()
	self.die_alpha = 1
	self.max_height = 0
	
    self.z_index = 1
    self.icon_stencil_function = function()
        graphics.circle("fill", 0, 0, PLAYER_DISTANCE)
    end
	
	self.font = fonts.depalettized.image_font1
    self.all_shown = false
end
function RoomObject:add_line(line_type, line_data, line_height, separator)
    if separator == nil then separator = true end
    if separator then
		self:add_separator()
	end
    table.insert(self.lines, { type = line_type, data = line_data, height = line_height or LINE_HEIGHT, t = 0 })
	self.sequencer:wait(LINE_TIME)
end

function RoomObject:add_separator()
	if not table.is_empty(self.lines) then
		table.insert(self.lines, { type = "separator", data = nil, height = 5, t = 0 })
		self.sequencer:wait(LINE_TIME)
	end
end

function RoomObject:add_spawn_lines(tab, sort_func)
	local current_icons = {}
	local current_icon = 0
	local icons_per_line = floor(RECT_WIDTH / (ICON_SIZE + 2) + 1)
    local counter = 0

	local sorted_tab = {}

    for spawn, count in pairs(tab) do
		-- print(spawn, count)
		table.insert(sorted_tab, { spawn = spawn, count = count.count })
	end
    if sort_func then
        table.sort(sorted_tab, sort_func)
    end
	
	local table_length = 0
	for _, data in ipairs(sorted_tab) do
		local count = data.count
        local num_entries = 1
        if data.spawn.subtype == "powerup" then
            num_entries = count
        end
		if type(num_entries) ~= "number" then
			print(num_entries)
		end
		table_length = table_length + num_entries
	end

    for _, data in ipairs(sorted_tab) do
        local spawn = data.spawn
        local count = data.count
        local num_entries = 1
		if data.spawn.subtype == "powerup" then 
			num_entries = count
		end
		for i=1, num_entries do

			-- local icon = spawn.icon
			local icon = graphics.depalettized[spawn.icon]
			-- print(spawn.name)
			local width, height = graphics.texture_data[icon]:getDimensions()
            local middle_x, middle_y = floor(width / 2), floor(height / 2)
			local icon_width = min(ICON_SIZE, width)
			local icon_height = min(ICON_SIZE, height)
			local icon_quad = graphics.new_quad(middle_x - icon_width / 2, middle_y - icon_height / 2, icon_width, icon_height, width, height)
			table.insert(current_icons, graphics.get_quad_table(icon, icon_quad, icon_width, icon_height))
			current_icon = current_icon + 1
			counter = counter + 1

			if current_icon >= icons_per_line or counter >= table_length then
				local line_data = {
					spawn = spawn,
					count = count,
					icons = current_icons,
				}
				self:add_line("spawn_count", line_data, ICON_SIZE + 2, false)
				current_icons = {}
				current_icon = 0
			end
			-- ::continue::
		end
	end
end

function RoomObject:enter()
    self:add_tag("room_object")
	
    local s = self.sequencer
	self:play_sfx("room_object_spawn", 0.65)


    s:start(function()

        if self.stored_room.is_egg_room then
			self:add_big_egg()
			return
		end

        -- self:add_spawn_lines(self.stored_room.all_spawn_types)

        -- self:add_line("text", "ENEMIES")

        if self.points_rating == 1 then
            -- do nothing
        elseif self.points_rating == 2 then
            -- self:add_separator()
            -- self:add_line("text", "SCORE+")
        elseif self.points_rating == 3 then
            self:add_line("text", tr.room_has_max_points)
        end

        -- if self.stored_room.bonus_room then
        --     self:add_line("text", tr.room_is_bonus)
        -- end

        if self.stored_room.is_hard then
            self:add_line("text", tr.room_is_hard)
        end

        self:add_separator()


        local priority = {
            "hazard",
            "enemy",
            "rescue",
            "artefact",
            "upgrade",
            "heart",
            "powerup",
        }

        local priority_map = {
        }
        for i, priority_type in pairs(priority) do
            priority_map[priority_type] = i
        end

        local sort_func = function(a, b)
            local a_type = a.spawn.subtype or a.spawn.type
            local b_type = b.spawn.subtype or b.spawn.type
            local a_priority = priority_map[a_type] or math.huge
            local b_priority = priority_map[b_type] or math.huge
			if a_priority == b_priority then
				if a.spawn.level and b.spawn.level then
					return a.spawn.level < b.spawn.level
				end
            end
            return a_priority < b_priority
        end

        self:play_sfx("room_object_tick", 0.35)

        self:add_spawn_lines(table.filtered_keys(self.stored_room.all_spawn_types, function(spawn)
            return spawn.type and (spawn.type == "enemy" or spawn.type == "hazard")
        end), sort_func)

        self:add_separator()

        -- self:add_spawn_lines(table.filtered_keys(self.stored_room.all_spawn_types, function(spawn)
        -- 	return spawn.type == "rescue"
        -- end), sort_func)

        self:add_spawn_lines(table.filtered_keys(self.stored_room.all_spawn_types, function(spawn)
            return spawn.type and (spawn.type == "rescue" or spawn.type == "pickup")
        end), sort_func)
        -- self:add_spawn_lines(table.filtered_keys(self.stored_room.all_spawn_types, function(spawn)
        -- 	return spawn.type == "enemy"
        -- end))
        -- -- self:add_line("text", "HAZARDS")
        -- self:add_spawn_lines(table.filtered_keys(self.stored_room.all_spawn_types, function(spawn)
        -- 	return spawn.type == "hazard"
        -- end))

        -- self:add_spawn_lines(table.filtered_keys(self.stored_room.all_spawn_types, function(spawn)
        -- 	return spawn.type == "rescue"
        -- end))

        -- self:add_spawn_lines(table.filtered_keys(self.stored_room.all_spawn_types, function(spawn)
        -- 	return spawn.type == "rescue" or spawn.type == "pickup"
        -- end))

        -- self:add_spawn_lines(table.filtered_keys(self.stored_room.all_spawn_types, function(spawn)
        -- 	return spawn.subtype == "heart"
        -- end))

        -- self:add_spawn_lines(table.filtered_keys(self.stored_room.all_spawn_types, function(spawn)
        -- 	return spawn.subtype == "upgrade"
        -- end))

        -- self:add_spawn_lines(table.filtered_keys(self.stored_room.all_spawn_types, function(spawn)
        -- 	return spawn.subtype == "artefact"
        -- end))
    end)
    local floor_object = self:spawn_object(RoomFloorObject(self.pos.x, self.pos.y))
    floor_object.direction = self.direction
	self:ref("floor_object", floor_object)
    self:bind_destruction(floor_object)
end

function RoomObject:add_big_egg()
	self:add_line("big_egg", nil, 54 + PADDING, false)
end

function RoomObject:close_animation()
	local s = self.world.sequencer
	s:start(function()
        for i = #self.lines, 1, -1 do
			s:wait(LINE_TIME * 4)
			if self then
            	self.lines[i] = nil
            else
				return
			end
		end
	end)
end

function RoomObject:update(dt)
	-- print(self.die_alpha)


    RoomObject.super.update(self, dt)
	
    self.max_height = self.max_height + dt * 10
	
	for _, line in pairs(self.lines) do
        line.t = min(line.t + dt)
    end
	-- if self.dead then
	-- 	return
	-- end
	local player = self:get_closest_player()
    if player and self.tick > 10 then
        local bx, by = self.pos.x, self.pos.y
        local pbx, pby = player:get_body_center()
		local start_x, start_y = self.pos.x + self.direction.y * PLAYER_DISTANCE, self.pos.y + self.direction.x * PLAYER_DISTANCE
		local end_x, end_y = self.pos.x - self.direction.y * PLAYER_DISTANCE, self.pos.y - self.direction.x * PLAYER_DISTANCE
		if capsule_contains_point(start_x, start_y, end_x, end_y, 5, pbx, pby) then
            self:emit_signal("room_chosen")
		end
    end

end

function RoomObject:die()
	self.dead = true
	self.die_time = self.world.elapsed
    self:close_animation()

end

function RoomObject:draw()
    self.die_alpha = self.dead and (max(1 - (self.world.elapsed - self.die_time) / 5, 0)) or 1
		
    if self.floor_object then
        self.floor_object.die_alpha = self.die_alpha
    end
	
    graphics.set_font(self.font)
	graphics.set_color(self.die_alpha, self.die_alpha, self.die_alpha, 1)
    -- self:body_translate()
    -- RoomObject.super.draw(self)
	local total_height = 0
    for _, line in pairs(self.lines) do
        total_height = total_height + line.height
    end
	
    local offset_x, offset_y = cos(self.random_offset + self.elapsed * 0.02), sin(self.random_offset + self.elapsed * 0.02)
	offset_x = floor(offset_x * 3)
	offset_y = floor(offset_y * 3)

	local rect_width = RECT_WIDTH + RECT_LINE_WIDTH * 2 + PADDING * 2
    local rect_height = min(total_height, self.max_height) + PADDING * 2

	if self.stored_room.is_egg_room then
		rect_width = EGG_ROOM_WIDTH + RECT_LINE_WIDTH * 2 + PADDING * 2
	end

    -- if self.direction.x == 1 then
	-- 	graphics.translate(1, 0)
	-- end

	-- if self.direction.y == 1 then
	-- 	graphics.translate(0, 1)
	-- end

	
    local rect_offset_x, rect_offset_y = vec2_rotated(-self.direction.x, -self.direction.y, -tau / 4)
	rect_offset_x = rect_offset_x * (rect_width - 5)
	rect_offset_y = clamp(rect_offset_y * (rect_height / 2 + 24), -self.stored_room.room_height / 2 + rect_height / 2, self.stored_room.room_height / 2 - rect_height / 2)
    local diag_offset_x, diag_offset_y = vec2_rotated(-self.direction.x, -self.direction.y, -tau / 16)
	diag_offset_x = diag_offset_x * (13)
    diag_offset_y = diag_offset_y * (13)
	
	local rect_x, rect_y = offset_x + rect_offset_x + diag_offset_x, offset_y + rect_offset_y + diag_offset_y

	local top, left = self:to_local(self.world.room.top, self.world.room.left)
    local bottom, right = self:to_local(self.world.room.bottom, self.world.room.right)


	local line_length = 32 * clamp(self.tick / 10, 0, 1)

    if idivmod_eq_zero(self.tick, 3, 2) then
        if self.direction.x ~= 0 then
			local start_x, start_y = 0, line_length * self.direction.x * 0.5
            start_y = start_y - sign(start_y) * 2
			start_x = start_x - sign(self.direction.x) * 5
			graphics.line(start_x, start_y, rect_x, start_y)
			graphics.points(rect_x, start_y)
			graphics.line(rect_x, start_y, rect_x, rect_y)
			graphics.rectangle("fill", start_x - 2, start_y - 2, 4, 4)
        else
            local start_x, start_y = -line_length * self.direction.y * 0.5, 0
            start_x = start_x - sign(start_x) * 2
			start_y = start_y - sign(self.direction.y) * 5
            graphics.line(start_x, start_y, start_x, rect_y)
			graphics.points(start_x, rect_y)
			graphics.line(start_x, rect_y, rect_x, rect_y)
			graphics.rectangle("fill", start_x - 2, start_y - 2, 4, 4)

		end
	end
	

	if self.tick % 2 == 0 then
		graphics.set_color(self.die_alpha, self.die_alpha, self.die_alpha, 1)
		graphics.push("all")
		local line_width = max(min(2, -1 + self.tick / 2), 0)
		graphics.set_line_width(line_width)
		graphics.rotate(self.direction:angle() + tau / 4)

		graphics.line(-line_length / 2, line_width / 2, line_length / 2, line_width / 2)
		graphics.pop()
	end

    if abs(self.direction.x) == 1 then
        if self.direction.x == 1 then
            graphics.translate(-rect_width, 0)
        end
        graphics.translate(0, floor(-rect_height / 2))
    elseif abs(self.direction.y) == 1 then
        if self.direction.y == 1 then
            graphics.translate(0, -rect_height)
        end
        graphics.translate(-floor(rect_width / 2), 0)
    end


	graphics.translate(rect_x, rect_y)


	if #self.lines == 0 then return end
	
	if gametime.tick % 2 == 0 then 
    	graphics.set_color(0, 0, 0, 1)
		graphics.rectangle("fill", 0, 0, rect_width, rect_height)
	end
    graphics.set_color(self.die_alpha, self.die_alpha, self.die_alpha, 1)
	

    graphics.rectangle("line", 0, 0, rect_width, rect_height)
	graphics.translate(RECT_LINE_WIDTH + PADDING, RECT_LINE_WIDTH + PADDING)

	local y = 0
    for _, line in pairs(self.lines) do
		self:draw_line(line, y)
		y = y + line.height
	end
end

-- function RoomObject:floor_draw()
-- 	self:draw()
-- end

function RoomObject:draw_line(line, y)
	if self.max_height < y + line.height then
		return
	end

	local die_alpha = self.die_alpha or 1
    graphics.set_color(die_alpha, die_alpha, die_alpha, 1)
    if line.type == "text" then
        local text = line.data

        graphics.print(string.sub(text, 1, floor(line.t / 1)), 0, y, 0, 1, 1, 0, 0)
    elseif line.type == "spawn_count" then
        -- graphics.draw(textures.enemy_base, 0, y, 0, 1, 1, 0, 0)
        for i, icon in pairs(line.data.icons) do
            if i < floor(line.t / 1) then
                graphics.draw_centered(icon, (i - 1) * (ICON_SIZE + 2) + ICON_SIZE / 2, y + ICON_SIZE / 2, 0, 1, 1, 0, 0)
            end
        end
    elseif line.type == "separator" then
        graphics.set_color(Color.darkergrey * die_alpha)
        local y_ = y + floor(line.height / 2)
        graphics.line(4, y_, RECT_WIDTH - 4, y_)
	elseif line.type == "big_egg" then
		graphics.push()
		graphics.translate(- RECT_LINE_WIDTH / 2, 0)
        graphics.draw(textures.hud_room_egg, 0, y, 0, 1, 1, 0, 0)
		graphics.pop()
	end
end

local MAX_PARTICLE_DISTANCE = 125
local PARTICLE_FIELD_WIDTH = PLAYER_DISTANCE

function RoomFloorObject:new(x, y)
	RoomFloorObject.super.new(self, x, y)
    self.particles = {}
    self.z_index = 0.5
	self:add_time_stuff()
end

function RoomFloorObject:update(dt)
	if self.is_new_tick then
        local num_particles = max(floor(abs(rng.randfn(0, 1.6))), 1 - self.tick)
		if num_particles > 0 then
			for i=1, num_particles do 
				local s = self.sequencer
				s:start(function()
					local particle = {}
					particle.distance = clamp(rng.randfn(MAX_PARTICLE_DISTANCE / 2, MAX_PARTICLE_DISTANCE / 4), 20, MAX_PARTICLE_DISTANCE)
					particle.size = max(rng.randfn(6.0, 1.5), 0.5)
					particle.brightness = max(rng.randfn(0.25, 0.15), 0.05)
					-- particle.rotated = rng.percent(50)
					particle.t = 0
					particle.offset = clamp(rng.randfn(0, PARTICLE_FIELD_WIDTH / 4), -PARTICLE_FIELD_WIDTH, PARTICLE_FIELD_WIDTH)
					local centered_ratio = pow(1 - abs(particle.offset) / (PARTICLE_FIELD_WIDTH), 2)
					particle.distance = particle.distance * clamp(remap_lower(pow(centered_ratio, 1.25), 0, 1, 0.25), 0.25, 1)
					particle.size = particle.size * remap_lower(centered_ratio, 0, 1, 0.5)
					self.particles[particle] = true
					s:tween_property(particle, "t", 0.0, 1, min(max(rng.randfn(200, 20) * particle.distance / MAX_PARTICLE_DISTANCE, 10), 300), "inCubic")
					self.particles[particle] = nil
				end)
			end
		end
	end
end


function RoomFloorObject:floor_draw()
	self:draw_particles(true)
end

function RoomFloorObject:draw()
    self:draw_particles()
end

function RoomFloorObject:draw_particles(is_floor)
	local die_alpha = self.die_alpha or 1

    for particle in pairs(self.particles) do
        if is_floor then
			if (not self.is_new_tick) or rng.percent(80) then
				goto continue
			end
		end
        local size = particle.size * (particle.t)
        local dist = remap(particle.distance * (1 - particle.t), 0, particle.distance, particle.size, particle.distance)
		local brightness = 1.0 * die_alpha
        if is_floor then
            brightness = particle.brightness * (particle.t)
        end
        graphics.set_color(brightness, brightness, brightness, 1)
        local offset_angle = remap_clamp(particle.offset, -PARTICLE_FIELD_WIDTH, PARTICLE_FIELD_WIDTH, -tau / 4, tau / 4)
		-- offset_angle = offset_angle * abs(pow(particle.offset / PARTICLE_FIELD_WIDTH, 2))
        local local_vector_x, local_vector_y = vec2_rotated(dist, 0, offset_angle)
		local_vector_y = local_vector_y + particle.offset
		
        local pos_x, pos_y = vec2_rotated(local_vector_x, local_vector_y,
        vec2_angle(-self.direction.x, -self.direction.y))
        if size >= 1 then
			graphics.push("all")
            graphics.translate(pos_x, pos_y)
			-- if particle.rotated then
			-- 	graphics.rotate(tau / 8)
			-- end
            graphics.rectangle((is_floor and (rng.percent(50) and "line" or "fill")) or "fill", -size * 0.5, -size * 0.5, size, size)
			graphics.pop()
        elseif size >= 0.5 then
            graphics.points(pos_x, pos_y)
			
		end
		
		::continue::
	end
end



return RoomObject
