local debuggy = setmetatable({}, { __index = debug })

debuggy.enabled = usersettings.debug_enabled
-- debuggy.enabled = true
debuggy.draw = false
debuggy.draw_bounds = false
debuggy.fast_forward = false
debuggy.frame_advance = false
debuggy.drawing_dt_history = true
debuggy.build_assets = true
debuggy.dt_history = {}
debuggy.dt_history_seconds = 1
debuggy.profiling = false
debuggy.disable_music = false
debuggy.lines = {}
debuggy.memory_used = 0
debuggy.skip_tutorial_sequence = false
debuggy.no_hatch_sound = false
debuggy.can_frame_advance = true
debuggy.slow_motion = false

local sorted_lines = {}
local lines_dirty = true

if IS_EXPORT then
	debuggy.enabled = false
end

function coroutine.xpcall(co, f)
	local output, err = coroutine.resume(co)
	if output == false then
		return false, err, debuggy.traceback(co)
	end
	return output, err
end

function debuggy.can_draw()
	return debuggy.enabled and debuggy.draw
end

function debuggy.can_draw_bounds()
	return debuggy.can_draw() and debuggy.draw_bounds
end

function debuggy.load()
    if not debuggy.enabled then return end
	if IS_EXPORT then return end
	if debuggy.build_assets then
		require("tools.palletizer")()
		graphics.load()
	end
end

function debuggy.printlines(x, y)
	graphics.push("all")
	local font = fonts["PixelOperator_double"]
	graphics.set_font(font)
	if not debuggy.can_draw() then
		graphics.pop()
		return
	end
	local line_height = font:getHeight() * 0.7

	if lines_dirty then
		table.clear(sorted_lines)
		for k, tab in pairs(debuggy.lines) do
			table.insert(sorted_lines, { k, tab })
		end
		table.sort(sorted_lines, function(a, b)
			local a_color = a[2][2] or Color.white
			local b_color = b[2][2] or Color.white

			if a_color == Color.white and b_color ~= Color.white then
				return false
			elseif a_color ~= Color.white and b_color == Color.white then
				return true
			end

			local a_h, a_s, a_l = a_color:to_hsl()
			local b_h, b_s, b_l = b_color:to_hsl()

			if a_h < b_h then
				return true
			elseif a_h > b_h then
				return false
			end

			if a_s < b_s then
				return true
			elseif a_s > b_s then
				return false
			end

			if a_l < b_l then
				return true
			elseif a_l > b_l then
				return false
			end

			return a[1] < b[1]
		end)
		lines_dirty = false
	end
	
	
    local counter = 0
	for i, line in pairs(sorted_lines) do
		local k, tab = line[1], line[2]
		local v, color = table.fast_unpack(tab)
		local string = string.format("%s: %s", k, v)
		local width = font:getWidth(string)
		graphics.set_color(0, 0, 0, 0.15)
		graphics.rectangle("fill", x, counter * line_height, width, line_height)
		counter = counter + 1
	end
	
	counter = 0
	for i, line in pairs(sorted_lines) do
		local k, tab = line[1], line[2]
		local v, color = table.fast_unpack(tab)

		graphics.set_color((color or Color.white), 0.75)
		if v == "" then
			graphics.print_outline(Color.black, k, x, counter * line_height)
			v = "nil"
		else
			local string = string.format("%s: %s", k, v)

			graphics.print_outline(Color.black, string, x, counter * line_height)
		end

		counter = counter + 1
	end
	graphics.pop()
end

local dt_history_points = {}
local memory_history_points = {}

