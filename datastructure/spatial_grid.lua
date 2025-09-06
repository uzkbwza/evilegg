local SpatialGrid = Object:extend("SpatialGrid")

local Pool = require("lib.pool")
local floor = math.floor

local function spatialgrid_insert_accumulate(value, results)
	results[#results + 1] = value
end

local function default_pairing(x, y)
	return x + y * 10000000
end

function SpatialGrid:new(cell_size, pool_size, pairing_func)
    
    -- self.pairing_function = xy_to_pairing_fast
    self.pairing_function = pairing_func or default_pairing
    
    self.cell_size = cell_size or 64
    self.inv_cell_size = 1 / self.cell_size
    self.grid = grid2d(self.pairing_function)
    self.entities = {}
    self.query_tab = {}
    self.set_pool = {}
    -- if pool_size then
    self.table_pool = Pool(function(x, y, w, h) return { x, y, w, h } end, pool_size or 0,
    function(tab, x, y, w, h)
        tab[1] = x
        tab[2] = y
        tab[3] = w
        tab[4] = h
    end,
    function(tab)
        if tab[0] then
            table.clear(tab)
        end
    end)
    self.create_table = function(me, x, y, w, h) return me.table_pool:get(x, y, w, h) end
    self.release_table = function(me, tab)
        me.table_pool:release(tab)
    end
    -- else
        -- self.create_table = function(me, x, y, w, h) return {x, y, w, h} end
        -- self.release_table = dummy_function
    -- end
end

function SpatialGrid:add(obj, rect_x, rect_y, rect_w, rect_h)
    if self.entities[obj] then error("object exists in spatial grid already: " .. obj) end

    local inv = self.inv_cell_size
    local start_cell_x = floor(rect_x * inv)
    local start_cell_y = floor(rect_y * inv)
    local end_cell_x = floor((rect_x + rect_w - 1) * inv)
    local end_cell_y = floor((rect_y + rect_h - 1) * inv)

    local e = self:create_table(rect_x, rect_y, rect_w, rect_h)
    self.entities[obj] = e

    local pairing = self.pairing_function
    local add_to_cell = self.add_object_to_cell
    for cell_x = start_cell_x, end_cell_x do
        for cell_y = start_cell_y, end_cell_y do
            add_to_cell(self, obj, pairing(cell_x, cell_y))
        end
    end
end

function SpatialGrid:update(obj, rect_x, rect_y, rect_w, rect_h)
    local e = self.entities[obj]
    local rect_dirty = e[1] ~= rect_x or e[2] ~= rect_y or e[3] ~= rect_w or e[4] ~= rect_h

    if not rect_dirty then return end

    -- Old cell bounds
    local inv = self.inv_cell_size
    local old_start_cell_x = floor(e[1] * inv)
    local old_start_cell_y = floor(e[2] * inv)
    local old_end_cell_x = floor((e[1] + e[3] - 1) * inv)
    local old_end_cell_y = floor((e[2] + e[4] - 1) * inv)

    -- New cell bounds
    local new_start_cell_x = floor(rect_x * inv)
    local new_start_cell_y = floor(rect_y * inv)
    local new_end_cell_x = floor((rect_x + rect_w - 1) * inv)
    local new_end_cell_y = floor((rect_y + rect_h - 1) * inv)

    local cell_dirty = old_start_cell_x ~= new_start_cell_x or old_start_cell_y ~= new_start_cell_y
        or old_end_cell_x ~= new_end_cell_x or old_end_cell_y ~= new_end_cell_y

    if cell_dirty then
        -- Remove from old cells
        local pairing = self.pairing_function
        local remove_from_cell = self.remove_obj_from_cell
        for cell_x = old_start_cell_x, old_end_cell_x do
            for cell_y = old_start_cell_y, old_end_cell_y do
                remove_from_cell(self, obj, pairing(cell_x, cell_y))
            end
        end
    end

    -- Update rect
    e[1] = rect_x
    e[2] = rect_y
    e[3] = rect_w
    e[4] = rect_h

    if cell_dirty then
        -- Add to new cells
        local pairing = self.pairing_function
        local add_to_cell = self.add_object_to_cell
        for cell_x = new_start_cell_x, new_end_cell_x do
            for cell_y = new_start_cell_y, new_end_cell_y do
                add_to_cell(self, obj, pairing(cell_x, cell_y))
            end
        end
    end
end

function SpatialGrid:remove(obj)
    local e = self.entities[obj]

    local inv = self.inv_cell_size
    local start_cell_x = floor(e[1] * inv)
    local start_cell_y = floor(e[2] * inv)
    local end_cell_x = floor((e[1] + e[3] - 1) * inv)
    local end_cell_y = floor((e[2] + e[4] - 1) * inv)

    local pairing = self.pairing_function
    local remove_from_cell = self.remove_obj_from_cell
    for cell_x = start_cell_x, end_cell_x do
        for cell_y = start_cell_y, end_cell_y do
            remove_from_cell(self, obj, pairing(cell_x, cell_y))
        end
    end

    self:release_table(e)
    self.entities[obj] = nil
end

function SpatialGrid:add_object_to_cell(obj, cell_id)
    local tab = self.grid:get_by_id(cell_id)
    if not tab then
        tab = {}
        tab[0] = 1
        tab[1] = obj
        self.grid:set_by_id(cell_id, tab)
    else
        local new_len = tab[0] + 1
        tab[new_len] = obj
        tab[0] = new_len
    end
 end

function SpatialGrid:remove_obj_from_cell(obj, cell_id)
    local tab = self.grid:get_by_id(cell_id)
    if tab then
        local len = tab[0]
        for j = 1, len do
            if tab[j] == obj then
                local last = tab[len]
                tab[j] = last
                tab[len] = nil
                tab[0] = len - 1
                break
            end
        end
        if tab[0] == 0 then
            self.grid:set_by_id(cell_id, nil)
        end
    end
end

function SpatialGrid:query(rect_x, rect_y, rect_w, rect_h)
    local results = self.query_tab
    table.clear(results)
    self:each(rect_x, rect_y, rect_w, rect_h, spatialgrid_insert_accumulate, results)
    return results
end

function SpatialGrid:get_cells(rect_x, rect_y, rect_w, rect_h)
    local inv = self.inv_cell_size
    local start_cell_x = floor(rect_x * inv)
    local start_cell_y = floor(rect_y * inv)
    local end_cell_x = floor((rect_x + rect_w - 1) * inv)
    local end_cell_y = floor((rect_y + rect_h - 1) * inv)
    local results = self.query_tab
    table.clear(results)
    results[0] = 0
    local get_by_id = self.grid.get_by_id
    local pairing = self.pairing_function
    local idx = 1
    for cell_x = start_cell_x, end_cell_x do
        for cell_y = start_cell_y, end_cell_y do
            local tab = get_by_id(self.grid, pairing(cell_x, cell_y))
            if tab then
                results[idx] = tab
                idx = idx + 1
                results[0] = results[0] + 1
            end
        end
    end
    return results
end

function SpatialGrid:query_neighbors(x, y)
    local inv = self.inv_cell_size
    local cell_x = floor(x * inv)
    local cell_y = floor(y * inv)
    return self.grid:neighbors(cell_x, cell_y, true)
end

function SpatialGrid:query_cell(x, y)
    local inv = self.inv_cell_size
    local cell_x = floor(x * inv)
    local cell_y = floor(y * inv)
    local tab = self.grid:get_by_id(self.pairing_function(cell_x, cell_y))
    return tab
end

--- Iterates over entities in the spatial grid within a given rectangle.
--- @param rect_x number: The x-coordinate of the rectangle's top-left corner.
--- @param rect_y number: The y-coordinate of the rectangle's top-left corner.
--- @param rect_w number: The width of the rectangle.
--- @param rect_h number: The height of the rectangle.
--- @param fn function: The function to call for each entity found.
--- @param ... any: Additional arguments to pass to the callback function.
function SpatialGrid:each(rect_x, rect_y, rect_w, rect_h, fn, ...)
    -- Note: rect_x, rect_y, rect_w, rect_h, fn, ... are expected as arguments.
    -- This function checks if there is a special entity at rect_x, and if so, uses its bounds.
    local e = self.entities[rect_x]
    if e then
        -- e is expected to be a table: {rect_x, rect_y, rect_w, rect_h}
        self:_query_func(e[1], e[2], e[3], e[4], rect_y, rect_w, rect_h, fn, ...)
        return
    else
        self:_query_func(rect_x, rect_y, rect_w, rect_h, fn, ...)
    end
end

function SpatialGrid:_query_func(rect_x, rect_y, rect_w, rect_h, fn, ...)
    local inv = self.inv_cell_size
    local start_cell_x = floor(rect_x * inv)
    local start_cell_y = floor(rect_y * inv)
    local end_cell_x = floor((rect_x + rect_w - 1) * inv)
    local end_cell_y = floor((rect_y + rect_h - 1) * inv)

    local qx1, qy1 = rect_x, rect_y
    local qx2, qy2 = rect_x + rect_w, rect_y + rect_h

    local grid = self.grid
    local get_by_id = grid.get_by_id
    local pairing = self.pairing_function
    local entities = self.entities

    -- Fast path: single-cell query (no duplicates possible)
    if start_cell_x == end_cell_x and start_cell_y == end_cell_y then
        local tab = get_by_id(grid, pairing(start_cell_x, start_cell_y))
        if not tab then return end
        local len = tab[0]
        for j = 1, len do
            local value = tab[j]
            if value then
                local e = entities[value]
                if e then
                    local ex1, ey1 = e[1], e[2]
                    local ex2, ey2 = e[1] + e[3], e[2] + e[4]
                    if ex2 > qx1 and ex1 < qx2 and ey2 > qy1 and ey1 < qy2 then
                        fn(value, ...)
                    end
                end
            end
        end
        return
    end

    local seen = table.remove(self.set_pool) or {}
    for cell_x = start_cell_x, end_cell_x do
        for cell_y = start_cell_y, end_cell_y do
            local tab = get_by_id(grid, pairing(cell_x, cell_y))
            if tab then
                local len = tab[0]
                for j = 1, len do
                    local value = tab[j]
                    if value and not seen[value] then
                        seen[value] = true
                        local e = entities[value]
                        if e then
                            local ex1, ey1 = e[1], e[2]
                            local ex2, ey2 = e[1] + e[3], e[2] + e[4]
                            if ex2 > qx1 and ex1 < qx2 and ey2 > qy1 and ey1 < qy2 then
                                fn(value, ...)
                            end
                        end
                    end
                end
            end
        end
    end

    for k in pairs(seen) do seen[k] = nil end
    table.insert(self.set_pool, seen)
end

--- Iterates over entities in the spatial grid within a given rectangle.
--- @param rect_x number: The x-coordinate of the rectangle's top-left corner.
--- @param rect_y number: The y-coordinate of the rectangle's top-left corner.
--- @param rect_w number: The width of the rectangle.
--- @param rect_h number: The height of the rectangle.
--- @param fn function: The function to call for each entity found.
--- @param tab table: The table to pass as 'self' to the callback function.
--- @param ... any: Additional arguments to pass to the callback function.
function SpatialGrid:each_self(rect_x, rect_y, rect_w, rect_h, fn, tab, ...)
    local e = self.entities[rect_x]
    if e then
        self:_query_func_self(e[1], e[2], e[3], e[4], rect_y, rect_w, rect_h, fn, tab, ...)
        return
    else
        self:_query_func_self(rect_x, rect_y, rect_w, rect_h, fn, tab, ...)
    end
end

function SpatialGrid:_query_func_self(rect_x, rect_y, rect_w, rect_h, fn, obj, ...)
    local start_cell_x = floor(rect_x / self.cell_size)
    local start_cell_y = floor(rect_y / self.cell_size)
    local end_cell_x = floor((rect_x + rect_w - 1) / self.cell_size)
    local end_cell_y = floor((rect_y + rect_h - 1) / self.cell_size)

    local qx1, qy1 = rect_x, rect_y
    local qx2, qy2 = rect_x + rect_w, rect_y + rect_h

    local grid = self.grid
    local get_by_id = grid.get_by_id
    local pairing = self.pairing_function
    local entities = self.entities

    -- Fast path: single-cell query
    if start_cell_x == end_cell_x and start_cell_y == end_cell_y then
        local tab = get_by_id(grid, pairing(start_cell_x, start_cell_y))
        if not tab then return end
        local len = tab[0]
        for j = 1, len do
            local value = tab[j]
            if value then
                local e = entities[value]
                if e then
                    local ex1, ey1 = e[1], e[2]
                    local ex2, ey2 = e[1] + e[3], e[2] + e[4]
                    if ex2 > qx1 and ex1 < qx2 and ey2 > qy1 and ey1 < qy2 then
                        fn(value, obj, ...)
                    end
                end
            end
        end
        return
    end

    local seen = table.remove(self.set_pool) or {}
    for cell_x = start_cell_x, end_cell_x do
        for cell_y = start_cell_y, end_cell_y do
            local tab = get_by_id(grid, pairing(cell_x, cell_y))
            if tab then
                local len = tab[0]
                for j = 1, len do
                    local value = tab[j]
                    if value and not seen[value] then
                        seen[value] = true
                        local e = entities[value]
                        if e then
                            local ex1, ey1 = e[1], e[2]
                            local ex2, ey2 = e[1] + e[3], e[2] + e[4]
                            if ex2 > qx1 and ex1 < qx2 and ey2 > qy1 and ey1 < qy2 then
                                fn(value, obj, ...)
                            end
                        end
                    end
                end
            end
        end
    end

    for k in pairs(seen) do seen[k] = nil end
    table.insert(self.set_pool, seen)
end

function SpatialGrid:has_object(obj)
    return self.entities[obj] ~= nil
end

function SpatialGrid:clear()
    local tmp = self.query_tab
    table.clear(tmp)
    local idx = 1
    for obj in pairs(self.entities) do
        tmp[idx] = obj
        idx = idx + 1
    end
    for i = 1, idx - 1 do
        self:remove(tmp[i])
        tmp[i] = nil
    end
end

function SpatialGrid:query_radius(x, y, radius)
    return self:query(x - radius, y - radius, radius * 2, radius * 2)
end

return SpatialGrid
