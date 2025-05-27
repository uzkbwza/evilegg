return {
    elevator_killed = {
		text_key = "bonus_boss_defeated",
		score = 10000,
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
    },
	
	twin_saved = {
		text_key = "bonus_twin_saved",
		score = function() return max(game_state.score * 0.5, 5000) end,
        score_multiplier = 0.00,
		ignore_score_multiplier = true,

		xp = 0,
		difficulty_modifier = 0.00,
	},

	aggression_bonus = {
		text_key = "bonus_aggression",
		score = function() return 
			game_state.aggression_bonus * (1 / 5)
		end,
		score_multiplier = 0.00,
		xp = 0,
		difficulty_modifier = 0.00,
	},

    hard_room = {
        text_key = "bonus_hard_room",
        score = 1000,
        score_multiplier = 0.1,
		xp = 200,
		difficulty_modifier = 0.1,
    },

	perfect = {
		text_key = "bonus_perfect",
		score = 1000,
		score_multiplier = 0.02,
		xp = 0,
		difficulty_modifier = 0.015,
	},

	no_damage = {
		text_key = "bonus_no_damage",
		score = 2000,
		score_multiplier = 0.02,
        xp = 0,
		difficulty_modifier = 0.05,
    },

	overheal = {
		text_key = "bonus_overheal",
		score = 1000,
		score_multiplier = 0.01,
		xp = 50,
        difficulty_modifier = 0.025,
    },
	
	rescue = {
		text_key = "bonus_rescue",
		score = 0,
		-- score = function()
		-- 	if game_state.final_room_entered then
		-- 		return 100
		-- 	end
		-- 	return 0
		-- end,
		score_multiplier = 0.00,
		xp = 10,
        difficulty_modifier = 0.01,
    },

	room_clear = {
		text_key = "bonus_room_clear",
		score = function() return game_state.level * 10 end,
		score_multiplier = 0.01,
        -- xp = function() return 60 + (floor(((game_state.level - 1) / 7) * 10)) end,
		xp = 600,
	},
	
	all_rescues = {
		text_key = "bonus_all_rescues",
		score = 2000,
		score_multiplier = 0.02,
		xp = 240,
		difficulty_modifier = 0.05,
    },
	
	quick_wave = {
		text_key = "bonus_quick_wave",
		score = 300,
		score_multiplier = 0.01,
		xp = 0,
		difficulty_modifier = 0.015,
	},

	quick_save = {
		text_key = "bonus_quick_save",
		score = 100,
		score_multiplier = 0.00,
		xp = 0,
		difficulty_modifier = 0.015,
	},
	
	ammo_saver = {
		text_key = "bonus_ammo_saver",
		score = 500,
		score_multiplier = 0.00,
		xp = 0,
		difficulty_modifier = 0.015,
    },

	twin_protected = {
		text_key = "bonus_twin_protected",
		score = 500,
		score_multiplier = 0.01,
		xp = 0,
		difficulty_modifier = 0.015,
	},
	
	twin_killed = {
		text_key = "bonus_twin_killed",
        score = 20000,
        negative = true,
		ignore_score_multiplier = true,
		score_multiplier = 0.5,
		xp = 0,
	},

	harmed_noid = {
		text_key = "bonus_harmed_noid",
        score = function()
            if game_state.final_room_entered then
                return 400
            end
			return 2000
        end,
		
		ignore_score_multiplier = true,
		
		score_multiplier = 0.03,
		negative = true,
		xp = 0,
		difficulty_modifier = 0.015,
	},

}