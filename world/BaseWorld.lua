local Camera = require "obj.camera"
local bump = require "lib.bump"
local GameMap = require "map.GameMap"

local SkipList = require "datastructure.skiplist"

local DEFAULT_CELL_SIZE = tilesets.TILE_SIZE * 2

-- represents an area of the game where objects can exist in space and interact with each other
local World = GameObject2D:extend("World")

-- Helper functions
local function add_to_table(array, obj)
	array:push(obj)
end

local function remove_from_array(array, obj)
	array:remove(obj)

end

function World:new(x, y)
    World.super.new(self, x, y)


	self.id_counter = 0x00000000
	self.id_to_object = setmetatable({}, { __mode = "v" })
	function GameObject:get_object(id)
		return self.id_to_object[id]
	end

    self.world = self

    self.objects = bonglewunch()

    self.update_objects = bonglewunch()
	
    self.draw_objects = bonglewunch()
	
	self.world_objects_to_destroy = {}

    self.time_scale = 1
	self.object_time_scale = 1

    self.bump_world = nil
    self.processing = true
	if self.center_camera == nil then
		self.center_camera = true
	end

    -- self.draw_sort = nil

    self.world_sfx = bonglewunch()
    self.sfx_polyphony = {}
    self.sfx_sources_playing = {}


    self.follow_camera = true
    self.input = input.dummy

	-- self.sorted_draw_objects = SkipList(self.draw_sort or function() return true end, 300)

    self:add_sequencer()
    self:add_elapsed_ticks()
	
end


function World:new_object_id()
    local id = self.id_counter
    -- GameObject.id_counter = bit.tobit(bit.band(GameObject.id_counter + 1, 0x0fffffff))
    self.id_counter = bit.tobit(self.id_counter + 1)
    return id
end

function World:init_camera()
    self:ref("camera", self:add_object(Camera()))
	self.camera_offset = Vec2()
	return self.camera
end

function World.z_sort(a, b)
	return (a.z_index or 0) < (b.z_index or 0)
end

function World.y_sort(a, b)
	local az = a.z_index or 0
	local bz = b.z_index or 0

	if az < bz then
        return true
	elseif az > bz then
		return false
	end

	local avalue = a.pos.y + az
	local bvalue = b.pos.y + bz
	if avalue == bvalue then
		return a.pos.x < b.pos.x
	end
	return avalue < bvalue
end

function World:create_bump_world(cell_size)
	cell_size = cell_size or DEFAULT_CELL_SIZE
	self.bump_world = bump.newWorld(cell_size)
end

function World:get_update_objects()
	self.frame_update_objects = self.frame_update_objects or {}
	table.clear(self.frame_update_objects)
	for _, obj in ((self.update_objects):ipairs()) do
		table.insert(self.frame_update_objects, obj)
	end
	return self.frame_update_objects
end

function World:update_shared(dt)
	dt = dt * self.time_scale
	-- audio.set_position(self.camera.pos.x, self.camera.pos.y, self.camera.z_index)

	local update_objects = self:get_update_objects()

	if self.update_sort then
		table.sort(update_objects, self.update_sort)
	end

    for _, obj in ipairs(update_objects) do
		obj:update_shared(dt * self.object_time_scale)
	end

	for _, src in (self.world_sfx:ipairs()) do
        if (not src) or (not src.isPlaying) or (not src:isPlaying()) then
            self.world_sfx:remove(src)
			if src.release then
				src:release()
			end
		end
	end

    if self.deferred_functions then
        for _, t in ipairs(self.deferred_functions) do
            local func, args = table.fast_unpack(t)
            func(args and table.fast_unpack(args) or nil)
        end
        table.clear(self.deferred_functions)
    end
	
    for _, obj in ipairs(self.world_objects_to_destroy) do
		if not obj.is_destroyed then
			obj:destroy()
		end
	end
	table.clear(self.world_objects_to_destroy)

	World.super.update_shared(self, dt)
end

function World:update(dt)
end

