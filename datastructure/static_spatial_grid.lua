local StaticSpatialGrid = Object:extend("StaticSpatialGrid")

function StaticSpatialGrid:new(w, h, cell_size)
    self.w = w
    self.h = h
    self.cell_size = cell_size
    self.grid = grid2d()
end

function StaticSpatialGrid:add(rect_x, rect_y, rect_w, rect_h, value)
    local start_cell_x = floor(rect_x / self.cell_size)
    local start_cell_y = floor(rect_y / self.cell_size)
    local end_cell_x = floor((rect_x + rect_w) / self.cell_size)
    local end_cell_y = floor((rect_y + rect_h) / self.cell_size)

    for cell_x = start_cell_x, end_cell_x do
        for cell_y = start_cell_y, end_cell_y do
            local tab = self.grid:get(cell_x, cell_y)
            if not tab then
                tab = {}
                self.grid:set(cell_x, cell_y, tab)
            end
            table.insert(tab, value)
        end
    end
end

function StaticSpatialGrid:query(rect_x, rect_y, rect_w, rect_h)
    local start_cell_x = floor(rect_x / self.cell_size)
    local start_cell_y = floor(rect_y / self.cell_size)
    local end_cell_x = floor((rect_x + rect_w) / self.cell_size)
    local end_cell_y = floor((rect_y + rect_h) / self.cell_size)

    local results = {}
    for cell_x = start_cell_x, end_cell_x do
        for cell_y = start_cell_y, end_cell_y do
            local tab = self.grid:get(cell_x, cell_y)
            if tab then
                for _, value in ipairs(tab) do
                    table.insert(results, value)
                end
            end
        end
    end
    return results
end

function StaticSpatialGrid:query_neighbors(x, y)
    local cell_x = floor(x / self.cell_size)
    local cell_y = floor(y / self.cell_size)
    return self.grid:neighbors(cell_x, cell_y, true)
end

function StaticSpatialGrid:query_cell(x, y)
    local cell_x = floor(x / self.cell_size)
    local cell_y = floor(y / self.cell_size)
    local tab = self.grid:get(cell_x, cell_y)
    if tab then
        return tab
    end
    return nil
end

function StaticSpatialGrid:query_radius(x, y, radius)
    return self:query(x - radius, y - radius, radius * 2, radius * 2)
end

return StaticSpatialGrid
