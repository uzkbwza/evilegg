local Enemies = {
    BaseEnemy = {
        level = 1, -- determine score based on level\
		type = "enemy",
        initial_wave_only = false,
        spawnable = true,
        room_select_weight = 10000,
		room_spawn_weight = 10000,
        min_level = 1,
		max_spawns = 999999,
    },	
    
	Walker = {
		level = 1, 
    },

	FastWalker = {
		inherit = { "Walker" },
		min_level = 2,
		room_select_weight = 5000,
		-- room_spawn_weight = 5000,
    },
	
    Roamer = {
		level = 1,
	},
	
	Hopper = {
		level = 2,
    },

	BigHopper = {
        -- inherit = { "Hopper" },
		level = 4,
		min_level = 3,
		-- room_select_weight = 5000000,
        room_spawn_weight = 3000,
		max_spawns = 2,
	},

    Enforcer = {
		level = 3,
    },

	Shielder = {
        level = 3,
        room_select_weight = 5000,
		room_spawn_weight = 6000,
		max_spawns = 1,
    },
	
	Charger = {
        level = 4,
        -- room_select_weight = 5000,
	},

}

local Hazards = {
    Bouncer = {
        initial_wave_only = true,
        level = 2,
		room_spawn_weight = 20000,
    },

	Quark = {
        level = 2,
        room_spawn_weight = 10000,
		min_level = 3,
	},

    Fungus = {
		level = 2,
        -- initial_wave_only=true,
		room_select_weight = 10000,
		-- room_spawn_weight = 10000,

	},
	
	Mine = {
		-- inherit = { "Walker", "Roamer" },
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
