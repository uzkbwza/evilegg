local MainMenuWorld = World:extend("MainMenuWorld")
local TitleTextObject = GameObject2D:extend("TitleTextObject")
local O = (require "obj")

local MENU_ITEM_H_PADDING = 12
local MENU_ITEM_V_PADDING = 12
local MENU_ITEM_SKEW = 0

function MainMenuWorld:new(started_from_title_screen)
    MainMenuWorld.super.new(self)
	self:add_signal("menu_item_selected")
    self:add_signal("start_game_requested")
    self:add_signal("options_menu_requested")
	self:add_signal("codex_menu_requested")
	self:add_signal("leaderboard_menu_requested")

	self.draw_sort = self.y_sort
	self.started_from_title_screen = started_from_title_screen
end

function MainMenuWorld:enter()
	
	-- self.camera:move(conf.viewport_size.x / 2, conf.viewport_size.y / 2)

    self:start_timer("create_buttons", 10, function() self:create_buttons() end)
    self:ref("title_text", self:spawn_object(TitleTextObject(2, 38)))
	local title_y = self.title_text.pos.y
	local s = self.sequencer
    s:start(function()
		s:tween(function(t) self.title_text:move_to(self.title_text.pos.x, lerp(title_y, -conf.viewport_size.y / 2 + 62, t)) end, 0, 1, 15, "linear")
    end)
	

	if not self.started_from_title_screen then
        self.sequencer:end_all()
        self:end_timer("create_buttons")
	else
		self:play_sfx("ui_menu_button_selected1", 0.6)
	end



end

function MainMenuWorld:create_buttons()
	local menu_root = self:spawn_object(O.MainMenu.MainMenuRoot(1, 1, 1, 1))

    local menu_items = {
		{name = tr.main_menu_start_button, func = function() self:emit_signal("start_game_requested") end},
        -- {name = tr.menu_codex_button, func = function() end},
        -- {name = tr.main_menu_tutorial_buttom, func = function() end},
		{
			name = tr.main_menu_leaderboard_button,
			func = function()
				self:emit_signal("leaderboard_menu_requested")
		end},
        {
            name = tr.menu_codex_button,
            func = function()
                self:emit_signal("codex_menu_requested")
				
			end },
		
        {name = tr.menu_options_button, func = function() self:emit_signal("options_menu_requested") end},
        -- {name = tr.main_menu_credits_button, func = function() end},

		{name = tr.main_menu_quit_button, func = function() love.event.quit() end},
	}

	self:ref_array("menu_items")

    local prev = nil
	local distance_between_items = 19
	-- local base = MENU_ITEM_V_PADDING
	-- local base = conf.viewport_size.y - (#menu_items * distance_between_items) - MENU_ITEM_V_PADDING
	local base = -18
    for i, menu_table in ipairs(menu_items) do
        local v_offset = (i - 1) * distance_between_items
		local h_offset = (i - 1) * MENU_ITEM_SKEW
		local menu_item = self:spawn_object(O.MainMenu.MainMenuButton(0, base + v_offset, menu_table.name:upper()))
        signal.connect(menu_item, "selected", self, "on_menu_item_selected", function()
			self:on_menu_item_selected(menu_item, menu_table.func)
		end)
        menu_root:add_child(menu_item)
		if prev then
            menu_item:add_neighbor(prev, "up")
			prev:add_neighbor(menu_item, "down")
		end
		prev = menu_item
        if i == 1 then
            menu_item:focus()
        end
		self:ref_array_push("menu_items", menu_item)
	end

	if #self.menu_items > 1 then
		self.menu_items[1]:add_neighbor(self.menu_items[#self.menu_items], "up")
		self.menu_items[#self.menu_items]:add_neighbor(self.menu_items[1], "down")
	end
end

function MainMenuWorld:on_menu_item_selected(menu_item, func)
	self:emit_signal("menu_item_selected")
	menu_item:focus()
	local s = self.sequencer
    s:start(function()
        for _, item in ipairs(self.menu_items) do
            if item ~= menu_item then
                item:disappear_animation()
            end
        end
		s:wait(2)
		func()
	end)
end

function TitleTextObject:new(x, y)
    TitleTextObject.super.new(self, x, y)
	self.z_index = 1
end

function TitleTextObject:draw()
    -- TitleTextObject.super.draw(self)
	graphics.draw_centered(textures.title_title_text, 0, 0)
end




return MainMenuWorld
