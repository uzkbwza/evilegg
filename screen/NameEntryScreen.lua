local NameEntryScreen = CanvasLayer:extend("NameEntryScreen")

function NameEntryScreen:new()
	self.blocks_input = true
    self.blocks_logic = true
	
	NameEntryScreen.super.new(self)
	self.clear_color = Color.black
    self:add_world(Worlds.NameEntryWorld(), "world")
	signal.connect(self.world, "name_selected", self, "on_name_selected")
end

function NameEntryScreen:on_name_selected(name)
	-- self:emit_signal("name_selected", name)
	self.handling_input = false
	savedata:set_save_data("name", name)
	local s = self.sequencer
	s:start(function()
		s:wait(5)
		self:queue_destroy()
	end)
end

return NameEntryScreen
