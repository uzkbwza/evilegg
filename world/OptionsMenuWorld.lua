local OptionsMenuWorld = World:extend("OptionsMenuWorld")
local O = (require "obj")

local MENU_ITEM_H_PADDING = 12
local MENU_ITEM_V_PADDING = 6
local MENU_ITEM_SKEW = 0
local DISTANCE_BETWEEN_ITEMS = 10
local HEADER_SPACE = 5


function OptionsMenuWorld:new()
    OptionsMenuWorld.super.new(self)
    self:add_signal("exit_menu_requested")
	
	self.draw_sort = self.y_sort
	-- menu_item:focus()
end

function OptionsMenuWorld:enter()
    self.camera:move(conf.viewport_size.x / 2, conf.viewport_size.y / 2)

    self:ref("menu_root", self:spawn_object(O.OptionsMenu.OptionsMenuRoot(1, 1, 1, 1)))

    self:ref_array("menu_items")

	local back_table = {
		name = tr.menu_back_button,
		item_type = "button",
        select_func = function()
			local s = self.sequencer
            s:start(function()
				self.handling_input = false
				s:wait(1)
				self:emit_signal("exit_menu_requested")
			end)
		end,
	}

    self.next_item_x, self.next_item_y = MENU_ITEM_H_PADDING, MENU_ITEM_V_PADDING

	self:ref("back_button",self:add_menu_item(back_table))

	-- local base = MENU_ITEM_V_PADDING


    for _, item in ipairs {
        { "header",                               text = tr.options_header_controls },
		{ "use_absolute_aim", item_type = "toggle" },
        { "mouse_sensitivity",    item_type = "slider",             slider_start = 0.0025,                                                                                       slider_stop = 0.1,       slider_granularity = 0.0025 },
		{ "relative_mouse_aim_snap_to_max_range", item_type = "toggle" },
		
		{ "header", text = tr.options_header_display },
		{ "fullscreen", item_type = "toggle"},
        { "use_screen_shader", item_type = "toggle" },
		{ "screen_shader_preset", item_type = "cycle", options = { "shader_preset_soft", "shader_preset_scanline", "shader_preset_lcd", "shader_preset_ledboard" }, translate_options = true },
        { "zoom_level", item_type = "slider", slider_start = 0.5, slider_stop = 1.0, slider_granularity = 0.025, on_set_function = function(value)
            for _, item in ipairs(self.menu_items) do
                item.focus_on_hover = false
				local s = self.sequencer
				s:start(function()
                    s:wait(3)
					if not item.is_destroyed then
						item.focus_on_hover = true
					end
				end)
			end
		end },
		{ "pixel_perfect", item_type = "toggle"},
		{ "vsync", item_type = "toggle"},
        { "cap_framerate",        item_type = "toggle" },
		{ "fps_cap", item_type = "slider", slider_start = 60, slider_stop = 600, slider_granularity = 60, slider_mouse_granularity = 60 },

		{ "header", text = tr.options_header_audio },
		{ "music_volume", item_type = "slider", slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.1 },
		{ "sfx_volume", item_type = "slider", slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.1 },
		
		{ "header", text = tr.options_header_other },
		{ "skip_tutorial", item_type = "toggle" },
		
		{ "header", text = "" },
    } do

		if item[1] == "header" then
			self:add_menu_item(item)
			goto continue
		end
        
		item.name = tr["options_" .. item[1]]

		if item.item_type == "toggle" then
            item.usersettings_toggle = item[1]
        end

		if item.item_type == "slider" then
			item.usersettings_slider = item[1]
		end

		if item.item_type == "cycle" then
			item.usersettings_cycle = item[1]
		end

        self:add_menu_item(item)
		
		::continue::

	end

	self:add_menu_item(back_table)

    if #self.menu_items > 1 then
        self.menu_items[1]:add_neighbor(self.menu_items[#self.menu_items], "up")
        self.menu_items[#self.menu_items]:add_neighbor(self.menu_items[1], "down")
    end
end

function OptionsMenuWorld:add_menu_item(menu_table)
	
    local classes = {
        button = O.OptionsMenu.OptionsMenuButton,
        toggle = O.OptionsMenu.OptionsMenuToggle,
        slider = O.OptionsMenu.OptionsMenuSlider,
        cycle = O.OptionsMenu.OptionsMenuCycle,
    }

	local num_items = #self.menu_items

	
    if menu_table[1] == "header" then
		self.next_item_x = self.next_item_x + MENU_ITEM_SKEW
        self.next_item_y = self.next_item_y + (menu_table.text ~= "" and HEADER_SPACE or 0)
        local object = self:spawn_object(O.OptionsMenu.OptionsMenuHeader(self.next_item_x, self.next_item_y,
        menu_table.text))
		self.next_item_x = self.next_item_x + MENU_ITEM_SKEW
		self.next_item_y = self.next_item_y + (menu_table.text ~= "" and DISTANCE_BETWEEN_ITEMS or HEADER_SPACE)
		return
	end


	local class = classes[menu_table.item_type]

	local menu_item = self:spawn_object(class(self.next_item_x, self.next_item_y, menu_table.name:upper()))


    if menu_table.select_func then
        signal.connect(menu_item, "selected", self, "on_menu_item_selected", menu_table.select_func)
    end
	
    if menu_item:is(O.OptionsMenu.OptionsMenuToggle) then
        local get_func = function() return usersettings[menu_table.usersettings_toggle] end
        local set_func = function() usersettings:set_setting(menu_table.usersettings_toggle, not get_func()) end
        menu_item.get_value_func = get_func
        menu_item.set_value_func = set_func
	elseif menu_item:is(O.OptionsMenu.OptionsMenuSlider) then
		local get_func = function() return usersettings[menu_table.usersettings_slider] end
		local set_func = function(value) usersettings:set_setting(menu_table.usersettings_slider, value) end
		menu_item.get_value_func = get_func
        menu_item.set_value_func = set_func
		menu_item.start = menu_table.slider_start
		menu_item.stop = menu_table.slider_stop
        menu_item.granularity = menu_table.slider_granularity or menu_item.granularity
		
		menu_item.mouse_granularity = menu_table.slider_mouse_granularity or menu_item.granularity
    elseif menu_item:is(O.OptionsMenu.OptionsMenuCycle) then
		local get_func = function() return usersettings[menu_table.usersettings_cycle] end
		local set_func = function(value) usersettings:set_setting(menu_table.usersettings_cycle, value) end
		menu_item.get_value_func = get_func
        menu_item.set_value_func = set_func
		menu_item.translate_options = menu_table.translate_options
		menu_item:set_options(menu_table.options)
	end

	if menu_table.on_set_function then
		if menu_item.set_value_func then
			local old_set_value_func = menu_item.set_value_func
			menu_item.set_value_func = function(value)
				menu_table.on_set_function(value)
				old_set_value_func(value)
			end
		end
	end

	self.menu_root:add_child(menu_item)

    self:ref_array_push("menu_items", menu_item)

    if num_items == 0 then
        menu_item:focus()
    else
        self.menu_items[num_items]:add_neighbor(menu_item, "down")
        menu_item:add_neighbor(self.menu_items[num_items], "up")
    end
	
	self.next_item_x = self.next_item_x + MENU_ITEM_SKEW
    self.next_item_y = self.next_item_y + DISTANCE_BETWEEN_ITEMS
	
	return menu_item
end

function OptionsMenuWorld:update(dt)
	local input = self:get_input_table()
	if input.ui_cancel_pressed then
		self.back_button:select()
	end
end

return OptionsMenuWorld
