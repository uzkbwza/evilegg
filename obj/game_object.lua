---@class GameObject : Object
local GameObject = Object:extend("GameObject")

---@class GameObject2D : GameObject
local GameObject2D = GameObject:extend("GameObject2D")

---@class GameObject3D : GameObject
local GameObject3D = GameObject:extend("GameObject3D")

local ObjectRefArray = Object:extend("ObjectRefArray")

GameObject.DEFAULT_DRAW_CULL_DIST = 32

function GameObject:new()
    self:add_signal("destroyed")
    self:add_signal("update_changed")
    self:add_signal("visibility_changed")

    -- self._update_functions = nil
    -- self._draw_functions = nil

    -- self.world = nil

    -- self.draw_cull_dist = nil

    self.visible = true

    self.static = false

    self.z_index = 0
end

if debug.enabled then
    function GameObject:set_id(id)
        if self.id == nil then
            self.id = id
        else
            error("GameObject:set_id() called but id is already set")
        end
    end
else
	function GameObject:set_id(id)
		self.id = id
	end
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
	signal.connect(object, "destroyed", self, "on_ref_destroyed_" .. name, function() self[name] = nil end, true)
	return object
end

function GameObject:unref(name)
    if not self[name] then return end
    signal.disconnect(self[name], "destroyed", self, "on_ref_destroyed_" .. name)
    self[name] = nil
end


function GameObject:ref_array(name)
	self[name] = {}
	return self[name]
end

function GameObject:ref_array_push(name, obj)
	local array = self[name]
	if table.list_has(array, obj) then return end
	table.insert(array, obj)
	signal.connect(obj, "destroyed", self, "on_object_in_ref_array_" .. name .. "_destroyed",
		function()
			table.erase(array, obj)
		end,
        true)
	return obj
end

function GameObject:ref_array_remove(name, obj)	
	if table.erase(self[name], obj) then
		signal.disconnect(obj, "destroyed", self, "on_object_in_ref_array_" .. name .. "_destroyed")
	end
end

function GameObject:ref_array_clear(name)
	local array = self[name]
    if not array then return end
	for i=#array, 1, -1 do
        signal.disconnect(array[i], "destroyed", self, "on_object_in_ref_array_" .. name .. "_destroyed")
		array[i] = nil
	end
end

function GameObject:ref_bongle(name)
	local array = bonglewunch()
	self[name] = array
	return array
end

function GameObject:ref_bongle_push(name, obj)
	local array = self[name]
	if array:has(obj) then return end
	array:push(obj)
	signal.connect(obj, "destroyed", self, "on_object_in_ref_bongle_" .. name .. "_destroyed",
		function()
			self[name]:remove(obj)
		end,
	true)
	return obj
end

function GameObject:ref_bongle_remove(name, obj)
	local array = self[name]
	if not array:has(obj) then return end
	
	signal.disconnect(obj, "destroyed", self, "on_object_in_ref_bongle_" .. name .. "_destroyed")
	
	array:remove(obj)
end

function GameObject:ref_bongle_clear(name)
	local array = self[name]
    if not array then return end
	local to_remove = {}
	for _, obj in array:ipairs() do
		table.insert(to_remove, obj)
	end
	for _, obj in to_remove do
		self:ref_bongle_remove(name, obj)
	end
end

function GameObject:_update_sequencer(dt)
    self.sequencer:update(dt)
end

function GameObject:_update_elapsed_time(dt)
	self.elapsed = self.elapsed + dt
end

function GameObject:_update_elapsed_ticks(dt)
	self.is_new_tick = false
	
	self.tick_accumulator = self.tick_accumulator + dt

	if self.tick_accumulator >= 1 then
		self.tick = self.tick + 1
		self.tick_accumulator = self.tick_accumulator - 1
		self.is_new_tick = true
	end

	-- local old = self.tick
	-- self.tick = floor(self.elapsed)
	-- if self.tick ~= old then
	-- 	self.is_new_tick = true
	-- end
	
end

function GameObject:tick_pulse(pulse_length, offset)
    offset = offset or 0
	return floor(((self.tick + offset) / pulse_length) % 2) == 0
end

function GameObject:add_sequencer()
	if self.sequencer then
		return
	end
	
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

	self.tick_accumulator = 0

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
	return func
end

function GameObject:remove_update_function(func)
	if self._update_functions == nil then
		return
	end
	table.erase(self._update_functions, func)
end

function GameObject:add_enter_function(func)
    if self._enter_functions == nil then
        self._enter_functions = {}
    end
    table.insert(self._enter_functions, func)
    return func
end

function GameObject:remove_enter_function(func)
	if self._enter_functions == nil then
		return
	end
	table.erase(self._enter_functions, func)
