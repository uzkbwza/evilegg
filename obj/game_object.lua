---@class GameObject : Object
local GameObject = Object:extend("GameObject")

---@class GameObject2D : GameObject
local GameObject2D = GameObject:extend("GameObject2D")

---@class GameObject3D : GameObject
local GameObject3D = GameObject:extend("GameObject3D")

local ObjectRefArray = Object:extend("ObjectRefArray")

GameObject.DEFAULT_DRAW_CULL_DIST = 32
GameObject.id_counter = 0x00000000
GameObject.id_to_object = {}
function GameObject:get_object(id)
	return self.id_to_object[id]
end

function GameObject:new()

	self:add_signal("destroyed")
	self:add_signal("update_changed")
    self:add_signal("visibility_changed")

	self.id = GameObject.new_id()
	GameObject.id_to_object[self.id] = self

	self._update_functions = nil
	self._draw_functions = nil
	
	self.world = nil

	self.draw_cull_dist = nil
	
	self.visible = true
	
	self.static = false
		
	self.zindex = 0
end

function GameObject.new_id()
    local id = GameObject.id_counter
    -- GameObject.id_counter = bit.tobit(bit.band(GameObject.id_counter + 1, 0x0fffffff))
    GameObject.id_counter = bit.tobit(GameObject.id_counter + 1)
    return id
end

function GameObject:get_id()
	return self.id
end

function GameObject:on_moved()
    -- self.moved:emit()
    if self._move_functions then
        for _, v in ipairs(self._move_functions) do
            v(self)
        end
    end
    self:emit_signal("moved")
end

function GameObject.dummy() end

-- safe, "weak" references to other objects, automatically unrefs when object is destroyed
function GameObject:ref(name, object)
	if object == self[name] then return end
	if self[name] then
		self:unref(name)
	end
	self[name] = object
	signal.connect(object, "destroyed", self, "on_ref_destroyed", function() self[name] = nil end, true)
	return object
end

function GameObject:unref(name)
	signal.disconnect(self[name], "destroyed", self, "on_ref_destroyed")
	self[name] = nil
end

function GameObject:ref_array(name)
	local array = bonglewunch()
	self[name] = array
	return array
end

function GameObject:ref_array_push(name, obj)
	local array = self[name]
	if array:has(obj) then return end
	array:push(obj)
	signal.connect(obj, "destroyed", self, "on_object_in_ref_array_" .. name .. "_destroyed",
		function()
			self[name]:remove(obj)
		end,
	true)
end

function GameObject:ref_array_remove(name, obj)
	local array = self[name]
	if not array:has(obj) then return end
	
	signal.disconnect(obj, "destroyed", self, "on_object_in_ref_array_" .. name .. "_destroyed")
	
	array:remove(obj)
end

function GameObject:_update_sequencer(dt)
    self.sequencer:update(dt)
end

function GameObject:_update_elapsed_time(dt)
	self.elapsed = self.elapsed + dt
end

function GameObject:_update_elapsed_ticks(_dt)
	self.is_new_tick = false
	local old = self.tick
	self.tick = floor(self.elapsed)
	if self.tick ~= old then
		self.is_new_tick = true
	end
end

function GameObject:tick_pulse(pulse_length, offset)
	offset = offset or 0
	return floor(((self.tick + offset) / pulse_length) % 2) == 0
end

function GameObject:add_sequencer()
	if self.sequencer then return end
	assert(self.sequencer == nil, "GameObject:add_sequencer() called but sequencer already exists")
	self.sequencer = Sequencer()
	self:add_update_function(self._update_sequencer)
end

function GameObject:add_elapsed_time()
	if self.elapsed ~= nil then return end
	self.elapsed = 1
	self:add_update_function(self._update_elapsed_time)
end

function GameObject:add_elapsed_ticks()
	if self.tick ~= nil then return end

	if self.elapsed == nil then 
		self:add_elapsed_time()
	end
	self.tick = 1
	self:add_update_function(self._update_elapsed_ticks)
end
function GameObject:add_time_stuff()
	self:add_elapsed_time()
    self:add_elapsed_ticks()
	self:add_sequencer()
