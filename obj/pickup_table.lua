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
		upgrade_type = "range",
		notification_text = "notif_range",
		notification_palette = "notif_range_up",
		name = "upgrade_name_range",
		description = "upgrade_desc_range",
    },
	
	NumBulletsUpgrade = {
		icon = textures.pickup_upgrade_num_bullets_icon,
		upgrade_type = "bullets",
		notification_text = "notif_bullets",
		notification_palette = "notif_bullets_up",
		name = "upgrade_name_bullets",
		description = "upgrade_desc_bullets",
	},

	BulletSpeedUpgrade = {
		icon = textures.pickup_upgrade_bullet_speed_icon,
		upgrade_type = "bullet_speed",
		notification_text = "notif_bullet_speed",
		notification_palette = "notif_bullet_speed_up",
		name = "upgrade_name_bullet_speed",
		description = "upgrade_desc_bullet_speed",
	},

	DamageUpgrade = {
		icon = textures.pickup_upgrade_damage_icon,
		upgrade_type = "damage",
		notification_text = "notif_damage",
		notification_palette = "notif_damage_up",
		name = "upgrade_name_damage",
		description = "upgrade_desc_damage",
	},

}

local Powerups = {
	BasePowerup = {
		icon = textures.pickup_powerup_placeholder,
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
	
	AmmoPowerup = {
		icon = textures.pickup_powerup_ammo1,
        spawn_weight = 1000,
		textures = {
			-- textures.pickup_base,
			textures.pickup_powerup_ammo1,
			textures.pickup_powerup_ammo2,
			-- textures.pickup_powerup_rocket3,
        },
        bullet_powerup = false,
		name = "powerup_ammo_name",
        description = "powerup_ammo_desc",
		no_spawn = true,
		gained_function = function(game_state)
			if game_state.secondary_weapon then
				game_state:gain_secondary_weapon_ammo(game_state.secondary_weapon.ammo_powerup_gain)
			end
		end
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
        
		can_spawn = function()
            if not game_state then return true end
            if game_state.egg_rooms_cleared > 0 then return false end
			return game_state.num_spawned_artefacts >= 1
		end,

        spawn_weight = function()
			if not game_state then return 1000 end
			if game_state.num_spawned_artefacts ~= 1 then return 1000 end
            return 100000000000000000
        end,

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
		can_spawn = function()
			if not game_state then return true end
			return game_state.num_spawned_artefacts >= 2
		end,

        spawn_weight = function()
			if not game_state then return 1000 end
			if (game_state.num_spawned_artefacts ~= 2) or (not game_state.artefacts.sacrificial_twin) then return 1000 end
            return 100000000000000000
        end,
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
	
    TransmitterArtefact = {
		icon = textures.pickup_artefact_transmitter,
		key = "transmitter",
		name = "artefact_transmitter_name",
		description = "artefact_transmitter_desc",
		spawn_weight = 1000,
		-- debug_spawn_weight = 10000000000000,
		requires_secondary_weapon = true
	},

    PrayerKnotArtefact = {
        icon = textures.pickup_artefact_prayer_knot,
		key = "prayer_knot",
		name = "artefact_prayer_knot_name",
		description = "artefact_prayer_knot_desc",
        spawn_weight = 1000,
        aim_prompt = true,
        -- debug_spawn_weight = 1000000000,
    },

	UselessArtefact = {
		icon = textures.pickup_artefact_gemstone,
		key = "useless",
		name = "artefact_useless_name",
		description = "artefact_useless_desc",
		spawn_weight = 1000,
		spawn_only_when_full = true,
		no_pickup = true,
		infinite_spawns = true,
		repeats_allowed = true,
        destroy_score = 750,
		-- destroy_xp = 600,
		destroy_xp = 450,
    },

    HeartTradeArtefact = {
		icon = textures.pickup_artefact_heart_trade,
		key = "heart_trade",
		name = "artefact_heart_trade_name",
		description = "artefact_heart_trade_desc",
        spawn_weight = 500,
        -- can_spawn = function()
        --     return rng:percent(50)
        -- end,
        infinite_spawns = true,
        destroy_score = 250,
        -- spawn_when_full = true,
        spawn_only_when_full = true,
        destroy_xp = 0,

        on_chosen = function(game_state)
            if table.is_empty(game_state.artefacts) then return end
            local keys = table.keys(game_state.artefacts)
            if #keys == 1 and keys[1] == "sacrificial_twin" then return end

            if game_state.artefacts.stone_trinket and rng:percent(85) then
                game_state.heart_trade_artefact = game_state.artefacts.stone_trinket
                return
            end

            local random_key = rng:choose(keys)
            while random_key == "sacrificial_twin" do
                random_key = rng:choose(keys)
            end
            local artefact = game_state.artefacts[random_key]
            game_state.heart_trade_artefact = artefact
        end,

        can_spawn = function(game_state)
            if (not game_state.cheat) and game_state.num_spawned_artefacts <= 5 then return false end
            if table.is_empty(game_state.artefacts) then return false end
            local keys = table.keys(game_state.artefacts)
            if #keys == 1 and keys[1] == "sacrificial_twin" then return false end
            return true
        end,
        alternative_gain_function = function(game_state)
            local artefact = game_state.heart_trade_artefact
            if not artefact then
                if table.is_empty(game_state.artefacts) then return end
                local keys = table.keys(game_state.artefacts)
                if #keys == 1 and keys[1] == "sacrificial_twin" then return end

                local random_key = rng:choose(keys)
                while random_key == "sacrificial_twin" do
                    random_key = rng:choose(keys)
                end
                artefact = game_state.artefacts[random_key]
            end
            if not artefact then return end
            game_state:set_selected_artefact_slot(artefact.slot)
            game_state:remove_artefact(artefact.slot)
            game_state:gain_heart()
            
            if game_state:is_fully_upgraded() then
                game_state:level_bonus("overflow")
				signal.emit(game_state, "player_overflowed")
            else
                local upgrade = game_state:get_random_available_upgrade(false)
                if upgrade then
                    game_state:upgrade(upgrade)
                end
            end
            global_game:get_main_screen():play_sfx("pickup_heart", 0.75)
            global_game:get_main_screen():play_sfx("ally_rescue_holding_pickup_saved", 0.87)
            -- global_game:get_main_screen():play_sfx("pickup_surgeon", 0.75)
        end,
        -- debug_spawn_weight = 100000000000000000,
    },

    BlastArmorArtefact = {
        icon = textures.pickup_artefact_blast_armor,
		key = "blast_armor",
		name = "artefact_blast_armor_name",
		description = "artefact_blast_armor_desc",
        spawn_weight = 1000,
        explode_on_destroy = true,
    },

    -- BulletSpeedStackArtefact = {
    --     icon = textures.pickup_artefact_bullet_speed_stack,
	-- 	key = "bullet_speed_stack",
	-- 	name = "artefact_bullet_speed_stack_name",
	-- 	description = "artefact_bullet_speed_stack_desc",
    --     spawn_weight = 1000,
    -- },
    
	
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
        starting_ammo = 3,
		ammo_powerup_gain = 2,
		ammo_color = Color.magenta,

		show_individual_ammo = false,

        cooldown = 8,
  
		holdable = false,
		rapid_fire = false,
	}, 

	BigLaserSecondaryWeapon = {
		sprite = textures.pickup_weapon_big_laser,
		icon = textures.pickup_weapon_big_laser_icon,
		hud_icon = textures.pickup_weapon_big_laser_hud,
		key = "big_laser",
		name = "weapon_big_laser_name",
		description = "weapon_big_laser_desc",
        spawn_weight = 1000,

		is_secondary_weapon = true,
		ammo = 750,
		ammo_gain_per_level = 75,
        ammo_needed_per_use = 150,
        minimum_ammo_needed_to_use = 150,
		held_ammo_consumption_rate = 1.5,
		low_ammo_threshold = 299,
		starting_ammo = 100,
		ammo_powerup_gain = 50,
		ammo_color = Color.cyan,

        cooldown = 0,
		show_individual_ammo = false,
		
		holdable = true,
		rapid_fire = false,

		-- divide_ammo_to_one = true,
		
		-- reduce_ammo_counts = true,
    },
	
	RailGunSecondaryWeapon = {
		sprite = textures.pickup_weapon_railgun,
		icon = textures.pickup_weapon_railgun_icon,
		hud_icon = textures.pickup_weapon_railgun_hud,
		key = "railgun",
		name = "weapon_railgun_name",
        description = "weapon_railgun_desc",
		spawn_weight = 1000,
		fire_rate_upgrade_cooldown_reduction = 10,
        is_secondary_weapon = true,
		
		ammo = 64,
		ammo_gain_per_level = 12,
        ammo_needed_per_use = 8,
		ammo_powerup_gain = 4,
		
		low_ammo_threshold = 23,
		starting_ammo = 8,
		ammo_color = Color.red,
		
		show_individual_ammo = false,
		
        cooldown = 50,
		is_railgun = true,
	},

    HatchedTwinArtefact = {
        icon = textures.pickup_artefact_hatched_twin,
		key = "hatched_twin",
        can_spawn = false,
        spawn_weight = 1000,
        codex_hidden = true,
        no_codex = true,
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

	local ammo_keytab = { "ammo", "ammo_gain_per_level", "ammo_needed_per_use", "low_ammo_threshold", "starting_ammo", "minimum_ammo_needed_to_use", "held_ammo_consumption_rate", "ammo_powerup_gain" }
	
    for k, v in pairs(tab) do
        v.name = v.name or k
        if v.icon == nil and not k == base_name then
            error("no icon for " .. k)
        end
        v.icon = v.icon or textures.pickup_placeholder
        v.textures = v.textures or { v.icon, v.icon, v.icon }
        v.type = "pickup"
        v.subtype = subtype

        if subtype == "artefact" and v.is_secondary_weapon then

            -- if v.reduce_ammo_counts then
            --     local values = {}
            --     for i, key in ipairs(ammo_keytab) do
            --         if v[key] then
            --             values[i] = v[key]
            --         end
            --     end

            --     local greatest_common_divisor = gcd(table.fast_unpack(values))

            --     for i, key in ipairs(ammo_keytab) do
            --         if v[key] then
            --             v[key] = v[key] / greatest_common_divisor
            --         end
            --     end
            -- end


            -- if v.divide_ammo_to_one then
			-- if v.ammo_needed_per_use > 1 then
			local num_ammo = v.ammo_needed_per_use
			for i, key in ipairs(ammo_keytab) do
				if v[key] then
					v[key .. "_normalized"] = v[key] / num_ammo
				end
			end
			-- end
			-- end
        end
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