end

function GameObject:add_exit_function(func)
	if self._exit_functions == nil then
		self._exit_functions = {}
	end
	table.insert(self._exit_functions, func)
	return func
end

function GameObject:remove_exit_function(func)
	if self._exit_functions == nil then
		return
	end
	table.erase(self._exit_functions, func)
end

function GameObject:add_draw_function(func)
	if self._draw_functions == nil then
		self._draw_functions = {}
	end
	table.insert(self._draw_functions, func)
	return func
end

function GameObject:remove_draw_function(func)
	if self._draw_functions == nil then
		return
	end
	table.erase(self._draw_functions, func)
end

function GameObject:add_move_function(func)
    if self._move_functions == nil then
        self._move_functions = {}
    end
    table.insert(self._move_functions, func)
	return func
end

function GameObject:remove_move_function(func)
    if self._move_functions == nil then
        return
    end
    table.erase(self._move_functions, func)
end

function GameObject:get_draw_offset()
    return 0, 0
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

    -- error(tostring(self) .. ":defer() called but no deferred function target found")
	
	func(self, ...)

end

		
-- does not affect transform, only world traversal
-- function GameObject:add_child(child)

--     if self.children == nil then
--         self.children = {}
--         self:add_update_function(GameObject.update_children)
--         signal.connect(child, "destroyed", self, "on_child_destroyed")
--     end
--     table.insert(self.children, child)
--     child.parent = self
-- end

-- function GameObject:on_child_destroyed(child)
-- 	self:remove_child(child)
-- end

-- function GameObject:remove_child(child)
-- 	table.fast_remove(self.children, function (v) return v == child end)
-- end

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
    if self.world then
		self.world:add_object_to_destroy(self)
	else
		self:defer(self.destroy)
	end
end


function GameObject:get_mouse_position()
	return self.world:get_mouse_position()
end

function GameObject:do_at_tick(tick, func)
    if not self.do_at_tick_functions then
        self.do_at_tick_functions = self.do_at_tick_functions or {}
        self:add_update_function(self._do_at_tick_update_function)
    end
	
	self.do_at_tick_functions[tick] = self.do_at_tick_functions[tick] or {}
	table.insert(self.do_at_tick_functions[tick], func)
end

function GameObject:_do_at_tick_update_function(dt)
    self.do_at_tick_functions_to_remove = self.do_at_tick_functions_to_remove or {}

    local finished_any = false

    if self.do_at_tick_functions[self.tick] then
        for _, v in ipairs(self.do_at_tick_functions[self.tick]) do
            v(self)
            table.insert(self.do_at_tick_functions_to_remove, v)
            finished_any = true
        end
    end


    if finished_any then
        for _, v in ipairs(self.do_at_tick_functions_to_remove) do
            table.erase(self.do_at_tick_functions, v)
        end
        table.clear(self.do_at_tick_functions_to_remove)
    end
end

function GameObject:set_at_tick(tick, prop, value) 
    if not self.set_at_tick_actions then
        self.set_at_tick_actions = {}
        self:add_update_function(self._set_at_tick_update_function)
    end
    if not self.set_at_tick_actions[tick] then
        self.set_at_tick_actions[tick] = {}
    end
    self.set_at_tick_actions[tick][prop] = value
end

function GameObject:_set_at_tick_update_function()
    if self.set_at_tick_actions and self.set_at_tick_actions[self.tick] then
        self._set_at_tick_temp_actions = self._set_at_tick_temp_actions or {}
        local temp_actions = self._set_at_tick_temp_actions
        
        -- Copy actions to temp table
        for prop, value in pairs(self.set_at_tick_actions[self.tick]) do
            temp_actions[prop] = value
        end
        self.set_at_tick_actions[self.tick] = nil

        -- Execute actions from temp table
        for prop, value in pairs(temp_actions) do
            self[prop] = value
        end
        
        -- Clear temp table for reuse
        for prop in pairs(temp_actions) do
            temp_actions[prop] = nil
        end

        local has_more_actions = false
        for _ in pairs(self.set_at_tick_actions) do
            has_more_actions = true
            break
        end

        if not has_more_actions then
            self:remove_update_function(self._set_at_tick_update_function)
            self.set_at_tick_actions = nil
        end
    end
end

function GameObject:interpolate_property(prop, start, finish, duration, nil_at_end)
	self[prop] = start
	self:interpolate_property_at_time(prop, start, finish, self.elapsed, duration, nil_at_end)
end

function GameObject:interpolate_property_at_time(prop, start, finish, start_time, duration, nil_at_end)
	self:interpolate_property_between_times(prop, start, finish, start_time, start_time + duration, nil_at_end)
