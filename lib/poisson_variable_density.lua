
local PoissonVariableDensity = Object:extend("PoissonVariableDensity")

-- Create a sampler covering width × height, minimum distance r, k trials
function PoissonVariableDensity:new(w, h, radius_function, num_attempts, min_radius, max_radius, irng)
    self.irng = irng or rng:new_instance()
    self.w = w
    self.h = h
    self.min_radius = min_radius
    self.max_radius = max_radius or min_radius * 2
    self.cell_size = ((self.min_radius + self.max_radius * 0.5) / sqrt(2))
    self.num_attempts = num_attempts
    self.radius_function = radius_function
    self.grid_indices = static_spatial_grid(ceil(w / self.cell_size), ceil(h / self.cell_size), self.cell_size)
    self.points = {}
end

function PoissonVariableDensity:generate()
    local num_attempts = self.num_attempts
    
    local irng = self.irng
    local min_radius = self.min_radius
    local max_radius = self.max_radius

    local all_directions = ALL_DIRECTIONS
    local num_directions = #all_directions

    local cell_size = self.cell_size

    local radius_func = self.radius_function
    local x, y = self.irng:randf(0, self.w), self.irng:randf(0, self.h)


    local point1_radius = radius_func(x / self.w, y / self.h)
    
    local point1 = { x, y, }
    local active = {point1}
    local points = self.points
    local grid_indices = self.grid_indices


    
    local point1cx, point1cy = self:_to_cell(point1[1], point1[2])

    local tinsert = table.insert

    self.grid_indices:add(point1cx - point1_radius, point1cy - point1_radius, point1_radius * 2, point1_radius * 2, 1)
    tinsert(self.points, point1)


    local grid_length = 1
    
    local active_length = 1

    -- local max_distance_sq = self.max_radius * self.max_radius

    local w, h = self.w, self.h

    -- local c = 1

    while active_length > 0 do


        local vec_i = irng:randi(1, active_length)
        local vec = active[vec_i]

        local added_new_point = false

        for k = 1, num_attempts do
            local valid = true
            local radius = radius_func(vec[1] / w, vec[2] / h)
            local new_x, new_y = self:_random_point_in_annulus(radius)
            new_x = new_x + vec[1]
            new_y = new_y + vec[2]

            local rect_x = new_x - radius
            local rect_y = new_y - radius
            local rect_size = radius * 2

            if new_x < 0 or new_y < 0 or new_x >= w or new_y >= h then
                valid = false
            end

            if valid then
                -- for j = 1, num_directions do
                --     local dir = all_directions[j]
                --     local nx, ny = cell_x + dir.x, cell_y + dir.y
                --     if nx >= 1 and nx <= grid_indices.w and ny >= 1 and ny <= grid_indices.h then
                --         local neighbor_index = grid_indices:get(nx, ny)
                --         if neighbor_index ~= 0 and neighbor_index ~= nil then
                --             local neighbor = points[neighbor_index]
                --                 valid = false
                --                 break
                --             end
                --         end
                --     end
                -- end
                for _, neighbor_index in ipairs(grid_indices:query(rect_x, rect_y, rect_size, rect_size)) do
                    local neighbor = points[neighbor_index]
                    if vec2_distance_squared(neighbor[1], neighbor[2], new_x, new_y) <= (radius * radius) then
                        valid = false
                        break
                    end
                end
            end

            if valid then
                local new_point = { new_x, new_y }
                active_length = active_length + 1
                grid_length = grid_length + 1
                points[grid_length] = new_point
                active[active_length] = new_point
                grid_indices:add(rect_x, rect_y, rect_size, rect_size, grid_length)
                added_new_point = true
                break
            end
        end

        if not added_new_point then
            active[vec_i] = active[active_length]
            active_length = active_length - 1
        end

        -- c = c + 1
        -- if c > 1000 then
            -- error("PoissonVariableDensity:generate() took too long")
        -- end

    end

    return self.points
end


function PoissonVariableDensity:_to_cell(x, y)
    return floor(x / self.cell_size) + 1, floor(y / self.cell_size) + 1
end

function PoissonVariableDensity:_random_point_in_annulus(radius)
    return self.irng:random_vec2_times(self.irng:randf(radius, radius * 2))
end

if debug.enabled then
    bench.start_bench("PoissonVariableDensity1")

    local p = PoissonVariableDensity(100, 100, function(x, y)
        return remap_clamp(y, 0, 1, 1, 10)
    end, 3, 5, 10)
    p:generate()

    bench.end_bench("PoissonVariableDensity1")
end

return PoissonVariableDensity

