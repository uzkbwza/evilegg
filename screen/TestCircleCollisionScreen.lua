local MainScreen = CanvasLayer:extend("MainScreen")

local TestObject = GameObject:extend("TestObject")

local MainWorld = World:extend("MainWorld")

function TestObject:new(x, y, radius)
    TestObject.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.CircleCollision, radius)
    self:lazy_mixin(Mixins.Behavior.TrackPreviousPosition)
end

function TestObject:update(dt)
    if self.target then
		self.colliding = false
		-- 	self.colliding = self:check_object_circle_collision(self.target)

        self.colliding =  circle_contains_point(self.pos.x, self.pos.y, self.collision_radius, self.target.pos.x, self.target.pos.y)

	end
end

function TestObject:draw()
    local prev_x, prev_y = self:to_local(self.prev_pos.x, self.prev_pos.y)

    graphics.set_color((self.colliding and Color.red or Color.white))
	
	graphics.circle("fill", prev_x, prev_y, self.collision_radius)
    for x, y in bresenham_line_iter(prev_x, prev_y, 0, 0) do
        graphics.circle("fill", x, y, self.collision_radius)
    end
	graphics.circle("fill", 0, 0, self.collision_radius)
end

function MainWorld:enter()
    self:ref("object1", self:spawn_object(TestObject(self.viewport_size.x / 2, self.viewport_size.y / 2, 10)))
    self:ref("object2", self:spawn_object(TestObject(0, 0, 2)))
    self.object1.target = self.object2
	-- self.object1.target = self.object2
	self:init_camera()
end

function MainWorld:update(dt)
	self.object2:move_to(self:get_mouse_position())
end

function MainScreen:enter()
    self:ref("world", self:add_world(MainWorld()))
end

function MainScreen:draw()
end

return MainScreen
