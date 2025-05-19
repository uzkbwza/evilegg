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
		bonus_boss_defeated = "BOSS KILLED",
		bonus_aggression = "COURAGE",
		bonus_perfect = "FLAWLESS",
		bonus_ammo_saver = "AMMO SAVER",
		bonus_harmed_noid = "NOID INJURY",
		bonus_final_room_clear = "EGG SLAIN",

		upgrade_name_fire_rate = "+FIRE RATE",
		upgrade_desc_fire_rate = "Increases how rapidly you can fire bullets and secondary weapons.",

		upgrade_name_range = "+RANGE",
		upgrade_desc_range = "Increases the range of your bullets and secondary weapons. Affects some artefacts.",

		upgrade_name_bullets = "+BULLETS",
		upgrade_desc_bullets = "Increases the number of bullets you can fire at once. Affects some artefacts.",

		upgrade_name_bullet_speed = "+BULLET SPEED",
		upgrade_desc_bullet_speed = "Increases the speed of your bullets as well as their knockback. Affects some artefacts.",

		upgrade_name_damage = "+DAMAGE",
		upgrade_desc_damage = "Increases the damage of your bullets, secondary weapons, and certain artefacts.",


		heart_base_name                              = "HEART",
		heart_base_desc                              = "Restores 1 heart. If you are damaged with no hearts left, you will die. Max 2.",

		powerup_rocket_name                          = "MISSILE",
		powerup_rocket_desc                          = "High-powered rocket-propelled missiles. Lasts for 6 seconds. Duration stacks.",

		-- artefact_more_bullets_name = "MORE BULLETS",
		-- artefact_damage_over_distance_name = "SNOWBALL",

		artefact_ricochet_name                       = "MAGIC MIRROR",
		artefact_grappling_hook_name                 = "ROD OF RETRIEVAL",
		artefact_amulet_of_rage_name                 = "AMULET OF RAGE",
		artefact_sacrificial_twin_name               = "SACRIFICIAL TWIN",
		artefact_drone_name                          = "HOMUNCULUS",
		artefact_ring_of_loyalty_name                = "RING OF LOYALTY",
		artefact_boost_damage_name                   = "PYRO TANK",
		artefact_stone_trinket_name                  = "STONE TRINKET",
		artefact_crown_of_frenzy_name                = "CROWN OF FRENZY",
		artefact_death_cap_name                      = "DEATH CAP",
		artefact_clock_name                          = "STOP WATCH",
		artefact_defabricator_name                   = "DEFABRICATOR",
		artefact_warbell_name                        = "WAR BELL",
		-- artefact_more_bullets_desc = "You have a higher bullet upgrade cap.",
		-- artefact_damage_over_distance_desc = "Your bullet damage increases with distance travelled.",

		artefact_grappling_hook_desc                 = "Shoot greenoids to pull them closer.",
		artefact_ricochet_desc                       = "Your bullets bounce off walls.",
		artefact_amulet_of_rage_desc                 = "Your bullets deal more damage up close.",
		artefact_sacrificial_twin_desc               = "It will die for you. Single-use.",
		artefact_drone_desc                          = "A loyal companion.",
		artefact_ring_of_loyalty_desc                = "Rescuing greenoids triggers a burst attack.",
		artefact_boost_damage_desc                   = "Faster boost that leaves a trail of fire.",
		artefact_stone_trinket_desc                  = "+Random upgrade when you overheal.",
		artefact_crown_of_frenzy_desc                = "+Fire rate when no greenoids on screen.",
		artefact_death_cap_desc                      = "Fungi are sympathetic to your mission.",
		artefact_clock_desc                          = "Chain rescues to increasingly slow enemies.",
		artefact_defabricator_desc                   = "Convert artefact in slot %d to XP.",
		artefact_warbell_desc                        = "Greenoids will attack nearby enemies.",

		weapon_sword_name                            = "THE DIVIDING LINE",
		weapon_sword_desc                            = "An executioner's sword.",

		-- menu_back_button = "BACK",
		menu_options_button                          = "OPTIONS",

		main_menu_start_button                       = "START",
		main_menu_leaderboard_button                 = "RANKINGS",
		menu_codex_button                            = "CODEX",
		main_menu_credits_button                     = "CREDITS",
		main_menu_quit_button                        = "QUIT",

		pause_menu_resume_button                     = "RESUME",
		pause_menu_quit_button                       = "QUIT",

		death_screen_retry_button                    = "RETRY",
		death_screen_quit_button                     = "QUIT",
		death_screen_leaderboard_button              = "RANKINGS",

		-- options_use_screen_shader = "Use Screen Shader",
		options_screen_shader_preset                 = "Screen Shader",
		options_pixel_perfect                        = "Pixel Perfect Scaling",
		options_vsync                                = "VSync",
		options_fullscreen                           = "Fullscreen",
		-- options_cap_framerate = "FPS Cap Enabled",
		options_fps_cap                              = "FPS Cap",
		options_fps_cap_unlimited                    = "No Cap",
		options_zoom_level                           = "Zoom Level",
		options_screen_shake_amount                  = "Screen Shake Amount",
		options_music_volume                         = "Music Volume",
		options_sfx_volume                           = "SFX Volume",
		options_debug_enabled                        = "Debug Enabled",
		-- options_relative_mouse_aim_enabled = "Twin-Stick Mouse Enabled",
		-- options_show_relative_aim_mouse_crosshair = "Twin-Stick Mouse Crosshair",
		options_use_absolute_aim                     = "Absolute Mouse Aim",
		options_mouse_sensitivity                    = "Relative Mouse Sensitivity",
		options_relative_mouse_aim_snap_to_max_range = "Rel. Mouse Snap Distance",
		options_skip_tutorial                        = "Skip Tutorial",
		options_enter_name                           = "Enter Name",


		options_brightness          = "Brightness",
		options_saturation          = "Saturation",
		options_hue                 = "Hue Shift",
		options_invert_colors       = "Invert Colors",

		options_header_controls     = "CONTROLS",
		options_header_display      = "DISPLAY",
		options_header_audio        = "AUDIO",
		options_header_other        = "OTHER",

		-- options_header_cheats = "CHEATS",
		-- options_header_leaderboard = "LEADERBOARD",

		name_entry_prompt           = "ENTER YOUR NAME",

		shader_preset_soft          = "Soft",
		shader_preset_scanline      = "Scanline",
		shader_preset_lcd           = "LCD",
		shader_preset_ledboard      = "LED Board",
		shader_preset_none          = "None",

		codex_name_walker           = "Ghost",
		codex_desc_walker           = "A stupid and weak pursuer.",

		codex_name_walksploder      = "Splode Ghost",
		codex_desc_walksploder      = "Even the sparsest kindling can produce roaring flames, if just for a moment.",

		codex_name_fastwalker       = "Wild Ghost",
		codex_desc_fastwalker       = "A jilted lover. A victim. Or maybe it was always like this.",

		codex_name_bigwalker        = "Shade",
		codex_desc_bigwalker        = "After death, age is only experience.",

		codex_name_roamer           = "Roamer",
		codex_desc_roamer           = "A frenetic urchin more violent than curious.",

		codex_name_roamsploder      = "Splode Roamer",
		codex_desc_roamsploder      = "Some cope with hurt by pre-empting their anger.",

		codex_name_hopper           = "Hopper",
		codex_desc_hopper           = "An invasive species.",

		codex_name_fasthopper       = "Wild Hopper",
		codex_desc_fasthopper       = "An adolescent with an extreme imbalance of humors.",

		codex_name_bighopper        = "Big Hopper",
		codex_desc_bighopper        = "In the final stages of its lifespan, the cycle starts anew.",

		codex_name_shotgunner       = "Sheriff",
		codex_desc_shotgunner       = "Stand your ground and maintain eye contact.",

		codex_name_enforcer         = "Deputy",
		codex_desc_enforcer         = "Just following orders.",

		codex_name_sniper           = "Sniper",
		codex_desc_sniper           = "A coward with good aim.",

		codex_name_turret           = "Cannon",
		codex_desc_turret           = "A naturally occurring mechanism of war.",

		codex_name_shielder         = "Shielder",
		codex_desc_shielder         = "Unnaturally selfless.",

		codex_name_cultist          = "Vampire",
		codex_desc_cultist          = "Greenoids are their preferred protein but you will do. Mom protects them from the sun.",

		codex_name_gnome            = "Gnome",
		codex_desc_gnome            = "Pack hunter. He knows it is cruel to laugh and laughs anyway.",

		codex_name_charger          = "Charger",
		codex_desc_charger          = "Most vulnerable when showing emotion.",

		codex_name_chargesploder    = "Splode Charger",
		codex_desc_chargesploder    = "Violent martyrdom is its first choice.",

		codex_name_mortar           = "Mortar",
		codex_desc_mortar           = "Some problems you can only address at the source.",

		codex_name_cuboid           = "Cuboid",
		codex_desc_cuboid           = "Death is the climax of life.",

		codex_name_eyeball          = "Eyeball",
		codex_desc_eyeball          = "Gently relax your gaze from the subject of your vision. Shift your awareness to the perception of light and color. There is no meaning to the image. This is seeing without looking.",

		codex_name_foot             = "Foot",
		codex_desc_foot             = "Guide your attention to your feet. What separates you from the ground beneath you? Focus not on yourself but all that is, and recognize you are that.",

		codex_name_hand             = "Hand",
		codex_desc_hand             = "Now open and close your hands, making a fist. To hold on tight is to look through a pinhole. Release the object of your attachment and you will see it clearly.",

		codex_name_nose             = "Nose",
		codex_desc_nose             = "Shift your focus to your breath. Inhale through the nose and slowly count to four. Let the air fall into your belly. Hold it for a moment,",
		codex_name_mouth            = "Mouth",
		codex_desc_mouth            = "Then exhale through your mouth for a slow count to six, still focusing on the breath. Now start again from the beginning.",

		codex_name_evilplayer       = "Shadow Self",
		codex_desc_evilplayer       = "Your heart takes you where it wants.",

		codex_name_evilgreenoidboss = "Lost Embryo",
		codex_desc_evilgreenoidboss = "Becomes aggressive and unpredictable as its makeshift shell decays.",

		codex_name_eggboss          = "Evil Egg",
		codex_desc_eggboss          = "I never wanted to be born a monster.",

		codex_name_bouncer          = "Mini Egg",
		codex_desc_bouncer          = "Bullets don't ring but thud off this impenetrable thing. Behind its hard shell there is only more shell.",

		codex_name_fastbouncer      = "Special Egg",
		codex_desc_fastbouncer      = "Mother's little helper.",

		codex_name_quark            = "Bouncer",
		codex_desc_quark            = "It coasts silently through the air with unnatural inertia.",

		codex_name_fungus           = "Fungus",
		codex_desc_fungus           = "A hydroid supermass of tendrils and bulbs. Surprisingly intelligent.",

		codex_name_mine             = "Land Mine",
		codex_desc_mine             = "Watch your step.",

		codex_name_exploder         = "Heavy Mine",
		codex_desc_exploder         = "Hateful engineering.",

		codex_name_blinker          = "Blinker",
		codex_desc_blinker          = "Erratic whims carry it here and there.",

		codex_name_normalrescue     = "Greenoid",
		codex_desc_normalrescue     = "Friendly and endangered.",

		codex_name_dogrescue        = "Gruppy",
		codex_desc_dogrescue        = "Distrustful of strangers.",

		codex_key_all               = "ALL",
		codex_key_enemy             = "ENEMIES",
		codex_key_hazard            = "HAZARDS",
		codex_key_rescue            = "GREENOIDS",
		codex_key_pickups           = "PICKUPS",
		codex_key_artefact          = "ARTEFACTS",
		codex_key_secondary_weapon  = "WEAPONS",


		game_over_score_display = "Final Score",
		game_over_rescue_display = "Greenoids Saved",
		game_over_kill_display = "Enemies Killed",
		game_over_level_display = "Level Reached",
		game_over_time_display = "Game Time",
		stat_display_prev_high = "Best",

		leaderboard_loading = "Connecting...",
		leaderboard_error = "Error connecting to leaderboard",
		leaderboard_deaths = "Hatchlings Vanquished",

		leaderboard_top_button = "TOP",
		leaderboard_me_button = "ME",
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
