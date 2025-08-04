return {
    elevator_killed = {
		text_key = "bonus_boss_defeated",
		score = 5000,
		score_multiplier = 1,
		xp = 1500,
		difficulty_modifier = 0.0,
	},

	final_room_clear = {
		text_key = "bonus_final_room_clear",
		score = function() return max(game_state.score * 0.5, 5000) end, 
		ignore_score_multiplier = true,
		score_multiplier = 0,
		xp = 0,
		difficulty_modifier = 0.0,
		-- final_room_allowed = true,
    },
	
	twin_saved = {
		text_key = "bonus_twin_saved",
		score = function() return max(game_state.score * 0.1, 5000) end, 
        score_multiplier = 0.00,
		ignore_score_multiplier = true,

		xp = 0,
        difficulty_modifier = 0.15,
		-- final_room_allowed = true,
    },
	
    overflow = {
		text_key = "bonus_overflow",
        score = 50,
        xp = 50,
		score_multiplier = 0.03,
		difficulty_modifier = 0.15,
    },

    tactful = {
        text_key = "bonus_tactful",
        score = 100,
        score_multiplier = 0.01,
        xp = 0,
        difficulty_modifier = 0.1,
    },
	
	ammo_hoarder = {
		text_key = "bonus_ammo_hoarder",
		score = 50,
		score_multiplier = 0.00,
		xp = 25,
		difficulty_modifier = 0.1,
	},

	aggression_bonus = {
		text_key = "bonus_aggression",
		score = function() return 
			stepify_ceil(game_state.aggression_bonus * 0.1, 10)
		end,
		score_multiplier = 0.00,
		xp = 0,
		difficulty_modifier = 0.00,
	},

    hard_room = {
        text_key = "bonus_hard_room",
        score = 500,
        score_multiplier = 0.05,
		xp = 200,
		difficulty_modifier = 0.1,
    },

	-- accuracy = {
	-- 	text_key = function() return string.format(tr.bonus_accuracy, (game_state.bullets_hit_this_level / game_state.bullets_shot_this_level * 10)) end,
	-- 	score = function() return 500 * (game_state.bullets_hit_this_level / game_state.bullets_shot_this_level) end,
	-- 	score_multiplier = 0.00,
	-- 	xp = 0,
	-- 	difficulty_modifier = 0.00,
	-- },

	perfect = {
		text_key = "bonus_perfect",
		score = 100,
		score_multiplier = 0.02,
		xp = 0,
		difficulty_modifier = 0.015,
	},

	no_damage = {
		text_key = "bonus_no_damage",
		score = 200,
		score_multiplier = 0.02,
        xp = 0,
		difficulty_modifier = 0.05,
    },

	overheal = {
		text_key = "bonus_overheal",
		score = 100,
		score_multiplier = 0.03,
		xp = 50,
        difficulty_modifier = 0.025,
    },
	
	rescue = {
		text_key = "bonus_rescue",
        score = 0,
		priority = 1,
		-- score = function()
		-- 	if game_state.final_room_entered then
		-- 		return 100
		-- 	end
		-- 	return 0
		-- end,
		score_multiplier = 0.00,
		xp = 10,
        difficulty_modifier = 0.01,
		custom_color_function = function(bonus, is_flashing, offset)
			return is_flashing and Color.darkgreen or Color.green
        end,
		-- always_show_count = true,
    },

	room_clear = {
        text_key = "bonus_room_clear",
		-- priority = 3,
		score = function() return game_state.level * 5 end,
		score_multiplier = 0.01,
        -- xp = function() return 60 + (floor(((game_state.level - 1) / 7) * 10)) end,
		xp = 600,
	},
	
	all_rescues = {
		text_key = "bonus_all_rescues",
        score = 10,
		-- priority = 1,
		score_multiplier = 0.02,
		xp = 240,
		difficulty_modifier = 0.05,
    },
	
	quick_wave = {
		text_key = "bonus_quick_wave",
		score = 25,
		score_multiplier = 0.01,
		xp = 0,
		difficulty_modifier = 0.015,
		-- always_show_count = true,
	},

	quick_save = {
		text_key = "bonus_quick_save",
		score = 10,
		score_multiplier = 0.00,
		xp = 0,
        difficulty_modifier = 0.015,
		-- always_show_count = true,
	},
	
	ammo_saver = {
		text_key = "bonus_ammo_saver",
		score = 50,
		score_multiplier = 0.00,
		xp = 0,
		difficulty_modifier = 0.015,
    },

	twin_protected = {
		text_key = "bonus_twin_protected",
		score = 50,
		score_multiplier = 0.01,
		xp = 0,
		difficulty_modifier = 0.015,
	},
	
	twin_killed = {
		text_key = "bonus_twin_killed",
        score = 30000, 
        negative = true,
		ignore_score_multiplier = true,
		score_multiplier = 0.15,
		xp = 0,
	},

	harmed_noid = {
		text_key = "bonus_harmed_noid",
        score = function()
            if game_state.final_room_entered then
                return 1000 
            end
			return 3000 
        end,
		
		ignore_score_multiplier = true,
		
		score_multiplier = 0.01,
		negative = true,
		xp = 0,
		-- always_show_count = true,
		-- difficulty_modifier = 0.015,
	},


	noid_died = {
		text_key = "bonus_noid_died",
        score = function()
            if game_state.final_room_entered then
                return 5000 
            end
			return 30000 
        end,
		
        ignore_score_multiplier = true,
		
		score_multiplier = 0.05,
        xp = 0,
        negative = true,
		-- always_show_count = true,
		-- priority = 0,
		-- difficulty_modifier = 0.015,
    },
    
    cursed_room = {
        text_key = "bonus_cursed_room",
        score = 50,
        score_multiplier = 0.01,
        xp = 100,
        difficulty_modifier = 0.015,
    },

	
}
