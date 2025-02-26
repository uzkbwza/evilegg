local MainWorld = World:extend("MainWorld")
local MainScreen = CanvasLayer:extend("MainScreen")

function MainWorld:new(x, y)
	MainWorld.super.new(self, x, y)
end

function MainWorld:enter()
    self:init_camera()
end

function MainWorld:update(dt)
end

function MainWorld:draw()
end

function MainScreen:enter()
	self:add_world(MainWorld(0, 0), "world")
end


function MainScreen:update(dt)
end

function MainScreen:draw()
end

return MainScreen
