local PlayerDeathScreenWorld = World:extend("PlayerDeathScreenWorld")
local O = require("obj")

function PlayerDeathScreenWorld:new()
	PlayerDeathScreenWorld.super.new(self)
    self:add_signal("restart_requested")
	self:add_signal("quit_requested")
	self:add_signal("menu_item_selected")
	self.blocks_render = true
	self.blocks_logic = true
end

function PlayerDeathScreenWorld:enter()
    self:ref("menu_root", self:spawn_object(O.Menu.GenericMenuRoot(0, 0)))

    local retry = self:spawn_object(O.DeathScreen.DeathScreenButton(-40, 50, tr.death_screen_retry_button))
    self.menu_root:add_child(retry)

    local quit = self:spawn_object(O.DeathScreen.DeathScreenButton(40, 50, tr.death_screen_quit_button))
    self.menu_root:add_child(quit)

    quit:add_neighbor(retry, "left")
    retry:add_neighbor(quit, "right")

    signal.connect(retry, "selected", self, "on_retry_selected",
        function() self:on_button_pressed("restart_requested") end)
    signal.connect(quit, "selected", self, "on_quit_selected", function() self:on_button_pressed("quit_requested") end)

    retry:focus()
end

function PlayerDeathScreenWorld:on_button_pressed(signal_name)
	self:emit_signal("menu_item_selected")

    local s = self.sequencer
    s:start(function()
		s:wait(1)
		self:emit_signal(signal_name)
	end)
end

return PlayerDeathScreenWorld

