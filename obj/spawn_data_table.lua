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
		max_level = 20,
        spawn_points = 10,
		icon = textures.enemy_base,
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
		spawn_points = 60,
		spawn_weight_modifier = 0.4,
		icon = textures.enemy_cultist,
	},
	
    Charger = {
		extra_score = 50,
        level = 4,
		spawn_points = 100,
		icon = textures.enemy_charger1,
    },
	
	Mortar = {
        level = 3,
		extra_score = 20,
		min_level = 7,
		spawn_points = 90,
		icon = textures.enemy_mortar5,
	},

}

local Hazards = {
    Bouncer = {
        initial_wave_only = true,
        level = 2,
		spawn_points = 50,
		icon = textures.enemy_bouncer1,
    },

	Quark = {
        level = 2,
		min_level = 3,
		spawn_points = 30,
		icon = textures.enemy_quark,
	},

    Fungus = {
		level = 2,
		spawn_points = 40,
		icon = textures.hazard_mushroom2,
	},
	
	Mine = {
		level = 1,
		spawn_points = 10,
		icon = textures.enemy_mine,
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
