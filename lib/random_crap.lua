---@diagnostic disable: lowercase-global

function UUID()
	local fn = function(x)
		local r = love.math.random(16) - 1
		r = (x == "x") and (r + 1) or (r % 4) + 9
		return ("0123456789abcdef"):sub(r, r)
	end
	return (("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", fn))
end

-- Removes all references to a module.
-- Do not call unrequire on a shared library based module unless you are 100% confidant that nothing uses the module anymore.
-- @param m Name of the module you want removed.
-- @return Returns true if all references were removed, false otherwise.
-- @return If returns false, then this is an error message describing why the references weren't removed.
function unrequire(m)
    package.loaded[m] = nil
    _G[m] = nil

    -- Search for the shared library handle in the registry and erase it
    local registry = debug.getregistry()
    local nMatches, mKey, mt = 0, nil, registry["_LOADLIB"]

    for key, ud in pairs(registry) do
        if type(key) == "string" and string.find(key, "LOADLIB: .*" .. m) and type(ud) == "userdata" and getmetatable(ud) == mt then
            nMatches = nMatches + 1
            if nMatches > 1 then
                return false, "More than one possible key for module '" .. m .. "'. Can't decide which one to erase."
            end

            mKey = key
        end
    end

    if mKey then
        registry[mKey] = nil
    end

    return true
end

function midpoint_circle(radius)
    resolution = resolution or 0

	local r2 = radius * radius

	local t = {}

    local x = -1
	local y = -radius
    while x <= -y do
		x = x + 1
        table.insert(t, x)
        table.insert(t, y)
		
		table.insert(t, -x)
        table.insert(t, y)
        
		table.insert(t, x)
        table.insert(t, -y)
        
		table.insert(t, -x)
        table.insert(t, -y)
		
		table.insert(t, y)
        table.insert(t, x)
		
        table.insert(t, -y)
        table.insert(t, x)
		
        table.insert(t, y)
        table.insert(t, -x)
		
        table.insert(t, -y)
        table.insert(t, -x)
		
		local ymid = (y + 0.5)
		
		if (x*x + ymid*ymid > r2) then
			y = y + 1
		end
	end

	return t
end

function neighbors(x, y)
    return {
        Vec2(x - 1, y),
        Vec2(x + 1, y),
        Vec2(x, y - 1),
        Vec2(x, y + 1),
        Vec2(x - 1, y - 1),
        Vec2(x + 1, y - 1),
        Vec2(x - 1, y + 1),
        Vec2(x + 1, y + 1),
    }
end

function frames_to_seconds(n)
	return n / ONE_SECOND
end

function seconds_to_frames(n)
	return n * ONE_SECOND
end

function frames_to_minutes(n)
	return (n / ONE_MINUTE)
end

function minutes_to_frames(n)
	return n * ONE_MINUTE
end

function xy_to_id(x, y, width)
    return ((y - 1) * width + (x - 1)) + 1
end

function id_to_xy(id, width)
	local x = (id - 1) % width + 1
	local y = math.floor((id - 1) / width) + 1
	return x, y
end

function xy_to_pairing(x, y)
    x = floor(x)
    y = floor(y)
    x = x >= 0 and (2 * x) or (-2 * x) - 1
    y = y >= 0 and (2 * y) or (-2 * y) - 1

    -- cantor pairing function
    local id = (x + y) * (x + y + 1) * 0.5 + y

    return id
end

function pairing_to_xy(id)
    -- Reverse the Cantor pairing function
    local t = math.floor((-1 + math.sqrt(1 + 8 * id)) * 0.5)
    local y = id - t * (t + 1) * 0.5
    local x = t - y

    -- Reverse the mapping for x and y
    x = (x % 2 == 0) and (x / 2) or -(x + 1) / 2
    y = (y % 2 == 0) and (y / 2) or -(y + 1) / 2

    return x, y
end

function world_to_room_id(x, y)
    return xy_to_pairing(x / conf.room_size.x, y / conf.room_size.y)
end

function world_to_room(x, y)
    return floor(x / conf.room_size.x), floor(y / conf.room_size.y)
end

