local SimplePhysics2D = Object:extend("SimplePhysics2D")

function SimplePhysics2D:apply_forcev(force)
	self.accel:add_in_place(force.x, force.y)
end

function SimplePhysics2D:apply_force(forcex, forcey)
	self.accel:add_in_place(forcex, forcey)
end

function SimplePhysics2D:__mix_init()
	self.vel = self.vel or Vec2(0, 0)
	self.accel = self.accel or Vec2(0, 0)
	self.impulses = self.impulses or Vec2(0, 0)
	self:add_update_function(SimplePhysics2D.apply_simple_physics)
    self.horizontal_drag = self.horizontal_drag or 0.0
    self.vertical_drag = self.vertical_drag or 0.0
	self.drag = self.drag or 0.1
    self.is_simple_physics_object = true
	self.applying_physics = true
    self.gravity = self.gravity or 0
    self.manipulate_velocity_functions = {}
    self.slide_functions = {}
	table.insert(self.slide_functions, function(self, col)
		self.vel:mul_in_place(col.normal.x ~= 0 and 0 or 1, col.normal.y ~= 0 and 0 or 1)
	end)
end

function SimplePhysics2D:add_manipulate_velocity_function(func)
	table.insert(self.manipulate_velocity_functions, func)
end

function SimplePhysics2D:set_physics_limits(t)
    if t.max_speed then
        self.max_speed = t.max_speed
        self:add_manipulate_velocity_function(function(self, dt)
            local speed = self.vel:magnitude()
            if speed > self.max_speed then
                self.vel:normalize_in_place()
                self.vel:mul_in_place(self.max_speed)
            end
        end)
    end

    if t.max_horizontal_speed then
        self.max_horizontal_speed = t.max_horizontal_speed
        self:add_manipulate_velocity_function(function(self, dt)
            if abs(self.vel.x) > self.max_horizontal_speed then
                self.vel.x = self.max_horizontal_speed * sign(self.vel.x)
            end
        end)
    end

    if t.max_vertical_speed then
        self.max_vertical_speed = t.max_vertical_speed
        self:add_manipulate_velocity_function(function(self, dt)
            if abs(self.vel.y) > self.max_vertical_speed then
                self.vel.y = self.max_vertical_speed * sign(self.vel.y)
            end
        end)
    end

    if t.max_upward_speed then
        self.max_upward_speed = t.max_upward_speed
        self:add_manipulate_velocity_function(function(self, dt)
            if self.vel.y < -self.max_upward_speed then
                self.vel.y = -self.max_upward_speed
            end
        end)
    end

    if t.max_downward_speed then
        self.max_downward_speed = t.max_downward_speed
        self:add_manipulate_velocity_function(function(self, dt)
            if self.vel.y > self.max_downward_speed then
                self.vel.y = self.max_downward_speed
            end
        end)
    end

    if t.max_rightward_speed then
        self.max_rightward_speed = t.max_rightward_speed
        self:add_manipulate_velocity_function(function(self, dt)
            if self.vel.x > self.max_rightward_speed then
                self.vel.x = self.max_rightward_speed
            end
        end)
    end

    if t.max_leftward_speed then
        self.max_leftward_speed = t.max_leftward_speed
        self:add_manipulate_velocity_function(function(self, dt)
            if self.vel.x < -self.max_leftward_speed then
                self.vel.x = -self.max_leftward_speed
            end
        end)
    end
end

function SimplePhysics2D:reset_physics()
	self.vel:mul_in_place(0)
	self.accel:mul_in_place(0)
	self.impulses:mul_in_place(0)
end

function SimplePhysics2D:apply_force_relative(forcex, forcey)
	self:apply_force(self.flip * forcex, forcey)
end

function SimplePhysics2D:apply_forcev_relative(force)
	self:apply_force(force.x * self.flip, force.y)
end

function SimplePhysics2D:apply_impulse(forcex, forcey)
	self.impulses:add_in_place(forcex, forcey)
end

function SimplePhysics2D:apply_impulsev(force)
	self.impulses:add_in_place(force.x, force.y)
end

function SimplePhysics2D:apply_impulse_relative(forcex, forcey)
    self:apply_impulse(self.flip * forcex, forcey)
end

function SimplePhysics2D:apply_impulsev_relative(force)
    self:apply_impulse(force.x * self.flip, force.y)
end

function SimplePhysics2D:physics_move(dt)
	self:move_to(self.pos.x + self.vel.x * dt, self.pos.y + self.vel.y * dt)
end

function SimplePhysics2D:apply_simple_physics(dt)
	if not self.applying_physics then return end
    -- self:apply_force(0, self.gravity)
    local ax, ay = vec2_mul_scalar(self.accel.x, self.accel.y, dt)
	local ix, iy = self.impulses.x, self.impulses.y
	self.vel:add_in_place(ix, iy)
    self.vel:add_in_place(ax, ay)
    for i, func in ipairs(self.manipulate_velocity_functions) do
        func(self, dt)
    end
	
	self:physics_move(dt)
	
	self.accel:mul_in_place(0)
	self.impulses:mul_in_place(0)

	self.vel.x = self.vel.x * (pow(1 - max(self.drag, self.horizontal_drag), dt))
	self.vel.y = self.vel.y * (pow(1 - max(self.drag, self.vertical_drag), dt))

end

return SimplePhysics2D
