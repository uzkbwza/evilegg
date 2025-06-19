-- local function select_test(...)
-- 	for i = 1, select("#", ...) do
-- 		local value = select(i, ...)
-- 		print(value)
-- 	end
-- end

-- local function create_bind(n)
-- 	local args = {}
-- 	for k = 1, n do
-- 		args[k] = "arg" .. k
-- 		if k ~= n then
-- 			args[k] = args[k] .. ", "
-- 		end
-- 	end

-- 	local args_string = table.concat(args)
-- 	-- print(args_string)

-- 	local output = string.format("function bind%s(f, %s)\n\treturn function(...)\n\t\treturn f(%s, ...)\n\tend\nend", n, args_string, args_string)

-- 	print(output, "\n")
-- end

-- create bind functions
-- for i = 1, 59 do
-- 	create_bind(i)
-- end

-- local function create_curry(n)
-- 	local args = {}
-- 	local args_no_comma = {}
-- 	for k = 1, n do
-- 		args[k] = "arg" .. k
-- 		args_no_comma[k] = args[k]
-- 		if k ~= n then
-- 			args[k] = args[k] .. ", "
-- 		end
-- 	end

-- 	local args_string = table.concat(args)
-- 	-- print(args_string)
-- 	local ret = { string.format("function curry%s(f)", n) }
		
-- 	for i = 1, n do
-- 		table.insert(ret, "\n")
-- 		table.insert(ret, string.rep(" ", i))
-- 		table.insert(ret, string.format("return function(%s%s)", args_no_comma[i], n == i and ", ..." or ""))
-- 	end

-- 	table.insert(ret, "\n")
-- 	table.insert(ret, string.rep(" ", n + 1))
-- 	table.insert(ret, string.format("return f(%s, ...)", args_string))

-- 	for i = 1, n do
-- 		table.insert(ret, "\n")
-- 		table.insert(ret, string.rep(" ", n - i + 1))
-- 		table.insert(ret, "end")
-- 	end

-- 	table.insert(ret, "\nend")
		
-- 	local output = table.concat(ret)

-- 	print(output, "\n")
-- end

-- for i=2, 59 do
-- 	create_curry(i)
-- end