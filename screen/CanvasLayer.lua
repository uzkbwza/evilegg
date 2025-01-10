local GameObject = require("obj.game_object")

---@class CanvasLayer : GameObject
local CanvasLayer = GameObject:extend("CanvasLayer")

---Create a new CanvasLayer.
---@param x number|nil # Initial x-position
---@param y number|nil # Initial y-position
---@param viewport_size_x number|nil # Viewport width
---@param viewport_size_y number|nil # Viewport height
---@return CanvasLayer
function CanvasLayer:new(x, y, viewport_size_x, viewport_size_y)
    CanvasLayer.super.new(self, x or 0, y or 0)

    -- Screen properties
    self.blocks_render = false
    self.blocks_input = false
    self.blocks_logic = false
    self.root = nil

    self.children = {}
    self.deferred_queue = {}

    self.viewport_size = Vec2(viewport_size_x or conf.viewport_size.x, viewport_size_y or conf.viewport_size.y)
    self.canvas = love.graphics.newCanvas(self.viewport_size.x, self.viewport_size.y)
    self.offset = Vec2(0, 0)
    self.zoom = 1
    self.clear_color = Color.from_hex("000000")
	self.clear_color.a = 0
    self.interp_fraction = 1

    self.parent = nil
    self.above = nil
    self.below = nil
	self.canvas_layer = self

    self:add_sequencer()
    self:add_elapsed_time()
    self:add_elapsed_ticks()

    self.worlds = {}
    self.objects = bonglewunch()
    self.input = input.dummy

    -- Existing signals
    self:add_signal("push_requested")
    self:add_signal("pop_requested")

    -- New signals for sibling operations
    -- These are emitted by a child to request a parent action.
    self:add_signal("add_sibling_above_requested")
    self:add_signal("add_sibling_below_requested")
    self:add_signal("add_sibling_relative_requested")
    self:add_signal("remove_sibling_requested")
    self:add_signal("replace_sibling_requested")

    return self
end

----------------------------------------------------------------
-- Helper Functions
----------------------------------------------------------------

---Normalize an index to be within the stack range and handle negative indices.
---@param index number
---@param length number
---@return number|nil
local function normalize_index(index, length)
	if index == nil then return nil end
    if index == 0 then return nil end
    if index < 0 then
        index = length + 1 + index
    end
    if index < 1 or index > length then
        return nil
    end
    return index
end

---@param l
---@return CanvasLayer
function CanvasLayer:load_layer(l)
	if type(l) == "string" then
		local layer = table.get_by_path(Screens, l)()
		layer.name = l
		return layer
	else
		local layer = l()
		layer.name = tostring(layer)
		return layer
	end
end

---Initialize layer after insertion: connect signals and call `enter()`.
---@param layer CanvasLayer
function CanvasLayer:init_layer(layer)
    signal.connect(layer, "push_requested", self, "push_deferred")
    signal.connect(layer, "pop_requested", self, "pop_deferred")

    -- Connect new sibling-related signals from the child to parent's deferred handling
    signal.connect(layer, "add_sibling_above_requested", self, "add_sibling_above_deferred")
    signal.connect(layer, "add_sibling_below_requested", self, "add_sibling_below_deferred")
    signal.connect(layer, "add_sibling_relative_requested", self, "add_sibling_relative_deferred")
    signal.connect(layer, "remove_sibling_requested", self, "remove_sibling_deferred")
    signal.connect(layer, "replace_sibling_requested", self, "replace_sibling_deferred")

    layer.root = self.root
    layer.parent = self

    layer:enter()
end

