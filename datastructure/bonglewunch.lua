---@class bonglewunch
local bonglewunch = {
	__type_name = function() return "bonglewunch" end,
}

function bonglewunch:__tostring() return "bonglewunch" end

function bonglewunch:__index(k)
	local meta = rawget(bonglewunch, k)
	if meta then
		return meta
	end

	local index = self.__indices[k]
	if index then return index end

	return nil
end

function bonglewunch:__newindex(k, v)
	if v == nil then
		self:remove(k)
	else
		error(
		"adding new items by indexing this way is unsupported. you can use bonglewunch:push(item) to add an item, and bonglewunch:pop(), bonglewunch:remove(item) or bonglewunch[item] = nil to remove an item.")
	end
end

function bonglewunch:length()
    return self.__length
end

function bonglewunch:random()
    return self.__array[rng.randi_range(1, self.__length)]
end

function bonglewunch:ipairs()
    local index = 0
    local t = self.__array
    return function()
        index = index + 1
        if t[index] then
            return index, t[index]
        else
            return nil
        end
    end
end

function bonglewunch:is_empty()
    return self.__length == 0
end

function bonglewunch:add(obj)
    self:push(obj)
end

function bonglewunch:has(obj)
    return self.__indices[obj] ~= nil
end

function bonglewunch:push(obj)
	if obj == nil then return end

	local indices = self.__indices

	if indices[obj] then
		return
	end

	self.__length = self.__length + 1

	self.__array[self.__length] = obj

	indices[obj] = self.__length
end

function bonglewunch:remove_at(index)
    if index > self.__length then return end
	
	local array = self.__array
	local indices = self.__indices
	local obj = array[index]
	local length = self.__length
	self.__length = self.__length - 1
	local last = array[length]
	array[index] = last
	indices[last] = index
	array[length] = nil
	indices[obj] = nil
end

function bonglewunch:remove(obj)
	local array = self.__array
	local indices = self.__indices
	local index = indices[obj]

    if not index then
        return
    end
	
	local length = self.__length
	self.__length = self.__length - 1
	local last = array[length]
	array[index] = last
	indices[last] = index
	array[length] = nil
	indices[obj] = nil
end

function bonglewunch:clear()
	self.__length = 0
	table.clear(self.__array)
	table.clear(self.__indices)
end

function bonglewunch:pop()
	if self.__length == 0 then return nil end
	local array = self.__array
	local indices = self.__indices
	local length = self.__length
	self.__length = self.__length - 1
	local last = array[length]
	array[length] = nil
	indices[last] = nil
	return last
end

function bonglewunch:pop_at(index)
    if index > self.__length then return end
	
	local array = self.__array
	local indices = self.__indices
	local obj = array[index]
	local length = self.__length
	self.__length = self.__length - 1
	local last = array[length]
	array[index] = last
	indices[last] = index
	array[length] = nil
    indices[obj] = nil
	return obj
end

function bonglewunch:peek(i)
	i = i or self.__length
	return self.__array[i]
end

local function new_bonglewunch(table)
	local b = setmetatable({ __array = {}, __indices = {}, __length = 0 }, bonglewunch)
	if table then
		for _, v in ipairs(table) do
			b:push(v)
		end
	end
	return b
end

local function benchmark_bonglewunch(n)
	local b = new_bonglewunch()
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
	for i = 1, 1 do
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
		t[i] = i
	end
	local insert_time = love.timer.getTime() - start

	start = love.timer.getTime()
	for i, v in ipairs(t) do
		local _ = v
	end
	local iterate_time = love.timer.getTime() - start

	-- Removal
	start = love.timer.getTime()
	for i = 1, 1 do
		table.erase(t, rng.randi_range(1, n))
	end

	local remove_time = love.timer.getTime() - start


	return insert_time, remove_time, iterate_time
end

-- local n = 100000
-- local b_insert, b_remove, b_iterate = benchmark_bonglewunch(n)
-- local t_insert, t_remove, t_iterate = benchmark_plain_table(n)

-- print("n = " .. n)
-- print(string.format("bonglewunch - Insert: %.10f, Remove: %.10f, Iterate: %.10f", b_insert, b_remove, b_iterate))
-- print(string.format("Plain table - Insert: %.10f, Remove: %.10f, Iterate: %.10f", t_insert, t_remove, t_iterate))

return new_bonglewunch
