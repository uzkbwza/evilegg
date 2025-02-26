local MainWorld = World:extend("MainWorld")
local MainScreen = CanvasLayer:extend("MainScreen")

function MainScreen:new()
	MainScreen.super.new(self)
end

function MainScreen:enter()
	love.mouse.set_visible(false)
	love.mouse.set_relative_mode(true)
	self:push(Screens.GameScreen)
end

function MainScreen:update(dt)
end

function MainScreen:draw()
end

return MainScreen
