local Upgrades = {
	BaseUpgrade = {
        spawn_weight = 1000,
	},
	
	FireRateUpgrade = {
        icon = textures.pickup_upgrade_fire_rate_icon,
        textures = {
			textures.pickup_upgrade_fire_rate_icon,
			textures.pickup_upgrade_fire_rate_icon,
			textures.pickup_upgrade_fire_rate_icon,
        },
        upgrade_type = "fire_rate",
        notification_text = "notif_fire_rate",
        notification_palette = "notif_fire_rate_up",
        name = "upgrade_name_fire_rate",
		description = "upgrade_desc_fire_rate",
		
    },

	RangeUpgrade = {
		icon = textures.pickup_upgrade_range_icon,
		-- textures = {
			-- textures.pickup_upgrade_range_icon,
			-- textures.pickup_upgrade_range_icon,
			-- textures.pickup_upgrade_range_icon,
		-- },
		upgrade_type = "range",
		notification_text = "notif_range",
		notification_palette = "notif_range_up",
		name = "upgrade_name_range",
		description = "upgrade_desc_range",
    },
	
	NumBulletsUpgrade = {
		icon = textures.pickup_upgrade_num_bullets_icon,
		-- textures = {
		-- 	textures.pickup_upgrade_num_bullets_icon,
		-- 	textures.pickup_upgrade_num_bullets_icon,
		-- 	textures.pickup_upgrade_num_bullets_icon,
		-- },
		upgrade_type = "bullets",
		notification_text = "notif_bullets",
		notification_palette = "notif_bullets_up",
		name = "upgrade_name_bullets",
		description = "upgrade_desc_bullets",
	},

	BulletSpeedUpgrade = {
		icon = textures.pickup_upgrade_bullet_speed_icon,
		-- textures = {
		-- 	textures.pickup_upgrade_bullet_speed_icon,
		-- 	textures.pickup_upgrade_bullet_speed_icon,
		-- 	textures.pickup_upgrade_bullet_speed_icon,
		-- },
		upgrade_type = "bullet_speed",
		notification_text = "notif_bullet_speed",
		notification_palette = "notif_bullet_speed_up",
		name = "upgrade_name_bullet_speed",
		description = "upgrade_desc_bullet_speed",
	},

	DamageUpgrade = {
		icon = textures.pickup_upgrade_damage_icon,
		-- textures = {
		-- 	textures.pickup_upgrade_damage_icon,
		-- 	textures.pickup_upgrade_damage_icon,
		-- 	textures.pickup_upgrade_damage_icon,
		-- },
		upgrade_type = "damage",
		notification_text = "notif_damage",
		notification_palette = "notif_damage_up",
		name = "upgrade_name_damage",
		description = "upgrade_desc_damage",
	},

	-- BoostUpgrade = {
	-- 	icon = textures.pickup_upgrade_boost_icon,
	-- 	-- textures = {
	-- 	-- 	textures.pickup_upgrade_boost_icon,
	-- 	-- 	textures.pickup_upgrade_boost_icon,
	-- 	-- 	textures.pickup_upgrade_boost_icon,
	-- 	-- },
	-- 	upgrade_type = "boost",
	-- 	notification_text = "notif_boost_up",
	-- 	notification_palette = "notif_boost_up",
	-- },
}

local Powerups = {
	BasePowerup = {
		icon = textures.pickup_powerup_placeholder,
		-- textures = {
		-- 	textures.pickup_powerup_placeholder,
		-- 	textures.pickup_powerup_placeholder,
		-- 	textures.pickup_powerup_placeholder,
		-- },
        spawn_weight = 1000,
		bullet_powerup = false,
		bullet_powerup_time = 10,
		name = "powerup_base_name",
		description = "powerup_base_desc",
	},

	RocketPowerup = {
		icon = textures.pickup_powerup_rocket1,
        spawn_weight = 1000,
		textures = {
			textures.pickup_powerup_rocket1,
			textures.pickup_powerup_rocket2,
			-- textures.pickup_powerup_rocket3,
        },
        bullet_powerup = true,
		bullet_powerup_time = 6,
		name = "powerup_rocket_name",
		description = "powerup_rocket_desc",
	},

	
}

local Hearts = {
	BaseHeart = {
        icon = textures.pickup_heart_icon,
		textures = {
			textures.pickup_heart_placeholder,
		},
        sound = "pickup_heart",
        sound_volume = 0.75,
		heart_type = "normal",
		notification_text = "notif_heart",
		notification_palette = "notif_heart_up",
		name = "heart_base_name",
		description = "heart_base_desc",
    },
	
	NormalHeart = {
		inherit = { "BaseHeart" },
        icon = textures.pickup_heart_icon,
		textures = {
			textures.pickup_heart_placeholder,
		},
        sound = "pickup_heart",
        sound_volume = 0.75,
		heart_type = "normal",
		notification_text = "notif_heart",
		notification_palette = "notif_heart_up",
		name = "heart_base_name",
		description = "heart_base_desc",
	},
}

