local tabley = setmetatable({}, {__index = table})

require "table.clear"
require "table.new"

function tabley.length (t)
    local count = 0
    local next = next
    local key, _ = next(t)
    while key do
        count = count + 1
        key, _ = next(t, key)
    end
    return count
end

function tabley.find(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
end

function tabley.filtered_keys(t, fn)
    local filtered = {}
    for k, v in pairs(t) do
        if fn(k) then
            filtered[k] = v
        end
    end
    return filtered
end

function tabley.filtered_values(t, fn)
    local filtered = {}
    for k, v in pairs(t) do
        if fn(v) then
            filtered[k] = v
        end
    end
    return filtered
end

function tabley.filtered(t, fn)
    local filtered = {}
    for k, v in pairs(t) do
        if fn(v) then
            table.insert(filtered, v)
        end
    end
	return filtered
end

function tabley.shuffle(t)
    local n = #t
    for i = n, 2, -1 do
        local j = rng(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

function tabley.equal(t1, t2)
	if type(t1) ~= type(t2) then return false end
	if type(t1) == "table" then
		for k, v in pairs(t1) do
			if not tabley.equal(v, t2[k]) then return false end
		end
	end
	return t1 == t2
end

function tabley.push_back(t, value)
  table.insert(t, value)
end

function tabley.pop_back(t)
  return table.remove(t)
end

function tabley.push_front(t, value)
  table.insert(t, 1, value)
end

function tabley.pop_front(t)
    return table.remove(t, 1)
end

function tabley.keys(tab)
    local keys = {}
    local next = next
    local key, _ = next(tab)
    while key do
        table.insert(keys, key)
        key, _ = next(tab, key)
    end
	return keys
end

function tabley.values(tab)
	local values = {}
    local next = next
    local key, value = next(tab)
    while key do
        table.insert(values, value)
		key, value = next(tab, key)
	end
	return values
end

function tabley.keys_and_values(tab)
    local keys = {}
    local values = {}
    local next = next
    local key, value = next(tab)

    while key do
        table.insert(keys, key)
        table.insert(values, value)
        key, value = next(tab, key)
    end

    return keys, values
end

function tabley.map_array(tab, f)
    local new_tab = {}
    for i = 1, #tab do
        table.insert(new_tab, f(tab[i]))
    end
	return new_tab
end

-- function tabley.clear(t)
--     local next = next
--     local i, _ = next(t)
--     while i do
--         t[i] = nil
--         i, _ = next(t)
--     end
-- end

---@overload fun(t: table, startx: number, starty: number, endx: number, endy: number)
---@param t table
---@param startx number
---@param starty number
---@param startz number
---@param endx number
---@param endy number
---@param endz number
function tabley.query_region(t, startx, starty, startz, endx, endy, endz, manipulate_coords, manipulate_object)
    manipulate_coords = manipulate_coords or identity_function
	manipulate_object = manipulate_object or identity_function
    if endy == nil then
        -- 2D case
        endy = endx
        endx = startz
        local state = { x = startx, y = starty }
        return function()
            while state.y <= endy do
                local row = t[state.y]
                if row then
                    while state.x <= endx do
                        local tile = row[state.x]
                        local x = state.x
                        state.x = state.x + 1
                        if tile then
							local x_, y_ = manipulate_coords(x, state.y)
                            return x_, y_, manipulate_object(tile)
                        end
                    end
                end
                state.x = startx
                state.y = state.y + 1
            end
        end
    else
        -- 3D case
        local state = { x = startx, y = starty, z = startz }
        return function()
            while state.z <= endz do
                local layer = t[state.z]
                if layer then
                    while state.y <= endy do
                        local row = layer[state.y]
                        if row then
                            while state.x <= endx do
                                local tile = row[state.x]
                                local x = state.x
                                state.x = state.x + 1
                                if tile then
									local x_, y_, z_ = manipulate_coords(x, state.y, state.z)
                                    return x_, y_, z_, manipulate_object(tile)
                                end
                            end
                        end
                        state.x = startx
                        state.y = state.y + 1
                    end
                end
                state.x = startx
                state.y = starty
                state.z = state.z + 1
            end
        end
    end
end

function tabley.push(t, value)
  table.insert(t, value)
end

function tabley.pop(t)
  return table.remove(t)
end

function tabley.list_has(t, value)
    for i, v in ipairs(t) do
		if v == value then 
			return true
		end
	end
end

function tabley.search_list(t, value)
    for i, v in ipairs(t) do
		if v == value then 
			return i
		end
	end
end

function tabley.is_empty(t)
	local next = next
	return next(t) == nil
end

function tabley.diff(t1, t2)
    local diff = {}
    local keys = {}
    for k in pairs(t1) do keys[k] = true end
    for k in pairs(t2) do keys[k] = true end

    for k in pairs(keys) do
        local v1 = t1[k]
        local v2 = t2[k]
        if v1 == nil and v2 ~= nil then
            diff[k] = { added = v2 }
        elseif v2 == nil and v1 ~= nil then
            diff[k] = { removed = v1 }
        elseif type(v1) == "table" and type(v2) == "table" then
            local sub_diff = tabley.diff(v1, v2)
            if next(sub_diff) then
                diff[k] = sub_diff
            end
        elseif v1 ~= v2 then
            diff[k] = { from = v1, to = v2 }
        end
    end
    return diff
end

function tabley.get_by_path(t, str)
	return tabley.get_recursive(t, unpack(string.split(str, ".")))
end

function tabley.sorted(t, sort)
	local sorted = {}
	for _, v in ipairs(t) do
		table.insert(sorted, v)
	end
	table.sort(sorted, sort)
	return sorted
end

function tabley.deepcopy(orig, copies)
	local orig_type = type(orig)
	
	
    local copy = orig
    if orig_type == 'table' then
		copies = copies or {}
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[tabley.deepcopy(orig_key, copies)] = tabley.deepcopy(orig_value, copies)
            end
            setmetatable(copy, tabley.deepcopy(getmetatable(orig), copies))
        end
    end
    return copy
end

function tabley.copy(t)
    local next = next
    local copy = {}
	local key, value = next(t)
	while key do
		copy[key] = value
		key, value = next(t, key)
	end
	return copy
end

function tabley.pretty_format(t, max_depth)
    max_depth = max_depth or math.huge
    local str = ""
    local function print(s)
        s = s or ""
        str = str .. s .. "\n"
    end
    local print_r_cache = {}

    local function to_string(value)
		if type(value) == "table" then
			if Object.is(value, Object) then
				return value.__class_type_name
			end
		end
		return tostring(value)
	end
    local function sub_print_r(t, indent, depth)
        depth = depth or 0
        if depth >= max_depth then
            print(indent .. "...")
            return
        end
        if (print_r_cache[to_string(t)]) then
            print(indent .. "*" .. to_string(t))
        else
            print_r_cache[to_string(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    pos = to_string(pos)
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] => " .. to_string(t) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8), depth + 1)
                        print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    elseif (type(val) == "string") then
                        print(indent .. "[" .. pos .. '] => "' .. val .. '"')
                    else
                        print(indent .. "[" .. pos .. "] => " .. to_string(val))
                    end
                end
            else
                print(indent .. to_string(t))
            end
        end
    end
    if (type(t) == "table") then
        print(to_string(t) .. " {")
        sub_print_r(t, " ")
        print("}")
    else
        sub_print_r(t, " ")
    end
    print()
    return str
end

function tabley.get_recursive(t, ...)
	local keys = { ... }
	local t_ = t
	local len = #keys
	local value = nil
	for i=1, len do
		local key = keys[i]
		value = t_[key]
		if value == nil then return nil	end
		if i < len then 
			if type(value) == "table" then
				t_ = value
			else
				error("Invalid table index: " .. key)
			end 
		end
	end
	return value
end

function tabley.pretty_print(t, max_depth, fd)
    max_depth = max_depth or math.huge
    fd = fd or io.stdout
    local function print(str)
        str = str or ""
        fd:write(str .. "\n")
    end
    local print_r_cache = {}

	local function to_string(value)
		if type(value) == "table" then
			if Object.is(value, Object) then
				return value.__class_type_name
			end
		end
		return tostring(value)
	end

    local function sub_print_r(t, indent, depth)
        depth = depth or 0
        if depth >= max_depth then
            print(indent .. "...")
            return
        end
        if (print_r_cache[to_string(t)]) then
            print(indent .. "*" .. to_string(t))
        else
            print_r_cache[to_string(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    pos = to_string(pos)
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] => " .. to_string(t) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8), depth + 1)
                        print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    elseif (type(val) == "string") then
                        print(indent .. "[" .. pos .. '] => "' .. val .. '"')
                    else
                        print(indent .. "[" .. pos .. "] => " .. to_string(val))
                    end
                end
            else
                print(indent .. to_string(t))
            end
        end
    end
    if (type(t) == "table") then
        print(to_string(t) .. " {")
        sub_print_r(t, "  ")
        print("}")
    else
        sub_print_r(t, "  ")
    end
    print()
end

function tabley.extend(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

function tabley.merge(t1, t2, overwrite)
    for k, v in pairs(t2) do
        if overwrite or t1[k] == nil then
            t1[k] = v
        end
    end
end

function tabley.merged(t1, t2, overwrite)
	local t = {}
	if t1 == nil then t1 = {} end
	if t2 == nil then t2 = {} end
	tabley.merge(t, t1, overwrite)
	tabley.merge(t, t2, overwrite)
	return t
end

function tabley.serialize(t, indent, start)
    if start == nil then start = true end
    indent = indent or ""
    local serialized = (start and "return " or "") .. "{\n"
    local next_indent = indent .. "\t"

    for key, value in pairs(t) do
        local formatted_key
        if type(key) == "string" then
            formatted_key = string.format("[%q]", key)
        else
            formatted_key = "[" .. tostring(key) .. "]"
        end

        if type(value) == "table" then
            local format_func = value.__table_format
            if format_func then
                local output = (format_func(value, next_indent))
                if type(output) == "string" then
                    serialized = serialized .. next_indent .. formatted_key .. " = " .. (output) .. ",\n"
                elseif type(output) == "table" then
                    -- Always serialize the full table, even if repeated
                    serialized = serialized ..
                        next_indent .. formatted_key .. " = " .. tabley.serialize(output, next_indent, false) .. ",\n"
                else 
                    serialized = serialized .. next_indent .. formatted_key .. " = " .. tostring(output) .. ",\n"
                end
            else
                -- Always serialize the full table, even if repeated
                serialized = serialized .. next_indent .. formatted_key .. " = " .. tabley.serialize(value, next_indent, false) .. ",\n"
            end
        elseif type(value) == "string" then
            serialized = serialized .. next_indent .. formatted_key .. " = " .. string.format("%q", value) .. ",\n"
        else
            serialized = serialized .. next_indent .. formatted_key .. " = " .. tostring(value) .. ",\n"
        end
    end

    serialized = serialized .. indent .. "}"
    return serialized
end

function tabley.deserialize(str)
    return assert(loadstring(str))()
end

function tabley.populate_recursive(tab, ...)
    local t = tab
    local keys = { ... }

    if #keys < 1 then
        return t
	end

    if #keys == 1 then
		t[keys[1]] = t[keys[1]] or true
		return t[keys[1]]
	end

    for i = 1, #keys - 2 do
        local key = keys[i]
        t[key] = t[key] or {}
        t = t[key]
    end
	local key = keys[#keys - 1]
	local lastkey = keys[#keys]
	t[key] = t[key] or lastkey
	return t[key]
end

function tabley.populate_recursive_from_table(tab, keys)
    local t = tab

    if #keys < 1 then
        return t
	end

    if #keys == 1 then
		t[keys[1]] = t[keys[1]] or true
		return t[keys[1]]
	end

    for i = 1, #keys - 2 do
        local key = keys[i]
        t[key] = t[key] or {}
        t = t[key]
    end
	local key = keys[#keys - 1]
	local lastkey = keys[#keys]
	t[key] = t[key] or lastkey
	return t[key]
end

function tabley.overwrite_recursive(tab, ...)
	local t = tab
    local keys = { ... }

    if #keys < 1 then
        return
	end

    if #keys == 1 then
        t[keys[1]] = true
        return t[keys[1]]
    end
	
    for i = 1, #keys - 2 do
        local key = keys[i]
        t[key] = {}
        t = t[key]
    end
	
	local key = keys[#keys - 1]
	local lastkey = keys[#keys]
    t[key] = lastkey
	return t[key]
end

function tabley.fast_remove_at(t, index)
    local length = #t
    t[index] = t[length]
    t[length] = nil
end

function tabley.erase(t, item)
    local n = #t
	
    for i = 1, n do
        if item == t[i] then
            t[i] = t[n]
			t[n] = nil
			return true
		end
	end
	return false
end

function tabley.fast_remove(t, fnKeep)
    if type(fnKeep) == "number" then return tabley.fast_remove_at(t, fnKeep) end

    if tabley.is_empty(t) then return t end

    local j, n = 1, #t;

    for i = 1, n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end

function tabley.slice(t, start, end_)
    local slice = {}
    for i = start or 1, end_ or #t do
        slice[i] = t[i]
    end
    return slice
end


local unpack_functions = {}

function tabley.fast_unpack(t)
    local n = #t
	if n == 0 then return nil end
    local func = unpack_functions[n]
    if func then
        return func(t)
    end
    return unpack(t)
end

if debug.enabled then
	function tabley.fast_unpack(t)
        local n = #t
		if n == 0 then return nil end
		local func = unpack_functions[n]
        if func then
            return func(t)
        end
		error("no fast unpack function found for " .. n .. " elements")
	end
end

local concat = table.concat
local loadstring = loadstring
function createunpack(n)
	local ret = {"local t = ...; return "}
    for k = 1, n do
        ret[#ret + 1] = "t[" .. k .. "]"
        if k ~= n then
            ret[#ret + 1] = ", "
        end
    end
    local output = concat(ret)
	return assert(loadstring(output))
end

for i = 1, 248 do
	local func = createunpack(i)
    unpack_functions[i] = func
end

function tabley.interpolate_index(t, ratio)
    ratio = clamp(ratio, 0, 1)
    local n = #t - 1
    local index = 1 + round(n * ratio)
    return index
end

function tabley.interpolate(t, ratio)
    ratio = clamp(ratio, 0, 1)
    local n = #t - 1
    local index = 1 + round(n * ratio)
    return t[index]
end

function tabley.get_circular(t, index)
    return t[((index - 1) % #t) + 1]
end

function tabley.get_circular_index(t, index)
    return ((index - 1) % #t) + 1
end

-- local fast_unpack = tabley.fast_unpack
-- local unpack = unpack

-- local tabs = {}

-- local num_tables = 1000000

-- for i = 1, num_tables do
--     local tab = { "a", "b", {}, true, false, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, "a", "b", tab2, true, false, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
--     local tab2 = {}
-- 	local len = 10
--     for i = 1, len do
-- 		table.insert(tab2, tab[love.math.random(1, #tab)])
-- 	end

-- 	table.insert(tabs, tab)
-- end

-- local time = love.timer.get_time()
-- for i = 1, num_tables do
--     local a, b, c = fast_unpack(tabs[i])
-- end 
-- print(love.timer.get_time() - time)

-- time = love.timer.get_time()
-- for i = 1, num_tables do
-- 	local a, b, c = unpack(tabs[i])
-- end
-- print(love.timer.get_time() - time)

return tabley

