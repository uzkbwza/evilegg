local OptionsMenuWorld = World:extend("OptionsMenuWorld")
local O = (require "obj")
local GamerHealthTimer = require("obj.Menu.GamerHealthTimer")

local MENU_ITEM_H_PADDING = 15
local MENU_ITEM_V_PADDING = 6
local MENU_ITEM_SKEW = 0
local DISTANCE_BETWEEN_ITEMS = 11
local HEADER_SPACE = 0
local HEADER_SPACE_UNDER = 1

local NUM_WINDOW_SIZES = 8

local function parse_ratio(str)
    local a, b = str:match("^(%d+):(%d+)$")
    return tonumber(a), tonumber(b)
end

local function is_close(a, b)
    return math.abs(a - b) < 0.01
end

local function process_scale(value)
	return usersettings.pixel_perfect and floor(value) or value
end

-- Helpers to keep logic clear and non-duplicated
function OptionsMenuWorld:get_window_size()
	local w, h = usersettings.window_size.x, usersettings.window_size.y
	if w == 0 or h == 0 then
		w, h = love.window.get_mode()
	end
	return w, h
end

local function format_scale_value(scale)
	local rounded = math.floor(scale * 100 + 0.5) / 100
	local txt = string.format("%.2f", rounded)
	txt = txt:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
	return txt
end

local function approximate_ratio_string(w, h)
	if not w or not h or h == 0 then return "?" end
	local denom = 100
	local num = round((w / h) * denom)
	if num < 1 then num = 1 end
	local g = gcd(num, denom)
	num = math.floor(num / g)
	denom = math.floor(denom / g)
	return tostring(num) .. ":" .. tostring(denom)
end

function OptionsMenuWorld:update_window_size_label_from_dimensions(new_w, new_h)
	local width_scale = process_scale(new_w / conf.viewport_size.x)
	local height_scale = process_scale(new_h / conf.viewport_size.y)
	local scale = min(width_scale, height_scale)
	if math.floor(scale) == scale and scale >= 1 and scale <= NUM_WINDOW_SIZES then
		self.current_window_size = tostring(scale)
	else
		self.current_window_size = format_scale_value(scale)
	end
end

function OptionsMenuWorld:apply_window_mode_anchored(new_w, new_h, cur_w, cur_h, pos_x, pos_y)
	cur_w = cur_w or select(1, love.window.get_mode())
	cur_h = cur_h or select(2, love.window.get_mode())
	pos_x = pos_x or select(1, love.window.get_position())
	pos_y = pos_y or select(2, love.window.get_position())

	local input = self:get_input_table()
	if input.last_input_device == "gamepad" then
		local center_x = pos_x + cur_w / 2
		local center_y = pos_y + cur_h / 2
		love.window.update_mode(new_w, new_h)
		love.window.set_position(center_x - new_w / 2, center_y - new_h / 2)
	elseif input.last_input_device == "mkb" then
		local mx, my = love.mouse.get_position()
		if mx and my and mx >= 0 and my >= 0 and mx <= cur_w and my <= cur_h then
			local anchor_x = pos_x + mx
			local anchor_y = pos_y + my
			love.window.update_mode(new_w, new_h)
			love.window.set_position(anchor_x - (mx * new_w / cur_w), anchor_y - (my * new_h / cur_h))
		else
			love.window.update_mode(new_w, new_h)
			love.window.set_position(pos_x, pos_y)
		end
	else
		love.window.update_mode(new_w, new_h)
		love.window.set_position(pos_x, pos_y)
	end
end

function OptionsMenuWorld:temporarily_disable_focus_on_hover()
	for _, item in ipairs(self.menu_items) do
		item.focus_on_hover = false
		local s = self.sequencer
		s:start(function()
			s:wait(5)
			if not item.is_destroyed then
				item.focus_on_hover = true
			end
		end)
	end
end

