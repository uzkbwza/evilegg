local OptionsMenuWorld = World:extend("OptionsMenuWorld")
local O = (require "obj")
local GamerHealthTimer = require("obj.Menu.GamerHealthTimer")

local MENU_ITEM_H_PADDING = 12
local MENU_ITEM_V_PADDING = 6
local MENU_ITEM_SKEW = 0
local DISTANCE_BETWEEN_ITEMS = 11
local HEADER_SPACE = 0
local HEADER_SPACE_UNDER = 1


function OptionsMenuWorld:new()
    OptionsMenuWorld.super.new(self)
	self:add_signal("exit_menu_requested")
	self:add_signal("enter_name_requested")
	
    self.draw_sort = self.y_sort
    self.current_page = 1
	-- menu_item:focus()
end

function OptionsMenuWorld:enter()
    self.camera:move(conf.viewport_size.x / 2, conf.viewport_size.y / 2)

    self:ref("menu_root", self:spawn_object(O.OptionsMenu.OptionsMenuRoot(1, 1, 1, 1)))

    self:ref_array("menu_items")

    self:show_menu(1)

end

function OptionsMenuWorld:show_menu(page)

    local items_to_remove = {}

    for _, item in ipairs(self.menu_items) do
        table.insert(items_to_remove, item)
    end

    for _, item in ipairs(items_to_remove) do
        item:queue_destroy()
        self:ref_array_remove("menu_items", item)
    end

    for _, item in (self:get_objects_with_tag("header")):ipairs() do
        item:queue_destroy()
    end

    self.current_page = page

    local back_table = {
		name = "⮌",
		item_type = "button",
		is_back = true,
        select_func = function()
            if self.current_page == 1 then
                local s = self.sequencer
                s:start(function()
                    self.handling_input = false
                    s:wait(1)
                    self:emit_signal("exit_menu_requested")
                end)
            else
                self:show_menu(1)
            end
		end,
	}

    self.next_item_x, self.next_item_y = MENU_ITEM_H_PADDING, MENU_ITEM_V_PADDING + 2

	self:ref("back_button",self:add_menu_item(back_table))

	self.next_item_y = self.next_item_y + 4

    -- local base = MENU_ITEM_V_PADDING
    local current_page = 1

    for _, item in ipairs {
        -- { "header", text = "" },
        {
            "header_display",
            item_type = "button",
            select_func = function()
                self:show_menu(2)
            end
        },
        { 
            "header_controls",
            item_type = "button",
            select_func = function()
			self:show_menu(3)
            end,
        },
        {
            "header_audio",
            item_type = "button",
            select_func = function()
                self:show_menu(4)
            end,
        },
        {
            "header_other",
            item_type = "button",
            select_func = function()
                self:show_menu(5)
            end,
        },
        { newpage = true },
		{ "header", text = tr.options_header_display },
		{ "fullscreen", item_type = "toggle", skip=conf.platform_force_fullscreen},
        -- { "use_screen_shader", item_type = "toggle" },
		
		{ "show_hud", item_type = "toggle", inverse = true},
        { "pixel_perfect", item_type = "toggle" },

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
		{ "vsync", item_type = "toggle"},
        -- { "cap_framerate",        item_type = "toggle" },
		{ "fps_cap", item_type = "slider", slider_start = 60, slider_stop = 660, slider_granularity = 60, slider_mouse_granularity = 60,
		set_func = function(value)
			if value >= 660 then
				usersettings:set_setting("cap_framerate", false)
			else
				usersettings:set_setting("cap_framerate", true)
				-- usersettings:set_setting("fps_cap", value)
			end
			usersettings:set_setting("fps_cap", value)
		end,
		-- get_func = function()
		-- 	if usersettings.cap_framerate then
		-- 		return usersettings.fps_cap
		-- 	else
		-- 		return 660
		-- 	end
		-- end,
		
		print_func = function(value)
			if value < 660 then
				return value
			else
				return tr.options_fps_cap_unlimited
			end
		end
        },
    {
        "show_fps",
        item_type = "toggle",
    },
	{ "screen_shader_preset", item_type = "cycle", options = self:get_screen_shader_presets(),

		get_func = function()
			-- if usersettings.use_screen_shader then
			return usersettings.screen_shader_preset
			-- end
		end,
		set_func = function(value)
			usersettings:set_screen_shader_preset(value)
		end,

            translate_options = true },

        { "shader_quality", item_type = "slider", slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.1,
        set_func = function(value)
            usersettings:set_setting("shader_quality", value)
        end,
        get_func = function()
            return usersettings.shader_quality
        end,
        },

        { "screen_shake_amount", item_type = "slider", slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.1},
        
	
		{ "brightness", item_type = "slider", slider_start = 0.5, slider_stop = 1.0, slider_granularity = 0.05 },
	-- { "saturation", item_type = "slider", slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.05 },
        { "hue",                                  item_type = "slider",             slider_start = 0.0,    slider_stop = 1.0, slider_granularity = 0.025 },
        { "disco_mode", item_type = "toggle", select_func = function()
            if not usersettings.disco_mode then
                usersettings:set_setting("hue", 0.5)
            else
                usersettings:set_setting("hue", 0.0)
            end
            usersettings:set_setting("disco_mode", not usersettings.disco_mode)
        end,
        get_func = function()
            return usersettings.disco_mode
        end },
	
        { "invert_colors", item_type = "toggle" },

		-- { "invert_colors", item_type = "toggle" },
        { newpage = true },
        { "header",                               text = tr.options_header_controls },
		{ "use_absolute_aim", item_type = "toggle" },
        { "mouse_sensitivity",    item_type = "slider",             slider_start = 0.0025,                                                                                       slider_stop = 0.1,       slider_granularity = 0.0025 },
		{ "relative_mouse_aim_snap_to_max_range", item_type = "toggle" },
        { "gamepad_plus_mouse",                   item_type = "toggle" },
        
        { newpage = true },
		{ "header", text = tr.options_header_audio },
		{ "master_volume", item_type = "slider", slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.05 },
		{ "music_volume", item_type = "slider", slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.05 },
        { "sfx_volume",    item_type = "slider",          slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.05 },
        { newpage = true },
		{ "header", text = tr.options_header_other },
        { "skip_intro", item_type = "toggle" },
        { "retry_cooldown", item_type = "toggle", update_function = function(self, dt)
            self:set_enabled(not (usersettings.retry_cooldown and savedata:get_seconds_until_retry_cooldown_is_over() > 0))
            if not self.enabled and not self.gamer_health_timer then
                self:ref("gamer_health_timer", self:spawn_object(GamerHealthTimer(self.pos.x, self.pos.y, self.width, self.height)))
            end
        end },
		{ "enter_name", item_type = "button", select_func = function()
			self:emit_signal("enter_name_requested")
        end },


        { "debug_enabled", item_type = "toggle", debug = true, set_func = function()
            debug.enabled = not debug.enabled
            usersettings:set_setting("debug_enabled", debug.enabled)
        end,
        get_func = function()
            return debug.enabled
        end },

        { "enable_leaderboard", item_type = "toggle" },

    } do
        if item.newpage then
            current_page = current_page + 1
            goto continue
        end

        if current_page ~= page then
            goto continue
        end

        if item[1] == "header" then
            self:add_menu_item(item)
            goto continue
        end

        if item.skip then
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
    
    -- self:add_menu_item({ "header", text = "" })

	-- self:add_menu_item(back_table)

    if #self.menu_items > 1 then
        self.menu_items[1]:add_neighbor(self.menu_items[#self.menu_items], "up")
        self.menu_items[#self.menu_items]:add_neighbor(self.menu_items[1], "down")
    end
end

function OptionsMenuWorld:get_screen_shader_presets()
	local presets = {}
	for _, preset in ipairs(graphics.screen_shader_presets) do
		table.insert(presets, preset[1])
	end
	return presets
end

function OptionsMenuWorld:add_menu_item(menu_table)

    if menu_table.debug and IS_EXPORT then
        return
    end

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
        self.next_item_y = self.next_item_y + DISTANCE_BETWEEN_ITEMS + HEADER_SPACE_UNDER
        object:add_tag_on_enter("header")
		return
	end


	local class = classes[menu_table.item_type]

	local menu_item

	if menu_table.is_back then
		class = O.PauseScreen.PauseScreenButton
		menu_item = self:spawn_object(class(self.next_item_x, self.next_item_y, menu_table.name:upper(), 10, 10, false))
	else
		menu_item = self:spawn_object(class(self.next_item_x, self.next_item_y, menu_table.name:upper()))
	end
	


    if menu_table.select_func then
        signal.connect(menu_item, "selected", self, "on_menu_item_selected", menu_table.select_func)
    end
	
    if menu_item:is(O.OptionsMenu.OptionsMenuToggle) then
        local get_func = menu_table.get_func or function() return usersettings[menu_table.usersettings_toggle] end
        local set_func = menu_table.set_func or function() usersettings:set_setting(menu_table.usersettings_toggle, not get_func()) end
        menu_item.get_value_func = get_func
        menu_item.set_value_func = set_func
		menu_item.inverse = menu_table.inverse
	elseif menu_item:is(O.OptionsMenu.OptionsMenuSlider) then
		local get_func = menu_table.get_func or function() return usersettings[menu_table.usersettings_slider] end
		local set_func = menu_table.set_func or function(value) usersettings:set_setting(menu_table.usersettings_slider, value) end
		menu_item.get_value_func = get_func
		menu_item.set_value_func = set_func
		menu_item.print_func = menu_table.print_func
		menu_item.start = menu_table.slider_start
		menu_item.stop = menu_table.slider_stop
        menu_item.granularity = menu_table.slider_granularity or menu_item.granularity
		
		menu_item.mouse_granularity = menu_table.slider_mouse_granularity or menu_item.granularity
    elseif menu_item:is(O.OptionsMenu.OptionsMenuCycle) then
		local get_func = menu_table.get_func or function() return usersettings[menu_table.usersettings_cycle] end
		local set_func = menu_table.set_func or function(value) usersettings:set_setting(menu_table.usersettings_cycle, value) end
		menu_item.get_value_func = get_func
        menu_item.set_value_func = set_func
		menu_item.translate_options = menu_table.translate_options
		menu_item:set_options(menu_table.options)
		menu_item.print_func = menu_table.print_func
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

    if menu_table.update_function then
        menu_item:add_update_function(menu_table.update_function)
    end

	self.menu_root:add_child(menu_item)

    self:ref_array_push("menu_items", menu_item)

    if num_items == 1 then
        menu_item:focus()
    end

    if num_items > 0 then
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

function OptionsMenuWorld:draw()
	local font = fonts.depalettized.image_bigfont1
	graphics.set_font(font)
	graphics.print(tr.menu_options_button, font, 28, MENU_ITEM_V_PADDING - 3, 0, 1, 1)
	OptionsMenuWorld.super.draw(self)
end

return OptionsMenuWorld
