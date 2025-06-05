---@diagnostic disable: lowercase-global
log, floor, ceil, min, abs, sqrt, cos, sin, atan2, pi, max, deg2rad, rad2deg, tau, pow
= math.log, math.floor, math.ceil, math.min, math.abs, math.sqrt, math.cos, math.sin, math.atan2, math.pi, math.max, math.rad, math.deg, math.pi * 2, math.pow
math.e = 2.718281828459045

quarter_tau	 		= tau * 0.25
half_tau            = tau * 0.5
three_quarter_tau   = tau * 0.75
eighth_tau          = tau * 0.125
sixteenth_tau       = tau * 0.0625

function clamp(x, min_x, max_x)
  return min(max(x, min_x), max_x)
end

function clamp01(x)
	return clamp(x, 0, 1)
end

function sign(x)
  return x > 0 and 1 or x < 0 and -1 or 0
end

-- 			   a      0       1      0.25    1
function remap(value, istart, istop, ostart, ostop)
	--     0.25      1.0     0.25        a       0          1       0
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))
end

function remap_upper(value, istart, istop, ostop)
    return istart + (ostop - istart) * ((value - istart) / (istop - istart))
end

-- 					  a    0       1      0.25
function remap_lower(value, istart, istop, ostart)
--         0.25      1       0           a        0         1       0
    return ostart + (istop - ostart) * ((value - istart) / (istop - istart))
end

function remap01(value, ostart, ostop)
	return ostart + (ostop - ostart) * value
end

function remap01_lower(value, ostart)
	return ostart + (1 - ostart) * value
end

function remap01_upper(value, ostop)
	return ostop * value
end

function remap_clamp(value, istart, istop, ostart, ostop)
    return clamp(remap(value, istart, istop, ostart, ostop), min(ostart, ostop), max(ostart, ostop))
end

function remap_pow(value, istart, istop, ostart, ostop, power)
    return ostart + (ostop - ostart) * pow((value - istart) / (istop - istart), power)
end

function stepify(value, step)
	return floor(value / step) * step
end

function sigmoid(x, a, b)
	return a + (b - a) * (1 / (1 + pow(math.e, -x)))
end

function lerp(a, b, t)
	return a + (b - a) * t
end

function round(x)
	return floor(x + 0.5)
end

function dtlerp(power, delta)
    return 1 - pow(pow(0.1, power), delta)
end

function ease_out(num, pow)
    assert(num <= 1 and num >= 0)
    return 1.0 - pow(1.0 - num, pow)
end

function clamp(value, min_val, max_val)
    if value < min_val then return min_val end
    if value > max_val then return max_val end
    return value
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function bezier_quad(x0, y0, x1, y1, x2, y2, t)
    local mt = 1 - t
    local mt2 = mt * mt
    local t2 = t * t
    
    local x = mt2 * x0 + 2 * mt * t * x1 + t2 * x2
    local y = mt2 * y0 + 2 * mt * t * y1 + t2 * y2
    
    return x, y
end

function bezier_cubic(x0, y0, x1, y1, x2, y2, x3, y3, t)
    local mt = 1 - t
    local mt2 = mt * mt
    local mt3 = mt2 * mt
    local t2 = t * t
    local t3 = t2 * t
    
    local x = mt3 * x0 + 3 * mt2 * t * x1 + 3 * mt * t2 * x2 + t3 * x3
    local y = mt3 * y0 + 3 * mt2 * t * y1 + 3 * mt * t2 * y2 + t3 * y3
    
    return x, y
end

function lerp_clamp(a, b, t)
    return lerp(a, b, clamp01(t))
end

function inverse_lerp(a, b, v)
    return (v - a) / (b - a)
end

function inverse_lerp_safe(a, b, v)
    if a == b then return 0 end
    return (v - a) / (b - a)
end

function inverse_lerp_safe_clamp(a, b, v)
    return clamp01(inverse_lerp_safe(a, b, v))