function debuggy.draw_dt_history(width, height)
	graphics.push("all")
	if #debuggy.dt_history < 2 then
		return
	end

	table.clear(dt_history_points)

	local min_time = gametime.love_time - debuggy.dt_history_seconds
	local highest_dt = 1 / 60
	local reference_dt = 1 / 60
	local highest_memory_used = 128
	local reference_memory_used = 64

	for i = 1, #debuggy.dt_history do
		local dt = debuggy.dt_history[i]
		if dt.dt > highest_dt then
			highest_dt = dt.dt
		end

		if dt.memory_used > highest_memory_used then
			highest_memory_used = dt.memory_used
		end
	end

	for i = 1, #debuggy.dt_history - 1 do
		local dt = debuggy.dt_history[i]
		local next_dt = debuggy.dt_history[i + 1]
		local x = width * inverse_lerp(min_time, gametime.love_time, dt.time)
		local next_x = width * inverse_lerp(min_time, gametime.love_time, next_dt.time)
		local y = height - height * inverse_lerp(0, highest_dt, dt.dt)
		-- local next_y = height -height * inverse_lerp(0, highest_dt, next_dt.dt)
		dt_history_points[i * 4 - 3], dt_history_points[i * 4 - 2] = x, y
		dt_history_points[i * 4 - 1], dt_history_points[i * 4] = next_x, y

		local memory_used = dt.memory_used
		local next_memory_used = next_dt.memory_used
		local y = height - height * inverse_lerp(0, highest_memory_used, memory_used)
		-- local next_y = height -height * inverse_lerp(0, highest_memory_used, next_memory_used)
		memory_history_points[i * 4 - 3], memory_history_points[i * 4 - 2] = x, y
		memory_history_points[i * 4 - 1], memory_history_points[i * 4] = next_x, y
	end

	local reference_y = inverse_lerp(0, highest_dt, reference_dt) * height
	-- print(highest_dt)
	-- local function draw_lines(outline)

	graphics.set_line_width(2)

	graphics.set_color(Color.cyan)

	graphics.line(memory_history_points)


	graphics.set_color(Color.green)


	graphics.line(dt_history_points)



	graphics.set_color(Color.navyblue)
	graphics.line(0, 0, width, 0)
	graphics.line(0, height, width, height)

	graphics.set_color(Color.red)

	graphics.line(0, reference_y, width, reference_y)

	graphics.set_color(Color.magenta)

	graphics.line(0, reference_memory_used, width, reference_memory_used)


	-- end

	-- outline

	-- graphics.set_line_width(8)
	-- graphics.set_color(Color.black)

	-- graphics.line(dt_history_points)

	-- graphics.line(0, reference_y, width, reference_y)
	-- graphics.line(0, 0, width, 0)
	-- graphics.line(0, height, width, height)




	graphics.pop()
end

function debuggy.clear(key)
	key = key or nil
	if key then
		debuggy.lines[key] = nil
		lines_dirty = true
		return
	end
	debuggy.lines = {}
	lines_dirty = true
end

