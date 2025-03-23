local ItemSpawn = require("obj.Spawn.Pickup.BasePickup"):extend("ItemSpawn")

function ItemSpawn:new(x, y)
    ItemSpawn.super.new(self, x, y)
    self.pickupable = false
	self:add_time_stuff()
end

return ItemSpawn

