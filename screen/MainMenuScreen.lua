local MainMenuScreen = CanvasLayer:extend("MainMenuScreen")

function MainMenuScreen:enter()
	if audio.playing_music ~= audio.get_music("title") then
		audio.play_music("title", 1.0)
	end
	self.clear_color = Color.black
	self:add_signal("start_game_requested")
	self:add_signal("options_menu_requested")
    self:ref("main_menu_world", self:add_world(Worlds.MainMenuWorld()))
    
	signal.chain_connect("start_game_requested", self.main_menu_world, self)
	signal.chain_connect("options_menu_requested", self.main_menu_world, self)
	
	signal.connect(self.main_menu_world, "menu_item_selected", self, "on_menu_item_selected")
end

function MainMenuScreen:on_menu_item_selected()
    self.handling_input = false
	-- local s = self.sequencer
	-- s:start(function()
        -- s:wait(2)
		-- self.handling_render = false
	-- end)
end

function MainMenuScreen:update(dt)
end

function MainMenuScreen:draw()
end

return MainMenuScreen