end

function inverse_lerp_clamp(a, b, v)
    return clamp01(inverse_lerp(a, b, v))
end

function angle_diff(a, b)
    local diff = a - b
    return (diff + math.pi) % (2 * math.pi) - math.pi
end


function sin01(value)
    return (sin(value) / 2.0) + 0.5
end

function sin_map(value, min, max)
	return min + (max - min) * sin01(value)
end

function round(n)
    return floor(n + 0.5)
end

function idiv(a, b)
    return floor(a / b)
end

function idivmod(a, b, c)
    return floor(a / b) % c
end

function idivmod_eq_zero(a, b, c)
    return floor(a / b) % c == 0
end


function stepify_safe(s, step)
	if step == 0 then return s end
    return round(s / step) * step
end

function stepify(s, step)
    return round(s / step) * step
end

function stepify_ceil_safe(s, step)
	if step == 0 then return ceil(s) end
	return ceil(s / step) * step
end

function stepify_ceil(s, step)
	return ceil(s / step) * step
end

function gcd(a, b, ...)
    local big = max(a, b)
    local small = min(a, b)


    while small ~= 0 do
		local temp = small
        small = big % small
        big = temp
	end

	local c, d = ...

    if c then
		return gcd(big, c, select(2, ...))
	end

	return big
end

-- print(gcd(4, 11))

-- print(gcd(20, 92, 8, 44))

function vec2_drag(vel_x, vel_y, drag, dt)
	return vel_x * (pow(1 - max(drag, 0.00001), dt)), vel_y * (pow(1 - max(drag, 0.00001), dt))
end

function drag(vel, drag, dt)
	return vel * (pow(1 - max(drag, 0.00001), dt))
end

function math.tent(x)
return 1 - 2 * math.abs(x - 0.5)
end

function math.bump(x)
    return math.cos((x - 0.5) * math.pi)
end

function math.tri(t)
    local period = 2 * math.pi
    local x = t % period
    if x < math.pi then
        return -1 + (2 * x / math.pi)
    else
        return 3 - (2 * x / math.pi)
    end
end

function math.saw(t)
    return t - floor(t)
end

function stepify_floor_safe(s, step)
	step = step or 1
	if step == 0 then return floor(s) end
	return floor(s / step) * step
end

function stepify_floor(s, step)
	step = step or 1
    return floor(s / step) * step
end

function stepify_offset(s, step, offset)
	return stepify(s + offset, step) - offset
end

function wave(from, to, duration, tick, offset)
    if offset == nil then offset = 0 end
    local t = tick or gametime.time
    local a = (to - from) * 0.5
    return from + a + sin(((t + duration * offset) / duration) * (2 * pi)) * a
end

function pulse(duration, width, tick, offset)
    if duration == nil then duration = 1.0 end
    if width == nil then width = 0.5 end
    return wave(0.0, 1.0, duration, offset, tick) < width
end

local epsilon = 0.00001

function is_approx_equal(a, b)
    return abs(a - b) < (epsilon)
end

function rad2deg(rad)
	return rad * (180 / pi)
end

function snap(value, step)
    return round(value / step) * step
end

function approach(a, b, amount)
    if a < b then
        a = a + amount
        if a > b then return b end
    else
        a = a - amount
        if a < b then return b end
    end
    return a
end

function next_power_of_2(n)
	power = 1
	while(power < n) do
		power = power * 2
	end
	return power
end


function polar_to_cartesian(distance, angle)
    local x = cos(angle) * distance
    local y = sin(angle) * distance
    return x, y
end

function logb(x, base)
    return log(x) / log(base)
end

function smoothstep(edge0, edge1, x)
    local t = clamp01((x - edge0) / (edge1 - edge0))
    return t * t * (3 - 2 * t)
end

-- Exponential decay function (splerp) for scalars
function splerp(a, b, half_life, delta)
    return b + (a - b) * pow(2, -delta / (frames_to_seconds(half_life)))
