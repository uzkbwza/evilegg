local SmoothCameraTarget = GameObject:extend("SmoothCameraTarget")

function SmoothCameraTarget:new(follow, splerp_half_life_seconds, target_function)
	local x, y = follow and follow.pos.x or 0, follow and follow.pos.y or 0
	SmoothCameraTarget.super.new(self, x, y)
	assert(follow == nil or type(follow) == "table", "follow must be a table or nil")
	self.following = follow
	self.smooth = seconds_to_frames(splerp_half_life_seconds or 10)

	self.target_function = target_function or function(obj) return obj.pos end
end

function SmoothCameraTarget:update(dt)
	local target_pos = self.target_function(self.following)
	self:move_to(splerp_vec_unpacked(self.pos.x, self.pos.y, target_pos.x, target_pos.y, dt, self.smooth))
end

function SmoothCameraTarget:draw()
	-- graphics.rectangle("fill", -self.collision_rect.width/2, -self.collision_rect.height/2, self.collision_rect.width, self.collision_rect.height)
	if debug.can_draw() then
		graphics.set_color(1, 0, 1, 1)
		graphics.circle("line", 0, 0, 4)
	end
end

return SmoothCameraTarget
