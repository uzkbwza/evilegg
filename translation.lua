local translations = {
    en = {
        room_has_max_points = "HI SCORE",
        room_is_bonus = "BONUS",
		room_is_hard = "HARD",
		
		notif_fire_rate = "FIRE RATE",
		notif_range = "RANGE",
		notif_bullets = "BULLETS",
		notif_bullet_speed = "BULLET SPEED",
		notif_damage = "DAMAGE",
        notif_boost = "BOOST",
		
        notif_heart = "HP",

		notif_upgrade_available = "UPGRADE AVAILABLE",
		notif_heart_available = "HEART AVAILABLE",
		notif_powerup_available = "POWERUP AVAILABLE",
		notif_item_available = "ARTEFACT AVAILABLE",

        bonus_hard_room = "HARD ROOM",
        bonus_no_damage = "NO DAMAGE",
        bonus_overheal = "OVERHEAL",
		bonus_rescue = "RESCUE",
        bonus_all_rescues = "HERO",
        bonus_quick_wave = "QUICK WAVE",
		-- bonus_mortar_rescue = "",
    },
}

local Translator = Object:extend("Translator")


function Translator:new()
    self:set_language("en")
	self.translations = translations
end

function Translator:set_language(language)
	self.current_language = language
end

function Translator:get_language()
    return self.current_language
end

function Translator:translate(key)
    if not (self.translations[self.current_language] and self.translations[self.current_language][key]) then
        if self.translations["en"][key] then
            return self.translations["en"][key]
        else
			if debug.enabled then
				error("missing translation: " .. key)
			end
			return key
        end
    end
    local text = self.translations[self.current_language][key]
    if debug.enabled and text == nil then
		error("missing translation: " .. key)
	end
    return text
end

local object = Translator()

tr = setmetatable({}, {
    __index = function(t, k)
        return object:translate(k)
    end,
    __call = function(t, k)
        return object:translate(k)
    end
})

return object
