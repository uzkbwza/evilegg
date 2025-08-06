local CollisionBubble = Object:extend("CollisionBubble")

CollisionBubble.is_bubble = true

local collision_handlers
collision_handlers = {
    circle = {
        circle = function(b1, b2)
            local x1, y1 = b1:get_position()
            local x2, y2 = b2:get_position()
            return circle_collision(x1, y1, b1.radius, x2, y2, b2.radius)
        end,
        capsule = function(b1, b2)
            local x1, y1 = b1:get_position()
            local x2, y2 = b2:get_position()
            local x2_2, y2_2 = b2:get_end_position()
            return circle_capsule_collision(x1, y1, b1.radius, x2, y2, x2_2, y2_2, b2.radius)
        end,
        aabb = function(b1, b2)
            local x1, y1 = b1:get_position()
            local x2, y2 = b2:get_position()
            return circle_aabb_collision(x1, y1, b1.radius, x2 - b2.width * 0.5, y2 - b2.height * 0.5, b2.width, b2.height)
        end,
    },
    capsule = {
        circle = function(b1, b2)
            return collision_handlers.circle.capsule(b2, b1)
        end,
        capsule = function(b1, b2)
            local x1, y1 = b1:get_position()
            local x1_2, y1_2 = b1:get_end_position()
            local x2, y2 = b2:get_position()
            local x2_2, y2_2 = b2:get_end_position()
            return capsule_capsule_collision(x1, y1, x1_2, y1_2, b1.radius, x2, y2, x2_2, y2_2, b2.radius)
        end,
        aabb = function(b1, b2)
            local x1, y1 = b1:get_position()
            local x1_2, y1_2 = b1:get_end_position()
            local x2, y2 = b2:get_position()
            return capsule_aabb_collision(x1, y1, x1_2, y1_2, b1.radius, x2 - b2.width * 0.5, y2 - b2.height * 0.5, b2.width, b2.height)
        end,
    },
    aabb = {
        circle = function(b1, b2)
            return collision_handlers.circle.aabb(b2, b1)
        end,
        capsule = function(b1, b2)
            return collision_handlers.capsule.aabb(b2, b1)
        end,
        aabb = function(b1, b2)
            local x1, y1 = b1:get_position()
            local x2, y2 = b2:get_position()
            return aabb_aabb_collision(x1 - b1.width * 0.5, y1 - b1.height * 0.5, b1.width, b1.height, x2 - b2.width * 0.5, y2 - b2.height * 0.5, b2.width, b2.height)
        end,
    }
}

local shape_methods = {
    circle = {
        collides_with_circle = function(self, x, y, radius)
            local my_x, my_y = self:get_position()
            return circle_collision(my_x, my_y, self.radius, x, y, radius)
        end,
        collides_with_capsule = function(self, x, y, x2, y2, radius)
            local my_x, my_y = self:get_position()
            return circle_capsule_collision(my_x, my_y, self.radius, x, y, x2, y2, radius)
        end,
        collides_with_aabb = function(self, x, y, width, height)
            local my_x, my_y = self:get_position()
            return circle_aabb_collision(my_x, my_y, self.radius, x, y, width, height)
        end,
        get_rect = function(self)
            return self.parent_x + self.x - self.radius, self.parent_y + self.y - self.radius, self.radius * 2, self.radius * 2
        end
    },
    capsule = {
        collides_with_circle = function(self, x, y, radius)
            local my_x, my_y = self:get_position()
            local my_x2, my_y2 = self:get_end_position()
            return circle_capsule_collision(x, y, radius, my_x, my_y, my_x2, my_y2, self.radius)
        end,
        collides_with_capsule = function(self, x, y, x2, y2, radius)
            local my_x, my_y = self:get_position()
            local my_x2, my_y2 = self:get_end_position()
            return capsule_capsule_collision(my_x, my_y, my_x2, my_y2, self.radius, x, y, x2, y2, radius)
        end,
        collides_with_aabb = function(self, x, y, width, height)
            local my_x, my_y = self:get_position()
            local my_x2, my_y2 = self:get_end_position()
            return capsule_aabb_collision(my_x, my_y, my_x2, my_y2, self.radius, x, y, width, height)
        end,
        get_rect = function(self)
            local x, y = self:get_position()
            local x2, y2 = self:get_end_position()
            return get_capsule_rect(x, y, x2, y2, self.radius)
        end
    },
    aabb = {
        collides_with_circle = function(self, x, y, radius)
            local my_x, my_y = self:get_position()
            return circle_aabb_collision(x, y, radius, my_x - self.width * 0.5, my_y - self.height * 0.5, self.width, self.height)
        end,
        collides_with_capsule = function(self, x, y, x2, y2, radius)
            local my_x, my_y = self:get_position()
            return capsule_aabb_collision(x, y, x2, y2, radius, my_x - self.width * 0.5, my_y - self.height * 0.5, self.width, self.height)
        end,
        collides_with_aabb = function(self, x, y, width, height)
            local my_x, my_y = self:get_position()
            return aabb_aabb_collision(my_x - self.width * 0.5, my_y - self.height * 0.5, self.width, self.height, x, y, width, height)
        end,
        get_rect = function(self)
            return self.parent_x + self.x - self.width * 0.5, self.parent_y + self.y - self.height * 0.5, self.width, self.height
        end
    }
}

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
            self.shape_type = "capsule"
        else
            self.width = radius
            self.height = x2
            self.shape_type = "aabb"
        end
    else
        self.shape_type = "circle"
	end

    local methods = shape_methods[self.shape_type]
    self.collides_with_circle = methods.collides_with_circle
    self.collides_with_capsule = methods.collides_with_capsule
    self.collides_with_aabb = methods.collides_with_aabb
    self.get_rect = methods.get_rect
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
    local handler = collision_handlers[self.shape_type][other.shape_type]
    return handler(self, other)
end

function CollisionBubble:set_radius(radius)
    self.radius = radius
end

function CollisionBubble:set_rect_width_height(width, height)
    self.width = width
    self.height = height
end

return CollisionBubble
