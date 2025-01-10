local Game = Object:extend("Game")

function Game:new()
    Game.super.new(self)
    self.layer_tree = CanvasLayer()
	self.layer_tree.root = self.layer_tree
end

function Game:load(screen)
	self.main_screen = screen
    self.layer_tree:transition_to(screen)
end

function Game:update(dt)
    self.layer_tree:update_shared(dt)

	if debug.enabled then
        if input.debug_editor_toggle_pressed then
            if self.layer_tree:get_child(1):is(Screens.LevelEditor) then
                self.layer_tree:transition_to(self.main_screen)
            else
                self.layer_tree:transition_to(Screens.LevelEditor)
            end
        end
	end
end

return Game
