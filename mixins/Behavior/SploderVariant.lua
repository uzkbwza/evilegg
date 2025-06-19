local SploderVariant = Object:extend("SploderVariant")

local DEFAULT_PARAMS = {
	max_hp = 2,
	bullet_push_modifier = 3.5,
	walk_speed = 0.5,
}

function SploderVariant:__mix_init(params)
	self.params = params or DEFAULT_PARAMS
end

