local rng = {}

-- local random = love.math.random

love.math.setRandomSeed(os.time())

function rng:randi(a, b)
    if a == nil then
        return self(0xffffffff)
    end
	return self(a, b)
end

function rng:randf(min_, max_)
    local min, max = min(min_, max_), max(min_, max_)
	local result = min + self() * (max - min)
	return result
end

function rng:chance(chance)
    local c = self()
	return c < chance
end

function rng:percent(chance)
	return (self() * 100) < chance
end

function rng:one_in(n)
    return self(1, n) == 1
end

function rng:randf_pow(min_, max_, power)
    return remap01(pow(self(), power), min_, max_)
end

function rng:randf_pow_inverted(min_, max_, power)
    return remap01(pow(1 - self(), power), max_, min_)
end

function rng:rand_sign()
	return self:coin_flip() and -1 or 1
end

function rng:rand_01()
    return self:coin_flip() and 0 or 1
end

function rng:set_seed(seed)
    self._rng:setSeed(seed)
end

function rng:get_seed()
    return self._rng:getSeed()
end

function rng:randfn(mean, std_dev)
	return self._rng:randomNormal(std_dev, mean)
end

function rng:randfn_abs(mean, std_dev)
	return abs(self:randfn(mean, std_dev))
end

function rng:coin_flip()
	return self() < 0.5
end

function rng:random_angle()
	-- for i =1, 10 do print(random(0, tau)) end
	return self:randf(0, tau)
end

function rng:random_vec2()
	return vec2_from_angle(self:random_angle())
end

function rng:random_vec2_times(radius)
	local x, y = self:random_vec2()
	return x * radius, y * radius
end

function rng:random_point_in_rect(x, y, w, h)
    return self:randf(x, x + w), self:randf(y, y + h)
end

function rng:random_point_in_circle(radius)
    if radius == 0 then return 0, 0 end
    local r = radius * math.sqrt(self())
    -- We get a random vector on the unit circle and scale it by r
    return self:random_vec2_times(r)
end

function rng:choose(...)
    local n = select('#', ...)
    if n == 1 then
        local a = ...
        if type(a) == "table" then
            return a[self(1, #a)]
        else
            return a
        end
    else
        local idx = self(1, n)
        for i = 1, n do
            if i == idx then
                local v = select(i, ...)
                return v
            end
        end
    end
end

function rng:shuffle(t)
    for i = #t, 2, -1 do
        local j = self(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function rng:pick(t)
	local len = #t
    if len == 0 then return nil end
    return table.remove(t, self(1, len))
end

local weight_table = {}

function rng:weighted_randi(start, finish, weight_function)
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
	
	local target = self:randi(0, sum)
	
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

function rng:weighted_choice(values, weights)
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
	local i = self:weighted_randi(1, #values, _array_index)
	_temp_weight_table = nil
	return values[i]
end

function rng:weighted_choice_dict(weights)
	local keys, values = table.keys_and_values(weights)
	return self:weighted_choice(keys, values)
end

local function _meta_call_random(self, min_, max_)
    return self._rng:random(min_, max_)
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
function rng:random_8_way_direction()
	return table.fast_unpack(_8_WAY_DIRECTIONS[self(1, #_8_WAY_DIRECTIONS)])
end

function rng:random_4_way_direction()
	return table.fast_unpack(_4_WAY_DIRECTIONS[self(1, #_4_WAY_DIRECTIONS)])
end

function rng:random_diagonal_direction()
    return table.fast_unpack(DIAGONAL_DIRECTIONS[self(1, #DIAGONAL_DIRECTIONS)])
end

function rng:new_instance(seed)
    local love_rng_instance = love.math.newRandomGenerator(seed or
        (self and self:randi() or love.math.random(0xffffffff)))
    local instance = {
        _rng = love_rng_instance
    }
    setmetatable(instance, {
        __call = _meta_call_random,
        __index = rng
    })
    return instance
end

function rng:random_point_on_rect_perimeter(x, y, w, h)
    if self:coin_flip() then
        return x + self:rand_01() * w, y + self() * h
    end
    return x + self() * w, y + self:rand_01() * h
end


function rng:random_point_on_centered_rect_perimeter(x, y, w, h)
    x = x - w / 2
    y = y - h / 2
    if self:coin_flip() then
        return x + self:rand_01() * w, y + self() * h
    end
    return x + self() * w, y + self:rand_01() * h
end

function rng:uuid()
    local fn = function(x)
        local r = self:randi(16) - 1
        r = (x == "x") and (r + 1) or (r % 4) + 9
        return ("0123456789abcdef"):sub(r, r)
    end
    return (("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", fn))
end

local global_rng = rng:new_instance(os.time() + love.math.random())

return global_rng
