---@class Pool
local Pool = {}
Pool.__index = Pool

--- Creates a new pool.
---@param constructor function A function that returns a new object for the pool when it's empty.
---@param pool_amount? number The initial number of objects to pre-allocate in the pool.
---@return Pool
function Pool.new(constructor, pool_amount, get_function, release_function)
    local pool = {
        pool = {},
        constructor = constructor or function() return {} end,
        get_function = get_function or function() end,
        release_function = release_function or function() end,
        total_created = 0,
        pool_available_count = 0,
        pool_amount = pool_amount or 0,
    }
    
    if pool_amount then
        for _ = 1, pool_amount do
            table.insert(pool.pool, pool.constructor())
        end
        pool.total_created = pool_amount
        pool.pool_available_count = pool_amount
    else
        pool.pool_amount = math.huge
    end

    return setmetatable(pool, Pool)
end

--- Retrieves an object from the pool. If the pool is empty, it uses the constructor to create a new one.
---@return table
function Pool:get(...)
    if self.pool_available_count > 0 then
        self.pool_available_count = self.pool_available_count - 1
        local tab = table.remove(self.pool)
        self.get_function(tab, ...)
        return tab
    else
        self.total_created = self.total_created + 1
        return self.constructor(...)
    end
end

-- - Releases an object back into the pool for reuse.
---@param tab table The object to release.
function Pool:release(tab)

    self.release_function(tab)
    -- if the pool is full, just let the tabect get garbage collected
    if self.pool_available_count >= self.pool_amount then
        self.total_created = self.total_created - 1
    else
        table.insert(self.pool, tab)
        self.pool_available_count = self.pool_available_count + 1
    end
end

--- Returns statistics about the pool's usage.
---@return {used: number, available: number, total: number}
function Pool:get_stats()
    local available = self.pool_available_count
    local total = self.total_created
    return {
        used = total - available,
        available = available,
        total = total,
    }
end

return Pool.new
