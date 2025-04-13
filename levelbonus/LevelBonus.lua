return {
    hard_room = {
        text_key = "bonus_hard_room",
        score = 10000,
        score_multiplier = 0.1,
		xp = 200,
		difficulty_modifier = 0.1,
    },

	no_damage = {
		text_key = "bonus_no_damage",
		score = 2000,
		score_multiplier = 0.02,
        xp = 100,
		difficulty_modifier = 0.05,
    },

	overheal = {
		text_key = "bonus_overheal",
		score = 1000,
		score_multiplier = 0.01,
		xp = 100,
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
		xp = 200,
		difficulty_modifier = 0.05,
    },
	
	quick_wave = {
		text_key = "bonus_quick_wave",
		score = 500,
		score_multiplier = 0.01,
		xp = 10,
		difficulty_modifier = 0.015,
    },

	
}