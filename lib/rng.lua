local rng = {}

local random = love.math.random

love.math.setRandomSeed(os.time())

function rng.randi(...)
	return random(...)
end

function rng.randf(min_, max_)
    local min, max = min(min_, max_), max(min_, max_)
	local result = min + random() * (max - min)
	return result
end

function rng.chance(chance)
	return (rng()) < chance
end

function rng.percent(chance)
	return (rng() * 100) < chance
end

function rng.randf_range(min_, max_)
	return rng.randf(min_, max_)
end

function rng.randi_range(min_, max_)
	return random(min_, max_)
end

function rng.sign()
	return rng() < 0.5 and -1 or 1
end

function rng.random_seed(seed)
	love.math.set_random_seed(seed)
end

function rng.randfn(mean, std_dev)
	return love.math.randomNormal(std_dev, mean)
end

function rng.coin_flip()
	return rng() < 0.5
end

function rng.random_angle()
	-- for i =1, 10 do print(random(0, tau)) end
	return rng.randf(0, tau)
end

function rng.random_vec2()
	return angle_to_vec2_unpacked(rng.random_angle())
end

function rng.random_vec2_times(radius)
	local x, y = rng.random_vec2()
	return x * radius, y * radius
end

function rng.choose(...)
    local args = { ... }
    if #args == 1 and type(args[1]) == "table" then
        return args[1][random(1, #args[1])]
    else
        return args[random(1, #args)]
    end
end

local weight_table = {}

function rng.weighted_randi_range(start, finish, weight_function)
    if start == finish then
        return start
    end
    local sum = 0

	table.clear(weight_table)

    local temp_start, temp_finish = start, finish
	start, finish = min(temp_start, temp_finish), max(temp_start, temp_finish)

	
	for i=start, finish do 
		local weight = weight_function(i)
		weight_table[i - start] = weight
		sum = sum + weight
	end

	local cursor = 0
	
	local target = rng.randi_range(0, sum)
	
	for i=start, finish do
		cursor = cursor + weight_table[i - start]
        if cursor >= target then
			return i
		end
	end

	return 0
end


local _temp_weight_table = nil

local function _array_index(i)
	return round(_temp_weight_table[i])
end


local function _array_item_to_weight(item)
	return item.weight
end

function rng.weighted_choice(values, weights)
	if #values == 0 then
		return nil
	end
    if weights == nil then
        weights = table.map_array(values, _array_item_to_weight)
	elseif type(weights) == "string" then
		weights = table.map_array(values, function(item) return item[weights] or 0 end)
	elseif type(weights) == "function" then 
		weights = table.map_array(values, weights)
    elseif type(weights) ~= "table" then
		error("parameter 'weights' must be a table, function, or string key pointing to a weight value in each item of the table")
	end
	_temp_weight_table = weights
	local i = rng.weighted_randi_range(1, #values, _array_index)
	_temp_weight_table = nil
	return values[i]
end

function rng.weighted_choice_dict(weights)
	local keys, values = table.keys_and_values(weights)
	return rng.weighted_choice(keys, values)
end

local function _meta_call_random(table, min_, max_)
    return random(min_, max_)
end


local _8_WAY_DIRECTIONS = {
	{1, 0},
	{-1, 0},
	{0, 1},
	{0, -1},
	{1, 1},
	{-1, -1},
	{1, -1},
	{-1, 1},
}

local _4_WAY_DIRECTIONS = {
	{1, 0},
	{-1, 0},
	{0, 1},
	{0, -1},
}

local DIAGONAL_DIRECTIONS = {
	{1, 1},
	{-1, -1},
	{1, -1},
	{-1, 1},
}
function rng.random_8_way_direction()
	return unpack(_8_WAY_DIRECTIONS[random(1, #_8_WAY_DIRECTIONS)])
end

function rng.random_4_way_direction()
	return unpack(_4_WAY_DIRECTIONS[random(1, #_4_WAY_DIRECTIONS)])
end

function rng.random_diagonal_direction()
	return unpack(DIAGONAL_DIRECTIONS[random(1, #DIAGONAL_DIRECTIONS)])
end


local mt = {
	__call = _meta_call_random
	
}
setmetatable(rng, mt)


return rng
