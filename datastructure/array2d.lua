local Array2D = Object:extend("Array2D")

function Array2D:new(w, h, default_value)
    self.w = w
    self.h = h

    for i = 1, w * h do
        self[i] = default_value or nil
    end

end

function Array2D:get(x, y)
    local id = xy_to_id(x, y, self.w)

    return self[id]
end

function Array2D:set(x, y, value)
    local id = xy_to_id(x, y, self.w)
    self[id] = value
end

function Array2D:neighbors(x, y, include_self)
    local neighbors = {}
    for _, direction in ipairs(include_self and ALL_DIRECTIONS or CARDINAL_AND_ORDINAL_DIRECTIONS) do
        local neighbor_id = xy_to_id(x + direction.x, y + direction.y, self.w)
        if self[neighbor_id] then
            table.insert(neighbors, self[neighbor_id])
        end
    end
    return neighbors
end

function Array2D:do_to_neighbors(func, x, y, include_self)
    for _, direction in ipairs(include_self and ALL_DIRECTIONS or CARDINAL_AND_ORDINAL_DIRECTIONS) do
        local neighbor_id = xy_to_id(x + direction.x, y + direction.y, self.w)
        func(self[neighbor_id])
    end
end

return Array2D
