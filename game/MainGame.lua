local MainGame = BaseGame:extend("MainGame")
local GlobalState = Object:extend("GlobalState")
local GlobalGameState = Object:extend("GlobalGameState")

function MainGame:new()
	MainGame.super.new(self)
	-- self.main_screen = Screens.TestPaletteCyclingScreen
	self.main_screen = Screens.MainScreen
end

function MainGame:initialize_global_state()
	game_state = GlobalGameState()
	return GlobalState()
end

function GlobalState:new()
end

function GlobalState:reset_game_state()
    game_state = GlobalGameState()
end

function GlobalGameState:new()
    self.level = 1
    self.difficulty = 1
    self.enemies_killed = 0
    if debug.enabled then
		self.level = 5
	end
end

return MainGame