local Artefacts = {
	BaseArtefact = {
		icon = textures.pickup_item_placeholder,
		key = "base",
		name = "artefact_base_name",
		description = "artefact_base_desc",
        spawn_weight = 1000,
	},

	RicochetArtefact = {
        icon = textures.pickup_artefact_ricochet,
		key = "ricochet",
		name = "artefact_ricochet_name",
		description = "artefact_ricochet_desc",
		spawn_weight = 1000,
    },
	
	-- MoreBulletsArtefact = {
    --     icon = textures.pickup_artefact_more_bullets,
	-- 	key = "more_bullets",
	-- 	name = "artefact_more_bullets_name",
	-- 	description = "artefact_more_bullets_desc",
    --     spawn_weight = 1000,
	-- 	remove_function = function(game_state)
	-- 		game_state.upgrades.bullets = min(game_state.upgrades.bullets, game_state:get_max_upgrade("bullets"))
	-- 	end,
    -- },
	
	-- DamageOverDistanceArtefact = {
    --     icon = textures.pickup_artefact_damage_over_distance,
	-- 	key = "damage_over_distance",
	-- 	name = "artefact_damage_over_distance_name",
	-- 	description = "artefact_damage_over_distance_desc",
    --     spawn_weight = 1000,
    -- },
	
	AmuletOfRageArtefact = {
        icon = textures.pickup_artefact_amulet_of_rage,
		key = "amulet_of_rage",
		name = "artefact_amulet_of_rage_name",
		description = "artefact_amulet_of_rage_desc",
        spawn_weight = 1000,
    },

	GrapplingHookArtefact = {
        icon = textures.pickup_artefact_grappling_hook,
		key = "grappling_hook",
		name = "artefact_grappling_hook_name",
		description = "artefact_grappling_hook_desc",
        spawn_weight = 1000,
    },
	
	SacrificialTwinArtefact = {
        icon = textures.pickup_artefact_twin,
		key = "sacrificial_twin",
		name = "artefact_sacrificial_twin_name",
		description = "artefact_sacrificial_twin_desc",
        spawn_weight = 1000,
		remove_function = function(game_state, slot)
            game_state:set_selected_artefact_slot(slot)
		end,
	},

	DroneArtefact = {
        icon = textures.pickup_artefact_drone,
		key = "drone",
		name = "artefact_drone_name",
		description = "artefact_drone_desc",
        spawn_weight = 1000,
	},

	RingOfLoyaltyArtefact = {
        icon = textures.pickup_artefact_ring_of_loyalty,
		key = "ring_of_loyalty",
		name = "artefact_ring_of_loyalty_name",
		description = "artefact_ring_of_loyalty_desc",
        spawn_weight = 1000,
        -- spawn_weight = 10000000,
		-- must_not_have_artefacts = {
		-- 	"clock"
		-- }
	},

	BoostDamageArtefact = {
        icon = textures.pickup_artefact_boost_damage,
		key = "boost_damage",
		name = "artefact_boost_damage_name",
		description = "artefact_boost_damage_desc",
        spawn_weight = 1000,
	},

	StoneTrinketArtefact = {
        icon = textures.pickup_artefact_stone_trinket,
		key = "stone_trinket",
		name = "artefact_stone_trinket_name",
		description = "artefact_stone_trinket_desc",
        spawn_weight = 1000,
    },
	
	CrownOfFrenzyArtefact = {
        icon = textures.pickup_artefact_crown_of_frenzy,
		key = "crown_of_frenzy",
		name = "artefact_crown_of_frenzy_name",
		description = "artefact_crown_of_frenzy_desc",
        spawn_weight = 1000,
    },
	
	DeathCapArtefact = {
        icon = textures.pickup_artefact_mushroom,
		key = "death_cap",
		name = "artefact_death_cap_name",
		description = "artefact_death_cap_desc",
        spawn_weight = 1000,
    },
	
	ClockArtefact = {
        icon = textures.pickup_artefact_clock,
		key = "clock",
		name = "artefact_clock_name",
		description = "artefact_clock_desc",
        spawn_weight = 1000,
        -- requires_artefacts = {
		-- 	"ring_of_loyalty"
		-- }
        -- must_not_have_artefacts = {
		-- 	"ring_of_loyalty"
		-- }
    },

    WarBellArtefact = {
		icon = textures.pickup_artefact_warbell,
		key = "warbell",
		name = "artefact_warbell_name",
		description = "artefact_warbell_desc",
        spawn_weight = 1000,
        -- spawn_weight = 10000000000000,
	},
	
	-- Secondary Weapons

	SwordSecondaryWeapon = {
		sprite = textures.pickup_weapon_sword,
		icon = textures.pickup_weapon_sword_icon,
		hud_icon = textures.pickup_weapon_sword_hud,
		key = "sword",
		name = "weapon_sword_name",
		description = "weapon_sword_desc",
        spawn_weight = 1000,
        -- debug_spawn_weight = 1000000000,

		is_secondary_weapon = true,
		ammo = 16,
        ammo_gain_per_level = 3,
		ammo_needed_per_use = 1,
		low_ammo_threshold = 3,
        starting_ammo = 4,
		ammo_color = Color.white,

        cooldown = 8,
  
		holdable = false,
		rapid_fire = false,
	},
}


local function process_pickup_table(tab, subtype, base_name)
	local function process_inheritance(child)
		local parent = tab[child.inherit] or tab[base_name]
		if child ~= parent then
			for k, v in pairs(parent) do
				if k ~= "base" then
					if child[k] == nil then
						child[k] = v
					end
				end
			end
			process_inheritance(parent)
		end
	end
	
	for k, v in pairs(tab) do
        v.name = v.name or k
		if v.icon == nil and not k == base_name then
			error("no icon for " .. k)
		end
        v.icon = v.icon or textures.pickup_placeholder
		v.textures = v.textures or {v.icon, v.icon, v.icon}
        v.type = "pickup"
		v.subtype = subtype
	end
    for k, v in pairs(tab) do
        process_inheritance(v)
    end
	
	tab[base_name].base = true
	return tab

end

local tab = {
	upgrades = process_pickup_table(Upgrades, "upgrade", "BaseUpgrade"),
	powerups = process_pickup_table(Powerups, "powerup", "BasePowerup"),
	hearts = process_pickup_table(Hearts, "heart", "BaseHeart"),
    artefacts = process_pickup_table(Artefacts, "artefact", "BaseArtefact"),
}

return tab
