local GameScreen = CanvasLayer:extend("GameScreen")

local GameLayer = CanvasLayer:extend("GameLayer")
local HUDLayer = CanvasLayer:extend("HUDLayer")
local UILayer = CanvasLayer:extend("UILayer")

local LevelBonus = require("levelbonus.LevelBonus")

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
	self.hud_layer:ref("game_layer", self.game_layer)

    signal.chain_connect("player_died", self.game_layer.world, self.game_layer, self)
    signal.connect(self.game_layer, "player_died", self, "on_player_died")
	-- signal.connect(self.game_layer, "room_cleared", self.hud_layer, "start_after_level_bonus_screen")
	signal.connect(self.game_layer.world, "all_spawns_cleared", self.hud_layer, "start_after_level_bonus_screen")
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

function GameScreen:get_clear_color()
	if self.game_layer then
		return self.game_layer:get_clear_color()
	end
	return Color.transparent
end

function GameLayer:new()
	GameLayer.super.new(self)
	self:add_signal("player_died")
end

function GameLayer:enter()
    self:add_world(Worlds.GameWorld(0, 0), "world")
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


function HUDLayer:new()
	HUDLayer.super.new(self)
    self.score_display = game_state.score
	self.after_level_bonus_screen = nil
end

function HUDLayer:start_after_level_bonus_screen()
	if not self.game_layer.world then
		return
	end

	local s = self.sequencer
    self.after_level_bonus_screen = {
		bonuses = {},
    }

	local temp_bonuses = {}

    for bonus, count in pairs(game_state.level_bonuses) do
        table.insert(temp_bonuses, {
			bonus = LevelBonus[bonus],
            count = count,
        })
    end
	
	table.sort(temp_bonuses, function(a, b)
		return a.bonus.score * a.count > b.bonus.score * b.count
	end)

	self.game_layer.world.waiting_on_bonus_screen = true

	s:start(function()
		s:wait(2)
        for _, bonus_table in pairs(temp_bonuses) do
            local bonus = bonus_table.bonus
            local b = {
                name = bonus.text_key,
                count = 0,
            }
            table.insert(self.after_level_bonus_screen.bonuses, b)
            while b.count < bonus_table.count do
                b.count = b.count + 1
                b.score = game_state:determine_score(try_function(bonus.score) * b.count)
                b.xp = try_function(bonus.xp) * b.count
                b.score_multiplier = try_function(bonus.score_multiplier) * b.count
                s:wait(3)
            end
        end
		
        s:wait(30)
        if self.game_layer.world then
            self.game_layer.world.waiting_on_bonus_screen = false
        end
		
		s:wait(120)
		
        if self.after_level_bonus_screen then
            for i = #self.after_level_bonus_screen.bonuses, 1, -1 do
                local bonus = self.after_level_bonus_screen.bonuses[i]
                table.remove(self.after_level_bonus_screen.bonuses, i)
				s:wait(5)
            end
        end
		
	end)
end

function HUDLayer:update(dt)
    if self.is_new_tick then
        if game_state.score > self.score_display then
            local step = 1
            local difference = game_state.score - self.score_display
            for i = 0, 10 do
                local ten_step = pow(10, i)
                if difference >= ten_step * 2 then
                    step = step + ten_step
                end
            end

            self.score_display = self.score_display + step
            if stepify_floor_safe(self.score_display, step) % (step * 5) == 0 then
                self:play_sfx("score_add", 0.15)
            end
        end
    end
    if game_state.score < self.score_display then
        self.score_display = game_state.score
    end
end

local bonus_palette = PaletteStack:new(Color.black, Color.white)

function HUDLayer:draw()
    local game_area_width = conf.viewport_size.x - conf.room_padding.x * 2
    local game_area_height = conf.viewport_size.y - conf.room_padding.y * 2
    local x_start = (graphics.main_viewport_size.x - conf.viewport_size.x) / 2
    local y_start = (graphics.main_viewport_size.y - conf.viewport_size.y) / 2
    local h_padding = conf.room_padding.x - 2
    local v_padding = conf.room_padding.y - 9
    local left = x_start + h_padding
    local top = y_start + v_padding
    local bottom = y_start + v_padding + game_area_height + 9
	local font = fonts.hud_font
    graphics.set_font(font)
    graphics.set_color(Color.white)

    local charwidth = fonts.hud_font:getWidth("0")
    graphics.push()
    graphics.translate(left, top)
    graphics.set_color(1, 1, 1, 0.25)
    graphics.print_outline(Color.black, string.format("LVL%02d ", game_state.level % 100), 0, 0)
    -- graphics.set_color(Palette.rainbow:tick_color(gametime.tick, 0, 10))
    graphics.set_color(Color.white)
    graphics.print_outline(Color.black, string.format("LVL%2d ", game_state.level % 100), 0, 0)
    graphics.print_outline(Color.black, string.format("WAVE%01d ", game_state.wave), charwidth * 7, 0)
    graphics.print_outline(Color.black,
        string.format("%d (x%-.2f)", self.score_display, game_state:get_score_multiplier()), charwidth * 13, 0)
    graphics.pop()
    graphics.push()
    graphics.translate(left, bottom)
    graphics.push()
    for i = 1, game_state.max_hearts do
        graphics.drawp(i <= game_state.hearts and textures.pickup_heart_icon or textures.pickup_empty_heart_icon, nil, 0,
            (i - 1) * 13, 0)
    end
    graphics.pop()
    -- graphics.print_outline(Color.black, string.format("x%-4.1f", game_state:get_score_multiplier()), charwidth * 16, 0)
    graphics.pop()
	
	graphics.push()
	graphics.set_color(1, 1, 1, 1)
    if self.after_level_bonus_screen then
        local font2 = fonts.depalettized.image_font2
		graphics.set_font(font2)
		local middle_x = self.viewport_size.x / 2
        local middle_y = self.viewport_size.y / 2
        local bonus_count = #self.after_level_bonus_screen.bonuses
		graphics.translate(middle_x - 90, middle_y)
        for i, bonus in ipairs(self.after_level_bonus_screen.bonuses) do
			local y = (i - (bonus_count + 1) / 2) * 10
            -- local text = string.format("%-20s %8d [+%3dXP] [X%2d]", tr[bonus.name], bonus.score, bonus.xp, bonus.count)
			graphics.printp(tr[bonus.name], font2, nil, 0, -16, y)
			graphics.printp(string.format("%-8d", bonus.score), font2, nil, 0, 60, y)
			graphics.printp(string.format("+%-2dXP", floor(bonus.xp * 10)), font2, nil, 0, 120, y)
			graphics.printp(string.format("×%d", bonus.count), font2, nil, 0, 180, y)
		end
    end
	graphics.pop()
end



function UILayer:new()
    UILayer.super.new(self)
	self:init_state_machine()
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

AutoStateMachine(UILayer, "Playing")

return GameScreen

