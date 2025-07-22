-- poisson.lua --------------------------------------------------------------
-- Bridson Poisson‑Disk sampling in 2‑D
local Poisson = Object:extend("Poisson")

-- Create a sampler covering width × height, minimum distance r, k trials
function Poisson:new(w, h, radius, num_attempts)
    local r = radius
    local k = num_attempts
    local cell = r / math.sqrt(2)
    self.w = w
    self.h = h
    self.r = r
    self.r2 = r * r
    self.k = k
    self.cell = cell
    self.grid_w = math.ceil(w / cell)
    self.grid_h = math.ceil(h / cell)
    self.grid = {}   -- sparse [i + j*grid_w] = {x, y}
    self.active = {} -- stack of point indices
    self.points = {} -- { {x, y}, ... }
end

-- Public: generate and return points
function Poisson:generate()
    self:_spawn_initial()
    while #self.active > 0 do
        local idx = math.random(#self.active)
        local pi = self.active[idx]
        local base = self.points[pi]
        local found = false

        for _ = 1, self.k do
            local nx, ny = self:_random_annulus(base[1], base[2])
            if self:_in_bounds(nx, ny) and self:_far_enough(nx, ny) then
                self:_add_point(nx, ny)
                found = true
                break
            end
        end

        if not found then -- retire
            self.active[idx] = self.active[#self.active]
            self.active[#self.active] = nil
        end
    end
    return self.points
end

-- -------------------------------------------------------------------------
-- Internal helpers
function Poisson:_spawn_initial()
    local x, y = math.random() * self.w, math.random() * self.h
    self:_add_point(x, y)
end

function Poisson:_add_point(x, y)
    local p = { x, y }
    table.insert(self.points, p)
    table.insert(self.active, #self.points)
    local ci, cj = self:_cell_coords(x, y)
    self.grid[ci + cj * self.grid_w] = p
end

function Poisson:_random_annulus(cx, cy)
    local r = self.r * (1 + math.random())
    local a = math.random() * 2 * math.pi
    return cx + r * math.cos(a), cy + r * math.sin(a)
end

function Poisson:_cell_coords(x, y)
    return math.floor(x / self.cell), math.floor(y / self.cell)
end

function Poisson:_in_bounds(x, y)
    return x >= 0 and x < self.w and y >= 0 and y < self.h
end

function Poisson:_far_enough(x, y)
    local ci, cj = self:_cell_coords(x, y)
    for i = ci - 2, ci + 2 do
        if i >= 0 and i < self.grid_w then
            for j = cj - 2, cj + 2 do
                if j >= 0 and j < self.grid_h then
                    local neighbour = self.grid[i + j * self.grid_w]
                    if neighbour then
                        local dx, dy = x - neighbour[1], y - neighbour[2]
                        if dx * dx + dy * dy < self.r2 then return false end
                    end
                end
            end
        end
    end
    return true
end

---------------------------------------------------------------------------

return Poisson
