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
		bullet_powerup_time = 10,

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
	},
}

local Items = {
	BaseItem = {
		icon = textures.pickup_item_placeholder,
		textures = {
			textures.pickup_item_placeholder,
			textures.pickup_item_placeholder,
			textures.pickup_item_placeholder,
		},
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
        v.name = k
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
	items = process_pickup_table(Items, "item", "BaseItem"),
}

return tab