end

function GameObject:add_update_function(func)
	if self._update_functions == nil then
		self._update_functions = {}
	end
	table.insert(self._update_functions, func)
end

function GameObject:add_enter_function(func)
	if self._enter_functions == nil then
		self._enter_functions = {}
	end
	table.insert(self._enter_functions, func)
end

function GameObject:add_exit_function(func)
	if self._exit_functions == nil then
		self._exit_functions = {}
	end
	table.insert(self._exit_functions, func)
end


function GameObject:add_draw_function(func)
	if self._draw_functions == nil then
		self._draw_functions = {}
	end
	table.insert(self._draw_functions, func)
end

function GameObject:get_draw_offset()
	return 0, 0
end

function GameObject:add_move_function(func)
    if self._move_functions == nil then
        self._move_functions = {}
    end
    table.insert(self._move_functions, func)
end

function GameObject:defer(func, ...)
    if self.world then
        self.world:add_deferred_function(func, { self, ... })
		return
	end
    if self.canvas_layer then
        self.canvas_layer:add_deferred_function(func, { self, ... })
        return
    end

	error(tostring(self) .. ":defer() called but no deferred function target found")
end

		
-- does not affect transform, only world traversal
function GameObject:add_child(child)

    if self.children == nil then
        self.children = {}
        self:add_update_function(GameObject.update_children)
        signal.connect(child, "destroyed", self, "on_child_destroyed")
    end
    table.insert(self.children, child)
    child.parent = self
end

function GameObject:on_child_destroyed(child)
	self:remove_child(child)
end

function GameObject:remove_child(child)
	table.fast_remove(self.children, function (v) return v == child end)
end

function GameObject:update_shared(dt, ...)
    if self._update_functions then
        for _, func in ipairs(self._update_functions) do
            func(self, dt, ...)
        end
    end
    self:update(dt, ...)

end

function GameObject:queue_destroy()
	self.is_queued_for_destruction = true
	self:defer(self.destroy)
end