---Refresh 'above' and 'below' references for all children.
function CanvasLayer:refresh_layer_links()
    for i, layer in ipairs(self.children) do
        layer.above = (i > 1) and self.children[i-1] or nil
        layer.below = (i < #self.children) and self.children[i+1] or nil
    end
end

----------------------------------------------------------------
-- Stack Management (Push/Pop/Transition)
----------------------------------------------------------------

---@param layer_name string
function CanvasLayer:push_deferred(layer_name)
    table.insert(self.deferred_queue, { action = "push", layer = layer_name })
end

function CanvasLayer:pop_deferred()
    table.insert(self.deferred_queue, { action = "pop" })
end

---@param layer_name string
function CanvasLayer:push(layer_name)
    return self:insert_layer(layer_name, #self.children + 1)
end

function CanvasLayer:pop()
    self:remove_layer(1)
end

function CanvasLayer:get_child(index)
    return self.children[index]
end

function CanvasLayer:get_child_by_name(name)
    for _, child in ipairs(self.children) do
        if child.name == name then
            return child
        end
    end
    return nil
end

---@param new_layer string
function CanvasLayer:transition_to(new_layer)
    local layer = self.parent or self
    for _=1, #layer.children do
        layer:pop_deferred()
    end
    layer:push_deferred(new_layer)
end

----------------------------------------------------------------
-- Insert/Remove/Replace Layers
----------------------------------------------------------------

---@param index? number # Position to insert; supports negative and 0
function CanvasLayer:insert_layer(l, index)

	local length = #self.children

	if index == nil then
		index = 1
	end

    if index == 0 then index = 1 end
    if index < 0 then
        index = length + 2 + index
    end
    if index < 1 then index = 1 end
    if index > length + 1 then index = length + 1 end

    local layer = self:load_layer(l)

    table.insert(self.children, index, layer)
    self:refresh_layer_links()
    self:init_layer(layer)
    self:bind_destruction(layer)
	signal.connect(layer, "destroyed", self, "remove_child_on_destroy", function() self:remove_child(layer) end)
	collectgarbage("collect")
	return layer
end

---@param layer CanvasLayer|string
function CanvasLayer:remove_child(layer)
	self:remove_layer(self:get_index_of_layer(layer))
end

function CanvasLayer:get_input_table()
	return self.input
end

---@param index number
function CanvasLayer:remove_layer(index)
    local idx = normalize_index(index, #self.children)
    if not idx then return end

    local layer = table.remove(self.children, idx)
    self:refresh_layer_links()

    layer:exit()
    layer.parent = nil
    layer:destroy()
	collectgarbage("collect")
end

---@param index number
---@return CanvasLayer|nil
function CanvasLayer:get_layer(index)
    local idx = normalize_index(index, #self.children)
    if not idx then return nil end
    return self.children[idx]
end

---@param target_layer CanvasLayer|string
---@return number|nil
function CanvasLayer:get_index_of_layer(target_layer)
    for i, layer in ipairs(self.children) do
        if layer == target_layer or layer.name == target_layer or layer.name == tostring(target_layer) then
            return i
        end
    end
    return nil
end

----------------------------------------------------------------
-- Sibling Management Signals & Deferred Handlers
----------------------------------------------------------------

function CanvasLayer:add_deferred_function(func, ...)
	self.deferred_functions = self.deferred_functions or {}
	table.insert(self.deferred_functions, {func, ...})
end

function CanvasLayer:queue_destroy()
	self.parent:add_deferred_function(function() self:destroy() end)
end

---Deferred handlers for sibling operations requested by children.
---They add operations to deferred_queue, which will be processed in update_shared.

---Add a sibling above the given layer.
---@param requesting_layer CanvasLayer
---@param name string
function CanvasLayer:add_sibling_above_deferred(requesting_layer, name)
    table.insert(self.deferred_queue, { action = "add_sibling_above", layer = requesting_layer, name = name })
end

---Add a sibling below the given layer.
---@param requesting_layer CanvasLayer
---@param name string
function CanvasLayer:add_sibling_below_deferred(requesting_layer, name)
    table.insert(self.deferred_queue, { action = "add_sibling_below", layer = requesting_layer, name = name })
end

---Add a sibling relative to the given layer by offset.
---@param requesting_layer CanvasLayer
---@param name string
---@param offset number
function CanvasLayer:add_sibling_relative_deferred(requesting_layer, name, offset)
    table.insert(self.deferred_queue, { action = "add_sibling_relative", layer = requesting_layer, name = name, offset = offset })
end

---Remove a sibling layer relative to the given layer by offset.
---@param requesting_layer CanvasLayer
---@param offset number
function CanvasLayer:remove_sibling_deferred(requesting_layer, offset)
    table.insert(self.deferred_queue, { action = "remove_sibling", layer = requesting_layer, offset = offset })
end

---Replace a sibling layer relative to the given layer by offset.
---@param requesting_layer CanvasLayer
---@param name string
---@param offset number
function CanvasLayer:replace_sibling_deferred(requesting_layer, name, offset)
    table.insert(self.deferred_queue, { action = "replace_sibling", layer = requesting_layer, name = name, offset = offset })
end

----------------------------------------------------------------
-- Sibling Operations Implementation
----------------------------------------------------------------

---Perform the requested sibling modifications.
---This is called during update_shared() after deferred_queue processing.
---@param op table
function CanvasLayer:process_sibling_operation(op)
    local requesting_layer = op.layer
	if not requesting_layer then return end
	if requesting_layer.parent ~= self then
		error("Requesting layer is not a child of this layer")
	end

    local idx = self:get_index_of_layer(requesting_layer)
    if not idx then return end

    if op.action == "add_sibling_above" then
        self:insert_layer(op.name, idx) -- Insert at idx means above requesting_layer
    elseif op.action == "add_sibling_below" then
        self:insert_layer(op.name, idx + 1) -- Insert below requesting_layer
    elseif op.action == "add_sibling_relative" then
        self:insert_layer(op.name, idx + op.offset)
    elseif op.action == "remove_sibling" then
        self:remove_layer(idx + op.offset)
    elseif op.action == "replace_sibling" then
        local target_index = idx + op.offset
        local length = #self.children
        if target_index >= 1 and target_index <= length then
            self:replace_layer(target_index, op.name)
        end
    end
end

----------------------------------------------------------------
-- Move/Swap/Clear/Replace Layers
----------------------------------------------------------------

---@param layer_or_index number|CanvasLayer|string
---@param new_index number
function CanvasLayer:move_layer(layer_or_index, new_index)
    local old_index = type(layer_or_index) == "number" and layer_or_index or self:get_index_of_layer(layer_or_index)
    if not old_index then return end
    if old_index == new_index then return end

    local idx = normalize_index(old_index, #self.children)
    local new_idx = normalize_index(new_index, #self.children)
    if not idx or not new_idx then return end

    local layer = table.remove(self.children, idx)
    table.insert(self.children, new_idx, layer)
    self:refresh_layer_links()
end

function CanvasLayer:clear()
    while #self.children > 0 do
        self:remove_layer(1)
    end
end

---@param old_layer_or_index number|CanvasLayer|string
---@param new_layer 
function CanvasLayer:replace_layer(old_layer_or_index, new_layer)
    local index = type(old_layer_or_index) == "number" and old_layer_or_index or self:get_index_of_layer(old_layer_or_index)
    if not index then return end

    local idx = normalize_index(index, #self.children)
    if not idx then return end

    local old_layer = table.remove(self.children, idx)
    old_layer:exit()
    old_layer.parent = nil
    old_layer:destroy()

    local new_layer = self:load_layer(new_layer)
    table.insert(self.children, idx, new_layer)
    self:refresh_layer_links()
    self:init_layer(new_layer)
end

---@param layer CanvasLayer|string
---@return boolean
function CanvasLayer:has_layer(layer)
    return self:get_index_of_layer(layer) ~= nil
end

function CanvasLayer:pop_until(target_layer)
    while #self.children > 0 do
        local top_layer = self.children[1]
        if top_layer == target_layer or top_layer.name == target_layer or top_layer.name == tostring(target_layer) then
            break
        end
        self:pop()
    end
end

function CanvasLayer:top()
    return self.children[1]
end

function CanvasLayer:bottom()
    return self.children[#self.children]
end

----------------------------------------------------------------
-- World and Update/Draw Management
----------------------------------------------------------------

---@param world table
---@return table
function CanvasLayer:add_world(world)
	world = world or World()
    table.insert(self.worlds, world)
    world.viewport_size = self.viewport_size
    world.canvas_layer = self
    self:bind_destruction(world)
    signal.connect(world, "destroyed", self, "delete_world", function() table.erase(self.worlds, world) end)
    world:enter_shared()
    return world
end

---@param dt number
function CanvasLayer:update_worlds(dt)
    for _, world in ipairs(self.worlds) do
        world.viewport_size = self.viewport_size
        world.input = self.input
        world:update_shared(dt)
    end
end

---@param dt number
function CanvasLayer:update_shared(dt)
    if self.is_destroyed then
        return
    end

    -- Process deferred operations
    while #self.deferred_queue > 0 do
        local op = table.remove(self.deferred_queue, 1)
        if op.action == "push" then
            self:push(op.layer)
        elseif op.action == "pop" then
            self:pop()
        elseif op.action == "add_sibling_above" or op.action == "add_sibling_below"
            or op.action == "add_sibling_relative" or op.action == "remove_sibling"
            or op.action == "replace_sibling" then
            self:process_sibling_operation(op)
        end
    end

    -- Update input state
    local process_input = true
    for i=#self.children, 1, -1 do
        local layer = self.children[i]
        layer.input = process_input and input or input.dummy
        if layer.blocks_input then
            process_input = false
        end
    end

    self:update_worlds(dt)

    for i = #self.children, 1, -1 do
        local layer = self.children[i]
        layer:update_shared(dt)
        if layer.blocks_logic then
            break
        end
    end
    
    CanvasLayer.super.update_shared(self, dt)
	
	if self.deferred_functions then
        for _, t in ipairs(self.deferred_functions) do
            local func, args = unpack(t)
            func(args and unpack(args) or nil)
        end
        table.clear(self.deferred_functions)
    end

end

function CanvasLayer:draw_shared()
    graphics.push("all")
    graphics.origin()
    graphics.set_canvas(self.canvas)

    if self.clear_color then
        graphics.clear(self.clear_color.r, self.clear_color.g, self.clear_color.b, self.clear_color.a or 1)
    end

    graphics.scale(self.zoom, self.zoom)
    graphics.translate(self.offset.x, self.offset.y)

    for _, world in ipairs(self.worlds) do
        world:draw_shared()
    end

	self:draw()

    local update_interp = true
    for i = 1, #self.children do
        local layer = self.children[i]
        layer:draw_shared()
        layer.interp_fraction = update_interp and self.interp_fraction or layer.interp_fraction
        if layer.blocks_render then
            break
        end
    end

    graphics.pop()
    graphics.draw(self.canvas, self.pos.x, self.pos.y)
end

---@param obj any
---@return any
function CanvasLayer:add_object(obj)
    self.objects:add(obj)
    obj.canvas_layer = self
    self:bind_destruction(obj)
    signal.connect(obj, "destroyed", self, "delete_object", function()
        self.objects:remove(obj)
    end)
    return obj
end

---Request that a parent CanvasLayer push a new layer.
---@param layer_name string
function CanvasLayer:push_to_parent(layer_name)
    self:emit_signal("push_requested", layer_name)
end

---Request that a parent CanvasLayer pop this layer.
function CanvasLayer:pop_from_parent()
    self:emit_signal("pop_requested")
end

----------------------------------------------------------------
-- Child Helper Functions for Sibling Operations
-- These are called from the current layer to request operations on siblings.
----------------------------------------------------------------

---Add a sibling layer above this layer.
---@param name string
function CanvasLayer:add_sibling_above(name)
    self:emit_signal("add_sibling_above_requested", self, name)
end

---Add a sibling layer below this layer.
---@param name string
function CanvasLayer:add_sibling_below(name)
    self:emit_signal("add_sibling_below_requested", self, name)
end

---Add a sibling layer relative to this layer by a certain offset.
---offset = -1 is above, offset = 1 is below, etc.
---@param name string
---@param offset number
function CanvasLayer:add_sibling_relative(name, offset)
    self:emit_signal("add_sibling_relative_requested", self, name, offset)
end

---Remove a sibling layer relative to this layer by an offset.
---@param offset number
function CanvasLayer:remove_sibling(offset)
    self:emit_signal("remove_sibling_requested", self, offset)
end
 
---Replace a sibling layer relative to this layer by an offset.
---@param name string
---@param offset number
function CanvasLayer:replace_sibling(name, offset)
    self:emit_signal("replace_sibling_requested", self, name, offset)
end

---Find a sibling layer relative to this layer by an offset.
---@param offset number
function CanvasLayer:get_sibling(offset)
	local id = self.parent:get_index_of_layer(self) + offset
	if id < 1 or id > #self.parent.children then
		return nil
	end
	return self.parent.children[id]
end

----------------------------------------------------------------
-- Override these in subclasses if needed
----------------------------------------------------------------

---@param dt number
function CanvasLayer:update(dt) end

function CanvasLayer:draw() end
function CanvasLayer:enter() end
function CanvasLayer:exit() end

return CanvasLayer
