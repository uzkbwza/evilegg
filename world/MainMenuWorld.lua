local MainMenuWorld = World:extend("MainMenuWorld")
local O = (require "obj")

local MENU_ITEM_H_PADDING = 12
local MENU_ITEM_V_PADDING = 12
local MENU_ITEM_SKEW = 0

function MainMenuWorld:new()
    MainMenuWorld.super.new(self)
	self:add_signal("menu_item_selected")
    self:add_signal("start_game_requested")
    self:add_signal("options_menu_requested")
	self:add_signal("codex_menu_requested")

	self.draw_sort = self.y_sort
	-- menu_item:focus()
end

function MainMenuWorld:enter()
	self.camera:move(conf.viewport_size.x / 2, conf.viewport_size.y / 2)

    local menu_root = self:spawn_object(O.MainMenu.MainMenuRoot(1, 1, 1, 1))

    local menu_items = {
		{name = tr.main_menu_start_button, func = function() self:emit_signal("start_game_requested") end},
        -- {name = tr.menu_codex_button, func = function() end},
        -- {name = tr.main_menu_tutorial_buttom, func = function() end},
        -- {name = tr.main_menu_leaderboard_button, func = function() end},
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
	local base = conf.viewport_size.y / 2 - (#menu_items * distance_between_items) / 2
    for i, menu_table in ipairs(menu_items) do
        local v_offset = (i - 1) * distance_between_items
		local h_offset = (i - 1) * MENU_ITEM_SKEW
		local menu_item = self:spawn_object(O.MainMenu.MainMenuButton(MENU_ITEM_H_PADDING + h_offset, base + v_offset, menu_table.name:upper()))
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

return MainMenuWorld
