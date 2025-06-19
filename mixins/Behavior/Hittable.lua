local Hittable = Object:extend("Hittable")

function Hittable:__mix_init()
	self.is_hittable = true
end

function Hittable:on_hit(by)
end

return Hittable
