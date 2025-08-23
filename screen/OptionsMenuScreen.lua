local OptionsMenuScreen = CanvasLayer:extend("OptionsMenuScreen")

function OptionsMenuScreen:new()
	OptionsMenuScreen.super.new(self)
    self:add_signal("exit_menu_requested")
	self.blocks_input = true
    -- self.blocks_logic = true
	-- self.blocks_render = true
end

function OptionsMenuScreen:enter()
	self.clear_color = Color.black
	-- self.clear_color = self.in_game and Color.transparent or Color.black
    self:add_world(Worlds.OptionsMenuWorld(), "options_menu_world")
	signal.chain_connect("exit_menu_requested", self.options_menu_world, self)
	signal.connect(self.options_menu_world, "enter_name_requested", self, "on_enter_name_requested")
    signal.connect(self.options_menu_world, "input_remapping_requested", self, "on_input_remapping_requested")
end

function OptionsMenuScreen:on_enter_name_requested()
    self:ref("enter_name_screen", self:push(Screens.NameEntryScreen()))
    self.handling_input = false
    self.enter_name_screen.blocks_input = true
    self.enter_name_screen.blocks_render = true
    signal.connect(self.enter_name_screen, "destroyed", self, "on_name_entered", function()
        self.handling_input = true
    end)
end

function OptionsMenuScreen:on_input_remapping_requested(input)
    self:ref("input_remapping_screen", self:push(Screens.InputRemappingScreen(input)))
    self.handling_input = false
    self.input_remapping_screen.blocks_input = true
    self.input_remapping_screen.blocks_render = true
    signal.connect(self.input_remapping_screen, "destroyed", self, "on_input_remapped", function()
        self.handling_input = true
    end)
end

function OptionsMenuScreen:update(dt)
	-- local input = self:get_input_table()
	-- if self.in_game and input.ui_cancel_pressed then
	-- 	self:emit_signal("exit_menu_requested")
	-- end
end

function OptionsMenuScreen:draw()
end

return OptionsMenuScreen
