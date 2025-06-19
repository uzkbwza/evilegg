---@diagnostic disable: lowercase-global
local string = require "lib.stringy"

function process_keys(tab, process_func, ...)

    local args = { ... }

    if #args == 0 then
        args = { "string", "number", "function", "boolean", "userdata", "thread" }
    end
	
    local type_map = {}
	
    for i = 1, #args do
		type_map[args[i]] = true
	end

    local tab_cache = {tab}
    local tab_stack = {tab}
	
    while #tab_stack > 0 do
		local new_keys = {}
		local top = table.remove(tab_stack)
    	for k, v in pairs(top) do
            if type(v) == "table" then
				if not tab_cache[v] then 
                    table.insert(tab_stack, v)
					tab_cache[v] = true
				end
			elseif type(k) == "string" and type_map[type(v)] then
				local kk = process_func(k)
				if top[kk] == nil then
					new_keys[kk] = v
				end
			end
        end
	
		for k, v in pairs(new_keys) do
			top[k] = v
		end
    end
	
	return tab
end

function snakeify(tab, ...)
    process_keys(tab, string.camelCase2snake_case, ...)
end

function kebabify(tab, ...)
    process_keys(tab, function(k) return k:lower():gsub("_", "-") end, ...)
end

function snakebabify(tab, ...)
    snakeify(tab, ...)
	if conf.use_fennel then
		kebabify(tab, ...)
	end
end

function function_style_key_process(tab)
	snakebabify(tab, "function")
end

-- local oldrequire = require
-- function require(name)

--     local mod = oldrequire(name)

--     if type(mod) == "table" then
-- 		if name == "graphics" then 
-- 			print"hi" 
-- 		end
--         function_style_key_process(mod)
--     end
	
-- 	return mod
-- end

