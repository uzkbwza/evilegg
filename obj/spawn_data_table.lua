local Enemies = {
    BaseSpawn = {
        level = 1, -- determine score based on level\
        initial_wave_only = false,
        spawnable = true,
        room_select_weight = 1000,
		spawn_points = 10,
        min_level = 1,
		icon = nil,
    },	
    
	Walker = {
        level = 1,
		-- max_level = 20,
        spawn_points = 10,
		icon = textures.enemy_base,
    },

	Walksploder = {
        -- inherit = { "Walker" },
		spawn_points = 15,
		level = 1,
        icon = textures.enemy_walksploder,
		spawn_group = { "exploder" },
	},

	FastWalker = {
        -- inherit = { "Walker" },
		level = 1,
		min_level = 7,
		room_select_weight = 500,
		spawn_points = 15,
		extra_score = 0,
		icon = textures.enemy_fastwalker,
    },
	
    Roamer = {
        level = 2,
		-- max_level = 7,
        icon = textures.enemy_roamer1,
		spawn_points = 10,
	},
	
	Roamsploder = {
		-- inherit = { "Roamer" },
		level = 2,
		min_level = 5,
		icon = textures.enemy_roamsploder1,
		spawn_points = 25,
        room_select_weight = 500,
		spawn_group = { "basic", "exploder" },
	},
	
	Hopper = {
        level = 2,
		spawn_points = 20,
		icon = textures.enemy_hopper1,
    },

	BigHopper = {
        -- inherit = { "Hopper" },
		level = 4,
        min_level = 3,
		extra_score = 0,
		spawn_points = 100,
		spawn_weight_modifier = 0.66,
		icon = textures.enemy_bighopper1,
	},

    Enforcer = {
        level = 3,
		extra_score = 10,
		spawn_points = 25,
		icon = textures.enemy_enforcer3,
    },

	Turret = {
        level = 4,
		
        -- room_select_weight = 1000000,
		extra_score = 100,
		min_level = 5,
        spawn_points = 100,
		-- room_select_weight = 1000,
		icon = textures.enemy_turret_gun1,
	},

	Shielder = {
        level = 3,
        spawn_points = 80,
        min_level = 6,
		extra_score = -50,
		spawn_weight_modifier = 0.35,
		icon = textures.enemy_shielder1,
    },

    Cultist = {
        level = 3,
		min_level = 5,
		-- room_select_weight = 250,
		spawn_points = 50,
        spawn_weight_modifier = 0.35,
		extra_score = 100,
		icon = textures.enemy_cultist,
	},
	
    Charger = {
		extra_score = 50,
        level = 4,
		spawn_points = 100,
		icon = textures.enemy_charger1,
    },

	Chargesploder = {
		inherit = { "Charger" },
		level = 4,
		extra_score = 100,
		spawn_points = 100,
        icon = textures.enemy_chargesploder1,
		spawn_group = { "exploder" },
	},
	
	Mortar = {
        level = 3,
		extra_score = 20,
		min_level = 7,
		spawn_points = 90,
		icon = textures.enemy_mortar5,
    },
	
    Eyeball = {
		level = 1,
        spawn_points = 20,
		extra_score = 75,
		min_level = 7,
        icon = textures.enemy_eyeball1,
        spawn_group = { "bodypart", "basic" },
		-- room_select_weight = 1000,
		basic_select_weight_modifier = 0.01
    },
	
    Hand = {
        level = 2,
		extra_score = 100,
        spawn_points = 50,
		min_level = 7,
		icon = textures.enemy_hand1,
		spawn_group = { "bodypart", "basic" },
		-- room_select_weight = 1000,
        basic_select_weight_modifier = 0.01,
    },
	
    Foot = {
		level = 2,
		spawn_points = 50,
		icon = textures.enemy_foot1,
		min_level = 7,
		spawn_group = { "bodypart", "basic" },
		-- room_select_weight = 1000,
        basic_select_weight_modifier = 0.01,
	},
	
	Nose = {
		level = 3,
		spawn_points = 75,
		min_level = 7,
		spawn_weight_modifier = 0.65,
		icon = textures.enemy_nose1,
		spawn_group = { "bodypart" },
		basic_select_weight_modifier = 0.01,
    },
	
	Mouth = {
		level = 4,
        extra_score = 200,
		min_level = 7,
        spawn_points = 55,
		spawn_weight_modifier = 0.55,
		icon = textures.enemy_mouth1,
		spawn_group = { "bodypart" },
		basic_select_weight_modifier = 0.01,
	},
}

local Hazards = {
    Bouncer = {
        initial_wave_only = true,
        level = 2,
		spawn_points = 50,
		max_spawns = 6,
		icon = textures.enemy_bouncer1,
    },

	Quark = {
        level = 2,
		min_level = 3,
		spawn_points = 30,
		icon = textures.hazard_quark,
	},

    Fungus = {
		level = 2,
		spawn_points = 40,
		icon = textures.hazard_mushroom2,
	},
	
	Mine = {
		level = 1,
		spawn_points = 10,
        icon = textures.hazard_mine,
		-- spawn_group = { "basic", "bodypart" },
	},
	
	Exploder = {
        level = 1,
		min_level = 4,
        spawn_points = 65,
		room_select_weight = 300,
		icon = textures.hazard_exploder,
		spawn_group = { "basic", "exploder" },
	},

	Blinker = {
		level = 1,
		min_level = 3,
        spawn_points = 20,
		room_select_weight = 300,
		icon = textures.hazard_blinker,
    },
	
}

local Bullets = {
	-- EnforcerBullet = {
	-- 	icon = textures.enemy_enforcer_bullet1,
	-- },
}

local Rescues = {
    NormalRescue = {
		-- level = 1,
		-- spawn_points = 10,
		icon = textures.ally_rescue1,
		spawn_weight = 1000,
    },
	
	DogRescue = {
		-- level = 1,
		-- spawn_points = 10,
        icon = textures.ally_rescue_dog1,
		level = 2,
		spawn_weight = 50,
		score = 1600,
	},
}




local t = {}

for k, v in pairs(Enemies) do
	v.type = "enemy"
end

for k, v in pairs(Rescues) do
    v.type = "rescue"
    v.spawn_weight = v.spawn_weight or 1000
	v.score = v.score or 1000
end

for k, v in pairs(Hazards) do
	v.type = "hazard"
end

for k, v in pairs(Bullets) do
	v.type = "bullet"
end


table.merge(t, Enemies)
table.merge(t, Hazards)
table.merge(t, Bullets)
table.merge(t, Rescues)


return t
