local BaseGame = Object:extend("BaseGame")

function BaseGame:new()
	self.layer_tree = CanvasLayer()
	self.layer_tree.root = self.layer_tree
end

function BaseGame:initialize_global_state()
	return Object()
end

function BaseGame:load()
	local f = require("gameload")

	if type(f) == "function" or type(f) == "table" then
		f()
	end

    global_state = self:initialize_global_state()
	
    self.layer_tree:transition_to(self.main_screen_class)
end

function BaseGame:get_main_screen()
	return self.layer_tree:get_child(1)
end

function BaseGame:update(dt)
    self.layer_tree:update_shared(dt)

	if debug.enabled then
        if input.debug_editor_toggle_pressed then
            if self:get_main_screen():is(Screens.LevelEditor) then
                self.layer_tree:transition_to(self.main_screen_class)
            else
                self.layer_tree:transition_to(Screens.LevelEditor)
            end
        end
	end
end

return BaseGame