end

function GameObject:interpolate_property_between_times(prop, start, finish, start_time, finish_time, nil_at_end)
    if not self.interpolate_properties then
        self.interpolate_properties = {}
        self:add_update_function(self._interpolate_properties_update_function)
    end
    table.insert(self.interpolate_properties, {
        prop = prop,
        start = start,
        finish = finish,
        start_time = start_time,
        finish_time = finish_time,
		nil_at_end = nil_at_end
    })
end

function GameObject:is_interpolating_property(prop)
    return self.interpolation_counts and self.interpolation_counts[prop]
end

function GameObject:_increment_interpolation_count(prop)
    self.interpolation_counts = self.interpolation_counts or {}
    self.interpolation_counts[prop] = (self.interpolation_counts[prop] or 0) + 1
end

function GameObject:_decrement_interpolation_count(prop)
    if not self.interpolation_counts or not self.interpolation_counts[prop] then
        return
    end
    self.interpolation_counts[prop] = self.interpolation_counts[prop] - 1
    if self.interpolation_counts[prop] == 0 then
        self.interpolation_counts[prop] = nil
    end
end

function GameObject:_interpolate_properties_update_function(dt)
    if not self.interpolate_properties or #self.interpolate_properties == 0 then return end

    -- Pass 1: Activate newly started interpolations and find the dominant one for each property.
    self._interpolate_latest_starters = self._interpolate_latest_starters or {}
    local latest_starters = self._interpolate_latest_starters
    
    -- Clear the cached table
    for prop in pairs(latest_starters) do
        latest_starters[prop] = nil
    end
    
    for i = 1, #self.interpolate_properties do
        local v = self.interpolate_properties[i]
        if self.elapsed >= v.start_time and not v.started then
            v.started = true
            self:_increment_interpolation_count(v.prop)

            local current_latest = latest_starters[v.prop]
            if not current_latest or v.start_time > current_latest.start_time then
                latest_starters[v.prop] = v
            end
        end
    end

    -- Pass 2: Update values, and remove completed or superseded interpolations.
    for i = #self.interpolate_properties, 1, -1 do
        local v = self.interpolate_properties[i]

		if not v.started then
			goto continue
		end

        -- Check if it is superseded by a new interpolation that just started
        local dominant_starter = latest_starters[v.prop]
        if dominant_starter and dominant_starter ~= v then
            self:_decrement_interpolation_count(v.prop)
            table.remove(self.interpolate_properties, i)
            goto continue
        end

		local elapsed = self.elapsed - v.start_time
		local duration = v.finish_time - v.start_time
		
		if elapsed >= duration then
			if v.nil_at_end then
				self[v.prop] = nil
			else
				self[v.prop] = v.finish
			end
			self:_decrement_interpolation_count(v.prop)
			table.remove(self.interpolate_properties, i)
		else
			self[v.prop] = lerp(v.start, v.finish, elapsed / duration)
		end
        ::continue::
    end

    if #self.interpolate_properties == 0 then
        self:remove_update_function(self._interpolate_properties_update_function)
        self.interpolate_properties = nil
    end
end

function GameObject:start_stopwatch(name)
	self.stopwatches = self.stopwatches or {}
	if self.stopwatches[name] then
		self.stopwatches[name].elapsed = 0
		self.stopwatches[name].tick = 0
		return
	end
    self.stopwatches[name] = {
        elapsed = 0,
        tick = 0,
		func = function(self, dt)
			self:_update_stopwatch(name, dt)
		end
    }
	self:add_update_function(self.stopwatches[name].func)
end

function GameObject:pause_stopwatch(name)
	if self.stopwatches[name].paused then return end
	self:remove_update_function(self.stopwatches[name].func)
	self.stopwatches[name].paused = true
end

function GameObject:resume_stopwatch(name)
	if not self.stopwatches[name].paused then return end
	self:add_update_function(self.stopwatches[name].func)
	self.stopwatches[name].paused = false
end

function GameObject:_update_stopwatch(name, dt)
	self.stopwatches[name].elapsed = self.stopwatches[name].elapsed + dt
    self.stopwatches[name].tick = floor(self.stopwatches[name].elapsed)
end

function GameObject:stop_stopwatch(name)
	self:remove_update_function(self.stopwatches[name].func)
    self.stopwatches[name] = nil
end

function GameObject:get_stopwatch(name)
	return self.stopwatches and self.stopwatches[name] or nil
end

