local BasePickup = GameObject2D:extend("BasePickup")

function BasePickup:new(x, y)
    BasePickup.super.new(self, x, y)

	self.terrain_collision_radius = self.terrain_collision_radius or 2
    self.body_height = self.body_height or 0
    self.hurt_bubble_radius = self.hurt_bubble_radius or 5
	self.hit_bubble_radius = self.hit_bubble_radius or 3
    self.hit_bubble_damage = self.hit_bubble_damage or 1
	self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
	self:lazy_mixin(Mixins.Behavior.Pickupable)
    self:lazy_mixin(Mixins.Behavior.RandomOffsetPulse)

	self:add_signal("picked_up")
	self.random_offset = rng.randi(0, 255)
	self.random_offset_ratio = self.random_offset / 255

    self.z_index = 0
end


function BasePickup:draw()
    -- local r = wave(6, 8, 200, self.elapsed, self.random_offset / 255)
    -- graphics.ellipse("line", 0, 0, r, r * 0.5)
    self:body_translate()
    local palette, offset = self:get_palette_shared()
    graphics.drawp_centered(self:get_sprite(), palette, offset, 0, 0, 0, self.flip or 1, 1)
end

function BasePickup:on_pickup(player)
	self:emit_signal("picked_up")
    self:queue_destroy()
end

function BasePickup:get_sprite()
    return textures.pickup_base
end
return BasePickup
