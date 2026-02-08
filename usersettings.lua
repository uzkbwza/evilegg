local default_usersettings = {
	-- display
    -- use_screen_shader = true,
	screen_shader_preset = "shader_preset_soft",
    pixel_perfect = false,
    vsync = false,
    fullscreen = true,
	fps_cap = 300,
    cap_framerate = true,
	zoom_level = 1,
    brightness = 1.0,
    saturation = 1.0,
    hue = 0.0,
    disco_mode = false,
    invert_colors = false,
    show_hud = true,
    show_fps = false,
    shader_quality = 0.5,
    window_size = { x = 0, y = 0 },
    screen_shake_amount = 1,
    fullscreen_mode = "desktop",
	
    -- audio
	master_volume = 1.0,
	music_volume = 1.0,
    sfx_volume = 1.0,
	
	-- debug 
	debug_enabled = true,
	
    -- controls
    use_absolute_aim = true,
	relative_mouse_aim_snap_to_max_range = false,
	mouse_sensitivity = 0.08,
    gamepad_plus_mouse = false,
    confine_mouse = "when_aiming", -- when_aiming, always, never
    southpaw_mode = false,
    rumble_intensity = 1.0,
    autofire = false,
    autofire_shoot_to_aim = true,

    input_remapping = {
    },

    -- misc
    retry_cooldown = false,
    enable_leaderboard = true,
    skip_intro = false,
    allow_windowed_mode_on_steam_deck = false,
    highlight_new_codex_entries = true,
    enable_tutorial = true,
}

local usersettings = {}

local buffer = {}
local dirty = false

-- New: dedicated buffer for input remapping so API calls are buffered
local input_buffer = {}
local input_dirty = false
local __INPUT_DELETE__ = {}

-- Deferred save system: prevent disk writes during active gameplay
local pending_save = false

function usersettings:load()
    local _, u = pcall(require, "_usersettings")


    if type(u) ~= "table" then
        u = default_usersettings
    end

    for k, v in pairs(default_usersettings) do
        if u[k] == nil then
            u[k] = v
        end
    end

    for k, v in pairs(u) do
        self[k] = v
    end
end

function usersettings:buffer_setting(key, value)
    buffer[key] = value
end

function usersettings:add_remapping(action, input_type, value)
    -- keep API same; route to input buffer
    input_dirty = true
    if type(value) ~= "table" then
        value = { value }
    end
    if not input_buffer[action] then
        input_buffer[action] = {}
    end
    input_buffer[action][input_type] = value
end

function usersettings:remove_remapping(action, input_type)
    -- keep API same; route to input buffer
    input_dirty = true
    if not input_buffer[action] then
        input_buffer[action] = {}
    end
    input_buffer[action][input_type] = __INPUT_DELETE__
end


function usersettings:_write_to_disk()
    local tab = {}
    for k, v in pairs(self) do
        if type(v) == "function" then
            goto continue
        end
        if k == "default_usersettings" then
            goto continue
        end
        if tab[k] ~= default_usersettings[k] then
            tab[k] = v
        end
        ::continue::
    end

    if debug.enabled then
        print("[DEBUG] writing usersettings to disk")
    end

    love.filesystem.write("_usersettings.lua", require("lib.tabley").serialize(tab))
end

function usersettings:save()
    if not self:can_save() then
        pending_save = true
        return
    end
    pending_save = false
    self:_write_to_disk()
end

function usersettings:flush_pending_save()
    if pending_save then
        pending_save = false
        self:_write_to_disk()
    end
end

function usersettings:has_pending_save()
    return pending_save
end


function usersettings:initial_load()
    self:load()
    self:save()
    -- if not IS_EXPORT then
        -- self.fullscreen = false
    -- else
    -- end
    self.apply_window_size = true
	self:apply_settings()
end

function usersettings:apply_settings()
    print("applying user settings")

	if conf:should_platform_force_fullscreen() then
        self.fullscreen = true
        self.fullscreen_mode = "exclusive"
	end
    love.window.setFullscreen(self.fullscreen, self.fullscreen_mode)

    if self.apply_window_size and not self.fullscreen and self.window_size then
        self.apply_window_size = nil
        if self.window_size and self.window_size.x > 0 and self.window_size.y > 0 then
            local _, _, flags = love.window.getMode()
            love.window.updateMode(self.window_size.x, self.window_size.y, flags)
        end
    end

	
    love.window.setVSync(self.vsync and -1 or 0)
    if graphics then
		if graphics.adjustment_shader_options then
			graphics.adjustment_shader_options.brightness = self.brightness
			graphics.adjustment_shader_options.saturation = self.saturation
            graphics.adjustment_shader_options.hue = self.hue
			graphics.adjustment_shader_options.invert_colors = self.invert_colors
		end
		graphics.set_screen_shader_from_preset(self.screen_shader_preset)
	end
	if audio then
		audio.usersettings_update()
	end

	-- southpaw remapping is now handled during buffer commit
