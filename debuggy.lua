local debuggy = setmetatable({}, {__index = debug})

debug.enabled = usersettings.debug_enabled
debug.draw = false
debug.draw_bounds = false
debug.build_assets = true
debug.lines = {}
debug.profiling = false

if IS_EXPORT then
	debug.enabled = false
end

function coroutine.xpcall(co, f)
	local output, err = coroutine.resume(co)
	if output == false then
	  return false, err, debug.traceback(co)
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
	if not debug.enabled then return end
    if debug.build_assets then
        require("tools.palletizer")()
        graphics.load()
    end
end


function debuggy.printlines(line, x, y)
	graphics.set_font(graphics.font["PixelOperator-Bold"])
	if not debuggy.can_draw() then
		return
	end
    local counter = 0

	
	for k, v in pairs(debuggy.lines) do
        if v == "" then

			graphics.print_outline(Color.black, k, x, counter * 12)
			v = "nil"
		else
			local string = string.format("%s: %s", k, v)

            graphics.print_outline(Color.black, string, x, counter * 12)

		end

		counter = counter + 1
	end

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
    if not debug.enabled then return end
	
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
		if debug.profiling then
			debug.profiling = false
			print(debug.profiler.report(100))
			debug.profiler.reset()
            debug.profiler.stop()
            debug.profiler = nil
			collectgarbage()
        else
			debug.profiler = require('profile')
			print("profiling started")
			debug.profiling = true
			debug.profiler.start()
		end
	end
	
    if input.debug_fixed_delta_toggle_pressed then
        conf.use_fixed_delta = not conf.use_fixed_delta
    end
	
	if input.debug_draw_bounds_toggle_pressed then
		debug.draw_bounds = not debug.draw_bounds
		debuggy.draw = true
	end

	if input.debug_shader_toggle_pressed then 
		usersettings.use_screen_shader = not usersettings.use_screen_shader
	end

	if input.debug_shader_preset_pressed then
		for i, shader_table in ipairs(graphics.screen_shader_presets) do
			if shader_table[1] == usersettings.screen_shader_preset then
				usersettings.screen_shader_preset = graphics.screen_shader_presets[((i) % #graphics.screen_shader_presets) + 1][1]
				graphics.set_screen_shader_from_preset(usersettings.screen_shader_preset)
				break
			end
		end
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
		for k,v in pairs(t) do
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
		for k,v in pairs(_G) do
			global_type_table[v] = k
		end
		global_type_table[0] = "table"
	end
	return global_type_table[getmetatable(o) or 0] or "Unknown"
end

function debuggy.type_count()
	local counts = {}
	local enumerate = function (o)
		local t = debuggy.type_name(o)
		counts[t] = (counts[t] or 0) + 1
	end
	debuggy.count_all(enumerate)
	return counts
end


function dbg(k, v)
	if not debug.enabled then return end
	if type(k) == "table" then
		for k2, v2 in pairs(k) do
			dbg(k2, v2)
		end
		return
	end
	if v == nil then
		v = ""
	end
	debuggy.lines[k] = v
end

return debuggy
