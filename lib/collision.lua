---@diagnostic disable: lowercase-global

function closest_point_on_line_segment(px, py, ax, ay, bx, by)
	local abx, aby = bx - ax, by - ay
	return vec2_lerp(ax, ay, bx, by, clamp01(vec2_dot(px - ax, py - ay, abx, aby) / vec2_dot(abx, aby, abx, aby)))
end

function closest_points_on_two_line_segments(ax, ay, bx, by, cx, cy, dx, dy)
    local ABx = bx - ax
    local ABy = by - ay
    local CDx = dx - cx
    local CDy = dy - cy
    local ACx = cx - ax
    local ACy = cy - ay

    local ABdotAB = ABx*ABx + ABy*ABy     -- |AB|^2
    local CDdotCD = CDx*CDx + CDy*CDy     -- |CD|^2
    local ABdotCD = ABx*CDx + ABy*CDy     -- AB·CD
    local ACdotAB = ACx*ABx + ACy*ABy     -- AC·AB
    local ACdotCD = ACx*CDx + ACy*CDy     -- AC·CD

    local denom = ABdotAB * CDdotCD - ABdotCD * ABdotCD

    local s, t
    if denom ~= 0 then
        -- If denom == 0, lines are parallel or nearly parallel
        s = (ABdotCD * ACdotCD - CDdotCD * ACdotAB) / denom
        t = (ABdotAB * ACdotCD - ABdotCD * ACdotAB) / denom
    else
        -- Parallel or nearly parallel: fallback
        s = 0
        if CDdotCD ~= 0 then
            t = ACdotCD / CDdotCD
        else
            t = 0
        end
    end

    -- Clamp s, t to [0, 1] so the points lie within the segments
    if s < 0 then s = 0 elseif s > 1 then s = 1 end
    if t < 0 then t = 0 elseif t > 1 then t = 1 end

    -- Compute closest points
    local px1 = ax + ABx * s
    local py1 = ay + ABy * s
    local px2 = cx + CDx * t
    local py2 = cy + CDy * t
    return px1, py1, px2, py2
end

function distance_squared_to_line_segment(px, py, ax, ay, bx, by)
	return vec2_distance_squared(px, py, closest_point_on_line_segment(px, py, ax, ay, bx, by))
end

function distance_to_line_segment(px, py, ax, ay, bx, by)
	return sqrt(distance_squared_to_line_segment(px, py, ax, ay, bx, by))
end

function line_segment_intersection_point(ax, ay, bx, by, cx, cy, dx, dy)
	local denominator = ((ax - bx) * (cy - dy) - (ay - by) * (cx - dx))

	if denominator == 0 then
		return nil
	end

	local modifier = 1 / denominator
	local t = ((ax - cx) * (cy - dy) - (ay - cy) * (cx - dx)) * modifier
	local u = -((ax - bx) * (ay - cy) - (ay - by) * (ax - cx)) * modifier

	if t < 0 or t > 1 or u < 0 or u > 1 then return nil end

	return ax + (t * (bx - ax)), ay + (t * (by - ay))
end

function circle_aabb_collision(circle_center_x, circle_center_y, circle_radius, aabb_min_x, aabb_min_y, aabb_max_x, aabb_max_y)
    -- Step 1: Find the closest point on the AABB to the circle's center
    local closest_x = max(aabb_min_x, min(circle_center_x, aabb_max_x))
    local closest_y = max(aabb_min_y, min(circle_center_y, aabb_max_y))

    -- Step 2: Calculate the vector from the circle's center to this closest point
    local distance_x = circle_center_x - closest_x
    local distance_y = circle_center_y - closest_y
    local distance_squared = distance_x * distance_x + distance_y * distance_y

    -- Step 3: Check for collision by comparing distance squared with radius squared
    if distance_squared <= circle_radius * circle_radius then
        return true
    end

    return false -- No collision
end

function circle_aabb_overlap_amount(circle_center_x, circle_center_y, circle_radius, aabb_min_x, aabb_min_y, aabb_max_x, aabb_max_y)
    -- Step 1: Find the closest point on the AABB to the circle's center
    local closest_x = max(aabb_min_x, min(circle_center_x, aabb_max_x))
    local closest_y = max(aabb_min_y, min(circle_center_y, aabb_max_y))

    -- Step 2: Calculate the vector from the circle's center to this closest point
    local distance_x = circle_center_x - closest_x
    local distance_y = circle_center_y - closest_y
    local distance_squared = distance_x * distance_x + distance_y * distance_y

    -- Step 3: Check for collision by comparing distance squared with radius squared
    if distance_squared <= circle_radius * circle_radius then
        -- Calculate the penetration depth (overlap)
        local overlap = circle_radius - sqrt(distance_squared)

        return overlap
    end

    return 0  -- No collision
end

function resolve_circle_aabb_collision(circle_center_x, circle_center_y, circle_radius, aabb_min_x, aabb_min_y, aabb_max_x, aabb_max_y)
    -- Step 1: Find the closest point on the AABB to the circle's center
    local closest_x = max(aabb_min_x, min(circle_center_x, aabb_max_x))
    local closest_y = max(aabb_min_y, min(circle_center_y, aabb_max_y))

    -- Step 2: Calculate the vector from the circle's center to this closest point
    local distance_x = circle_center_x - closest_x
    local distance_y = circle_center_y - closest_y
    local distance_squared = distance_x * distance_x + distance_y * distance_y

    -- Step 3: Check for collision by comparing distance squared with radius squared
    if distance_squared < circle_radius * circle_radius then
        -- Calculate the penetration depth (overlap)
        local overlap = circle_radius - sqrt(distance_squared)

        -- Normalize the distance vector to get the collision normal
        local distance_magnitude = sqrt(distance_squared)
        local normal_x = distance_x / distance_magnitude
        local normal_y = distance_y / distance_magnitude

		local new_x = circle_center_x + normal_x * overlap
		local new_y = circle_center_y + normal_y * overlap
        return new_x, new_y, normal_x, normal_y
    end

    return nil  -- No collision
end

function resolve_circle_circle_collision(cx, cy, cr, ocx, ocy, ocr)
	local dx = cx - ocx
	local dy = cy - ocy
	local rs = cr + ocr
	local distance_squared = dx*dx + dy*dy
	if distance_squared <= rs*rs then
		local distance = sqrt(distance_squared)
		local normal_x = dx / distance
		local normal_y = dy / distance
		local overlap = cr - distance
		local new_x = cx + normal_x * overlap
		local new_y = cy + normal_y * overlap
		return new_x, new_y, normal_x, normal_y
	end
	return nil
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

function circle_capsule_collision(cx, cy, cr, csx1, csy1, csx2, csy2, csr)
    local rs = cr + csr
    return distance_squared_to_line_segment(cx, cy, csx1, csy1, csx2, csy2) <= (rs * rs)
end

function capsule_capsule_collision(ax, ay, bx, by, abr, cx, cy, dx, dy, cdr)
	local pabx, paby, pcdx, pcdy = closest_points_on_two_line_segments(ax, ay, bx, by, cx, cy, dx, dy)
	local rs = abr + cdr
	local dist_x = pcdx - pabx
	local dist_y = pcdy - paby
	return (dist_x*dist_x) + (dist_y*dist_y) <= (rs * rs)
end