end

-- Exponential decay function (splerp) for Vec2
function splerp_vec_table(a, b, half_life, delta)
    local t = pow(2, -delta / (frames_to_seconds(half_life)))
    return b + (a - b) * t  -- Uses Vec2 operations
end

function splerp_vec(ax, ay, bx, by, half_life, delta)
	local t = pow(2, -delta / (frames_to_seconds(half_life)))
	return bx + (ax - bx) * t, by + (ay - by) * t
end

-- Exponential decay function (splerp) for Vec3
function splerp_vec3_table(a, b, half_life, delta)
    local t = pow(2, -delta / (frames_to_seconds(half_life)))
    return b + (a - b) * t  -- Uses Vec3 operations
end

function splerp_vec3(ax, ay, az, bx, by, bz, half_life, delta)
	local t = pow(2, -delta / (frames_to_seconds(half_life)))
	return bx + (ax - bx) * t, by + (ay - by) * t, bz + (az - bz) * t
end

function lerp_angle(a, b, t)
    local diff = ((b - a + pi) % (2 * pi)) - pi
    return a + diff * t
end

function splerp_angle(a, b, half_life, delta)
    local t = 1 - pow(2, -delta / (frames_to_seconds(half_life)))
    return lerp_angle(a, b, t)
end

function lerp_wrap(a, b, mod_value, t)
    local delta = ((b - a) % mod_value + mod_value) % mod_value
    if delta > mod_value / 2 then
        delta = delta - mod_value
    end
    return ((a + delta * t) % mod_value + mod_value) % mod_value
end

function splerp_wrap(a, b, mod_value, half_life, delta)
    local t = 1 - pow(2, -delta / (frames_to_seconds(half_life)))
    return lerp_wrap(a, b, mod_value, t)
end

function wrap_diff(a, b, period)
    local diff = a - b
    return (diff + period / 2) % period - period / 2
end

function wrap_dist_from_center(from_value, center, wrap)
    return wrap_diff(from_value, center, wrap)
end

function ping_pong_interpolate(value, a, b, ease_value)
    if ease_value == nil then ease_value = 1.0 end
    local start = min(a, b)
    local finish = max(a, b)
    local t = inverse_lerp(start, finish, value)
    local f = t % 1.0
    if (floor(t) % 2) ~= 0 then
        f = 1.0 - f
    end
    return start + pow(f, ease_value) * (finish - start)
end

function damp(source, target, smoothing, dt)
    return lerp(source, target, dtlerp(smoothing, dt))
end

function damp_angle(source, target, smoothing, dt)
    return lerp_angle(source, target, 1 - pow(smoothing, dt))
end

function damp_vec2(source, target, smoothing, dt)
    local t = 1 - pow(smoothing, dt)
    return source + (target - source) * t  -- Uses Vec2 operations
end

function damp_vec3(source, target, smoothing, dt)
    local t = 1 - pow(smoothing, dt)
    return source + (target - source) * t  -- Uses Vec3 operations
end

function vec_dir(vec_1, vec_2)
    return (vec_2 - vec_1):normalized()  -- Uses Vec2 methods
end

-- Example function for clamping a cell within a map's dimensions
function clamp_cell(cell, map)
    return Vec2(
        clamp(cell.x, 0, map.width - 1),
        clamp(cell.y, 0, map.height - 1)
    )
end

function fposmod(x, y)
	return x - y * floor(x / y)
end

function floor_div(a, b)
	return floor(a / b)
end

function iposmod(x, y)
	return x - y * floor_div(x, y)
end

function point_along_line_segment(ax, ay, bx, by, distance)
	local dir_x, dir_y = bx - ax, by - ay
	local len = sqrt(dir_x * dir_x + dir_y * dir_y)
	dir_x = dir_x / len
	dir_y = dir_y / len
	return ax + dir_x * distance, ay + dir_y * distance
end

