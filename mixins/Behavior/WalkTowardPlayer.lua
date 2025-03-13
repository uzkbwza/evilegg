local WalkTowardPlayer = Object:extend("WalkTowardPlayer")

function WalkTowardPlayer:__mix_init(x, y)
    self.walk_speed = self.walk_speed or 0.05
	self:add_update_function(self.walk_toward_player_update)
end

function WalkTowardPlayer:walk_toward_player_update(dt)
    local closest

	if self.only_follow_rescues then
        closest = self:get_closest_rescue()
    elseif self.follow_rescues_first then
		closest = self:get_closest_rescue()
		if not closest then
			closest = self:get_closest_ally()
		end
	elseif self.follow_allies then
		closest = self:get_closest_ally()
	else
		closest = self:get_closest_player()
	end
    if closest then
        local bx, by = self:get_body_center()
		local cx, cy = closest:get_body_center()
		local dx, dy = cx - bx, cy - by
        local direction_x, direction_y = vec2_normalized(dx, dy)
		if self.walk_snap_angle then
			direction_x, direction_y = vec2_snap_angle(direction_x, direction_y, self.walk_snap_angle)
		end
		self:apply_force(direction_x * self.walk_speed, direction_y * self.walk_speed)
	end
end

return WalkTowardPlayer
