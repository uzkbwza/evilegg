local GameScreen = CanvasLayer:extend("GameScreen")

local GameLayer = CanvasLayer:extend("GameLayer")
local HUDLayer = CanvasLayer:extend("HUDLayer")
local UILayer = CanvasLayer:extend("UILayer")

function GameScreen:enter()
    self:add_world(Worlds.GameWorld(0, 0), "world")
	signal.connect(self.world, "player_died", self, "on_player_died")
	self.clear_color = Color.black
end

function GameScreen:on_player_died()
	self:transition_to(Screens.GameScreen)
end

-- function GameScreen:clear_procedure()
-- end

function GameScreen:update(dt)
end

function GameScreen:draw()
	graphics.set_color(1, 1, 1, 0.5)
	graphics.set_font(graphics.font.PixelOperator8)
	graphics.print("Level " .. game_state.level, 0, 0)
end

return GameScreen

