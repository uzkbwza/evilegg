local AllyFinder = Object:extend("AllyFinder")

function AllyFinder:get_players()
	return self.world:get_objects_with_tag("player")
end

function AllyFinder:get_allies()
	return self.world:get_objects_with_tag("ally")
end



function AllyFinder:get_closest_player()
    return self:get_closest_object_with_tag("player")
end

function AllyFinder:get_closest_ally()
    return self:get_closest_object_with_tag("ally")
end

function AllyFinder:get_closest_rescue()
    return self:get_closest_object_with_tag("rescue_object")
end

function AllyFinder:get_any_player()
    return self:get_first_object_with_tag("player")
end

function AllyFinder:get_any_ally()
    return self:get_first_object_with_tag("ally")
end

function AllyFinder:ref_closest_player()
    local player = self:find_closest_player()
    if player then
        self:ref("closest_player", player)
    end
end

function AllyFinder:ref_closest_ally()
    local ally = self:find_closest_ally()
    if ally then
        self:ref("closest_ally", ally)
    end
end

function AllyFinder:get_player_direction()
    local px, py = self:closest_last_player_pos()

    return vec2_direction_to(self.pos.x, self.pos.y, px, py)
end

function AllyFinder:closest_ally_pos()
	local closest_ally = self:get_closest_ally()
    if closest_ally then
        return closest_ally.pos.x, closest_ally.pos.y
    end
	
	return self:closest_last_player_pos()
end

function AllyFinder:closest_ally_body_pos()
	local closest_ally = self:get_closest_ally()
    if closest_ally then
        return closest_ally:get_body_center()
    end
	return self:closest_last_player_body_pos()
end

function AllyFinder:get_ally_direction()
    local px, py = self:closest_last_ally_pos()

    return vec2_direction_to(self.pos.x, self.pos.y, px, py)
end

function AllyFinder:get_random_player()
    local player = self.world:get_random_object_with_tag("player")
    return player
end

function AllyFinder:get_random_ally()
	return self.world:get_random_object_with_tag("ally")
end

function AllyFinder:random_last_player_pos()
	return rng:choose(table.values(self.world.last_player_positions))
end

function AllyFinder:random_last_ally_pos()
    local random_ally = self:get_random_ally()
    if random_ally then
        return random_ally.pos
    end
    return self:random_last_player_pos()
end

function AllyFinder:random_last_ally_body_pos()
	local random_ally = self:get_random_ally()
    if random_ally then
        return random_ally:get_body_center()
    end
    return self:random_last_player_body_pos()
end

function AllyFinder:random_last_player_body_pos()
	local pos = rng:choose(table.values(self.world.last_player_body_positions))
	return pos.x, pos.y
end

function AllyFinder:closest_last_player_pos()
	local x, y = self.pos.x, self.pos.y
    local closest_player_pos = nil
    local closest_distance = math.huge

    for _, player_pos in pairs(self.world.last_player_positions) do
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

function AllyFinder:closest_last_player_body_pos()
    local x, y = self.pos.x, self.pos.y
    if self.get_body_center then
		x, y = self:get_body_center()
	end
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

function AllyFinder:get_body_direction_to_player()
    local px, py = self:get_body_center()
    local bx, by = self:closest_last_player_body_pos()
    if bx == nil then
        bx, by = 0, 0
    end
    return vec2_direction_to(px, py, bx, by)
end

function AllyFinder:get_body_distance_to_player()
    local px, py = self:get_body_center()
    local bx, by = self:closest_last_player_body_pos()
    if bx == nil then
        bx, by = 0, 0
    end
    return vec2_distance(px, py, bx, by)
end

function AllyFinder:get_body_direction_to_ally()
	local px, py = self:get_body_center()
    local bx, by = self:closest_ally_body_pos()
    if bx == nil then
		bx, by = 0, 0
	end
	return vec2_direction_to(px, py, bx, by)
end

return AllyFinder
