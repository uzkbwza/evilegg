local debuggy = setmetatable({}, { __index = debug })

debuggy.enabled = usersettings.debug_enabled
debuggy.draw = false
debuggy.draw_bounds = false
debuggy.fast_forward = false
debuggy.drawing_dt_history = true
debuggy.build_assets = true
debuggy.dt_history = {}
debuggy.dt_history_seconds = 1
debuggy.profiling = false
debuggy.disable_music = false
debuggy.lines = {}
debuggy.memory_used = 0

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
	if debuggy.build_assets then
		require("tools.palletizer")()
		graphics.load()
	end
end

function debuggy.printlines(line, x, y)
	graphics.push("all")
	local font = fonts["PixelOperator-double"]
	graphics.set_font(font)
	if not debuggy.can_draw() then
		graphics.pop()
		return
	end
	local line_height = font:getHeight() * 0.7
	
	
    local counter = 0
    for k, tab in pairs(debuggy.lines) do
		local string = string.format("%s: %s", k, tab[1])
		local width = font:getWidth(string)
		graphics.set_color(0, 0, 0, 0.5)
		graphics.rectangle("fill", x, counter * line_height, width, line_height)
		counter = counter + 1
	end
	
	counter = 0
	for k, tab in pairs(debuggy.lines) do
        local v, color = unpack(tab)

		graphics.set_color(color or Color.white)
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
		return
	end
	debuggy.lines = {}
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

	if input.debug_shader_toggle_pressed then
		usersettings.use_screen_shader = not usersettings.use_screen_shader
	end

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

	table.insert(debuggy.dt_history, {
		time = gametime.love_time,
		dt = gametime.love_delta,
		memory_used = debuggy.memory_used
	})

	local min_time = gametime.love_time - debuggy.dt_history_seconds
	local number_of_old_times_to_remove = 0
	-- local interpolated_dt = nil

	if #debuggy.dt_history > 1 then
		for i = #debuggy.dt_history, 2, -1 do
			if debuggy.dt_history[i].time >= min_time and debuggy.dt_history[i - 1].time < min_time then
				-- local this_time = debuggy.dt_history[i].time
				-- local last_time = debuggy.dt_history[i - 1].time
				-- local this_dt = debuggy.dt_history[i].dt
				-- local last_dt = debuggy.dt_history[i - 1].dt

				-- interpolated_dt = {time = min_time, dt = lerp(last_dt, this_dt, inverse_lerp(last_time, this_time, min_time))}
				number_of_old_times_to_remove = i - 1
				break
			end
		end
	end

	for i = number_of_old_times_to_remove, 1, -1 do
		table.remove(debuggy.dt_history, i)
	end

	-- if interpolated_dt then
	-- 	table.insert(debuggy.dt_history, 1, interpolated_dt)
	-- end
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

function debuggy.type_count()
	local counts = {}
	local enumerate = function(o)
		local t = debuggy.type_name(o)
		counts[t] = (counts[t] or 0) + 1
	end
	debuggy.count_all(enumerate)
	return counts
end

function dbg(k, v, color)
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
	debuggy.lines[k] = debuggy.lines[k] or { v, color }
	debuggy.lines[k][1] = v
	debuggy.lines[k][2] = color
end

return debuggy
