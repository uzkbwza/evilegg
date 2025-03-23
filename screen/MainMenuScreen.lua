local MainMenuScreen = CanvasLayer:extend("MainMenuScreen")
local MainMenuWorld = World:extend("MainMenuWorld")

function MainMenuScreen:enter()
	self:ref("main_menu_world", self:add_world(MainMenuWorld()))
end

function MainMenuScreen:update(dt)
end

function MainMenuScreen:draw()
end

return MainMenuScreen