function GameObject:start_tick_timer(name, duration, callback)
    name = name or (self.tick_timers and #self.tick_timers + 1 or 1)
	duration = max(floor(duration), 1)

    if self.tick_timers == nil then
        self.tick_timers = {}
        self:add_update_function(function(self, dt)
            if self.tick_timers == nil then return end
			if self.is_destroyed then return end
			local to_remove = nil
			local num_to_remove = 0
            for k, v in pairs(self.tick_timers) do
                v.elapsed = v.elapsed + dt
				local tick = floor(v.elapsed)
				if tick >= v.duration then
                    
					local changed = false
                    if v.callback then
                        v.callback()
                    end

                    if v ~= self.tick_timers[k] then
                        changed = true
                    end
					
					if not changed then
						to_remove = to_remove or {}
						num_to_remove = num_to_remove + 1
						table.insert(to_remove, k)
					end
				end
            end
			for i=1, num_to_remove do 
				self.tick_timers[to_remove[i]] = nil
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
        self:add_update_function(function(self, dt)
            if self.timers == nil then return end
			if self.is_destroyed then return end
			local to_remove = nil
			local num_to_remove = 0
            for k, v in pairs(self.timers) do
				v.elapsed = v.elapsed + dt
				if v.elapsed >= v.duration then
                    
					local changed = false
                    if v.callback then
                        v.callback()
                    end

                    if v ~= self.timers[k] then
                        changed = true
                    end
					
					if not changed then
						to_remove = to_remove or {}
						num_to_remove = num_to_remove + 1
						table.insert(to_remove, k)
					end
				end
            end
			for i=1, num_to_remove do 
				self.timers[to_remove[i]] = nil
			end
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

function GameObject:timer_progress(name)
	if not self:timer_duration(name) then
		return 0
	end
	return ((self:timer_time_left(name) or 1) / (self:timer_duration(name)))
end

function GameObject:tick_timer_progress(name)
	if not self:tick_timer_duration(name) then
		return 0
	end
	return ((self:tick_timer_time_left(name) or 1) / (self:tick_timer_duration(name)))
end

function GameObject:timer_duration(name)
    return (self.timers and self.timers[name] and self.timers[name].duration) or nil
end

function GameObject:tick_timer_duration(name)
    return (self.tick_timers and self.tick_timers[name] and self.tick_timers[name].duration) or nil
end

function GameObject:stop_timer(name)
	if self.timers then
		self.timers[name] = nil
	end
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
	if self.tick_timers then
		self.tick_timers[name] = nil
	end
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

function GameObject:add_tag_on_enter(tag)
	self:add_enter_function(function() self:add_tag(tag) end)
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
	self.visible = false
	self:emit_signal("visibility_changed")
end

function GameObject:show()
	if self.visible then
		return
	end
	self.visible = true
	self:emit_signal("visibility_changed")
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

	love.graphics.translate(self.pos.x, self.pos.y + self.z_index)
	
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
                color = Color.darkergrey
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
--     -- 	z = z or (relative and (audio.default_z_index) or self.z_index + audio.default_z_index)
--     -- end
--     -- audio.set_src_position(t.src, x, y, z)
--     -- t.src:setPosition(x, y, z)
--     audio.play_sfx(t.src, volume or t.volume, pitch or t.pitch, loop or t.loop)
-- end

function GameObject:play_sfx(sfx_name, volume, pitch, loop, x, y, z)
	audio.play_sfx_object(self, sfx_name, volume, pitch, loop, self.canvas_layer)
    -- audio.play_sfx_monophonic(sfx_name, volume, pitch, loop)
end

function GameObject:play_sfx_if_stopped(sfx_name, volume, pitch, loop, x, y, z)
	audio.play_sfx_object_if_stopped(self, sfx_name, volume, pitch, loop, self.canvas_layer)
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

    if self.objects_bound_for_destruction then
        -- Create a copy to iterate over, as the table may be modified during iteration
        -- by the "destroyed" signal handlers.
        local to_destroy_copy = {}
        for obj, _ in pairs(self.objects_bound_for_destruction) do
            table.insert(to_destroy_copy, obj)
        end

        for _, obj in ipairs(to_destroy_copy) do
			if not obj.is_destroyed then
				obj:destroy()
			end
        end
    end
    self.objects_bound_for_destruction = nil

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
	signal.cleanup(self)



	-- nuclear debugging
    if debug.enabled then
        self:override_instance_metamethod("__index", destroyed_index_func)
	end
end

function GameObject:bind_destruction(obj)
    self.objects_bound_for_destruction = self.objects_bound_for_destruction or {}
    self.objects_bound_for_destruction[obj] = true
    signal.connect(obj, "destroyed", self, "on_object_to_destroy_destroyed_early", function()
		self.objects_bound_for_destruction[obj] = nil
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
    -- if not debug.enabled then
	-- 	if not signal.get(self, signal_name) then
	-- 		return
	-- 	end
	-- end
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
