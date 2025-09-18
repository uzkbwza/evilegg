Rect = Object:extend("Rect")
---@diagnostic disable: lowercase-global

function Rect:new(x, y, width, height)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 0
    self.height = height or width
end

function Rect.centered(x, y, width, height)
	height = height or width
	return Rect(x - width / 2, y - height / 2, width, height)
end

function Rect:to_centered()
	return Rect.centered(self.x, self.y, self.width, self.height)
end

function Rect:ends()
	return self.x + self.width, self.y + self.height
end

function Rect:center_to(x, y, width, height)
    self.width = width or self.width
    self.height = height or self.height
    self.x = x - self.width / 2
    self.y = y - self.height / 2
    return self
end


-- Define addition for rect position shift
function Rect.__add(a, b)
    return Rect(a.x + b.x, a.y + b.y, a.width, a.height)
end

-- Define subtraction for rect position shift
function Rect.__sub(a, b)
    return Rect(a.x - b.x, a.y - b.y, a.width, a.height)
end

-- Scaling by scalar
function Rect.__mul(a, b)
    if type(b) == "number" then
        return Rect(a.x, a.y, a.width * b, a.height * b)
    else
        error("Rect can only be multiplied by a scalar.")
    end
end

function Rect.__div(a, b)
    if type(b) == "number" then
        return Rect(a.x, a.y, a.width / b, a.height / b)
    else
        error("Rect can only be divided by a scalar.")
    end
end

function Rect.__eq(a, b)
    return a.x == b.x and a.y == b.y and a.width == b.width and a.height == b.height
end

function Rect:area()
    return self.width * self.height
end

function Rect:contains(px, py)
    return px >= self.x and px <= self.x + self.width and
        py >= self.y and py <= self.y + self.height
end


function Rect:contains_circle(px, py, radius)
    return px >= self.x + radius and px <= self.x + self.width - radius and
        py >= self.y + radius and py <= self.y + self.height - radius
end

function Rect:clamp_point(px, py)
    return clamp(px, self.x, self.x + self.width), clamp(py, self.y, self.y + self.height)
end

function Rect:get_line_intersection(x1, y1, x2, y2)
    return line_rect_intersection(x1, y1, x2, y2, self.x, self.y, self.width, self.height)
end

function Rect:clamp_circle(px, py, radius)
    return clamp(px, self.x - radius, self.x + self.width + radius), clamp(py, self.y - radius, self.y + self.height + radius)
end

function Rect:intersects(other)
	return self.x < other.x + other.width and


		   self.x + self.width > other.x and
		   self.y < other.y + other.height and
		   self.y + self.height > other.y
end

function Rect:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
    return self
end

function Rect:scale(factor)
    self.width = self.width * factor
    self.height = self.height * factor
    return self
end

function Rect:clone()
    return Rect(self.x, self.y, self.width, self.height)
end

function Rect:__tostring()
    return "Rect(x=" .. self.x .. ", y=" .. self.y .. ", width=" .. self.width .. ", height=" .. self.height .. ")"
end

function Rect:perimeter()
    return self.width * 2 + self.height * 2
end

function rect_perimeter(w, h)
    return w * 2 + h * 2
end


function rect_clamp_point(px, py, rx, ry, rw, rh)
    return clamp(px, rx, rx + rw), clamp(py, ry, ry + rh)
end

