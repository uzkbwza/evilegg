local Pickupable = Object:extend("Pickupable")

function Pickupable:__mix_init()
	self.pickup_radius = self.pickup_radius or 3
    self:add_enter_function(Pickupable.pickupable_enter)
end

function Pickupable:pickupable_enter()
    self.world:add_to_spatial_grid(self, "pickup_objects", self.get_pickup_rect)
end

function Pickupable:get_pickup_rect()
	local bx, by = self:get_body_center_local()
    return bx - self.pickup_radius, by - self.pickup_radius, self.pickup_radius * 2, self.pickup_radius * 2
end

function Pickupable:on_pickup(player)
	self:die()
end

function Pickupable:die()
	self:queue_destroy()
end

return Pickupable
