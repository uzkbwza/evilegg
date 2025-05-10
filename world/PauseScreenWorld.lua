local PauseScreenWorld = World:extend("PauseScreenWorld")
local O = (require "obj")

local DISTANCE_BETWEEN_ITEMS = 19

function PauseScreenWorld:new()
    PauseScreenWorld.super.new(self)
	self:add_signal("resume_requested")
    self:add_signal("quit_requested")
	self:add_signal("options_menu_requested")
	self:add_signal("codex_menu_requested")
	self.draw_sort = self.y_sort
	-- menu_item:focus()
end

function PauseScreenWorld:enter()
    -- self.camera:move(conf.viewport_size.x / 2, conf.viewport_size.y / 2)

    local menu_root = self:spawn_object(O.PauseScreen.PauseScreenRoot(0, 0, 1, 1))

    local menu_items = {
        { name = tr.pause_menu_resume_button, func = function() self:emit_signal("resume_requested") end },
        -- {name = tr.menu_codex_button, func = function() end},
        -- {name = tr.main_menu_tutorial_buttom, func = function() end},
        -- {name = tr.main_menu_leaderboard_button, func = function() end},
        { name = tr.menu_codex_button,        func = function() self:emit_signal("codex_menu_requested") end },
        { name = tr.menu_options_button,      func = function() self:emit_signal("options_menu_requested") end },
        -- {name = tr.main_menu_credits_button, func = function() end},

        { name = tr.pause_menu_quit_button,   func = function() self:emit_signal("quit_requested") end },
    }

    self:ref_array("menu_items")

    local prev = nil

    local base = -(#menu_items * DISTANCE_BETWEEN_ITEMS) / 2
    for i, menu_table in ipairs(menu_items) do
        local v_offset = (i) * DISTANCE_BETWEEN_ITEMS

        local menu_item = self:spawn_object(O.PauseScreen.PauseScreenButton(0, base + v_offset, menu_table.name:upper()))
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

    -- if #self.menu_items > 1 then
    --     self.menu_items[1]:add_neighbor(self.menu_items[#self.menu_items], "up")
    --     self.menu_items[#self.menu_items]:add_neighbor(self.menu_items[1], "down")
    -- end
end

function PauseScreenWorld:draw()
	-- local font = fonts.depalettized.image_font2
    -- graphics.set_font(font)
    -- graphics.print_centered("PAUSEHOLDER PLACEMENU", font, 0, -40)
    PauseScreenWorld.super.draw(self)

end

function PauseScreenWorld:on_menu_item_selected(menu_item, func)
	-- self:emit_signal("menu_item_selected")
	menu_item:focus()
	func()
end

return PauseScreenWorld