function World:add_tag(object, tag)
    self.tags = self.tags or {}
    self.tags[tag] = self.tags[tag] or bonglewunch()
	if not self:has_tag(object, tag) then
		self.tags[tag]:push(object)
		signal.connect(object, "destroyed", self, "remove_tag_" .. tag, function()
			self:remove_tag(object, tag)
		end)
	end
end

function World:has_tag(object, tag)
    if self.tags and self.tags[tag] then
        return self.tags[tag]:has(object)
    end
    return false
end

function World:remove_tag(object, tag)
    if self.tags and self.tags[tag] then
        self.tags[tag]:remove(object)
    end
	if signal.is_connected(object, "destroyed", self, "remove_tag_" .. tag) then
		signal.disconnect(object, "destroyed", self, "remove_tag_" .. tag)
	end
end

---@return bonglewunch?

local dummy_bonglewunch = bonglewunch()
function World:get_objects_with_tag(tag)
    if self.tags and self.tags[tag] then
        return self.tags[tag]
    end
    return dummy_bonglewunch
end

function World:get_number_of_objects_with_tag(tag)
    if self.tags and self.tags[tag] then
        return self.tags[tag]:length()
    end
    return 0
end

function World:get_first_object_with_tag(tag)
    if self.tags and self.tags[tag] then
        return self.tags[tag]:peek(1)
    end
    return nil
end

function World:get_random_object_with_tag(tag)
    if self.tags and self.tags[tag] then
        return self.tags[tag]:random()
    end
    return nil
end

function World:add_spatial_grid(name, cell_size)
    self[name] = spatial_grid(cell_size or DEFAULT_CELL_SIZE)
    self.spatial_grids = self.spatial_grids or {}
    table.insert(self.spatial_grids, self[name])
	return self[name]
end

function World.default_rect_function(obj)
	local dist = tilesets.TILE_SIZE
	local posx, posy = obj.pos.x, obj.pos.y
	return posx - dist / 2, posy - dist / 2, dist, dist
end

function World:get_closest_object_with_tag(tag, x, y)
	local objs = self:get_objects_with_tag(tag)
    if not objs then return end
    local closest_obj = nil
    local closest_dist = nil
    for _, obj in (objs):ipairs() do
		local dist = vec2_distance_squared(obj.pos.x, obj.pos.y, x, y)
		if not closest_obj or dist < closest_dist then
			closest_obj = obj
			closest_dist = dist
		end
	end
	return closest_obj
end

function World:add_to_spatial_grid(obj, grid_name, get_rect_function)
    if not self[grid_name] then
        error("No spatial grid with name " .. grid_name)
    end

	if self[grid_name]:has_object(obj) then
		return
	end
	
    if get_rect_function == nil then
		get_rect_function = World.default_rect_function
	end

	local grid = self[grid_name]

	local x, y, w, h = get_rect_function(obj)
	grid:add(obj, x, y, w, h)

	if signal.get(obj, "moved") then
		signal.connect(obj, "moved", self, "update_spatial_grid_" .. grid_name, function()
			local x, y, w, h = get_rect_function(obj)
			grid:update(obj, x, y, w, h)
		end)
	end

	if signal.get(obj, "destroyed") then
		signal.connect(obj, "destroyed", self, "remove_from_spatial_grid_" .. grid_name, function()
			self:remove_from_spatial_grid(obj, grid_name)
		end, true)
	end
end

function World:remove_from_spatial_grid(obj, grid_name)
	if not self[grid_name] then
		return
	end

	self[grid_name]:remove(obj)
    signal.disconnect(obj, "moved", self, "update_spatial_grid_" .. grid_name)
	signal.disconnect(obj, "destroyed", self, "remove_from_spatial_grid_" .. grid_name)
end

function World:show_object(obj)
    self.draw_objects:push(obj)
	-- self.sorted_draw_objects:insert(obj)
end

function World:hide_object(obj)
    self.draw_objects:remove(obj)
	-- self.sorted_draw_objects:remove(obj)
