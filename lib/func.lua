---@diagnostic disable: lowercase-global

require "lib.gen.curry"
require "lib.gen.bind"

local binds = {}

for i = 1, 59 do
	binds[i] = _G["bind" .. i]
end

function bind(func, ...)
	return binds[select("#", ...)](func, ...)
end


local curry_functions = {}
for i=1, 59 do
	curry_functions[i] = _G["curry" .. i]
end

function curry(n, f)
	return curry_functions[n](f)
end

local function add(...)
	local sum = 0
	for i = 1, select("#", ...) do
		sum = sum + select(i, ...)
	end
	return sum
end


-- local function add(a, b)
-- 	return a + b
-- end

-- local add_one = bind(add, 1)

-- local result = add_one(2)

-- print(result)
-- -->> 3

-- local function add_three(a, b, c)
-- 	return a + b + c
-- end

-- local add_one_and_two = bind(add_three, 1, 2)

-- local result = add_one_and_two(3)

-- print(result)
-- -->> 6

-- local add_one = bind(add_three, 1)
-- local add_one_and_two = bind(add_one, 2)

-- local result = add_one_and_two(3)
-- print(result)
-- -->> 6


-- print(curry(50, add)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1))
-->> 50
