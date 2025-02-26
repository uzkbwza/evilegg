local PlayerFinder = Object:extend("PlayerFinder")

function PlayerFinder:get_closest_player()
	return self:get_closest_object_with_tag("player")
end

function PlayerFinder:get_any_player()
	return self:get_first_object_with_tag("player")
end

function PlayerFinder:ref_closest_player()
	local player = self:find_closest_player()
	if player then
		self:ref("closest_player", player)
	end
end

function PlayerFinder:get_player_direction()
	return vec2_direction_to(self.pos.x, self.pos.y, self.world.last_player_pos.x, self.world.last_player_pos.y)
end

function PlayerFinder:get_body_direction_to_player()
	local px, py = self:get_body_center()
	local bx, by = self.world.last_player_body_pos.x, self.world.last_player_body_pos.y
	return vec2_direction_to(px, py, bx, by)
end

return PlayerFinder
