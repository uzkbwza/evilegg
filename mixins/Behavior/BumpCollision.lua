local BumpCollision = Object:extend("BumpCollision")
local BumpSensor = require("obj.bump_sensor")

function BumpCollision.default_bump_filter(item, other)
	if other and other.solid then
		return "slide"
	else 
		return "cross"
	end
end

local default_bump_info = {
	solid = false,
	filter = BumpCollision.default_bump_filter,
    track_overlaps = false,
	bump_frozen = false,
	-- collide_with_slopes = true,
}

function BumpCollision:collide_unmoving()
	if self.bump_frozen then return end
	self:move(0, 0)
end

function BumpCollision:__mix_init()
    -- initializes bump.lua physics with AABB collisions and spatial hashing. useful even for non-physics objects for collision detection for e.g. coins
    self:implement(Mixins.Behavior.CollisionRect)
	self:implement(Mixins.Behavior.BumpLayerMask)
    if self.tracks_overlaps == nil then
        self.tracks_overlaps = default_bump_info.track_overlaps
    end


    if self.solid == nil then
        self.solid = default_bump_info.solid
    end

    if self.bump_filter == nil then
        self.bump_filter = default_bump_info.filter
    end

	if self.bump_frozen == nil then
		self.bump_frozen = default_bump_info.bump_frozen
	end

    -- TODO: position centered on feet?



    if self.tracks_overlaps then
        self.overlaps = {}
        self:add_update_function(self.bump_track_overlaps)
    end

	self:add_update_function(self.collide_unmoving)

	-- self:add_update_function(self.bump_world_update)

    self.is_bump_object = true
    self.move_to = BumpCollision.move_to_bump
    self.bump_filter_checks = {}
    self.bump_world = nil
    self.colliding_objects = {}
    self.collision_rect_update_functions = self.collision_rect_update_functions or {}
    table.insert(self.collision_rect_update_functions, function()
        if self.bump_world then
			local offset_x, offset_y = self.collision_offset.x, self.collision_offset.y
			local width, height = self.collision_rect.width, self.collision_rect.height
			self.bump_world:update(self, self.pos.x + offset_x, self.pos.y + offset_y, width, height)
		end
	end)
end

function BumpCollision:bump_track_overlaps()
	local cr = self.collision_rect

	local overlaps = {}

	local query = self.bump_world:queryRect(self.pos.x + cr.x, self.pos.y + cr.y, cr.width, cr.height, self.bump_filter, self.bump_mask)
	
	for _, other in ipairs(query) do
		if other == self then
			goto continue
		end
		if other and not (other.solid) then
			if self.overlaps[other] == nil then
				self:object_entered_rect_shared(other)
			end
			overlaps[other] = true
		end
		::continue::
	end

	for k, _ in pairs(self.overlaps) do 
		if not overlaps[k] then 
			self:object_exited_rect_shared(k)
		end
	end

	self.overlaps = overlaps
end

function BumpCollision:bump_world_update()
    if self.bump_world then
        local offset_x, offset_y = self:get_collision_rect_offset()
        self.bump_world[self.bump_world:hasItem(self) and "update" or "add"](self.bump_world,
            self,
            self.pos.x + offset_x,
            self.pos.y + offset_y,
            self.collision_rect.width,
            self.collision_rect.height,
            self.bump_layer,
            self.bump_mask
        )
    end
end


function BumpCollision:set_bump_world(world)
    if self.bump_world then
        if self.bump_world:hasItem(self) then
            self.bump_world:remove(self)
        end
    end
    self.bump_world = world
	self:bump_world_update()

    if self.bump_sensors then
        for _, sensor in ipairs(self.bump_sensors) do
            sensor:set_bump_world(world)
        end
    end
end

function BumpCollision:move_to_bump(x, y, filter, noclip)
	y = y or self.pos.y
    local old_x = self.pos.x
    local old_y = self.pos.y

    local offset_x, offset_y = self:get_collision_rect_offset()

    if noclip or self.noclip then
        self.pos.x = x
        self.pos.y = y
        if old_x ~= self.pos.x or old_y ~= self.pos.y then
            if self.bump_world then
                self.bump_world:update(self, x + offset_x, y + offset_y)
            end
            self:on_moved()
        end
        return
    end

    filter = filter or self.bump_filter

    local actual_x, actual_y, collisions, num_collisions = self.bump_world:move(self, x + offset_x, y + offset_y, filter)

    self.pos.x = actual_x - offset_x
    self.pos.y = actual_y - offset_y

    for i = 1, num_collisions do
        local col = collisions[i]
        if col.slide then
			if self.slide_functions then
				for _, func in ipairs(self.slide_functions) do
					func(self, col)
				end
			end	
        end
		self:process_collision(col)
    end

    if old_x ~= self.pos.x or old_y ~= self.pos.y then
        self:on_moved()
    end
end

---@param config table<string, any>
---@return BumpSensor
function BumpCollision:add_bump_sensor(config)
	local sensor = BumpSensor(self, config)
	if self.bump_sensors == nil then
		self.bump_sensors = {}
		self:add_update_function(BumpCollision.update_bump_sensors)
		self:add_move_function(BumpCollision.move_bump_sensors)
	end

	table.insert(self.bump_sensors, sensor)
	return sensor
end

function BumpCollision:update_bump_sensors(dt)
	for _, sensor in ipairs(self.bump_sensors) do
		sensor:update(dt)
	end
end

function BumpCollision:move_bump_sensors()
	for _, sensor in ipairs(self.bump_sensors) do
		if not sensor.static then
			sensor:move_to(self.pos.x, self.pos.y)
			-- return
		end
	end
end

function BumpCollision:bump_check(dx, dy, filter)
    local offset_x, offset_y = self:get_collision_rect_offset()

    filter = filter or self.bump_filter

    local actual_x, actual_y, collisions, num_collisions = self.bump_world:check(self, self.pos.x + dx + offset_x,
        self.pos.y + dy + offset_y, filter)

    return collisions, num_collisions, actual_x, actual_y
end


function BumpCollision:get_overlapping_bump_objects_in_rect(rect, object_filter)
	local objects = {}
	rect = rect + self.pos
	local query = self.bump_world:queryRect(rect.x, rect.y, rect.width, rect.height, object_filter, self.bump_mask)
	for i, v in ipairs(query) do
		if not v.collision_rect and not v.pos then goto continue end
			if rect:intersects(v.collision_rect + v.pos) then
				table.insert(objects, v)
			end
		::continue::
	end
	return objects
end

function BumpCollision:get_closest_overlapping_bump_object(rect, object_filter)
	local closest = nil
	local closest_dist = math.huge

	if rect ~= nil then
		rect = rect + self.pos
		local query = self.bump_world:queryRect(rect.x, rect.y, rect.width, rect.height, object_filter, self.bump_mask)
		for i, v in ipairs(query) do
			if not v.collision_rect and not v.pos then goto continue end
				if rect:intersects(v.collision_rect + v.pos) then
					if v ~= self and self.pos:distance_squared(v.pos) < closest_dist then
						closest = v
						closest_dist = self.pos:distance_squared(v.pos)
					end
				end
			::continue::
		end
		return closest
	end

	for k, _ in pairs(self.overlaps) do
		if self.pos:distance_squared(k.pos) < closest_dist then
			closest = k
			closest_dist = self.pos:distance_squared(k.pos)
		end
	end
	return closest
end


return BumpCollision