function debuggy.update(dt)
	if not debuggy.enabled then return end

	if input.debug_draw_toggle_pressed then
		debuggy.draw = not debuggy.draw
	end

	if input.debug_count_memory_pressed then
		filesystem.save_file(table.pretty_format(_G), "game_memory.txt")
		-- table.pretty_print(_G)
		table.pretty_print(debuggy.type_count())
		collectgarbage()
	end

	if input.debug_console_toggle_pressed then
		debuggy.toggle_console()
	end

	if input.debug_build_assets_pressed then
		require("tools.palletizer")()
	end

	if input.debug_profile_pressed then
		if debuggy.profiling then
			debuggy.profiling = false
			print(debuggy.profiler.report(100))
			debuggy.profiler.reset()
			debuggy.profiler.stop()
			debuggy.profiler = nil
			collectgarbage()
		else
			debuggy.profiler = require('profile')
			print("profiling started")
			debuggy.profiling = true
			debuggy.profiler.start()
		end
	end

	if input.debug_fixed_delta_toggle_pressed then
		conf.use_fixed_delta = not conf.use_fixed_delta
	end

    if input.debug_draw_bounds_toggle_pressed then
        debuggy.draw_bounds = not debuggy.draw_bounds
        debuggy.draw = true
    end
	
	if input.debug_turn_on_frame_advance_pressed and not debuggy.frame_advance and debuggy.can_frame_advance then
		debuggy.frame_advance = true
	elseif input.debug_turn_off_frame_advance_pressed and debuggy.frame_advance and debuggy.can_frame_advance then
		debuggy.frame_advance = false
	end

	if input.debug_toggle_slow_motion_pressed then
		debuggy.slow_motion = not debuggy.slow_motion
	end

	-- if input.debug_shader_toggle_pressed then
		-- usersettings.use_screen_shader = not usersettings.use_screen_shader
	-- end

	if input.debug_shader_preset_pressed then
		for i, shader_table in ipairs(graphics.screen_shader_presets) do
			if shader_table[1] == usersettings.screen_shader_preset then
				usersettings.screen_shader_preset = graphics.screen_shader_presets
					[((i) % #graphics.screen_shader_presets) + 1][1]
				graphics.set_screen_shader_from_preset(usersettings.screen_shader_preset)
				break
			end
		end
	end


	if input.debug_fast_forward_held then
		debuggy.fast_forward = true
	else
		debuggy.fast_forward = false
	end

	if input.debug_signal_snapshot_pressed then
		debuggy.snapshot_signals()
	end

	table.insert(debuggy.dt_history, {
		time = gametime.love_time,
		dt = gametime.love_delta,
		memory_used = debuggy.memory_used
	})

	local min_time = gametime.love_time - debuggy.dt_history_seconds
	local number_of_old_times_to_remove = 0

	if #debuggy.dt_history > 1 then
		for i = #debuggy.dt_history, 2, -1 do
			if debuggy.dt_history[i].time >= min_time and debuggy.dt_history[i - 1].time < min_time then
				number_of_old_times_to_remove = i - 1
				break
			end
		end
	end

	for i = number_of_old_times_to_remove, 1, -1 do
		table.remove(debuggy.dt_history, i)
	end
end

function debuggy.toggle_console()
	-- debuggy.console_open = not debuggy.console_open
end

function debuggy.count_all(f)
	local seen = {}

	local count_table
	count_table = function(t)
		if seen[t] then return end
		f(t)
		seen[t] = true
		for k, v in pairs(t) do
			if type(v) == "table" then
				count_table(v)
			elseif type(v) == "userdata" then
				f(v)
			end
		end
	end
	count_table(_G)
end

function debuggy.type_name(o)
	if Object.is(o, Object) then
		return (o.__type_name())
	end
	if global_type_table == nil then
		global_type_table = {}
		for k, v in pairs(_G) do
			global_type_table[v] = k
		end
		global_type_table[0] = "table"
	end
	return global_type_table[getmetatable(o) or 0] or "Unknown"
end

function debuggy.type_count(t, counted)
	counted = counted or {}
	local types = {}
	local biggest_guys = {}
	for k, v in pairs(t) do
		local type_name = type(v)
		types[type_name] = (types[type_name] or 0) + 1
		if type_name == "table" then
			if not counted[v] then
				counted[v] = true
				local sub_types = debuggy.type_count(v, counted)
				for sub_type_name, count in pairs(sub_types) do
					types[sub_type_name] = (types[sub_type_name] or 0) + count
				end
			end
		end
	end
	return types
end

function dbg(k, v, color)
	color = color or Color.white
	if not debuggy.enabled then return end
	if type(k) == "table" then
		for k2, v2 in pairs(k) do
			dbg(k2, v2)
		end
		return
	end
	if v == nil then
		v = ""
	end
	if not debuggy.lines[k] then
		lines_dirty = true
	end
	debuggy.lines[k] = debuggy.lines[k] or { v, color }
	debuggy.lines[k][1] = v
	debuggy.lines[k][2] = color
end

local signal_snapshot = nil

local function tostring_with_hash(val)
    if type(val) ~= "table" then
        return tostring(val)
    end

    local name = tostring(val)
    local success, mt = pcall(getmetatable, val)

    if success and mt and mt.__tostring then
        local original_tostring = mt.__tostring
        mt.__tostring = nil
        local hash = tostring(val)
        mt.__tostring = original_tostring
        if string.find(name, hash, 1, true) then
            return name
        end
        return string.format('%s (%s)', name, hash)
    else
        return name
    end
end

local function get_top_level_keys_as_set(t)
    local set = {}
    for k, _ in pairs(t) do
        set[tostring_with_hash(k)] = true
    end
    return set
end

local function print_sorted_diff(title, diff_table)
    local keys = {}
    for k in pairs(diff_table) do
        table.insert(keys, k)
    end
    table.sort(keys)

    if #keys > 0 then
        print(title)
        for _, k in ipairs(keys) do
            local v = diff_table[k]
            if v.added then
                print("  + " .. k)
            elseif v.removed then
                print("  - " .. k)
            end
        end
    end
end

function debuggy.snapshot_signals()
    if not signal_snapshot then
        print("Taking initial signal snapshot...")
        signal_snapshot = {
            emitters = get_top_level_keys_as_set(signal.emitters),
            listeners = get_top_level_keys_as_set(signal.listeners)
        }
        print("Snapshot taken.")
        return
    end

    print("Comparing with previous signal snapshot...")
    local new_snapshot = {
        emitters = get_top_level_keys_as_set(signal.emitters),
        listeners = get_top_level_keys_as_set(signal.listeners)
    }

    local emitters_diff = table.diff(signal_snapshot.emitters, new_snapshot.emitters)
    local listeners_diff = table.diff(signal_snapshot.listeners, new_snapshot.listeners)

    if not next(emitters_diff) and not next(listeners_diff) then
        print("No changes in signals.")
    else
        print_sorted_diff("--- Emitters Diff ---", emitters_diff)
        print_sorted_diff("--- Listeners Diff ---", listeners_diff)
    end

    signal_snapshot = new_snapshot
    print("New snapshot taken.")
end

return debuggy
