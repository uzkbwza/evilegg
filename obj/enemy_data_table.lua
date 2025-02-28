local Enemies = {
    BaseEnemy = {
        level = 1, -- determine score based on level\
		type = "enemy",
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
        spawn_points = 8,
		icon = textures.enemy_base,
    },

	FastWalker = {
		-- inherit = { "Walker" },
		min_level = 3,
		room_select_weight = 500,
		spawn_points = 10,
		icon = textures.enemy_fastwalker,
    },
	
    Roamer = {
        level = 2,
		max_level = 7,
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
		
		spawn_points = 150,
		icon = textures.enemy_bighopper1,
	},

    Enforcer = {
		level = 3,
		spawn_points = 30,
		icon = textures.enemy_enforcer3,
    },

	Turret = {
		level = 4,
        spawn_points = 100,
		-- room_select_weight = 1000,
		icon = textures.enemy_turret_gun1,
	},

	Shielder = {
        level = 3,
        spawn_points = 200,
		min_level = 6,
		icon = textures.enemy_shielder1,
    },
	
	Charger = {
        level = 4,
		spawn_points = 100,
		icon = textures.enemy_charger1,
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
		spawn_points = 20,
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
	-- },
}

local t = {}

for k, v in pairs(Hazards) do
	v.type = "hazard"
end

for k, v in pairs(Bullets) do
	v.type = "bullet"
end

table.merge(t, Enemies)
table.merge(t, Hazards)
table.merge(t, Bullets)


return t