end

function usersettings:reset_to_default()
    for k, v in pairs(default_usersettings) do
        self[k] = v
    end
    self:save()
    self:load()
    self:apply_settings()
end

function usersettings:set_setting(key, value)
	if buffer[key] == value then
		return
	end
    buffer[key] = value
    
	dirty = true

end

function usersettings:is_dirty()
	return dirty or input_dirty
end

function usersettings:can_save()
    -- Allow saves outside of gameplay
    if not game_state then
        return true
    end
    -- Allow saves when paused
    if game_state.pause_menu_open then
        return true
    end
    -- Allow saves when dying or game over
    if game_state.dying or game_state.game_over then
        return true
    end
    -- Allow saves during level transitions
    if game_state.level_transition_can_save then
        return true
    end
    -- Block saves during active gameplay
    return false
end

function usersettings:apply_buffer()

	dirty = false
	input_dirty = false
	
    for k, v in pairs(buffer) do
        self[k] = v
    end
	-- Apply input buffer into persistent input_remapping
	for action, tab in pairs(input_buffer) do
		self.input_remapping[action] = self.input_remapping[action] or {}
		for input_type, val in pairs(tab) do
			if val == __INPUT_DELETE__ then
				if self.input_remapping[action] then
					self.input_remapping[action][input_type] = nil
				end
			else
				self.input_remapping[action][input_type] = val
			end
		end
	end

	-- Enforce southpaw immediately during commit (no extra frame)
	if self.southpaw_mode and not (self.input_remapping.move_up and self.input_remapping.move_up.joystick_axis) then
		self.input_remapping.move_up   = self.input_remapping.move_up   or {}
		self.input_remapping.move_down = self.input_remapping.move_down or {}
		self.input_remapping.move_left = self.input_remapping.move_left or {}
		self.input_remapping.move_right= self.input_remapping.move_right or {}
		self.input_remapping.aim_up    = self.input_remapping.aim_up    or {}
		self.input_remapping.aim_down  = self.input_remapping.aim_down  or {}
		self.input_remapping.aim_left  = self.input_remapping.aim_left  or {}
		self.input_remapping.aim_right = self.input_remapping.aim_right or {}
		self.input_remapping.move_up.joystick_axis    = { axis = "righty", dir = -1 }
		self.input_remapping.move_down.joystick_axis  = { axis = "righty", dir = 1 }
		self.input_remapping.move_left.joystick_axis  = { axis = "rightx", dir = -1 }
		self.input_remapping.move_right.joystick_axis = { axis = "rightx", dir = 1 }
		self.input_remapping.aim_up.joystick_axis     = { axis = "lefty", dir = -1 }
		self.input_remapping.aim_down.joystick_axis   = { axis = "lefty", dir = 1 }
		self.input_remapping.aim_left.joystick_axis   = { axis = "leftx", dir = -1 }
		self.input_remapping.aim_right.joystick_axis  = { axis = "leftx", dir = 1 }
	elseif not self.southpaw_mode and (self.input_remapping.move_up and self.input_remapping.move_up.joystick_axis) then
		if self.input_remapping.move_up   then self.input_remapping.move_up.joystick_axis   = nil end
		if self.input_remapping.move_down then self.input_remapping.move_down.joystick_axis = nil end
		if self.input_remapping.move_left then self.input_remapping.move_left.joystick_axis = nil end
		if self.input_remapping.move_right then self.input_remapping.move_right.joystick_axis = nil end
		if self.input_remapping.aim_up    then self.input_remapping.aim_up.joystick_axis    = nil end
		if self.input_remapping.aim_down  then self.input_remapping.aim_down.joystick_axis  = nil end
		if self.input_remapping.aim_left  then self.input_remapping.aim_left.joystick_axis  = nil end
		if self.input_remapping.aim_right then self.input_remapping.aim_right.joystick_axis = nil end
	end

	-- Clear input buffer before apply_settings
	table.clear(input_buffer)
	self:save()
	self:apply_settings()

	table.clear(buffer)
end

function usersettings:set_screen_shader_preset(value)
    -- if value == "shader_preset_none" then
        -- self.use_screen_shader = false
    -- else
        -- self.use_screen_shader = true
        -- self.screen_shader_preset = value
    -- end
	self.use_screen_shader = true
	self.screen_shader_preset = value
    self:save()
    self:apply_settings()
end

return usersettings