function room_to_world(x, y)
    return x * conf.room_size.x, y * conf.room_size.y
end

function room_id_to_room(id)
	return pairing_to_xy(id)
end

function room_id_to_world(id)
    local rx, ry = pairing_to_xy(id)
	return room_to_world(rx, ry)
end

function flood_fill(x, y, fill, check_solid, force_first)
    local stack = { Vec2(x, y) }
	if force_first then
		local started = false
        while not table.is_empty(stack) do
            local coord = table.pop_front(stack)
            if (not started) or (not check_solid(coord.x, coord.y)) then
                started = true
                fill(coord.x, coord.y)
                table.insert(stack, coord + Vec2(-1, 0))
                table.insert(stack, coord + Vec2(1, 0))
                table.insert(stack, coord + Vec2(0, -1))
                table.insert(stack, coord + Vec2(0, 1))
            end
        end
		return
	end
	while not table.is_empty(stack) do
		local coord = table.pop_front(stack)
        if (not check_solid(coord.x, coord.y)) then
			fill(coord.x, coord.y)
			table.insert(stack, coord + Vec2(-1, 0))
			table.insert(stack, coord + Vec2(1, 0))
			table.insert(stack, coord + Vec2(0, -1))
			table.insert(stack, coord + Vec2(0, 1))
		end
	end
end

function bresenham_los_callback(x0, y0, x1, y1, callback)
    x0 = floor(x0)
    y0 = floor(y0)
    x1 = floor(x1)
    y1 = floor(y1)

    local sx, sy, dx, dy

    if x0 < x1 then
        sx = 1
        dx = x1 - x0
    else
        sx = -1
        dx = x0 - x1
    end

    if y0 < y1 then
        sy = 1
        dy = y1 - y0
    else
        sy = -1
        dy = y0 - y1
    end

    local err, e2 = dx - dy, nil

    if not callback(x0, y0) then return false end

    while not (x0 == x1 and y0 == y1) do
        e2 = err + err
        if e2 > -dy then
            err = err - dy
            x0  = x0 + sx
        end
        if e2 < dx then
            err = err + dx
            y0  = y0 + sy
        end
        if not callback(x0, y0) then return false end
    end

    return true
end

function identity_function(...)
    return ...
end

function dummy_function()
end

function bresenham_los(x0, y0, x1, y1, points)
	x0 = floor(x0)
	y0 = floor(y0)
	x1 = floor(x1)
	y1 = floor(y1)
	local sx, sy, dx, dy

	if x0 < x1 then
		sx = 1
		dx = x1 - x0
	else
		sx = -1
		dx = x0 - x1
	end

	if y0 < y1 then
		sy = 1
		dy = y1 - y0
	else
		sy = -1
		dy = y0 - y1
	end

    local err, e2 = dx - dy, nil
	
	table.insert(points, Vec2(x0, y0))

	while not (x0 == x1 and y0 == y1) do
		e2 = err + err
		if e2 > -dy then
			err = err - dy
			x0  = x0 + sx
		end
        if e2 < dx then
            err = err + dx
            y0  = y0 + sy
        end
		
		table.insert(points, Vec2(x0, y0))
	end
end

function bresenham_line(x0, y0, x1, y1, callback)
    x0 = floor(x0)
    y0 = floor(y0)
    x1 = floor(x1)
	y1 = floor(y1)
    local points = {}
    local count = 0
    if callback then
        local result = bresenham_los_callback(x0, y0, x1, y1, function(x, y)
            if callback and not callback(x, y) then return false end
            count = count + 1
            points[count] = Vec2(x, y)
            return true
        end)
        return points, result
    end
    bresenham_los(x0, y0, x1, y1, points)
    return points
end

