local GameScreen = CanvasLayer:extend("GameScreen")

local GameLayer = CanvasLayer:extend("GameLayer")
local UILayer = CanvasLayer:extend("UILayer")

local PlayerDeathScreenWorld = CanvasLayer:extend("PlayerDeathScreenWorld")


function GameScreen:new(x, y, width, height)
	GameScreen.super.new(self, x, y, width, height)
    self:add_signal("restart_requested")
	self:add_signal("quit_requested")
    self:add_signal("leaderboard_menu_requested")
end

function GameScreen:enter()
    self.clear_color = Color.black
	self:ref("game_layer", self:push(GameLayer))
	self:ref("hud_layer", self:push(Screens.HUDLayer))
	self:ref("ui_layer", self:push(UILayer))

    self.ui_layer:ref("game_layer", self.game_layer)
    self.ui_layer:ref("hud_layer", self.hud_layer)
	self.hud_layer:ref("game_layer", self.game_layer)

	signal.chain_connect("quit_requested", self.ui_layer, self)
    signal.chain_connect("restart_requested", self.game_layer, self)
	signal.chain_connect("restart_requested", self.ui_layer, self)
	signal.connect(self.game_layer, "player_died", self, "on_player_died")
    signal.connect(self.game_layer, "restart_requested", self, "on_game_layer_restart_requested")
    signal.connect(self.game_layer.world, "all_spawns_cleared", self.hud_layer, "start_after_level_bonus_screen")
	signal.connect(self.game_layer, "player_death_sequence_finished", self.ui_layer, "on_player_death_sequence_finished")
	signal.connect(self.ui_layer, "leaderboard_requested", self, "on_leaderboard_requested")

end

function GameScreen:on_player_died()
	-- self.hud_layer:hide()
end

function GameScreen:on_leaderboard_requested()
	self:emit_signal("leaderboard_menu_requested")
end

function GameScreen:on_game_layer_restart_requested()
	self:emit_signal("restart_requested")
end

function GameScreen:update(dt)
    if input.menu_pressed then
    end
    if self.game_layer.world then
        self.game_layer.world.showing_hud = self.hud_layer:should_show()
        self.game_layer.world:always_update(dt)
    end

    if self.game_layer.world.fog_of_war then
        local width, height = conf.viewport_size.x - 18, conf.viewport_size.y - 22
        self.game_layer:set_viewport_size(width, height)
        -- print(self.viewport_size.x / 2 - width / 2, self.viewport_size.y / 2 - height / 2 - 2)
        self.game_layer:move_to(self.viewport_size.x / 2 - width / 2, self.viewport_size.y / 2 - height / 2 - 2)
    else
        self.game_layer:set_expand_viewport(true)
        self.game_layer:move_to(0, 0)
    end

    self.clear_color = self:get_clear_color()
end

function GameScreen:get_mouse_mode()
    if self:in_menu() then return true, false end


    if usersettings.use_absolute_aim then
        return true, true
    end

    return false, true
end

function GameScreen:in_menu()
    if self.ui_layer and self.ui_layer.state == "Paused" then
        return true
    end

    if self.game_layer and self.game_layer.world.player_died then
        return true
    end
end


function GameScreen:draw_cursor(x, y)

    if not usersettings.use_absolute_aim or self:in_menu() then
        return false
    end

    local size = 9

    graphics.push()
    graphics.translate(x, y)
    
    graphics.push()
    graphics.rotate(self.elapsed * 0.1)
    graphics.set_line_width(3)
    graphics.set_color(Color.black)
    graphics.dashrect_centered(0, 0, size, size, 3, 3)
    graphics.set_line_width(1)
    graphics.set_color(Color.white)
    graphics.dashrect_centered(0, 0, size, size, 3, 3)
    graphics.pop()

    graphics.set_color(Color.black)
    graphics.rectangle_centered("fill", 0, 0, 4, 4)
    graphics.set_color(Color.white)
    graphics.rectangle_centered("fill", 0, 0, 2, 2)
    graphics.pop()
    return true
end




function GameScreen:get_clear_color()

    if self.game_layer then
        local color = self.game_layer:get_clear_color()
        if color ~= Color.transparent then
            return color
        end
	end
	
    return Color.black
end

function GameLayer:new()
	GameLayer.super.new(self)
    -- self.centered = true
    self:add_signal("restart_requested")
	self:add_signal("player_death_sequence_finished")
	self:add_signal("player_died")
end

function GameLayer:enter()
    self:add_world(Worlds.GameWorld(0, 0), "world")
    signal.chain_connect("player_died", self.world, self)
    signal.chain_connect("player_death_sequence_finished", self.world, self)
end

function GameLayer:update(dt)
    -- self.clear_color = Color.black
    -- if self.world then
    self.clear_color = self:get_clear_color()

	-- end
end

