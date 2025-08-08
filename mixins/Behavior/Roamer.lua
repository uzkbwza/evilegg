local Roamer = Object:extend("Roamer")

local ROAM_DIRECTIONS = {
	Vec2(1, 0),
	Vec2(-1, 0),
	Vec2(0, 1),
	Vec2(0, -1),
}

local ROAM_DIRECTIONS_DIAGONALS = {
	Vec2(1, 0),
	Vec2(-1, 0),
	Vec2(0, 1),
	Vec2(0, -1),
	Vec2(1, 1),
	Vec2(-1, 1),
	Vec2(1, -1),
	Vec2(-1, -1),
}

function Roamer:__mix_init()
	self.roam_chance = self.roam_chance or 2
	self.walk_timer = self.walk_timer or 10
    self.walk_speed = self.walk_speed or 0.8
    self.walk_toward_player_chance = self.walk_toward_player_chance or 0.0
    self.back_away_distance = self.back_away_distance or 32
    self:add_update_function(self.roamer_update)
    if self.back_away == nil then
        self.back_away = false
    end
    if self.roaming == nil then
        self.roaming = true
    end
	if self.roam_diagonals == nil then
		self.roam_diagonals = false
	end
	self.roam_direction = self.roam_direction or rng:choose((self.roam_diagonals and ROAM_DIRECTIONS_DIAGONALS or ROAM_DIRECTIONS)):clone()
end

function Roamer:roamer_update(dt)
	if not self.roaming then
		return
	end
    if self.is_new_tick then
        local player
        -- if self.follow_allies then
            -- player = self.get_closest_ally and self:get_closest_ally()
        -- else
        player = self.get_closest_player and self:get_closest_player()

        local back_away = false

        if player and self.back_away then
            local dist_squared = self.pos:distance_squared(player.pos)
            if dist_squared < self.back_away_distance * self.back_away_distance then
                back_away = true
            end
        end

		if back_away or (rng:percent(self.roam_chance) and not self:is_tick_timer_running("walk_timer")) then

            if self.follow_allies then
                player = self.get_closest_ally and self:get_closest_ally()
            else
                player = self.get_closest_player and self:get_closest_player()
            end

            self:start_tick_timer("walk_timer", self.walk_timer)


            local new_direction = rng:choose((self.roam_diagonals and ROAM_DIRECTIONS_DIAGONALS or ROAM_DIRECTIONS))
            self.roam_direction.x, self.roam_direction.y = new_direction.x, new_direction.y

            if player then
                local dx, dy = vec2_normalized(player.pos.x - self.pos.x, player.pos.y - self.pos.y)
               
                local use_new_roam_direction = false

                if back_away then
                    dx = dx * -1
                    dy = dy * -1
                    use_new_roam_direction = true
                end

                if not use_new_roam_direction and rng:percent(self.walk_toward_player_chance) then
                    use_new_roam_direction = true
                end

                if use_new_roam_direction then
                    if not self.roam_diagonals then
                        if abs(dx) > abs(dy) then
                            self.roam_direction.x = dx
                            self.roam_direction.y = 0
                        else
                            self.roam_direction.x = 0
                            self.roam_direction.y = dy
                        end
                    else
                        local angle = stepify(vec2_angle(dx, dy), tau / 8)
                        self.roam_direction.x, self.roam_direction.y = vec2_from_angle(angle)
                    end
                end
            end


		end
	end

	-- if self.get_any_player then
    --     if not self:get_any_player() then
    --         return
    --     end
    -- end
	
	local dx, dy = self.roam_direction.x, self.roam_direction.y
	local direction_x, direction_y = vec2_normalized(dx, dy)
    local padding = self.terrain_collision_radius or 0
	
	self:move(direction_x * self.walk_speed * dt, direction_y * self.walk_speed * dt)
	
	if self.pos.x <= self.world.room.left + padding or self.pos.x >= self.world.room.right - padding then
		self.roam_direction.x = -self.roam_direction.x
	end
	if self.pos.y <= self.world.room.top + padding then
		self.roam_direction.y = abs(self.roam_direction.y)
	end
	if self.pos.y >= self.world.room.bottom - padding then
		self.roam_direction.y = -abs(self.roam_direction.y)
	end
	if self.pos.x <= self.world.room.left + padding then
		self.roam_direction.x = abs(self.roam_direction.x)
	end
	if self.pos.x >= self.world.room.right - padding then
		self.roam_direction.x = -abs(self.roam_direction.x)
	end
end

function Roamer:new_roam_direction()
	local new_direction = rng:choose(ROAM_DIRECTIONS)
	self.roam_direction.x, self.roam_direction.y = new_direction.x, new_direction.y
end

return Roamer
