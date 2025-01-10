local Warning = GameObject:extend("Warning")
local enemy_sensor_config = {
	collision_rect = Rect.centered(0, 0, 16, 16),
	entered_function = function(self, other)
		if other.is_skullbird then
		self:queue_destroy()
		end
	end,
	bump_mask = to_layer_bit(PHYSICS_ENEMY, PHYSICS_PLAYER)
}
function Warning:new(x, y)
	Warning.super.new(self, x, y)
	self:add_elapsed_ticks()
    self:implement(Mixins.Behavior.BumpCollision)
	self:add_bump_sensor(enemy_sensor_config)
	self.z_index = -1
	self.collision_rect = Rect.centered(0, 0, 16, 16)
	self.texture = textures.enemy_warning
end

function Warning:draw()
	if floor(self.tick / 2) % 3 == 0 then
		graphics.draw_centered(self.texture, 0, 0, 0, self.pos.x < self.world.middle.x and 1 or -1, 1)
	end
end

return Warning
