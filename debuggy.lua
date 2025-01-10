local debuggy = setmetatable({}, {__index = debug})

debug.enabled = usersettings.debug_enabled
debug.draw = true
debug.build_assets = true
debug.lines = {}

if IS_EXPORT then
	debug.enabled = false
end

function debuggy.can_draw()
	return debuggy.enabled and debuggy.draw
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
	end

	if input.debug_console_toggle_pressed then
		debuggy.toggle()
	end

	if input.debug_build_assets_pressed then
		require("tools.palletizer")()
	end
	-- if input.debug_shader_toggle_pressed then 
	-- 	usersettings.use_screen_shader = not usersettings.use_screen_shader
	-- end
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
