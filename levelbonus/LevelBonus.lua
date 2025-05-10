return {
    elevator_killed = {
		text_key = "bonus_boss_defeated",
		score = 20000,
		score_multiplier = 1,
		xp = 1500,
		difficulty_modifier = 0.0,
	},

	aggression_bonus = {
		text_key = "bonus_aggression",
		score = function() return 
			game_state.aggression_bonus * (1 / 3)
		end,
		score_multiplier = 0.00,
		xp = 0,
		difficulty_modifier = 0.00,
	},

    hard_room = {
        text_key = "bonus_hard_room",
        score = 5000,
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
		xp = 10,
        difficulty_modifier = 0.025,
    },
	
	rescue = {
		text_key = "bonus_rescue",
		score = 0,
		score_multiplier = 0.00,
		xp = 10,
        difficulty_modifier = 0.01,
    },

	room_clear = {
		text_key = "bonus_room_clear",
		score = 0,
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
	
	ammo_saver = {
		text_key = "bonus_ammo_saver",
		score = 500,
		score_multiplier = 0.00,
		xp = 0,
		difficulty_modifier = 0.015,
	},

	harmed_noid = {
		text_key = "bonus_harmed_noid",
		score = 100,
		score_multiplier = 0.00,
		negative = true,
		xp = 0,
		difficulty_modifier = 0.015,
	},

}