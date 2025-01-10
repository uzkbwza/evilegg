-- array based version
Bst2 = Object:extend("Bst2")

local function left(index)
	return 2 * index
end

local function right(index)
	return 2 * index + 1
end

local function default_sort(a, b)
	return a < b
end

function Bst2:new(sort_function)
	self.tree = {}
	self.sort = sort_function or default_sort
end

function Bst2:insert(value, index)
	index = index or 1
	local root = self.tree[index]
	if root == nil then
		self.tree[index] = value
		return
	end

	if self.sort(value, root) then
		self:insert(value, left(index))
	else
		self:insert(value, right(index))
	end
end

function Bst2:ipairs()

	local stack = {}
	local c = 0

	local function push_left_nodes(i) 
		while self.tree[i] ~= nil do
			table.insert(stack, i)
			i = left(i)
		end
	end

	local function next()
		local node = table.remove(stack)
		local value = self.tree[node]
		if value == nil then
			return
		end
		local r_node = right(node)
		if self.tree[r_node] ~= nil then
			push_left_nodes(r_node)
		end
		c = c + 1
		return c, value
	end

	push_left_nodes(1)

	return next
end
