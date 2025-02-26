local CircleCollision = Object:extend("CircleCollision")

function CircleCollision:get_circle_collision_rect()
    return {
        x = self.pos.x - self.collision_radius,
        y = self.pos.y - self.collision_radius,
        width = self.collision_radius * 2,
        height = self.collision_radius * 2
    }
end

function CircleCollision:__mix_init(radius)
    self.collision_radius = self.collision_radius or radius

    if self.collision_radius == nil then
        error("CircleCollision: radius is required")
    end

end

function CircleCollision:update_radius(radius)
    self.collision_radius = radius
	self:emit_signal("moved", self)
end

function CircleCollision:add_to_circle_collision_grid(grid)
	self:add_to_spatial_grid(grid, self.get_circle_collision_rect)
end

function CircleCollision:remove_from_circle_collision_grid(grid)
    self:remove_from_spatial_grid(grid)
end

function CircleCollision:check_object_circle_collision(other)
	return self:is_colliding_with_circle(other.pos.x, other.pos.y, other.collision_radius)
end

function CircleCollision:is_colliding_with_circle(x, y, r2)
    return circle_collision(self.pos.x, self.pos.y, self.collision_radius, x, y, r2)
end

function CircleCollision:collision_circle_contains_point(x, y)
	return circle_contains_point(self.pos.x, self.pos.y, self.collision_radius, x, y)
end


return CircleCollision