function GameLayer:get_clear_color()
	-- possible game layer stuff here?


	local world_color = nil
    
	if self.world then
			world_color = self.world:get_clear_color()
	end

	if world_color then
		return world_color
	end

	return Color.black
end

function GameLayer:exit()
	self:stop_all_sfx()
end

function UILayer:new()
    UILayer.super.new(self)
	self:init_state_machine()
    self:add_signal("quit_requested")
	self:add_signal("restart_requested")
	self:add_signal("leaderboard_requested")
end

function UILayer:state_Playing_update(dt)
	local input = self:get_input_table()
    if input.menu_pressed and self:can_pause() then
        self:change_state("Paused")
    end
end

function UILayer:on_player_death_sequence_finished()
	self:change_state("PlayerDeath")
end

function UILayer:state_PlayerDeath_enter()
	self:add_world(Worlds.PlayerDeathScreenWorld(0, 0), "player_death_screen_world")
	signal.connect(self.player_death_screen_world, "covering_screen", self, "on_death_world_covering_screen", function()
		-- self.blocks_render = true
		-- self.blocks_logic = true
		-- self.blocks_input = true
		self.game_layer:hide()
		self.game_layer.handling_logic = false
	end)
    signal.chain_connect("restart_requested", self.player_death_screen_world, self)
    signal.chain_connect("quit_requested", self.player_death_screen_world, self)
	signal.chain_connect("leaderboard_requested", self.player_death_screen_world, self)

end

function UILayer:state_PlayerDeath_exit()
    self.player_death_screen_world:queue_destroy()
end


function UILayer:can_pause()
    if self.game_layer.world.player_died then
        return false
    end

	if game_state.cutscene_no_pause then
		return false
	end

	if not self.game_layer.world:can_pause() then
		return false
	end

	if not self.hud_layer:can_pause() then
		return false
	end
    return true
end

function UILayer:state_Paused_enter()
	self.blocks_input = true
    -- self.blocks_logic = true
	self.game_layer.world.paused = true
	self.game_layer.handling_logic = false
	
	self:ref("pause_screen", self:push(Screens.PauseScreen))

	signal.chain_connect("resume_requested", self.pause_screen.world, self.pause_screen)
    signal.chain_connect("options_menu_requested", self.pause_screen.world, self.pause_screen)
	signal.chain_connect("codex_menu_requested", self.pause_screen.world, self.pause_screen)
	signal.chain_connect("quit_requested", self.pause_screen.world, self.pause_screen, self)

	
    signal.connect(self.pause_screen, "resume_requested", self, "on_resume_requested", function()
        self:defer(function() self:change_state("Playing") end)
    end)
	
    signal.connect(self.pause_screen, "options_menu_requested", self, "on_options_menu_requested",
        function() self:show_options_menu() end)

	signal.connect(self.pause_screen, "codex_menu_requested", self, "on_codex_menu_requested",
        function() self:show_codex_menu() end)
	

end

function UILayer:show_options_menu()
    self:ref("options_menu", Screens.OptionsMenuScreen()).in_game = true
    self.handling_input = false
    self:add_sibling_below(self.options_menu)
    self.pause_screen.handling_render = false

    signal.connect(self.options_menu, "exit_menu_requested", self, "on_exit_menu_requested", function()
        self.options_menu:queue_destroy()
        local s = self.sequencer
        s:start(function()
            s:wait(1)
            self.handling_input = true
            if self.pause_screen then
                self.pause_screen.handling_render = true
            end
        end)
    end)
end

function UILayer:show_codex_menu()
    self:ref("codex_menu", Screens.CodexScreen()).in_game = true
    self.handling_input = false
    self:add_sibling_below(self.codex_menu)
    self.pause_screen.handling_render = false

    signal.connect(self.codex_menu, "exit_menu_requested", self, "on_exit_menu_requested", function()
        self.codex_menu:queue_destroy()
		local s = self.sequencer
		s:start(function()
			s:wait(1)
			self.handling_input = true
			if self.pause_screen then
				self.pause_screen.handling_render = true
			end
		end)
    end)
end

function UILayer:state_Paused_exit()
	self.game_layer.world.paused = false
	self.game_layer.handling_logic = true
    self.blocks_input = false
    -- self.blocks_logic = false
    -- self.blocks_render = false
	if self.pause_screen then
		self.pause_screen:queue_destroy()
	end
end


function UILayer:state_Paused_update(dt)
	-- if not self.unpausing then
	-- 	if input.menu_pressed then
	-- 		self.unpausing = true
	-- 		local s = self.sequencer
	-- 		self.blocks_render = false
			
	-- 		s:start(function()
	-- 			s:wait(2)
	-- 			self:change_state("Playing")
	-- 		end)
	-- 	end
	-- end
end

function UILayer:state_Paused_draw()

end

function UILayer:draw()

end

AutoStateMachine(UILayer, "Playing")

return GameScreen