function GameObject:start_tick_timer(name, duration, callback)
	name = name or (self.tick_timers and #self.tick_timers + 1 or 1)

    if self.tick_timers == nil then
        self.tick_timers = {}
        self:add_update_function(function(obj, dt)
			if obj.tick_timers == nil then return end
            for k, v in pairs(obj.tick_timers) do
			if self.is_new_tick then
				v.elapsed = v.elapsed + 1
			end
			if v.elapsed >= v.duration then
				obj.tick_timers[k] = nil
				if v.callback then
					v.callback()
				end
			end
            end
        end)
    end
    if self.tick_timers[name] then
		self:stop_tick_timer(name)
	end
	self.tick_timers[name] = {
		duration = duration,
		elapsed = 0,
		callback = callback
	}
end


function GameObject:start_timer(name, duration, callback)
	name = name or (self.timers and #self.timers + 1 or 1)

    if self.timers == nil then
        self.timers = {}
		self.timers_to_remove = {}
		self:add_update_function(function(obj, dt)
            if obj.timers == nil then return end
            for k, v in pairs(obj.timers) do
                v.elapsed = v.elapsed + dt
                if v.elapsed >= v.duration then
                    table.insert(self.timers_to_remove, k)
                    if v.callback then
                        v.callback()
                    end
                end
            end
			for _, k in ipairs(self.timers_to_remove) do
				obj.timers[k] = nil
			end
			table.clear(self.timers_to_remove)

        end)
    end
    if self.timers[name] then
		self:stop_timer(name)
	end
	self.timers[name] = {
		duration = duration,
		elapsed = 0,
		callback = callback
	}
end

function GameObject:unref_from_table(name, tab)
	signal.disconnect(tab[name], "destroyed", self, "on_table_ref_destroyed")

	if tab[name] then
		self:unref(name)
	end

	tab[name] = nil
end

function GameObject:is_timer_running(name)
    return self.timers and self.timers[name] ~= nil
end

function GameObject:is_tick_timer_running(name)
    return self.tick_timers and self.tick_timers[name] ~= nil
end

function GameObject:timer_time_left(name)
    return (self.timers and self.timers[name] and self.timers[name].duration - self.timers[name].elapsed) or nil
end

function GameObject:tick_timer_time_left(name)
    return (self.tick_timers and self.tick_timers[name] and self.tick_timers[name].duration - self.tick_timers[name].elapsed) or nil
end

function GameObject:stop_timer(name)
	self.timers[name] = nil
end

function GameObject:end_timer(name)
	if self.timers and self.timers[name] then
		self.timers[name].callback()
		self:stop_timer(name)
	end
end

function GameObject:end_tick_timer(name)
	if self.tick_timers and self.tick_timers[name] then
		self.tick_timers[name].callback()
		self:stop_tick_timer(name)
	end
end

function GameObject:stop_tick_timer(name)
	self.tick_timers[name] = nil
end



function GameObject:start_destroy_timer(duration)
	self:start_timer("destroy_timer", duration, function() self:queue_destroy() end)
end

function GameObject:add_to_spatial_grid(grid, func)
    self.world:add_to_spatial_grid(self, grid, func)
end

function GameObject:remove_from_spatial_grid(grid)
    self.world:remove_from_spatial_grid(self, grid)
end

function GameObject:spawn_object(obj)
	local world = self.world

	self:defer(function() world:add_object(obj) end)
	-- self.world:add_object(obj)
	return obj
end

function GameObject:spawn_object_relative(obj, rel_x, rel_y)
	rel_x, rel_y = rel_x or 0, rel_y or 0
	local world = self.world
	local pos = self.pos
	obj:move_to(pos.x + rel_x, pos.y + rel_y)
    self:spawn_object(obj)
	return obj
end

function GameObject:get_input_table()
    if self.world then
        return self.world:get_input_table()
    end
    if self.canvas_layer then
        return self.canvas_layer:get_input_table()
    end
end

function GameObject:add_tag(tag)
    self.world:add_tag(self, tag)
end

function GameObject:remove_tag(tag)
	self.world:remove_tag(self, tag)
end

function GameObject:movev(dv, ...)
	self:move(dv.x, dv.y, ...)
end

function GameObject:move(dx, dy, ...)
	dy = dy or 0
	self:move_to(self.pos.x + dx, self.pos.y + dy, ...)
end

function GameObject:set_visibility(visible)
	local different = self.visible ~= visible
	self.visible = visible
	if different then
		self:emit_signal("visibility_changed")
	end
end

function GameObject:hide()
    if not self.visible then
        return
    end
	local different = self.visible
	self.visible = false
	if different then
		self:emit_signal("visibility_changed")
	end
end

function GameObject:show()
	if self.visible then
		return
	end
	local different = self.visible	
	self.visible = true
	if different then
		self:emit_signal("visibility_changed")
	end
end


function GameObject:add_object_entered_rect_function(func)
	if self._object_entered_rect_functions == nil then
		self._object_entered_rect_functions = {}
	end
	table.insert(self._object_entered_rect_functions, func)
end

function GameObject:add_object_exited_rect_function(func)
	if self._object_exited_rect_functions == nil then
		self._object_exited_rect_functions = {}
	end
	table.insert(self._object_exited_rect_functions, func)
end

function GameObject:object_entered_rect_shared(other)
	if self._object_entered_rect_functions then
		for _, v in ipairs(self._object_entered_rect_functions) do
			v(self, other)
		end
	end
	
	self:object_entered_rect(other)
end

function GameObject:object_entered_rect(other)

end

function GameObject:object_exited_rect_shared(other)
	if self._object_exited_rect_functions then
		for _, v in ipairs(self._object_exited_rect_functions) do
			v(self, other)
		end
	end

	self:object_exited_rect(other)
end

function GameObject:object_exited_rect(other)
end

function GameObject:process_collision(col)
end


function GameObject:set_update(on)
	self.static = not on
	self:emit_signal("update_changed")
end

function GameObject:update(dt, ...)
end

function GameObject:local_draw()
	graphics.translate(self.pos.x, self.pos.y)
end

function GameObject:draw_shared(...)

    love.graphics.push()
		
	local offsx, offsy = self:get_draw_offset()

	love.graphics.translate(offsx, offsy)
	love.graphics.setColor(1, 1, 1, 1)

	if self._draw_functions then
		for _, func in ipairs(self._draw_functions) do
			func(self, ...)
		end
	end

	self:draw(...)

	love.graphics.pop()
end

function GameObject:debug_draw_shared(...)
	love.graphics.push()
	
	if self.debug_draw then self:debug_draw(...) end

	love.graphics.pop()
end

function GameObject:debug_draw_bounds_shared()
	love.graphics.push()

	love.graphics.translate(self.pos.x, self.pos.y + self.zindex)
	
	if self.collision_rect then
		local offset_x, offset_y = self:get_collision_rect_offset()
		if self.solid then 
			love.graphics.setColor(0, 0.25, 1, 0.125)
		else 
			love.graphics.setColor(1, 0.5, 0, 0.125)
		end

        love.graphics.rectangle("fill", offset_x + 1, offset_y + 1, self.collision_rect.width - 1, self.collision_rect.height - 1)
		
		if self.solid then 
			love.graphics.setColor(0, 0.25, 1, 1.0)
		else 
			love.graphics.setColor(1, 0.5, 0, 1.0)
		end
		love.graphics.rectangle("line", offset_x + 1, offset_y + 1, self.collision_rect.width - 1, self.collision_rect.height - 1)
	end

	if self.bump_sensors then
		for _, sensor in ipairs(self.bump_sensors) do
            local color
			local alpha = 1.0
			if sensor.monitoring and sensor.monitorable then
				color = Color.purple
			elseif sensor.monitorable then
				color = Color.green
			elseif sensor.monitoring then
				color = Color.pink
			else
                color = Color.darkgrey
				alpha = 0.25
			end 
			graphics.draw_collision_box(sensor.rect, color, alpha)
		end
	end

	self:debug_draw_bounds()

	love.graphics.pop()
end

function GameObject:debug_draw_bounds()
end

function GameObject:add_sfx(sfx_name, volume, pitch, loop, relative)
    self.sfx = self.sfx or {}
    local src = audio.get_sfx(sfx_name)
	if relative then
		src:setRelative(true)
	end
	self.sfx[sfx_name] = {
		src = src,
		volume = volume,
        pitch = pitch,
		loop = loop
    }
	return src
end

-- function GameObject:play_sfx(sfx_name, volume, pitch, loop, x, y, z)
--     local t = self.sfx[sfx_name]
--     -- local relative = t.src:isRelative()
--     t.src:stop()
--     -- x = x or (relative and (0) or self.pos.x)
--     -- y = y or (relative and (0) or self.pos.y)
--     -- if self.pos.z then
--     -- 	z = self.pos.z
--     -- else
--     -- 	z = z or (relative and (audio.default_zindex) or self.zindex + audio.default_zindex)
--     -- end
--     -- audio.set_src_position(t.src, x, y, z)
--     -- t.src:setPosition(x, y, z)
--     audio.play_sfx(t.src, volume or t.volume, pitch or t.pitch, loop or t.loop)
-- end

function GameObject:play_sfx(sfx_name, volume, pitch, loop, x, y, z)
	audio.play_sfx_object(self, sfx_name, volume, pitch, loop)
    -- audio.play_sfx_monophonic(sfx_name, volume, pitch, loop)
end

function GameObject:play_world_sfx(sfx_name, volume, pitch, loop, x, y, z)
	self.world:play_sfx(sfx_name, volume, pitch, loop, x, y, z)
end

function GameObject:get_sfx(sfx_name)
	return self.sfx[sfx_name].src
end

function GameObject:stop_sfx(sfx_name)
	audio.stop_sfx_object(self, sfx_name)
	-- self.sfx[sfx_name].src:stop()
end

local destroyed_index_func = function(t, k)
	if t == "is_destroyed" then
		return true
	end
	error("attempt to access variable of destroyed object", 2)
end

function GameObject:destroy()
	if self.is_destroyed then return end
    if self.objects_to_destroy then
        for v, _ in pairs(self.objects_to_destroy) do
			if signal.get(v, "destroyed") then
				signal.disconnect(v, "destroyed", self, "on_object_to_destroy_destroyed_early")
			end
            v:destroy()
        end
    end
    if self.sfx then
        for _, t in pairs(self.sfx) do
            t.src:stop()
            t.src:release()
        end
    end

	self.is_destroyed = true
	self:exit_shared()
    if self.sequencer then
        self.sequencer:destroy()
    end
    self:emit_signal("destroyed", self)
    
	GameObject.id_to_object[self.id] = nil
	signal.cleanup(self)

	-- nuclear debugging
    if debug.enabled then
        self:override_instance_metamethod("__index", destroyed_index_func)
	end
end

function GameObject:bind_destruction(obj)
    self.objects_to_destroy = self.objects_to_destroy or {}
    self.objects_to_destroy[obj] = true
    signal.connect(obj, "destroyed", self, "on_object_to_destroy_destroyed_early", function()
		self.objects_to_destroy[obj] = nil
	end)
end

function GameObject:prune_signals()
	-- for _, v in pairs(self.signals) do 
	-- 	v:prune()
	-- end
end

function GameObject:clear_signals()
	-- for _, v in pairs(self.signals) do
	-- 	v:clear()
	-- end
end

function GameObject:enter_shared()
	if self._enter_functions then
		for _, func in ipairs(self._enter_functions) do
			func(self)
		end
	end
    self:enter()
end

function GameObject:get_objects_with_tag(tag)
    return self.world:get_objects_with_tag(tag)
end
function GameObject:get_first_object_with_tag(tag)
    return self.world:get_first_object_with_tag(tag)
end
function GameObject:has_tag(tag)
    return self.world:has_tag(self, tag)
end
function GameObject:get_closest_object_with_tag(tag)
	local objs = self:get_objects_with_tag(tag)
    if not objs then return end
    local closest_obj = nil
    local closest_dist = nil
    for _, obj in (objs):ipairs() do
		local dist = vec2_distance_squared(obj.pos.x, obj.pos.y, self.pos.x, self.pos.y)
		if not closest_obj or dist < closest_dist then
			closest_obj = obj
			closest_dist = dist
		end
	end
	return closest_obj
end

function GameObject:enter() end

function GameObject:exit_shared()
    self:exit()
	if self._exit_functions then
		for _, func in ipairs(self._exit_functions) do
			func(self)
		end
	end
end

function GameObject:dp()
	-- get the draw position from the world
    return self.world:get_object_draw_position(self)
end

function GameObject:to_local(pos_x, pos_y)
	return pos_x - self.pos.x, pos_y - self.pos.y

end

function GameObject:to_global(pos_x, pos_y)
	return pos_x + self.pos.x, pos_y + self.pos.y
end

function GameObject:add_signal(signal_name)
	self.signals = self.signals or {}
	self.signals[signal_name] = true
	signal.register(self, signal_name)
end

function GameObject:has_signal(signal_name)
    return self.signals and self.signals[signal_name]
end

function GameObject:remove_signal(signal_name)
	self.signals[signal_name] = nil
	signal.deregister(self, signal_name)
end

function GameObject:emit_signal(signal_name, ...)
    if not debug.enabled then
		if not signal.get(self, signal_name) then
			return
		end
	end
	signal.emit(self, signal_name, ...)
end

function GameObject:exit() end

local mix2D = Mixins.Behavior.Object2D
local mix3D = Mixins.Behavior.Object3D

GameObject2D:implement(mix2D)
GameObject3D:implement(mix3D)

function GameObject2D:new(x, y)
	GameObject.new(self)
	self:mix_init(mix2D, x, y)
end

function GameObject3D:new(x, y, z)
	GameObject.new(self)
	self:mix_init(mix3D, x, y, z)
end

return {
	GameObject = GameObject,
	GameObject2D = GameObject2D,
	GameObject3D = GameObject3D,
}
