local CollisionRect = Object:extend("CollisionRect")

function CollisionRect:__mix_init()
	self.collision_rect = self.collision_rect or Rect(0, 0, 1, 1)
	self.collision_offset = self.collision_offset or Vec2(0, 0)
    self.collision_rect_update_functions = {}
	self.global_collision_rect = nil
end

function CollisionRect:get_collision_rect_offset()
	local offset_x, offset_y = self.collision_offset and self.collision_offset.x or 0, self.collision_offset and self.collision_offset.y or 0
	return -self.collision_rect.width / 2 + offset_x, -self.collision_rect.height / 2 + offset_y
end

function CollisionRect:update_collision_rect(x, y, width, height, offset_x, offset_y)
    self.collision_rect = Rect(x, y, width, height)
    self.collision_offset = Vec2(offset_x or 0, offset_y or 0)
	for _, v in ipairs(self.collision_rect_update_functions) do
		v()
	end
end

function CollisionRect:get_global_collision_rect()
	local x, y = self:get_collision_rect_offset()
	local width, height = self.collision_rect.width, self.collision_rect.height
	return self.pos.x + x, self.pos.y + y, width, height, self.pos.x + x + width, self.pos.y + y + height
end

return CollisionRect
