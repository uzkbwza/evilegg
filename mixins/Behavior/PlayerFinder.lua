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
	local px, py = self:closest_last_player_pos()

	return vec2_direction_to(self.pos.x, self.pos.y, px, py)
end


function PlayerFinder:closest_last_player_body_pos()
	local x, y = self.pos.x, self.pos.y
    local closest_player_pos = nil
    local closest_distance = math.huge

    for _, player_pos in pairs(self.world.last_player_body_positions) do
        local distance = vec2_distance_squared(x, y, player_pos.x, player_pos.y)
        if distance < closest_distance then
            closest_distance = distance
            closest_player_pos = player_pos
        end
    end

	if closest_player_pos then
		return closest_player_pos.x, closest_player_pos.y
	end

    return 0, 0
end

function PlayerFinder:get_body_direction_to_player()
	local px, py = self:get_body_center()
    local bx, by = self:closest_last_player_body_pos()
    if bx == nil then
		bx, by = 0, 0
	end
	return vec2_direction_to(px, py, bx, by)
end

return PlayerFinder
