local smart_array = {
    __type_name = "smart_array",
}

function smart_array:__tostring() return "smart_array" end

function smart_array:__index(k)
	local meta = rawget(smart_array, k)
    if meta then
        return meta
    end

	return rawget(self, k)
end

function smart_array:__len()
	return self.__length
end

function smart_array:push(obj)
    self.__length = self.__length + 1
    self[self.__length] = obj
end

function smart_array:insert_at(index, obj)
	local array = self
	local length = self.__length
    self.__length = length + 1
	table.insert(array, index, obj)
end

function smart_array:remove_at(index)
	local array = self
	local length = self.__length
	local last = array[length]
	array[index] = last
	array[length] = nil
    self.__length = length - 1
	return last
end

function smart_array:remove(obj)
    local array = self
    local index = table.find(self, obj)

    if not index then
        return
    end

	local length = self.__length
	local last = array[length]
    array[index] = last
    array[length] = nil
    self.__length = length - 1
	return last
end

function smart_array:pop()
	local array = self
	local length = self.__length
	if length == 0 then
		return nil
	end
    self.__length = self.__length - 1
	local last = array[length]
	array[length] = nil
	return last
end

function smart_array:ipairs()
    local index = 0
    local t = self
    return function()
        index = index + 1
        if t[index] then
            return index, t[index]
        else
            return nil
        end
    end
end

local function new_smart_array()
    return setmetatable({ __length = 0 }, smart_array)
end

local function benchmark_smart_array(n)
    local b = new_smart_array()
    local start = love.timer.getTime()
    
    for i = 1, n do
        b:push(i)
    end
    local insert_time = love.timer.getTime() - start

	start = love.timer.getTime()
    for i, v in b:ipairs() do
        local _ = v
    end
    local iterate_time = love.timer.getTime() - start
	
    start = love.timer.getTime()
    for i = 1, n do
        b:remove(rng.randi_range(1, n))
    end
	local remove_time = love.timer.getTime() - start

	


    return insert_time, remove_time, iterate_time
end

local function benchmark_plain_table(n)
    local t = {}
    local start = love.timer.getTime()
    
    -- Insertion
    for i = 1, n do
        table.insert(t, i)
    end
    local insert_time = love.timer.getTime() - start

    start = love.timer.getTime()
    for i, v in ipairs(t) do
        local _ = v
    end
	local iterate_time = love.timer.getTime() - start

    -- Removal
    start = love.timer.getTime()
    for i = 1, n do
        table.erase(t, rng.randi_range(1, n))
    end
	
    local remove_time = love.timer.getTime() - start


    return insert_time, remove_time, iterate_time
end

-- local n = 100000
-- local b_insert, b_remove, b_iterate = benchmark_smart_array(n)
-- local t_insert, t_remove, t_iterate = benchmark_plain_table(n)

-- print("n = " .. n)
-- print(string.format("smart_array - Insert: %.10f, Remove: %.10f, Iterate: %.10f", b_insert, b_remove, b_iterate))
-- print(string.format("Plain table - Insert: %.10f, Remove: %.10f, Iterate: %.10f", t_insert, t_remove, t_iterate))
return new_smart_array
