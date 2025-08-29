local Grid2D = Object:extend("Grid2D")

function Grid2D:new(pairing_func)
    self.pairing_func = pairing_func or xy_to_pairing_fast
end

function Grid2D:get(x, y)
    return self[self.pairing_func(x, y)]
end

function Grid2D:get_by_id(id)
    return self[id]
end

function Grid2D:set_by_id(id, value)
    self[id] = value
end

function Grid2D:set(x, y, value)
    self[self.pairing_func(x, y)] = value
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
