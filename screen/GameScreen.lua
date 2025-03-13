local GameScreen = CanvasLayer:extend("GameScreen")

local GameLayer = CanvasLayer:extend("GameLayer")
local HUDLayer = CanvasLayer:extend("HUDLayer")
local UILayer = CanvasLayer:extend("UILayer")

function GameScreen:new(x, y, width, height)
	GameScreen.super.new(self, x, y, width, height)
	self:add_signal("player_died")
end

function GameScreen:enter()
    self.clear_color = Color.black
	self:ref("game_layer", self:push(GameLayer))
	self:ref("hud_layer", self:push(HUDLayer))
	self:ref("ui_layer", self:push(UILayer))

	self.ui_layer:ref("game_layer", self.game_layer)

    signal.chain_connect("player_died", self.game_layer.world, self.game_layer, self)
	signal.connect(self.game_layer, "player_died", self, "on_player_died")
end

function GameScreen:on_player_died()
	self:emit_signal("player_died")
end

function GameScreen:update(dt)
    if input.menu_pressed then
	end
end

function GameScreen:get_mouse_mode()
	if self.ui_layer and self.ui_layer.state == "Paused" then
		return true, false
	end

	if self.game_layer and self.game_layer.world.player_died then
		return true, false
	end

	return false, true
end

function GameScreen:draw()
end

function GameLayer:new()
	GameLayer.super.new(self)
	self:add_signal("player_died")
end

function GameLayer:enter()
	self:add_world(Worlds.GameWorld(0, 0), "world")
end


local game_area = {
    width = conf.viewport_size.x - conf.room_padding.x * 2,
    height = conf.viewport_size.y - conf.room_padding.y * 2,
}

function HUDLayer:new()
	HUDLayer.super.new(self)
	self.score_display = game_state.score
end

function HUDLayer:update(dt)
	if self.is_new_tick then
        if game_state.score > self.score_display then
            local step = 111
			if game_state.score - self.score_display >= 1000 then
                step = 1111
			end
            self.score_display = self.score_display + step
            if stepify_floor_safe(self.score_display, step) % (step * 5) == 0 then
				self:play_sfx("score_add", 0.25, 1.0)
			end
		end
	end
	if game_state.score < self.score_display then
		self.score_display = game_state.score
	end
end

function HUDLayer:draw()
    local h_padding = 18
    local v_padding = conf.room_padding.y - 9
    local top = v_padding
    local bottom = v_padding + game_area.height + 12
    graphics.set_font(fonts.hud_font)
	graphics.set_color(Color.white)

	local charwidth = fonts.hud_font:getWidth("0")
	graphics.push()
    graphics.translate(h_padding, top)
	graphics.set_color(1, 1, 1, 0.25)
    graphics.print_outline(Color.black, string.format("LVL%02d ", game_state.level % 100), 0, 0)
	-- graphics.set_color(Palette.rainbow:tick_color(gametime.tick, 0, 10))
	graphics.set_color(Color.white)
    graphics.print_outline(Color.black, string.format("LVL%2d ", game_state.level % 100), 0, 0)
    graphics.print_outline(Color.black, string.format("WAVE%01d ", game_state.wave), charwidth * 7, 0)
    graphics.print_outline(Color.black, string.format("%d (x%-.1f)", self.score_display, game_state:get_score_multiplier()), charwidth * 13, 0)
    graphics.pop()
	graphics.push()
    graphics.translate(h_padding, bottom)
    graphics.print_outline(Color.black, string.rep("<3", game_state.hearts), 0, 0)
    -- graphics.print_outline(Color.black, string.format("x%-4.1f", game_state:get_score_multiplier()), charwidth * 16, 0)
	graphics.pop()
end

function UILayer:new()
    UILayer.super.new(self)
	self:lazy_mixin(Mixins.Behavior.AutoStateMachine, "Playing")
end

function UILayer:state_Playing_update(dt)
    if input.menu_pressed and not self.game_layer.world.player_died then
		self:change_state("Paused")
	end
end

function UILayer:state_Paused_enter()
    self.blocks_input = true
    self.blocks_logic = true
	-- self.blocks_render = true
    self.unpausing = false
	local s = self.sequencer

end

function UILayer:state_Paused_exit()
    self.blocks_input = false
    self.blocks_logic = false
	self.blocks_render = false
end


function UILayer:state_Paused_update(dt)
	if not self.unpausing then
		if input.menu_pressed then
			self.unpausing = true
			local s = self.sequencer
			self.blocks_render = false
			
			s:start(function()
				s:wait(2)
				self:change_state("Playing")
			end)
		end
	end
end

function UILayer:state_Paused_draw()
	-- if not self.blocks_render then
	-- 	return
	-- end
    graphics.set_color(1, 1, 1, 1)
    graphics.set_font(fonts.main_font)
    local x, y = graphics.text_center_offset("Paused", fonts.main_font)
    graphics.print_outline(Color.black, "Paused", self.viewport_size.x / 2 + x, self.viewport_size.y / 2 + y)
end

function UILayer:draw()

end

return GameScreen