end

function World:query_spatial_grid(grid_name, x, y, w, h, t)
	return self[grid_name]:query(x, y, w, h, t)
end

function World:add_deferred_function(func, ...)
	self.deferred_functions = self.deferred_functions or {}
	table.insert(self.deferred_functions, {func, ...})
end

function World:queue_destroy()
	self.canvas_layer:add_deferred_function(function() self:destroy() end)
end

local Rbt = require "datastructure.rbt"

function World:populate_visible_objects_table()
    self.draw_objects_table = self.draw_objects_table or {}
	table.clear(self.draw_objects_table)
    for _, obj in ((self.draw_objects):ipairs()) do
        table.insert(self.draw_objects_table, obj)
    end
end

function World:get_visible_objects(sort)
    self:populate_visible_objects_table()

    if sort == nil or sort then
		self:sort_visible_objects()
	end

	return self.draw_objects_table
end

function World:sort_visible_objects()
    if self.draw_sort then
        table.sort(self.draw_objects_table, self.draw_sort)
    end
end

function World:get_mouse_position()
    local input = self:get_input_table()
    -- local offsx, offsy = self.world.canvas_layer:get_absolute_pos()
    -- print(offsx, offsy)
    return input.mouse.pos.x - self.camera_offset.x - self.pos.x - self.canvas_layer.pos.x, input.mouse.pos.y - self.camera_offset.y - self.pos.y - self.canvas_layer.pos.y
end

function World:get_draw_rect()
	return -self.camera_offset.x, -self.camera_offset.y, self.viewport_size.x, self.viewport_size.y,
		-self.camera_offset.x + self.viewport_size.x, -self.camera_offset.y + self.viewport_size.y,
		-self.camera_offset.y + self.viewport_size.y
end

function World:draw()
    local sorted_draw_objects = self:get_visible_objects()
	self:draw_sorted_objects(sorted_draw_objects)
end

function World:draw_sorted_objects(sorted_draw_objects)
    -- for _, obj in sorted_draw_objects:ipairs() do
    for _, obj in ipairs(sorted_draw_objects) do
		self:draw_object(obj)
    end
end

function World:draw_object(obj)
    graphics.push("all")
	local x, y = self:get_object_draw_position(obj)
	graphics.translate(x, y)

	if obj.draw_shared then
		obj:draw_shared()
	elseif obj.draw then
		obj:draw()
	end

    if debug.can_draw() then
        if obj.debug_draw_shared then obj:debug_draw_shared() end
    end
	
	graphics.pop()
end

function World:get_camera_offset()
	local offset_x, offset_y = 0, 0
	local zoom = 1.0

	if self.follow_camera then
		zoom = self.camera.zoom

		if self.camera.following then
			offset_x, offset_y = self:get_object_draw_position(self.camera.following)
		else
			offset_x, offset_y = self:get_object_draw_position(self.camera)
		end

		offset_x, offset_y = self.camera:clamp_to_limits(offset_x, offset_y)

		local local_offset_x, local_offset_y = self.camera:get_draw_offset()

		offset_x = offset_x + local_offset_x
		offset_y = offset_y + local_offset_y

        if self.center_camera then
            offset_y = -offset_y + (self.viewport_size.y / 2) / zoom
			offset_x = -offset_x + (self.viewport_size.x / 2) / zoom
        else
            offset_y = -offset_y
			offset_x = -offset_x
        end
		

	end

	-- return Vec2(0, 0), 1
	return offset_x, offset_y, zoom
end

function World:draw_shared()

	self.camera.viewport_size = self.viewport_size


	local offset_x, offset_y, zoom = self:get_camera_offset()

	self.camera_offset = self.camera_offset or Vec2()
	self.camera_offset.x = floor(offset_x)
    self.camera_offset.y = floor(offset_y)


	graphics.push()
	graphics.origin()
	graphics.set_color(1, 1, 1, 1)
	graphics.scale(zoom, zoom)

	graphics.translate(self.pos.x + offset_x, self.pos.y + offset_y)
	self:draw()

	-- if self.bump_world and debug.can_draw() then
	-- end

	graphics.pop()
