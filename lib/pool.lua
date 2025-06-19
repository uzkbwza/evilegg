---@class Pool
---@field new (fun():table, number?):Pool
local Pool = {}
Pool.__index = Pool

--- Creates a new pool.
---@param constructor function A function that returns a new object for the pool when it's empty.
---@param initial_size? number The initial number of objects to pre-allocate in the pool.
---@return Pool
function Pool.new(constructor, initial_size)
    local pool = {
        pool = {},
        constructor = constructor or function() return {} end,
        total_created = 0,
        initial_size = initial_size or 0
    }
    
    if initial_size then
        for _ = 1, initial_size do
            table.insert(pool.pool, pool.constructor())
        end
        pool.total_created = initial_size
    end

    return setmetatable(pool, Pool)
end

--- Retrieves an object from the pool. If the pool is empty, it uses the constructor to create a new one.
---@return table
function Pool:get()
    if #self.pool > 0 then
        return table.remove(self.pool)
    else
        self.total_created = self.total_created + 1
        return self.constructor()
    end
end

--- Releases an object back into the pool for reuse. If the pool has grown beyond its
--- initial size, this will discard the object to allow the pool to shrink over time.
---@param obj table The object to release.
function Pool:release(obj)
    if #self.pool >= self.initial_size then
        self.total_created = self.total_created - 1
        -- By not re-inserting the object, we allow it to be garbage collected,
        -- effectively shrinking the pool's total object count.
    else
        table.insert(self.pool, obj)
    end
end

--- Returns statistics about the pool's usage.
---@return {used: number, available: number, total: number}
function Pool:get_stats()
    local available = #self.pool
    local total = self.total_created
    return {
        used = total - available,
        available = available,
        total = total,
    }
end

return Pool.new
