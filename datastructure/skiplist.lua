local min, floor, log, random = math.min, math.floor, math.log, math.random

-- Probability that a node appears in a higher level.
local P = 0.5

-- Log base 'base'. Used for calculating maximum levels from expected size.
local function logb(n, base)
    return log(n) / log(base)
end

local skiplist = {}
skiplist.__index = skiplist

-- Clear the skiplist: remove all items.
function skiplist:clear()
    self.head     = {}     -- head is a dummy node whose next pointers are stored in numeric keys
    self._levels  = 1      -- current maximum level in the list
    self._count   = 0      -- how many items
    self._size    = 2^1    -- threshold for next level increase
    self.exists   = {}     -- set/table of existing values (for quick membership check)
end

-- Create a new skiplist.
--   expected_size: integer to guide max-level calculation
--   comp: function(a, b) -> bool (true if 'a' comes before 'b')
function skiplist.new(comp, expected_size)
    local expected = expected_size or 100
    local levels   = floor(logb(expected, 1 / P))
    if levels < 1 then levels = 1 end

    local self = setmetatable({}, skiplist)
    self.head    = {}
    self._levels = levels
    self._count  = 0
    self._size   = 2 ^ levels
    -- If user omitted a comparator, default to a < b
    self.comp    = comp or function(a, b) return a < b end
    self.exists  = {}
    return self
end

-- How many items are in the skiplist?
function skiplist:length()
    return self._count
end

--------------------------------------------------------------------------------
-- FIND
--   Return the node containing 'value', or nil if not found.
--   This is used by remove() to find an existing node.
--------------------------------------------------------------------------------
function skiplist:find(value)
    local node = self.head
    local comp = self.comp
    -- Start from the highest level, descend to level 1
    for level = self._levels, 1, -1 do
        -- As long as the next node at this level exists AND is "before" or equal to 'value',
        -- move forward. We specifically check comp(node[level].value, value).
        while node[level] and comp(node[level].value, value) do
            node = node[level]
        end
    end

    -- Now, the node we want (if it exists) should be the "next" at level 1:
    local candidate = node[1]
    if not candidate then
        return nil
    end

    -- We must verify that candidate.value == value (not just "less than" or "greater than").
    -- Because the user says "all values are tables, we can check equality directly"
    -- but to handle the possibility that comp is just "<", do a direct check:
    if candidate.value == value then
        return candidate
    end
    return nil
end

--------------------------------------------------------------------------------
-- INSERT
--   Inserts 'value' if not already present. Uses random-level logic.
--------------------------------------------------------------------------------
function skiplist:insert(value)
    -- If we already have this value, do nothing.
    if self.exists[value] then
        return
    end

    local update = {}
    local node   = self.head
    local comp   = self.comp

    -- 1) Build an update[] table so we know where to link the new node at each level.
    for level = self._levels, 1, -1 do
        while node[level] and comp(node[level].value, value) do
            node = node[level]
        end
        update[level] = node
    end

    -- 2) Decide how tall this new node will be using the geometric distribution.
    --    (Same logic as in your original snippet)
    local new_level = 1
    -- p = 0.5 means on average half the nodes go up each level
    while random() < P and new_level < self._levels do
        new_level = new_level + 1
    end

    -- 3) Create the new node
    local new_node = { value = value }

    -- 4) Link the new_node into all levels from 1..new_level
    for level = 1, new_level do
        -- "Backward" link at negative index
        new_node[-level] = update[level]
        -- "Forward" link: new_node[level] is what used to follow update[level]
        new_node[level]  = update[level][level]
        -- Fix forward pointer from update[level] to new_node
        update[level][level] = new_node
        -- Fix backward pointer of the node *after* new_node, if any
        if new_node[level] then
            new_node[level][-level] = new_node
        end
    end

    -- 5) Increase our count, record existence
    self._count             = self._count + 1
    self.exists[value]      = new_node

    -- 6) Possibly increase the overall skip list height
    if self._count > self._size then
        self._levels = self._levels + 1
        self._size   = self._size * 2
    end
end

--------------------------------------------------------------------------------
-- INTERNAL _delete(node)
--   Unlinks a node from the skiplist at all the levels it participates in.
--------------------------------------------------------------------------------
function skiplist:_delete(node)
    local level = 1
    -- We keep climbing levels while there's a valid backward link at level
    while node[-level] do
        local prev_node = node[-level]
        local next_node = node[level]
        -- The previous node at 'level' now points forward to the next_node
        prev_node[level] = next_node
        -- The next_node at 'level', if it exists, points backward to prev_node
        if next_node then
            next_node[-level] = prev_node
        end
        level = level + 1
    end
    self._count = self._count - 1
end

--------------------------------------------------------------------------------
-- REMOVE
--   Removes 'value' if it exists. (No-op if it doesn't exist.)
--   Implementation uses find() and then calls _delete on the node.
--------------------------------------------------------------------------------
function skiplist:remove(value)
    local node = self.exists[value]
    if not node then
        -- Maybe user mutated exists somehow? Or we never inserted it.
        -- Double check with find() (though typically not needed if 'exists' is kept up to date).
        node = self:find(value)
        if not node then
            return -- not found
        end
    end

    -- We found the node -> unlink and remove from 'exists'.
    self:_delete(node)
    self.exists[value] = nil
end

--------------------------------------------------------------------------------
-- IPAIRS
--   Returns an iterator that yields (i, value) in ascending order at level 1.
--   Because the skiplist is sorted at level 1 according to comp, this is sorted iteration.
--------------------------------------------------------------------------------
function skiplist:ipairs()
    local i = 1
    -- Start at the first “real” node (if any) at level 1
    local node = self.head[1]
    return function()
        if node then
            local ret = node.value
            node = node[1]  -- proceed to the next node at level 1
            local idx = i
            i = i + 1
            return idx, ret
        end
    end
end

return skiplist.new
