local Grid2D = Object:extend("Grid2D")

function Grid2D:new()
    self.grid = {}
end

function Grid2D:get(x, y)
    if not self.grid[y] then
        return nil
    end
    return self.grid[y][x]
end

function Grid2D:set(x, y, value)
    if not self.grid[y] then
        self.grid[y] = {}
    end
    self.grid[y][x] = value
end

function Grid2D:neighbors(x, y, include_self)
    local neighbors = {}
    for _, direction in ipairs(include_self and ALL_DIRECTIONS or CARDINAL_AND_ORDINAL_DIRECTIONS) do
        local neighbor_x = x + direction.x
        local neighbor_y = y + direction.y
        local neighbor = self:get(neighbor_x, neighbor_y)
        if neighbor then
            table.insert(neighbors, neighbor)
        end
    end
    return neighbors
end

return Grid2D
