local MainMenuScreen = CanvasLayer:extend("MainMenuScreen")

function MainMenuScreen:enter()

    if game_state and not game_state.stopped_updating then
        game_state:stop_updating()
    end

	self.clear_color = Color.black
	self:add_signal("start_game_requested")
    self:add_signal("options_menu_requested")
	self:add_signal("codex_menu_requested")
	self:add_signal("start_title_screen_requested")
	self:add_signal("leaderboard_menu_requested")
    self:ref("main_menu_world", self:add_world(Worlds.MainMenuWorld(self.started_from_title_screen)))


	signal.chain_connect("start_game_requested", self.main_menu_world, self)
	signal.chain_connect("options_menu_requested", self.main_menu_world, self)
	signal.chain_connect("codex_menu_requested", self.main_menu_world, self)
	signal.chain_connect("leaderboard_menu_requested", self.main_menu_world, self)

    signal.connect(self.main_menu_world, "menu_item_selected", self, "on_menu_item_selected")
	
	if string.strip_whitespace(savedata.name) == "" then
		self:add_sibling_below(Screens.NameEntryScreen())
	end
	
    audio.play_music_if_stopped("music_main_menu", 0.7)

    local s = self.sequencer
	s:start(function() 
		self.clear_color = Color.purple:clone()
		for _, prop in ipairs({ "r", "g", "b" }) do
			s:start(function()
				s:tween_property(self.clear_color, prop, self.clear_color[prop], 0, 2, "linear", 0.125)
				self.clear_color[prop] = 0
			end)
		end
    end)

    if not self.started_from_title_screen then
        self.sequencer:end_all()
	end

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
	local input = self:get_input_table()
	if input.ui_cancel_pressed then
		self:emit_signal("start_title_screen_requested")
	end
end

function MainMenuScreen:draw()
    MainMenuScreen.super.draw(self)
	graphics.push("all")

	-- self:draw_guide_placeholder()

	graphics.pop()
end

function MainMenuScreen:draw_guide_placeholder()
    local x_start = (graphics.main_viewport_size.x - conf.viewport_size.x) / 2

	graphics.translate(x_start, 0)
	
	local font = fonts.depalettized.image_font1
	graphics.set_font(font)
    graphics.set_color(Color.white)

	-- todo: localize
	local gamepad = input:get_prompt_device() == "gamepad"

    local controls = {
        { label = gamepad and "LEFT STICK" or "WASD", action = "MOVE"},
        { label = gamepad and "RIGHT STICK" or "MOUSE", action = "SHOOT"},
        { label = gamepad and "LEFT TRIGGER" or "SPACE", action = "BOOST" },
        -- { label = "RMB/RIGHT TRIGGER: ", action = "SECONDARY WEAPON" },
		{ label = "", action = "SAVE THE GREENOIDS" },
    }
	
    local vert = 11

	-- graphics.translate(-conf.viewport_size.x / 2, -conf.viewport_size.y / 2)

	graphics.translate(11, 0)
	for i, control in ipairs(controls) do
		local label = control.label
		if #label > 0 then
			label = control.label .. " - "
		end
		graphics.translate(0, vert)
		graphics.set_color(Color.white)
		graphics.print_outline(Color.black, label, 0, 0)
		graphics.set_color(Color.green)
		graphics.print_outline(Color.black, control.action, font:getWidth(label), 0)
	end
end

return MainMenuScreen
