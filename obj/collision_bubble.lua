local CollisionBubble = Object:extend("CollisionBubble")

CollisionBubble.is_bubble = true

function CollisionBubble:new(parent, x, y, parent_x, parent_y, radius)
    self.x = x
    self.y = y
    self.parent_x = parent_x
    self.parent_y = parent_y
	self.parent = parent
    self.radius = radius
end

function CollisionBubble:set_parent_position(x, y)
    self.parent_x = x
    self.parent_y = y
end

function CollisionBubble:set_position(x, y)
    self.x = x
    self.y = y
end

function CollisionBubble:get_position()
    return self.parent_x + self.x, self.parent_y + self.y
end

function CollisionBubble:collides_with_bubble(other)
	local my_x, my_y = self:get_position()
	local other_x, other_y = other:get_position()
	return circle_collision(my_x, my_y, self.radius, other_x, other_y, other.radius)
end

function CollisionBubble:collides_with_circle(x, y, radius)
	local my_x, my_y = self:get_position()
	return circle_collision(my_x, my_y, self.radius, x, y, radius)
end

function CollisionBubble:set_radius(radius)
    self.radius = radius
end

function CollisionBubble:get_rect()
    return self.parent_x + self.x - self.radius, self.parent_y + self.y - self.radius, self.radius * 2, self.radius * 2
end

return CollisionBubble
