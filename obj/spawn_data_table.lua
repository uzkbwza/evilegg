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
		max_level = 18,
        spawn_points = 10,
		room_select_weight = 2000,
        icon = textures.enemy_base,
		
    },
	
	Walksploder = {
		-- inherit = { "Walker" },
		spawn_points = 15,
		level = 1,
        extra_score = 10,
		basic_after_level = 30,
        icon = textures.enemy_walksploder,
		spawn_group = { "exploder", "basic" },
        basic_select_weight_modifier = 0.2,
        enemy_spawn_effect = "ExplosiveEnemySpawn",
	},

	FastWalker = {
        -- inherit = { "Walker" },
		level = 1,
		min_level = 12,
		-- room_select_weight = 500,
		spawn_points = 15,
		extra_score = 10,
		icon = textures.enemy_fastwalker,

    },

	BigWalker = {
		-- inherit = { "Walker" },
		level = 1,
		min_level = 16,
		room_select_weight = 500,
		spawn_points = 30,
		extra_score = 10,
        icon = textures.enemy_bigwalker,
    },
	
    Roamer = {
        level = 2,
		max_level = 15,
        icon = textures.enemy_roamer1,
        spawn_points = 10,
	},
	
	Roamsploder = {
		-- inherit = { "Roamer" },
		level = 2,
		min_level = 7,
		icon = textures.enemy_roamsploder1,
		spawn_points = 25,
        room_select_weight = 500,
		spawn_group = { "basic", "exploder" },
        enemy_spawn_effect = "ExplosiveEnemySpawn",
	},
	
	RoyalRoamer = {
		-- inherit = { "Roamer" },
        level = 2,
        min_level = 30,
		extra_score = 10,
		icon = textures.enemy_royalroamer1,
		spawn_points = 9,
		room_select_weight = 150,
	},

	Hopper = {
        level = 2,
        spawn_points = 20,
		max_level = 18,
        icon = textures.enemy_hopper1,

    },

	FastHopper = {
		level = 2,
		min_level = 14,
		spawn_points = 35,
        room_select_weight = 1000,
		extra_score = 5,
		icon = textures.enemy_fasthopper1,

	},

	BigHopper = {
        -- inherit = { "Hopper" },
		level = 4,
        min_level = 5,
		max_level = 30,
		extra_score = -16,
		spawn_points = 100,
        spawn_weight_modifier = 0.66,
		icon = textures.enemy_bighopper1,

		-- enemy_spawn_effect = "BigEnemySpawn",
	},

	Shotgunner = {
		level = 4,
		min_level = 17,
		spawn_points = 150,
		extra_score = 9,
		icon = textures.enemy_shotgunner1,
		spawn_group = { "basic", "police" },
	},
	
    Enforcer = {
		level = 3,
        extra_score = 1,
		max_level = 70,
		spawn_points = 45,
		icon = textures.enemy_enforcer3,
		spawn_group = { "basic", "police" },
    },
	
	RoyalGuard = {
		level = 3,
		extra_score = 50,
        spawn_points = 55,
		min_level = 30,
        icon = textures.enemy_royalguard3,
        -- room_select_weight = 500,
		spawn_group = { "basic", "police" },
		
		-- spawn_group = { "basic", "police" },
	},
	
    Sniper = {
		level = 3,
		extra_score = -10,
		spawn_points = 100,
		icon = textures.enemy_sniper,
        spawn_group = { "basic", "police" },
		basic_after_level = 30,
		basic_select_weight_modifier = 0.2
        -- spawn_group = { "basic", "police" },
		-- basic_select_weight_modifier = 0.5,
	},

	Turret = {
        level = 4,
		
        -- room_select_weight = 1000000,
		extra_score = 10,
		min_level = 7,
        spawn_points = 100,
		-- room_select_weight = 1000,
		icon = textures.enemy_turret_icon,
	},


    Cultist = {
        level = 4,
		min_level = 8,
		-- room_select_weight = 250,
		spawn_points = 50,
        spawn_weight_modifier = 0.65,
		extra_score = 20,
		icon = textures.enemy_cultist,
	},

    Gnome = {
        level = 4,
		min_level = 13,
		-- room_select_weight = 250,
		spawn_points = 150,
        spawn_weight_modifier = 1.5,
        extra_score = -20,
        min_spawns = 2,
        icon = textures.enemy_gnome1,
		-- max_spawns = 6
	},
	
    Charger = {
		extra_score = 0,
        level = 4,
		spawn_points = 90,
		icon = textures.enemy_charger1,
    },
	
	AcidCharger = {
		extra_score = 10,
        level = 4,
        min_level = 14,
		room_select_weight = 600,
		spawn_points = 120,
		icon = textures.enemy_acidcharger1,
	},
	
	Chargesploder = {
		inherit = { "Charger" },
        level = 4,
		min_level = 7,
		extra_score = 10,
		spawn_points = 100,
        icon = textures.enemy_chargesploder1,
		spawn_group = { "exploder", "basic" },
		basic_after_level = 30,
		basic_select_weight_modifier = 0.1,
        enemy_spawn_effect = "ExplosiveEnemySpawn",
	},
	
	Mortar = {
        level = 3,
		extra_score = 2,
		min_level = 8,
		spawn_points = 90,
		icon = textures.enemy_mortar5,
    },

    Cuboid = {
        level = 2,
		min_level = 14,
		extra_score = 20,
		spawn_points = 120,
		room_select_weight = 300,
        icon = textures.enemy_cube4,
		-- spawn_group = { "basic" },
    },

    Dancer = {
        level = 3,
        min_level = 22,
        extra_score = 30,
        spawn_points = 60,
        spawn_weight_modifier = 0.75,
        min_spawns = 3,
        valid_chance = 0.3,
        -- max_spawns = 20,
        room_select_weight = 700,
        icon = textures.enemy_dancer_icon,
        codex_sprite = textures.enemy_dancer1,
        codex_icon = textures.enemy_dancer_codex_icon,
    },

    -- HookWorm = {
    --     level = 3,
    --     spawn_points = 50,
    --     min_level = 11,
    --     spawn_weight_modifier = 1.0,
    --     icon = textures.enemy_hookworm1,
    --     room_select_weight = 300,
    -- },
	
	-- HoopSnake = {
	-- 	level = 4,
    --     spawn_points = 165,
    --     min_level = 30,
	-- 	extra_score = 100,
    --     icon = textures.enemy_hoop_snake2,
	-- 	room_select_weight = 500,
	-- 	enemy_spawn_effect = "BigEnemySpawn",
	-- },
	
    Eyeball = {
		level = 1,
        spawn_points = 35,
		extra_score = 0,
		min_level = 8,
        icon = textures.enemy_eyeball1,
        spawn_group = { "bodypart", "basic" },
		-- room_select_weight = 1000,
		basic_select_weight_modifier = 0.1,
    },
	
    Hand = {
		level = 2,
		extra_score = 20,
        spawn_points = 50,
		min_level = 8,
		icon = textures.enemy_hand1,
		spawn_group = { "bodypart", "basic" },
		-- room_select_weight = 1000,
        basic_select_weight_modifier = 0.1,
		basic_after_level = 15,
    },
	
    Foot = {
		level = 2,
		spawn_points = 50,
		extra_score = 30,
		icon = textures.enemy_foot1,
		min_level = 8,
		spawn_group = { "bodypart", "basic" },
		-- room_select_weight = 1000,
        basic_select_weight_modifier = 0.1,
		basic_after_level = 15,
	},
	
	Nose = {
		level = 3,
		spawn_points = 65,
		min_level = 8,
		extra_score = 10,
		spawn_weight_modifier = 0.45,
		icon = textures.enemy_nose1,
		spawn_group = { "bodypart" },
		basic_select_weight_modifier = 0.1,
		basic_after_level = 30,
    },
	
	Mouth = {
		level = 4,
        extra_score = 50,
		min_level = 10,
        spawn_points = 55,
		spawn_weight_modifier = 0.55,
		icon = textures.enemy_mouth1,
		spawn_group = { "bodypart" },
        basic_select_weight_modifier = 0.1,
		basic_after_level = 30,
    },
	
	Rook = {
		level = 4,
		min_level = 36,
        spawn_points = 150,
		extra_score = 10,
		spawn_weight_modifier = 0.4,
		room_select_weight = 500,
		icon = textures.enemy_big_monster1,
	},


    EvilPlayer = {
        spawnable = false,
        icon = textures.enemy_evil_player1,
        boss = true,
		min_level = 100,
	},

	EvilGreenoidBoss = {
        spawnable = false,
		icon = textures.enemy_evil_greenoid1,
		codex_sprite = textures.enemy_evil_greenoid_core,
        boss = true,
		min_level = 101,
    },
    
    Penitent = {
        -- level = 1,
        min_level = 102,
        spawn_points = 100,
        spawnable = false,
        boss = true,
        icon = textures.enemy_penitent,
    },

    PenitentSoul = {
        -- level = 1,
        min_level = 103,
        spawn_points = 100,
        spawnable = false,
        boss=true,
        icon = textures.enemy_penitent_soul1,
    },

	EggBoss = {
		spawnable = false,
        icon = textures.enemy_egg_boss1,
        boss = true,
		min_level = 1000,
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

	FastBouncer = {
        initial_wave_only = true,
        level = 2,
		min_level = 28,
		spawn_points = 50,
		max_spawns = 6,
		room_select_weight = 500,
		icon = textures.enemy_fast_bouncer1,
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
		min_level = 8,
        spawn_points = 65,
		room_select_weight = 300,
		icon = textures.hazard_exploder,
		spawn_group = { "basic", "exploder" },

        enemy_spawn_effect = "ExplosiveEnemySpawn",
	},

	Blinker = {
		level = 1,
		min_level = 11,
        spawn_points = 9,
		room_select_weight = 300,
		icon = textures.hazard_blinker,
    },

	
	Shielder = {
        level = 2,
        spawn_points = 80,
        min_level = 6,
		-- extra_score = -50,
        spawn_weight_modifier = 0.35,
		room_select_weight = 200,
		icon = textures.enemy_shielder1,
    },
	
}

local Bullets = {
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
		score = 160,
	},
}




local t = {}

for k, v in pairs(Enemies) do
	v.type = "enemy"
end

for k, v in pairs(Rescues) do
    v.type = "rescue"
    v.spawn_weight = v.spawn_weight or 1000
	v.score = v.score or 100
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