function point_along_line_segment_clamped(ax, ay, bx, by, distance)
	local dir_x, dir_y = bx - ax, by - ay
	local len = sqrt(dir_x * dir_x + dir_y * dir_y)
	dir_x = dir_x / len
	dir_y = dir_y / len
	return ax + dir_x * clamp(distance, 0, len), ay + dir_y * clamp(distance, 0, len)
end


function get_ellipse_point(a, b, angle, phase)
    local x = a * math.cos(angle + phase)
    local y = b * math.sin(angle + phase)
    return x, y
end


function get_line_bounds(x1, y1, x2, y2)
    -- gets the aabb of the line in the form x, y, w, h
    local min_x = min(x1, x2)
    local min_y = min(y1, y2)
    local max_x = max(x1, x2)
    local max_y = max(y1, y2)
    return min_x, min_y, max_x - min_x, max_y - min_y
end

-- Function to clamp a point to the nearest point on or within a capsule
function clamp_point_to_capsule(point_x, point_y, capsule_ax, capsule_ay, capsule_bx, capsule_by, capsule_radius)
    -- Calculate the line segment vector from A to B
    local ab_x = capsule_bx - capsule_ax
    local ab_y = capsule_by - capsule_ay

    -- Calculate vector from A to the point
    local ap_x = point_x - capsule_ax
    local ap_y = point_y - capsule_ay

    -- Calculate the squared length of AB to avoid division by zero
    local ab_length_squared = ab_x * ab_x + ab_y * ab_y

    -- Handle degenerate case where A and B are the same point (capsule is just a circle)
    if ab_length_squared == 0 then
        local distance = math.sqrt(ap_x * ap_x + ap_y * ap_y)
        if distance <= capsule_radius then
            -- Point is already inside the circle
            return point_x, point_y
        else
            -- Clamp to circle boundary
            local scale = capsule_radius / distance
            return capsule_ax + ap_x * scale, capsule_ay + ap_y * scale
        end
    end

    -- Project point onto the line segment AB
    -- t represents how far along the line segment the projection is (0 = A, 1 = B)
    local t = (ap_x * ab_x + ap_y * ab_y) / ab_length_squared

    -- Clamp t to [0, 1] to stay within the line segment
    t = math.max(0, math.min(1, t))

    -- Find the closest point on the line segment to our input point
    local closest_x = capsule_ax + t * ab_x
    local closest_y = capsule_ay + t * ab_y

    -- Calculate distance from input point to closest point on line segment
    local distance_x = point_x - closest_x
    local distance_y = point_y - closest_y
    local distance = math.sqrt(distance_x * distance_x + distance_y * distance_y)

    -- If point is already within the capsule, return it unchanged
    if distance <= capsule_radius then
        return point_x, point_y
    end

    -- If point is outside, clamp it to the capsule surface
    local scale = capsule_radius / distance
    local clamped_x = closest_x + distance_x * scale
    local clamped_y = closest_y + distance_y * scale

    return clamped_x, clamped_y
end


function get_ellipse_arc_length(a, b, angle)
    local h = ((a - b) / (a + b)) ^ 2
    local perimeter = math.pi * (a + b) * (1 + (3 * h) / (10 + math.sqrt(4 - 3 * h)))
    return (angle / (2 * math.pi)) * perimeter
end

function find_angle_at_distance(target_distance, a, b, start_angle, step)
    -- Binary search to find angle that gives us desired arc length
    step = step or 0.001
    local current_distance = 0
    local current_angle = start_angle
    local last_x, last_y = get_ellipse_point(a, b, start_angle, 0)
    
    while current_distance < target_distance do
        current_angle = current_angle + step
        local x, y = get_ellipse_point(a, b, current_angle, 0)
        
        -- Calculate actual 2D distance between points
        local dx = x - last_x
        local dy = y - last_y
        current_distance = current_distance + math.sqrt(dx * dx + dy * dy)
        
        last_x, last_y = x, y
    end
    
    return current_angle
end
