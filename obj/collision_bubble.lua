local CollisionBubble = Object:extend("CollisionBubble")

CollisionBubble.is_bubble = true

function CollisionBubble:new(parent, x, y, parent_x, parent_y, radius, x2, y2)
    self.x = x
    self.y = y
    self.parent_x = parent_x
    self.parent_y = parent_y
	self.parent = parent
    self.radius = radius
	self.x2 = x2
	self.y2 = y2
    if x2 then
        if y2 then
            -- self.shape_type = "capsule"
            self.capsule = true
            self.get_rect = self.get_capsule_rect
            self.collides_with_bubble = self.capsule_collides_with_bubble
            self.collides_with_circle = self.capsule_collides_with_circle
            self.collides_with_capsule = self.capsule_collides_with_capsule
            self.collides_with_aabb = self.capsule_collides_with_aabb
        else
            self.width = radius
            self.height = x2
            -- self.shape_type = "aabb"
            self.aabb = true
            self.get_rect = self.get_aabb_rect
            self.collides_with_bubble = self.aabb_collides_with_bubble
            self.collides_with_circle = self.aabb_collides_with_circle
            self.collides_with_capsule = self.aabb_collides_with_capsule
            self.collides_with_aabb = self.aabb_collides_with_aabb
        end
    -- else
        -- self.shape_type = "circle"
	end
end

function CollisionBubble:get_capsule_rect()
	local x, y = self:get_position()
	local x2, y2 = self:get_end_position()
	return get_capsule_rect(x, y, x2, y2, self.radius)
end

function CollisionBubble:get_aabb_rect()
    return self.parent_x + self.x - self.width * 0.5, self.parent_y + self.y - self.height * 0.5, self.width, self.height
end

function CollisionBubble:capsule_collides_with_bubble(other)
	local my_x, my_y = self:get_position()
	local my_x2, my_y2 = self:get_end_position()
    local other_x, other_y = other:get_position()
    if other.capsule then
		local other_x2, other_y2 = other:get_end_position()
        return capsule_capsule_collision(my_x, my_y, my_x2, my_y2, self.radius, other_x, other_y, other_x2, other_y2,
        other.radius)
    elseif other.aabb then
        return capsule_aabb_collision(my_x, my_y, my_x2, my_y2, self.radius, other_x, other_y, other.width, other.height)
	end
	return circle_capsule_collision(other_x, other_y, other.radius, my_x, my_y, my_x2, my_y2, self.radius)
end

function CollisionBubble:capsule_collides_with_circle(x, y, radius)
    local my_x, my_y = self:get_position()
	local my_x2, my_y2 = self:get_end_position()
    return circle_capsule_collision(x, y, radius, my_x, my_y, my_x2, my_y2, self.radius)
end

function CollisionBubble:capsule_collides_with_aabb(x, y, width, height)
    local my_x, my_y = self:get_position()
    local my_x2, my_y2 = self:get_end_position()
    return capsule_aabb_collision(my_x, my_y, my_x2, my_y2, self.radius, x, y, width, height)
end

function CollisionBubble:capsule_collides_with_capsule(x, y, x2, y2, radius)
    local my_x, my_y = self:get_position()
    local my_x2, my_y2 = self:get_end_position()
    return capsule_capsule_collision(my_x, my_y, my_x2, my_y2, self.radius, x, y, x2, y2, radius)
end

function CollisionBubble:aabb_collides_with_bubble(other)
    local my_x, my_y = self:get_position()
    local other_x, other_y = other:get_position()
    if other.capsule then
        local other_x2, other_y2 = other:get_end_position()
        return capsule_aabb_collision(other_x, other_y, other_x2, other_y2, other.radius, my_x - self.width * 0.5, my_y - self.height * 0.5, self.width, self.height)
    elseif other.aabb then
        return aabb_aabb_collision(other_x, other_y, other.width, other.height, my_x - self.width * 0.5, my_y - self.height * 0.5, self.width, self.height)
    end
    return circle_aabb_collision(other_x, other_y, other.radius, my_x - self.width * 0.5, my_y - self.height * 0.5, self.width, self.height)
end

function CollisionBubble:aabb_collides_with_capsule(x, y, x2, y2, radius)
    local my_x, my_y = self:get_position()
    return capsule_aabb_collision(x, y, x2, y2, radius, my_x - self.width * 0.5, my_y - self.height * 0.5, self.width, self.height)
end

function CollisionBubble:aabb_collides_with_aabb(x, y, width, height)
    local my_x, my_y = self:get_position()
    return aabb_aabb_collision(my_x, my_y, self.width, self.height, x, y, width, height)
end

function CollisionBubble:set_parent_position(x, y)
    self.parent_x = x
    self.parent_y = y
end

function CollisionBubble:set_position(x, y)
    self.x = x
    self.y = y
end

function CollisionBubble:set_capsule_end_points(x2, y2)
	self.x2 = x2
	self.y2 = y2
end

function CollisionBubble:get_position()
    return self.parent_x + self.x * (self.parent.flip or 1), self.parent_y + self.y
end

function CollisionBubble:get_end_position()
    return self.parent_x + self.x2 * (self.parent.flip or 1), self.parent_y + self.y2
end

function CollisionBubble:collides_with_bubble(other)
	local my_x, my_y = self:get_position()
    local other_x, other_y = other:get_position()
	if other.capsule then
		local other_x2, other_y2 = other:get_end_position()
		return circle_capsule_collision(my_x, my_y, self.radius, other_x, other_y, other_x2, other_y2, other.radius)
    elseif other.aabb then
        return circle_aabb_collision(my_x, my_y, self.radius, other_x - other.width * 0.5, other_y - other.height * 0.5, other.width, other.height)
	end
	return circle_collision(my_x, my_y, self.radius, other_x, other_y, other.radius)
end

function CollisionBubble:collides_with_circle(x, y, radius)
    local my_x, my_y = self:get_position()
    return circle_collision(my_x, my_y, self.radius, x, y, radius)
end

function CollisionBubble:collides_with_capsule(x, y, x2, y2, radius)
	local my_x, my_y = self:get_position()
	return circle_capsule_collision(my_x, my_y, self.radius, x, y, x2, y2, radius)
end

function CollisionBubble:collides_with_aabb(x, y, width, height)
    local my_x, my_y = self:get_position()
    return circle_aabb_collision(my_x, my_y, self.radius, x, y, width, height)
end

function CollisionBubble:set_radius(radius)
    self.radius = radius
end

function CollisionBubble:set_rect_width_height(width, height)
    self.width = width
    self.height = height
end

function CollisionBubble:get_rect()
    return self.parent_x + self.x - self.radius, self.parent_y + self.y - self.radius, self.radius * 2, self.radius * 2
end

return CollisionBubble
