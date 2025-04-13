local translations = {
    en = {
        room_has_max_points = "HI SCORE",
        room_is_bonus = "BONUS",
		room_is_hard = "HARD",
		
		notif_fire_rate = "FIRE RATE",
		notif_range = "RANGE",
		notif_bullets = "BULLETS",
		notif_bullet_speed = "BULLET SPEED",
		notif_damage = "DAMAGE",
        notif_boost = "BOOST",
		
        notif_heart = "HP",

		notif_upgrade_available = "EARNED UPGRADE",
		notif_heart_available = "EARNED HEART",
		notif_powerup_available = "EARNED POWERUP",
		notif_artefact_available = "EARNED ARTEFACT",

        bonus_hard_room = "HARD ROOM",
        bonus_no_damage = "NO DAMAGE",
        bonus_overheal = "OVERHEAL",
		bonus_rescue = "GREENOIDS",
        bonus_all_rescues = "RESCUED ALL",
        bonus_quick_wave = "QUICK WAVE",
        bonus_room_clear = "ROOM CLEAR",
		bonus_kill = "KILLS",
		
		-- artefact_more_bullets_name = "MORE BULLETS",
        -- artefact_damage_over_distance_name = "SNOWBALL",

		artefact_ricochet_name = "MAGIC MIRROR",
        artefact_grappling_hook_name = "ROD OF RETRIEVAL",
        artefact_amulet_of_rage_name = "AMULET OF RAGE",
		artefact_sacrificial_twin_name = "SACRIFICIAL TWIN",
		artefact_drone_name = "HOMUNCULUS",
		artefact_ring_of_loyalty_name = "RING OF LOYALTY",
		artefact_boost_damage_name = "PYRO TANK",
		artefact_stone_trinket_name = "STONE TRINKET",
		artefact_crown_of_frenzy_name = "CROWN OF FRENZY",
		artefact_death_cap_name = "DEATH CAP",
		artefact_clock_name = "STOP WATCH",
		-- artefact_more_bullets_desc = "You have a higher bullet upgrade cap.",
        -- artefact_damage_over_distance_desc = "Your bullet damage increases with distance travelled.",
		
        artefact_ricochet_desc         = "Your bullets bounce off walls.",
		artefact_grappling_hook_desc   = "Shoot greenoids to pull them closer.",
		artefact_amulet_of_rage_desc   = "Your bullets deal more damage up close.",
		artefact_sacrificial_twin_desc = "It will die for you. Single-use.",
		artefact_drone_desc            = "A loyal companion.",
		artefact_ring_of_loyalty_desc  = "Rescuing greenoids triggers a burst attack.",
		artefact_boost_damage_desc     = "Boosting leaves a trail of fire.",
		artefact_stone_trinket_desc    = "+Random upgrade when you overheal.",
        artefact_crown_of_frenzy_desc  = "+Fire rate when no greenoids on screen.",
		artefact_death_cap_desc        = "Fungi are sympathetic to your mission.",
		artefact_clock_desc            = "Chain rescues increasingly slow enemies.",

        menu_back_button = "BACK",
		menu_options_button = "OPTIONS",
		
		main_menu_start_button = "START",
		main_menu_leaderboard_button = "RANKINGS",
		main_menu_codex_button = "CODEX",
		main_menu_credits_button = "CREDITS",
		main_menu_quit_button = "QUIT",

        pause_menu_resume_button = "RESUME",
		pause_menu_quit_button = "QUIT",

		death_screen_retry_button = "RETRY",
		death_screen_quit_button = "QUIT",

        options_use_screen_shader = "Use Screen Shader",
        options_screen_shader_preset = "Screen Shader",
		options_pixel_perfect = "Pixel Perfect Scaling",
		options_vsync = "VSync",
		options_fullscreen = "Fullscreen",
		options_cap_framerate = "FPS Cap Enabled",
		options_fps_cap = "FPS Cap",
        options_zoom_level = "Zoom Level",
		options_screen_shake_amount = "Screen Shake Amount",
		options_music_volume = "Music Volume",
        options_sfx_volume = "SFX Volume",
        options_debug_enabled = "Debug Enabled",
		-- options_relative_mouse_aim_enabled = "Twin-Stick Mouse Enabled",
		-- options_show_relative_aim_mouse_crosshair = "Twin-Stick Mouse Crosshair",
		options_use_absolute_aim = "Absolute Mouse Aim",
        options_mouse_sensitivity      = "Relative Mouse Sensitivity",
		options_relative_mouse_aim_snap_to_max_range = "Rel. Mouse Snap Distance",

		options_header_controls = "CONTROLS",
		options_header_display = "DISPLAY",
		options_header_audio = "AUDIO",
		options_cheats = "CHEATS",

		shader_preset_soft = "Soft",
		shader_preset_scanline = "Scanline",
		shader_preset_lcd = "LCD",
		shader_preset_ledboard = "LED Board",
    },
}

local Translator = Object:extend("Translator")


function Translator:new()
    self:set_language("en")
	self.translations = translations
end

function Translator:set_language(language)
	self.current_language = language
end

function Translator:get_language()
    return self.current_language
end

function Translator:has_key(key)
    return self.translations[self.current_language] and self.translations[self.current_language][key]
end

function Translator:translate(key)
    if not (self.translations[self.current_language] and self.translations[self.current_language][key]) then
        if self.translations["en"][key] then
            return self.translations["en"][key]
        else
			if debug.enabled then
				error("missing translation: " .. key)
			end
			return key
        end
    end
    local text = self.translations[self.current_language][key]
    if debug.enabled and text == nil then
		error("missing translation: " .. key)
	end
    return text
end

local object = Translator()

tr = setmetatable({}, {
    __index = function(t, k)
		if object[k] then
			return object[k]
        end
        return object:translate(k)
    end,
    __call = function(t, k)
        return object:translate(k)
    end
})

return object
