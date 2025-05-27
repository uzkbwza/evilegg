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
    skip_tutorial = true,
    brightness = 1.0,
    saturation = 1.0,
	hue = 0.0,
    invert_colors = false,
	show_hud = true,
	
    -- fx
    screen_shake_amount = 1,
	
    -- audio
	music_volume = 1.0,
	sfx_volume = 1.0,
	
	-- debug
	debug_enabled = true,
	
    -- controls
    use_absolute_aim = true,
	relative_mouse_aim_snap_to_max_range = false,
	mouse_sensitivity = 0.08,
}

local just_started = true

local usersettings = {}

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

function usersettings:save()
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

    love.filesystem.write("_usersettings.lua", require("lib.tabley").serialize(tab))
end


function usersettings:initial_load()
    self:load()
    self:save()

    self:apply_settings()
	just_started = false
end


function usersettings:apply_settings()
    if IS_EXPORT or (not just_started) then
		if love.window.getFullscreen() ~= self.fullscreen then
			love.window.setFullscreen(self.fullscreen)
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
	if self[key] == value then return end
    self[key] = value
    self:save()
    self:apply_settings()
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
