local Roamer = Object:extend("Roamer")

local ROAM_DIRECTIONS = {
	Vec2(1, 0),
	Vec2(-1, 0),
	Vec2(0, 1),
	Vec2(0, -1),
}

function Roamer:__mix_init()
	self.roam_direction = self.roam_direction or rng.choose(ROAM_DIRECTIONS):clone()
	self.roam_chance = self.roam_chance or 2
    self.walk_speed = self.walk_speed or 0.8
	self.walk_timer = self.walk_timer or 10
	self.walk_toward_player_chance = self.walk_toward_player_chance or 0.0
	self:add_update_function(self.roamer_update)
end

function Roamer:roamer_update(dt)
	if self.is_new_tick then
		if rng.percent(self.roam_chance) and not self:is_tick_timer_running("walk_timer") then
            self:start_tick_timer("walk_timer", self.walk_timer)
			local player = self.get_closest_player and self:get_closest_player()
			if player and rng.percent(self.walk_toward_player_chance) then
				local dx, dy = vec2_normalized(player.pos.x - self.pos.x, player.pos.y - self.pos.y)
				if abs(dx) > abs(dy) then
					self.roam_direction.x = dx
					self.roam_direction.y = 0
				else
					self.roam_direction.x = 0
					self.roam_direction.y = dy
				end
			else
				local new_direction = rng.choose(ROAM_DIRECTIONS)
				self.roam_direction.x, self.roam_direction.y = new_direction.x, new_direction.y
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
	local new_direction = rng.choose(ROAM_DIRECTIONS)
	self.roam_direction.x, self.roam_direction.y = new_direction.x, new_direction.y
end

return Roamer