end

function World.bump_draw_filter(obj)
	if Object.is(obj, GameObject) then return false end

	if type(obj) == "table" and obj.collision_rect then
		return true
	end

	return false
end

function World:bump_draw()
	-- for _, object in self.bump_world do
	local x, y, w, h = self:get_draw_rect()
	self.bump_draw_query_table = self.bump_draw_query_table or {}
	local objects = self.bump_world:queryRect(x, y, w, h, World.bump_draw_filter, self.bump_draw_query_table)
	for _, object in ipairs(objects) do
		graphics.draw_collision_box(object.collision_rect, object.solid and Color.blue or Color.orange)
	end
end

function World:enter_shared(center_camera)
	self:init_camera()
	self.camera:move_to(center_camera and self.viewport_size.x / 2 or 0, center_camera and self.viewport_size.y / 2 or 0, 0)
	World.super.enter_shared(self)
end

function World:get_object_draw_position(obj)
	local offset_x, offset_y = obj:get_draw_offset()
	return self:get_draw_position(obj.pos.x + offset_x, obj.pos.y + offset_y, obj.pos.z)
end

function World:get_draw_position(x, y, z)
	return x, y
end

function World:get_input_table()
	return self:get_base_world().input

end

function World:get_camera_bounds()
	return -self.camera_offset.x, -self.camera_offset.y, self.camera_offset.x + self.viewport_size.x,
		self.camera_offset.x + self.viewport_size.y
end

function World:get_base_world()
    local s = self.world
    while s ~= s.world do
        s = s.world
    end
    return s
end

function World:on_object_visibility_changed(obj)
	if obj.visible and obj.draw then
		self:show_object(obj)
	else
		self:hide_object(obj)
	end
end

function World:add_object_to_destroy(obj)
	table.insert(self.world_objects_to_destroy, obj)
end

function World:add_object(obj)
	if obj.is_destroyed then return end
    if obj.world then
        error("cannot move objects between worlds")
    end

    obj.world = self
	obj.canvas_layer = self.canvas_layer

	add_to_table(self.objects, obj)

	self:add_to_update_tables(obj)

	if self.on_object_visibility_changed then
		if signal.get(obj, "visibility_changed") then
			signal.connect(obj, "visibility_changed", self, "on_object_visibility_changed", function()
				self:on_object_visibility_changed(obj)
			end)
		end
	end

    if signal.get(obj, "update_changed") then
        signal.connect(obj, "update_changed", self, "on_object_update_changed", (function()
            if not obj.static then
                add_to_table(self.update_objects, obj)
            else
                remove_from_array(self.update_objects, obj)
            end
        end))
    end

	obj:set_id(self:new_object_id())
	self.id_to_object[obj.id] = obj

    signal.connect(obj, "destroyed", self, "remove_object", nil, true)

	self:bind_destruction(obj)

	if obj.is_bump_object then
		obj:set_bump_world(self.bump_world)
	end

	obj:enter_shared()

	if obj.children then
		for _, child in ipairs(obj.children) do
			child:tpv_to(obj.pos)
			self:add_object(child)
		end
	end

	return obj
end

function World:add_to_update_tables(obj)
    if not obj.static then
        add_to_table(self.update_objects, obj)
    end

	self:on_object_visibility_changed(obj)
end

function World:remove_object(obj)
    if not obj then return end

    if not obj.world == self then
        return
    end

    self.id_to_object[obj.id] = nil

    obj.world = nil
    obj.base_world = nil
    remove_from_array(self.objects, obj)
    remove_from_array(self.update_objects, obj)
    self:hide_object(obj)
    if obj.is_bump_object then
        self.bump_world:remove(obj)
        obj:set_bump_world(nil)
    end
    obj:prune_signals()
end

return World
