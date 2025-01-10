-- Red-Black Tree implementation

local RED = false
local BLACK = true

Rbt = Object:extend("Rbt")

local function default_sort(a, b)
    return a < b
end

function Rbt:new(sort_function)
    self.tree = nil
    self.sort = sort_function or default_sort
end

function Rbt:insert(value)
    local new_node = {value = value, color = RED, left = nil, right = nil, parent = nil}
    self:_insert_node(new_node)
    self:_insert_fixup(new_node)
end

function Rbt:_insert_node(node)
    local y = nil
    local x = self.tree
    while x ~= nil do
        y = x
        if self.sort(node.value, x.value) then
            x = x.left
        else
            x = x.right
        end
    end
    node.parent = y
    if y == nil then
        self.tree = node
    elseif self.sort(node.value, y.value) then
        y.left = node
    else
        y.right = node
    end
end

function Rbt:_insert_fixup(node)
    while node.parent ~= nil and node.parent.color == RED do
        if node.parent == node.parent.parent.left then
            local y = node.parent.parent.right
            if y ~= nil and y.color == RED then
                node.parent.color = BLACK
                y.color = BLACK
                node.parent.parent.color = RED
                node = node.parent.parent
            else
                if node == node.parent.right then
                    node = node.parent
                    self:_left_rotate(node)
                end
                node.parent.color = BLACK
                node.parent.parent.color = RED
                self:_right_rotate(node.parent.parent)
            end
        else
            local y = node.parent.parent.left
            if y ~= nil and y.color == RED then
                node.parent.color = BLACK
                y.color = BLACK
                node.parent.parent.color = RED
                node = node.parent.parent
            else
                if node == node.parent.left then
                    node = node.parent
                    self:_right_rotate(node)
                end
                node.parent.color = BLACK
                node.parent.parent.color = RED
                self:_left_rotate(node.parent.parent)
            end
        end
    end
    self.tree.color = BLACK
end

function Rbt:_left_rotate(x)
    local y = x.right
    x.right = y.left
    if y.left ~= nil then
        y.left.parent = x
    end
    y.parent = x.parent
    if x.parent == nil then
        self.tree = y
    elseif x == x.parent.left then
        x.parent.left = y
    else
        x.parent.right = y
    end
    y.left = x
    x.parent = y
end

function Rbt:_right_rotate(y)
    local x = y.left
    y.left = x.right
    if x.right ~= nil then
        x.right.parent = y
    end
    x.parent = y.parent
    if y.parent == nil then
        self.tree = x
    elseif y == y.parent.left then
        y.parent.left = x
    else
        y.parent.right = x
    end
    x.right = y
    y.parent = x
end

function Rbt:ipairs()
    local stack = {}
    local stack_top = 0
    local node = self.tree
    local c = 0

    local function next_node()
        while node ~= nil do
            stack_top = stack_top + 1
            stack[stack_top] = node
            node = node.left
        end
        if stack_top == 0 then
            return nil
        end
        node = stack[stack_top]
        stack_top = stack_top - 1
        local value = node.value
        node = node.right
        c = c + 1
        return c, value
    end

    return next_node
end
