local WalkTowardPlayer = Object:extend("WalkTowardPlayer")

function WalkTowardPlayer:__mix_init(x, y)
    self.walk_speed = self.walk_speed or 0.05
	self:add_update_function(self.walk_toward_player_update)
end

function WalkTowardPlayer:walk_toward_player_update(dt)
	local player = self:get_closest_player()
	if player then
		local dx, dy = player.pos.x - self.pos.x, player.pos.y - self.pos.y
        local direction_x, direction_y = vec2_normalized(dx, dy)
		if self.walk_snap_angle then
			direction_x, direction_y = vec2_snap_angle(direction_x, direction_y, self.walk_snap_angle)
		end
		self:apply_force(direction_x * self.walk_speed, direction_y * self.walk_speed)
	end
end

return WalkTowardPlayer