function OptionsMenuWorld:recompute_window_and_aspect_options()
	local w, h = self:get_window_size()

	-- Window size state (use min of width/height scales)
	local width_scale = process_scale(w / conf.viewport_size.x)
	local height_scale = process_scale(h / conf.viewport_size.y)
	local scale = min(width_scale, height_scale)
	if math.floor(scale) == scale and scale >= 1 and scale <= NUM_WINDOW_SIZES then
		self.current_window_size = tostring(scale)
		self.window_size_options = {}
		for i = 1, NUM_WINDOW_SIZES do
			local idx = 1 + ((scale - 1 + (i - 1)) % NUM_WINDOW_SIZES)
			table.insert(self.window_size_options, tostring(idx))
		end
	else
		self.current_window_size = format_scale_value(scale)
		local nearest = clamp(round(scale), 1, NUM_WINDOW_SIZES)
		self.window_size_options = {}
		for i = 1, NUM_WINDOW_SIZES do
			local idx = 1 + ((nearest - 2 + (i - 1)) % NUM_WINDOW_SIZES)
			table.insert(self.window_size_options, tostring(idx))
		end
	end

	-- Aspect ratio state
	local current_ratio = w / h
	local matched_index = nil
	for i, ar in ipairs(self.base_aspects) do
		local aw, ah = parse_ratio(ar)
		if aw and ah and is_close(current_ratio, aw / ah) then
			matched_index = i
			self.current_aspect_ratio = ar
			break
		end
	end
	self.aspect_ratio_options = {}
	if matched_index then
		for i = 1, #self.base_aspects do
			table.insert(self.aspect_ratio_options, self.base_aspects[1 + (i - 1 + (matched_index - 1)) % #self.base_aspects])
		end
	else
		self.current_aspect_ratio = approximate_ratio_string(w, h)
		local nearest_idx = 1
		local best_diff = math.huge
		for i, ar in ipairs(self.base_aspects) do
			local aw, ah = parse_ratio(ar)
			if aw and ah then
				local diff = math.abs(current_ratio - (aw / ah))
				if diff < best_diff then
					best_diff = diff
					nearest_idx = i
				end
			end
		end
		for i = 1, #self.base_aspects do
			local idx = 1 + ((nearest_idx - 2 + (i - 1)) % #self.base_aspects)
			table.insert(self.aspect_ratio_options, self.base_aspects[idx])
		end
	end

	-- Push recomputed options into UI controls so cycling reflects current state
	if self.window_size_item then
		if not (tonumber(self.current_window_size) ~= nil) then
			self.window_size_item.current_option = 1
		end
		self.window_size_item:set_options(self.window_size_options)
	end
	if self.aspect_ratio_item then
		if not (self.current_aspect_ratio == "7:6" or self.current_aspect_ratio == "4:3" or self.current_aspect_ratio == "16:9") then
			self.aspect_ratio_item.current_option = 1
		end
		self.aspect_ratio_item:set_options(self.aspect_ratio_options)
	end
end


local function format_scale_value(scale)
	local rounded = math.floor(scale * 100 + 0.5) / 100
	local txt = string.format("%.2f", rounded)
	txt = txt:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
	return txt
end

local function approximate_ratio_string(w, h)
	if not w or not h or h == 0 then return "?" end
	local denom = 100
	local num = round((w / h) * denom)
	if num < 1 then num = 1 end
	local g = gcd(num, denom)
	num = math.floor(num / g)
	denom = math.floor(denom / g)
	return tostring(num) .. ":" .. tostring(denom)
end

function OptionsMenuWorld:new()
    OptionsMenuWorld.super.new(self)
	self:add_signal("exit_menu_requested")
    self:add_signal("enter_name_requested")
    self:add_signal("input_remapping_requested")
	
    self.draw_sort = self.y_sort
    self.current_page = 1
    self.current_window_size = tr.options_window_size_custom
    self.current_aspect_ratio = tr.options_window_size_custom
    local window_width, window_height = usersettings.window_size.x, usersettings.window_size.y
    if window_width == 0 or window_height == 0 then
        window_width, window_height = love.window.get_mode()
    end
    window_width = window_width / conf.viewport_size.x
    window_height = window_height / conf.viewport_size.y
    self.window_size_options = {

    }
    local init_width_scale = process_scale(window_width)
    local init_height_scale = process_scale(window_height)
    local init_scale = min(init_width_scale, init_height_scale)
    if floor(init_scale) == init_scale and init_scale >= 1 and init_scale <= NUM_WINDOW_SIZES then
        self.current_window_size = tostring(init_scale)
        for i = 1, NUM_WINDOW_SIZES do
            table.insert(self.window_size_options, tostring(1 + (i - 1 + self.current_window_size) % NUM_WINDOW_SIZES))
        end
    else
        self.current_window_size = format_scale_value(init_scale)
        local nearest = clamp(round(init_scale), 1, NUM_WINDOW_SIZES)
        for i = 1, NUM_WINDOW_SIZES do
            -- start from the item BEFORE nearest, so index 2 is nearest
            local idx = 1 + ((nearest - 2 + (i - 1)) % NUM_WINDOW_SIZES)
            table.insert(self.window_size_options, tostring(idx))
        end
    end

	self.aspect_ratio_options = {}
	local base_aspects = {  "7:6", "4:3", "16:9" }
	self.base_aspects = base_aspects
    local real_w, real_h = love.window.get_mode()
	local current_ratio = real_w / real_h
	local matched_index = nil
	for i, ar in ipairs(base_aspects) do
		local aw, ah = parse_ratio(ar)
		if aw and ah and is_close(current_ratio, aw / ah) then
			matched_index = i
			self.current_aspect_ratio = ar
			break
		end
	end
    if matched_index then
        for i = 1, #base_aspects do
            table.insert(self.aspect_ratio_options, base_aspects[1 + (i - 1 + (matched_index - 1)) % #base_aspects])
        end
    else
        -- Custom aspect: order so next cycle selects closest, then proceed in base order
        local nearest_idx = 1
        local best_diff = math.huge
        for i, ar in ipairs(base_aspects) do
            local aw, ah = parse_ratio(ar)
            if aw and ah then
                local diff = math.abs(current_ratio - (aw / ah))
                if diff < best_diff then
                    best_diff = diff
                    nearest_idx = i
                end
            end
        end
        for i = 1, #base_aspects do
            -- start from item BEFORE nearest, so index 2 is nearest
            local idx = 1 + ((nearest_idx - 2 + (i - 1)) % #base_aspects)
            table.insert(self.aspect_ratio_options, base_aspects[idx])
        end
    end
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

    if page == 2 and self.canvas_layer.in_game then
        self.next_item_y = self.next_item_y + 4
        self:ref("back_button",self:add_menu_item(back_table))
        self.next_item_y = self.next_item_y - 11
    else
        self:ref("back_button",self:add_menu_item(back_table))
        self.next_item_y = self.next_item_y + 4
    end
    



    -- local base = MENU_ITEM_V_PADDING
    local current_page = 1

    local options_table = {
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
            { "fullscreen",    item_type = "toggle",            skip = conf.platform_force_fullscreen },
            -- { "use_screen_shader", item_type = "toggle" },
    
    
            { "zoom_level", item_type = "slider", slider_start = 0.5, slider_stop = 1.0, slider_granularity = 0.025, on_set_function = function(value) self:temporarily_disable_focus_on_hover() end },
            { "pixel_perfect", item_type = "toggle" },
            { "set_window_size", item_type = "cycle", options = self.window_size_options, skip = conf.platform_force_fullscreen,
            set_func = function(value)
                    self.current_window_size = value
                    usersettings:set_setting("fullscreen", false)
                    usersettings:apply_settings()
                    love.window.restore()
                    local s = self.sequencer
                    s:start(function()
                        s:wait(1)
                        local cur_w, cur_h = love.window.get_mode()
                        local pos_x, pos_y = love.window.get_position()
                        -- Determine target integer scale when starting from a fractional scale
                        local cur_scale_w = cur_w / conf.viewport_size.x
                        local cur_scale_h = cur_h / conf.viewport_size.y
                        local cur_scale = min(cur_scale_w, cur_scale_h)
                        local target = tonumber(value) or 1
                        if math.floor(cur_scale) ~= cur_scale then
                            target = clamp(math.ceil(cur_scale), 1, NUM_WINDOW_SIZES)
                        end
                        -- Compute new size keeping aspect
                        local ratio_w_over_h = cur_w / cur_h
                        local base_ratio = conf.viewport_size.x / conf.viewport_size.y
                        local new_w, new_h
                        if ratio_w_over_h >= base_ratio then
                            new_h = conf.viewport_size.y * target
                            new_w = math.floor(new_h * ratio_w_over_h + 0.5)
                        else
                            new_w = conf.viewport_size.x * target
                            new_h = math.floor(new_w / ratio_w_over_h + 0.5)
                        end
                        self:apply_window_mode_anchored(new_w, new_h, cur_w, cur_h, pos_x, pos_y)
                        usersettings:apply_settings()
                    end)
                end,
            
            on_set_function = function(value) self:temporarily_disable_focus_on_hover() end,
    
            get_func = function()
                return self.current_window_size
            end },
    
            { "set_aspect_ratio", item_type = "cycle", options = self.aspect_ratio_options, skip = conf.platform_force_fullscreen,
                set_func = function(value)
                    self.current_aspect_ratio = value
                    usersettings:set_setting("fullscreen", false)
                    usersettings:apply_settings()
                    love.window.restore()
                    local s = self.sequencer
                    s:start(function()
                        s:wait(1)
                        local cur_w, cur_h = love.window.get_mode()
                        local aw, ah = value:match("^(%d+):(%d+)$")
                        aw, ah = tonumber(aw), tonumber(ah)
                        if not (aw and ah) then return end
                        local min_w, min_h = conf.viewport_size.x, conf.viewport_size.y
                        local new_w = math.floor(cur_h * aw / ah + 0.5)
                        local new_h = cur_h
                        if new_w < min_w then
                            new_w = min_w
                            new_h = math.floor(new_w * ah / aw + 0.5)
                        end
                        if new_h < min_h then
                            new_h = min_h
                            new_w = math.floor(new_h * aw / ah + 0.5)
                            if new_w < min_w then
                                new_w = min_w
                            end
                        end
                        local pos_x, pos_y = love.window.get_position()
                        self:apply_window_mode_anchored(new_w, new_h, cur_w, cur_h, pos_x, pos_y)
                        self:update_window_size_label_from_dimensions(new_w, new_h)
                        usersettings:apply_settings()
                    end)
                end,
    
                on_set_function = function(value) self:temporarily_disable_focus_on_hover() end,
    
                get_func = function()
                    return self.current_aspect_ratio
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
                
        { "show_hud", item_type = "toggle", inverse = false},
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
        { "saturation", item_type = "slider", slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.05 },
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
            { "use_absolute_aim", item_type = "toggle", inverse = true },
            { "mouse_sensitivity",    item_type = "slider",             slider_start = 0.0025,                                                                                       slider_stop = 0.1,       slider_granularity = 0.0025 },
            { "relative_mouse_aim_snap_to_max_range", item_type = "toggle" },
            { "gamepad_plus_mouse",                   item_type = "toggle" },
            { "confine_mouse", item_type = "cycle", options = { "when_aiming", "always", "never" },
            set_func = function(value)
                usersettings:set_setting("confine_mouse", value)
            end,
            print_func = function(value)
                local key = "options_confine_mouse_" .. (value or "")
                return tr:has_key(key) and tr[key] or "???"
            end,
            translate_options = true
            },
            { "southpaw_mode", item_type = "toggle", set_func = function()
                usersettings:set_setting("southpaw_mode", not usersettings.southpaw_mode)
            end,
            get_func = function()
                return usersettings.southpaw_mode
            end,
        },
            { "remap_inputs", item_type = "button", select_func = function()
                self:show_menu(6)
                end,
            },

            { newpage = true },
            { "header", text = tr.options_header_audio },
            { "master_volume", item_type = "slider", slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.05 },
            { "music_volume", item_type = "slider", slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.05 },
            { "sfx_volume",    item_type = "slider",          slider_start = 0.0, slider_stop = 1.0, slider_granularity = 0.05 },
            { newpage = true },
            { "header", text = tr.options_header_other },
            { "skip_intro", item_type = "toggle", skip = savedata.new_version_force_intro },
            { "retry_cooldown", item_type = "toggle", update_function = function(tab, dt)
                tab:set_enabled(not (usersettings.retry_cooldown and savedata:get_seconds_until_retry_cooldown_is_over() > 0))
                if not tab.enabled and not tab.gamer_health_timer and self.current_page == 5 then
                    tab:ref("gamer_health_timer",
                        tab:spawn_object(GamerHealthTimer(tab.pos.x, tab.pos.y, tab.width, tab.height)))
                    self:ref("gamer_health_timer", tab.gamer_health_timer)
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

            { newpage = true },
            { "header", text = tr.options_header_input_map },
    
    }

    for _, input_action in ipairs {
        "shoot",
        "secondary_weapon",
        "hover",
        "dont_shoot",
        "move_left",
        "move_right",
        "move_up",
        "move_down",
        "aim_left_digital",
        "aim_right_digital",
        "aim_up_digital",
        "aim_down_digital",
        "skip_bonus_screen",
        "show_hud",
    } do
        local input_item = {
            "input_map_" .. input_action,
            item_type = "input_button",
            input_action = input_action,
            select_func = function()
                self:emit_signal("input_remapping_requested", input_action)
            end
        }
        table.insert(options_table, input_item)
    end


    table.extend(options_table, {
        {
            "reset_controls_to_default",
            item_type = "button",
            select_func = function()
                usersettings:set_setting("input_remapping", {})
            end
        }
    })

    for _, item in ipairs(options_table) do
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

        local created_item = self:add_menu_item(item)

        if item.item_type == "cycle" then
            if item[1] == "set_window_size" then
                self:ref("window_size_item", created_item)
            elseif item[1] == "set_aspect_ratio" then
                self:ref("aspect_ratio_item", created_item)
            end
        end

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
        input_button = O.OptionsMenu.OptionsMenuInputButton,
    }

	local num_items = #self.menu_items

	
    if menu_table[1] == "header" then
		self.next_item_x = self.next_item_x + MENU_ITEM_SKEW
        self.next_item_y = self.next_item_y + (menu_table.text ~= "" and HEADER_SPACE or 0)
        local x_offs = 0
        if self.current_page == 2 and self.canvas_layer.in_game then
            x_offs = 12
        end
        local object = self:spawn_object(O.OptionsMenu.OptionsMenuHeader(self.next_item_x + x_offs, self.next_item_y,
        menu_table.text))
		self.next_item_x = self.next_item_x + MENU_ITEM_SKEW
        self.next_item_y = self.next_item_y + DISTANCE_BETWEEN_ITEMS + HEADER_SPACE_UNDER
        object:add_tag_on_enter("header")
		return
	end


	local class = classes[menu_table.item_type]

	local menu_item

    if menu_table.item_type == "input_button" then
        class = O.OptionsMenu.OptionsMenuInputButton
        menu_item = self:spawn_object(class(self.next_item_x, self.next_item_y, menu_table.name:upper(), menu_table.input_action))
    elseif menu_table.is_back then
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

    if self.current_page ~= 5 and self.gamer_health_timer then
        self.gamer_health_timer:queue_destroy()
    end

    -- Update displayed values and option lists every frame
    self:recompute_window_and_aspect_options()
end

function OptionsMenuWorld:draw()
	local font = fonts.depalettized.image_bigfont1
    graphics.set_font(font)
    if not (self.current_page == 2 and self.canvas_layer.in_game) then        
        graphics.print(tr.menu_options_button, font, 28, MENU_ITEM_V_PADDING - 3, 0, 1, 1)
    end
	OptionsMenuWorld.super.draw(self)
end

return OptionsMenuWorld
