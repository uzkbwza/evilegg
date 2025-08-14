-- poisson.lua --------------------------------------------------------------
-- Bridson Poisson‑Disk sampling in 2‑D
local Poisson = Object:extend("Poisson")

-- Create a sampler covering width × height, minimum distance r, k trials
function Poisson:new(w, h, radius, num_attempts, slack, irng)
    self.irng = irng or rng:new_instance()
    self.w = w
    self.h = h
    self.slack = slack or 2.0
    self.min_radius = radius
    self.max_radius = radius * self.slack
    self.cell_size = (self.min_radius / sqrt(2))
    self.num_attempts = num_attempts
    self.grid_indices = array2d(ceil(w / self.cell_size), ceil(h / self.cell_size), 0)
    self.points = {}
end

function Poisson:generate()
    local num_attempts = self.num_attempts
    
    local irng = self.irng
    local min_radius = self.min_radius
    local max_radius = self.max_radius

    local all_directions = ALL_DIRECTIONS
    local num_directions = #all_directions

    local cell_size = self.cell_size

    local vec1 = self:_random_point()
    local active = {vec1}
    local points = self.points
    local grid_indices = self.grid_indices


    
    local vec1cx, vec1cy = self:_to_cell(vec1[1], vec1[2])

    local tinsert = table.insert

    self.grid_indices:set(vec1cx, vec1cy, 1)
    tinsert(self.points, vec1)


    local grid_length = 1
    
    local active_length = 1

    -- local max_distance_sq = self.max_radius * self.max_radius
    local min_distance_sq = self.min_radius * self.min_radius

    local w, h = self.w, self.h


    while active_length > 0 do


        local vec_i = irng:randi(1, active_length)
        local vec = active[vec_i]

        local added_new_point = false

        for k = 1, num_attempts do
            local valid = true
            local radius = sqrt(irng:randf(min_radius * min_radius, max_radius * max_radius))
            local new_x, new_y = irng:random_vec2_times(radius)
            new_x = new_x + vec[1]
            new_y = new_y + vec[2]
            local cell_x = floor(new_x / cell_size) + 1
            local cell_y = floor(new_y / cell_size) + 1

            if new_x < 0 or new_y < 0 or new_x >= w or new_y >= h then
                valid = false
            end

            if valid then
                for j = 1, num_directions do
                    local dir = all_directions[j]
                    local nx, ny = cell_x + dir.x, cell_y + dir.y
                    if nx >= 1 and nx <= grid_indices.w and ny >= 1 and ny <= grid_indices.h then
                        local neighbor_index = grid_indices:get(nx, ny)
                        if neighbor_index ~= 0 and neighbor_index ~= nil then
                            local neighbor = points[neighbor_index]
                            if vec2_distance_squared(neighbor[1], neighbor[2], new_x, new_y) <= min_distance_sq then
                                valid = false
                                break
                            end
                        end
                    end
                end
            end

            if valid then
                local new_vec = { new_x, new_y }
                active_length = active_length + 1
                grid_length = grid_length + 1
                points[grid_length] = new_vec
                active[active_length] = new_vec
                grid_indices:set(cell_x, cell_y, grid_length)
                added_new_point = true
                break
            end
        end

        if not added_new_point then
            active[vec_i] = active[active_length]
            active_length = active_length - 1
        end

    end

    return self.points
end

function Poisson:_to_cell(x, y)
    return floor(x / self.cell_size) + 1, floor(y / self.cell_size) + 1
end

function Poisson:_random_point()
    local x, y = self.irng:randf(0, self.w), self.irng:randf(0, self.h)
    return { x, y }
end


-- bench.start_bench("poisson1")

-- local p = Poisson(10000, 10000, 5, 5)
-- p:generate()

-- bench.end_bench("poisson1")

-- require"lib.poisson2"

return Poisson

