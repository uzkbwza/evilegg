local MainWorld = World:extend("MainWorld")
local MainScreen = CanvasLayer:extend("MainScreen")

function MainWorld:new(x, y)
	MainWorld.super.new(self, x, y)
end

function MainWorld:enter()
    self:create_camera()
end

function MainWorld:update(dt)
end

function MainWorld:draw()
end

function MainScreen:enter()
	self:ref("world", self:add_world(MainWorld(0, 0)))
end

function MainScreen:update(dt)
end

function MainScreen:draw()
end

return MainScreen
