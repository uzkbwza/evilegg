---@diagnostic disable: lowercase-global

function circle_aabb_collision(circle_center, circle_radius, aabb_min, aabb_max)
    -- Step 1: Find the closest point on the AABB to the circle's center
    local closest_x = math.max(aabb_min.x, math.min(circle_center.x, aabb_max.x))
    local closest_y = math.max(aabb_min.y, math.min(circle_center.y, aabb_max.y))

    -- Step 2: Calculate the vector from the circle's center to this closest point
    local distance_x = circle_center.x - closest_x
    local distance_y = circle_center.y - closest_y
    local distance_squared = distance_x * distance_x + distance_y * distance_y

    -- Step 3: Check for collision by comparing distance squared with radius squared
    if distance_squared < circle_radius * circle_radius then

        return true
    end

    return false -- No collision
end

function circle_aabb_overlap(circle_center, circle_radius, aabb_min, aabb_max)
    -- Step 1: Find the closest point on the AABB to the circle's center
    local closest_x = math.max(aabb_min.x, math.min(circle_center.x, aabb_max.x))
    local closest_y = math.max(aabb_min.y, math.min(circle_center.y, aabb_max.y))

    -- Step 2: Calculate the vector from the circle's center to this closest point
    local distance_x = circle_center.x - closest_x
    local distance_y = circle_center.y - closest_y
    local distance_squared = distance_x * distance_x + distance_y * distance_y

    -- Step 3: Check for collision by comparing distance squared with radius squared
    if distance_squared < circle_radius * circle_radius then
        -- Calculate the penetration depth (overlap)
        local overlap = circle_radius - math.sqrt(distance_squared)

        return overlap 
    end

    return 0  -- No collision
end


function resolve_circle_aabb_collision(circle_center, circle_radius, aabb_min, aabb_max)
    -- Step 1: Find the closest point on the AABB to the circle's center
    local closest_x = math.max(aabb_min.x, math.min(circle_center.x, aabb_max.x))
    local closest_y = math.max(aabb_min.y, math.min(circle_center.y, aabb_max.y))

    -- Step 2: Calculate the vector from the circle's center to this closest point
    local distance_x = circle_center.x - closest_x
    local distance_y = circle_center.y - closest_y
    local distance_squared = distance_x * distance_x + distance_y * distance_y

    -- Step 3: Check for collision by comparing distance squared with radius squared
    if distance_squared < circle_radius * circle_radius then
        -- Calculate the penetration depth (overlap)
        local overlap = circle_radius - math.sqrt(distance_squared)

        -- Normalize the distance vector to get the collision normal
        local distance_magnitude = math.sqrt(distance_squared)
        local normal_x = distance_x / distance_magnitude
        local normal_y = distance_y / distance_magnitude

        -- Push the circle out of the AABB along the normal
        circle_center.x = circle_center.x + normal_x * overlap
        circle_center.y = circle_center.y + normal_y * overlap

        return true  -- Collision was resolved
    end

    return false  -- No collision
end


function circle_collision(x1, y1, r1, x2, y2, r2)
	local dx = x1 - x2
    local dy = y1 - y2
	local rs = r1 + r2
	return (dx*dx) + (dy*dy) <= (rs * rs)
end

function circle_contains_point(cx, cy, cr, x, y)
	local dx = cx - x
    local dy = cy - y
	return (dx*dx) + (dy*dy) <= (cr * cr)
end
