local OffsetBasePickup = require ("obj.Spawn.Pickup.BasePickup"):extend("OffsetBasePickup")

function OffsetBasePickup:new(x, y)
    self.body_height = 4
    OffsetBasePickup.super.new(self, x, y)
end

function OffsetBasePickup:get_palette()
	return Palette.rainbow, self.random_offset + floor(self.tick / 3)
end

return OffsetBasePickup
