---@class GameObject : Object
local GameObject = Object:extend("GameObject")
local SoundPool = require("lib.sound")

GameObject.DEFAULT_DRAW_CULL_DIST = 32

function GameObject:new(x, y)

	self:add_signal("destroyed")
    self:add_signal("moved")
	self:add_signal("update_changed")
    self:add_signal("visibility_changed")

	if x then
		if type(x) == "table" then
			self.pos = Vec2(x.x, x.y)
		else
			self.pos = Vec2(x, y)
		end
	else
		self.pos = Vec2(0, 0)
	end

	self.rot = 0
	self.scale = Vec2(1, 1)
	
	self._update_functions = nil
	self._draw_functions = nil
	
	self.world = nil

	self.draw_cull_dist = nil
	
	self.visible = true
	
	self.static = false
		
	self.z_pos = 0

end

function GameObject:get_draw_rect(get_draw_pos)
    local cull_dist = self.draw_cull_dist or GameObject.DEFAULT_DRAW_CULL_DIST
	local posx, posy = get_draw_pos(self)
	return posx - cull_dist / 2, posy - cull_dist / 2, cull_dist, cull_dist
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


-- references to other objects, automatically unrefs when object is destroyed
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

function GameObject:add_sequencer()
	if self.sequencer then return end
	assert(self.sequencer == nil, "GameObject:add_sequencer() called but sequencer already exists")
	self.sequencer = Sequencer()
	self:add_update_function(function(obj, dt) obj.sequencer:update(dt) end)
end

function GameObject:add_elapsed_time()
	if self.elapsed ~= nil then return end
	self.elapsed = 1
	self:add_update_function(function(obj, dt) obj.elapsed = obj.elapsed + dt end)
end

function GameObject:add_elapsed_ticks()
	if self.tick ~= nil then return end

	if self.elapsed == nil then 
		self:add_elapsed_time()
	end
	self.tick = 1
	self:add_update_function(
        function(obj, dt)
			self.is_new_tick = false
			local old = obj.tick
            obj.tick = floor(obj.elapsed)
			if obj.tick ~= old then
				self.is_new_tick = true
			end
	end)
end

function GameObject:add_update_function(func)
	if self._update_functions == nil then
		self._update_functions = {}
	end
	table.insert(self._update_functions, func)
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

function GameObject:timer_running(name)
    return self.timers and self.timers[name] ~= nil
end

function GameObject:stop_timer(name)
	self.timers[name] = nil
end

function GameObject:start_timer(name, duration, callback)
    if callback == nil and type(name) == "number" then
		callback = duration
        duration = name
        name = self.timers and #self.timers + 1 or 1
	end
	
    if self.timers == nil then
        self.timers = {}
        self:add_update_function(function(obj, dt)
            for k, v in pairs(obj.timers) do
                v.elapsed = v.elapsed + dt
                if v.elapsed >= v.duration then
					obj.timers[k] = nil
                    if v.callback then
                        v.callback(obj)
                    end
                end
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

function GameObject:move_toward(x, y, speed)
	local dx, dy = x - self.pos.x, y - self.pos.y
	local dist = sqrt(dx * dx + dy * dy)
	if dist < speed then
		self:move_to(x, y)
	else
		self:move(dx / dist * speed, dy / dist * speed)
	end
end
	

---@diagnostic disable-next-line: duplicate-set-field
function GameObject:move_to(x, y)
	local old_x = self.pos.x
	local old_y = self.pos.y

	self.pos.x = x
	self.pos.y = y

	if old_x ~= self.pos.x or old_y ~= self.pos.y then
		self:on_moved()
	end
end

function GameObject:movev_to(v)
	self:move_to(v.x, v.y)
end

function GameObject:tp(x, y, ...)
    self:move_to(self.pos.x + x, self.pos.y + y, nil, true, ...)
end

function GameObject:tp_to(x, y, ...)
	-- old method from when interpolation was used
	self:move_to(x, y, nil, true, ...)
end

function GameObject:tpv_to(v)
	self:tp_to(v.x, v.y)
end


function GameObject:set_update(on)
	self.static = not on
	self:emit_signal("update_changed")
end

function GameObject:update(dt, ...)
end

function GameObject:graphics_transform(translate_offs_x, translate_offs_y)
    translate_offs_x = translate_offs_x or 0
	translate_offs_y = translate_offs_y or 0
	-- using the api here directly because it's faster
	local pos = self.pos
    local scale = self.scale

	-- love.graphics.translate(pos.x + translate_offs_x, pos.y + self.z_pos + translate_offs_y)
	love.graphics.translate(round(pos.x + translate_offs_x), round(pos.y + self.z_pos + translate_offs_y))
	love.graphics.rotate(self.rot)
	love.graphics.scale(scale.x, scale.y)
	love.graphics.setColor(1, 1, 1, 1)
end

function GameObject:draw_shared(...)

	love.graphics.push()
	
	local offsx, offsy = self:get_draw_offset()
	self:graphics_transform(offsx, offsy)
    

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

	self:graphics_transform()

	if self.debug_draw then self:debug_draw(...) end

	love.graphics.pop()
end

function GameObject:debug_draw_bounds_shared()
	love.graphics.push()

	love.graphics.translate(self.pos.x, self.pos.y + self.z_pos)
	
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

function GameObject:play_sfx(sfx_name, volume, pitch, loop, x, y, z)
    local t = self.sfx[sfx_name]
    -- local relative = t.src:isRelative()
    t.src:stop()
    -- x = x or (relative and (0) or self.pos.x)
    -- y = y or (relative and (0) or self.pos.y)
    -- z = z or (relative and (audio.default_z_pos) or self.z_pos + audio.default_z_pos)
    -- audio.set_src_position(t.src, x, y, z)
    -- t.src:setPosition(x, y, z)
    audio.play_sfx(t.src, volume or t.volume, pitch or t.pitch, loop or t.loop)
end

function GameObject:get_sfx(sfx_name)
	return self.sfx[sfx_name].src
end

function GameObject:stop_sfx(sfx_name)
	self.sfx[sfx_name].src:stop()
end

local destroyed_index_func = function(t, k)
	if t == "is_destroyed" then
		return true
	end
	error("attempt to access variable of destroyed object")
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
end

function GameObject:to_local(pos_x, pos_y)
	return pos_x - self.pos.x, pos_y - self.pos.y
end

function GameObject:to_global(pos_x, pos_y)
	return pos_x + self.pos.x, pos_y + self.pos.y
end

function GameObject:add_signal(signal_name)
	signal.register(self, signal_name)
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

return GameObject