function bresenham_line_iter(x0, y0, x1, y1)
	x0 = floor(x0)
	y0 = floor(y0)
	x1 = floor(x1)
	y1 = floor(y1)
    local sx, sy, dx, dy

    if x0 < x1 then
        sx = 1
        dx = x1 - x0
    else
        sx = -1
        dx = x0 - x1
    end

    if y0 < y1 then
        sy = 1
        dy = y1 - y0
    else
        sy = -1
        dy = y0 - y1
    end

    local err = dx - dy

    local current_x, current_y = x0, y0

    local done = false

    return function()
        if done then
            return nil
        end

        local px, py = current_x, current_y

        if current_x == x1 and current_y == y1 then
            done = true
        else
            local e2 = err * 2

            if e2 > -dy then
                err = err - dy
                current_x = current_x + sx
            end

            if e2 < dx then
                err = err + dx
                current_y = current_y + sy
            end
        end

        return px, py
    end
end

function xassert(a, ...)
	if a then return a, ... end
	local f = ...
	if type(f) == ___f then
	  local args = {...}
	  table.remove(args, 1)
	  error(f(table.fast_unpack(args)), 2)
	else
	  error(f or "assertion failed!", 2)
	end
end

function xtype(t)
	local s = type(t)
	if s == "table" and t.__type_name then return t.__type_name() end
	return s
end

function is_nan(number)
    return number ~= number and type(number) == "number"
end

local _16_way_temp = {1, 2, 3, 2}

function get_16_way_from_3_base_sprite(angle)
    -- assume texture 1 is pointing right, 2 is right and 22.5 degrees down, 3 is 45 degrees down

    angle = fposmod(angle, tau)      -- wrap angle into [0, tau)
    local step = angle / tau         -- fraction of the full circle
    local step_16 = round(step * 16) -- which of the 16 directions (0..15)
    local step_4 = round((step_16 - 2) / 4)

    local y_scale = 1

    -- pick the sprite index from a repeating pattern {1, 2, 3, 2}
    local index = _16_way_temp[(step_16) % 4 + 1]

    -- base rotation is quarter_tau * step_4
    local rotation = quarter_tau * step_4

    -- extra flip/rotation if step_16 mod 4 == 3
    if ((step_16 + 1) % 4 == 0) then
        rotation = rotation + quarter_tau
        y_scale = y_scale * -1
    end

    return index, rotation, y_scale
end

local _32_way_temp = {1, 2, 3, 4, 5, 4, 3, 2}

function get_32_way_from_5_base_sprite(angle)

    angle = fposmod(angle, tau)
    local step = angle / tau
    local step_32 = round(step * 32)
    local step_4 = floor((step_32) / 8)

    local y_scale = 1

	local table_index = (step_32) % 8 + 1
    
    local texture_index = _32_way_temp[table_index]

    local rotation = quarter_tau * (step_4)

    if (table_index > 5) then
		rotation = rotation + quarter_tau

        y_scale = y_scale * -1
    end

    return texture_index, rotation, y_scale
end


    -- if debug.enabled then
	-- 	local dir_x, dir_y = angle_to_vec2_unpacked(angle)
	-- 	print(string.format("step:%-2d step_4:%-2d step_8:%-2d step_32:%-2d dir_x:%-6.3f dir_y:%-6.3f angle:%-6.2f texture_index:%-2s rot:%-6.2f y_scale:%-2d",
	-- 		step,
	-- 		step_4,
	-- 		step_8,
	-- 		step_32,
	-- 		dir_x,
	-- 		dir_y, 
	-- 		rad2deg(angle),
	-- 		texture_index,
	-- 		rad2deg(rotation),
	-- 		y_scale))
	-- end

function asset_collision_error(name, path, existing_path)
    error(
    "asset with name " ..
    name ..
    " already exists. file IDs are generated from file paths, with slashes (/) replaced with underscores (_), so it is recommended to treat underscores as category separators. please rename one of the files: \n" ..
    path .. "\n" .. existing_path .. "\n", 2)
end

function comma_sep(number)

	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
  
	-- reverse the int-string and append a comma to all blocks of 3 digits
	int = int:reverse():gsub("(%d%d%d)", "%1,")
  
	-- reverse the int-string back remove an optional comma and put the 
	-- optional minus and fractional part back
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

function try_function(f, ...)
    if type(f) == "function" then
        return f(...)
    else
        return f
    end
end

dummy_table = setmetatable({}, {
    __index = function()
        return nil
    end,

	__newindex = function()
		error("attempt to write to dummy table")
	end
})


