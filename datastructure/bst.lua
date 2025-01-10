Bst = Object:extend("Bst")


local function default_sort(a, b)
	return a < b
end

function Bst:new(sort_function)
	self.tree = {}
	self.sort = sort_function or default_sort
end

function Bst:insert(value, node)
	node = node or self.tree
	if node == nil or next(node) == nil then
		node.value = value
		node.left = {}
		node.right = {}
		return
	end
	
	local root = node.value

	if self.sort(value, root) then
		self:insert(value, node.left)
	else
		self:insert(value, node.right)
	end
end

function Bst:ipairs()
	-- Remember that a closure is a function that accesses one or 
	-- more local variables from its enclosing function.

	local stack = {}
	local c = 0

	local function push_left_nodes(node) 
		while next(node) ~= nil do
			table.insert(stack, node)
			node = node.left
		end
	end

	local function iter()
		local node = table.remove(stack)
		if node == nil or next(node) == nil then
			return
		end
		local value = node.value
		local r_node = node.right
		if next(r_node) ~= nil then
			push_left_nodes(r_node)
		end
		c = c + 1
		return c, value
	end

	push_left_nodes(self.tree)

	return iter
end
