local LastEnemyTarget = Effect:extend("LastEnemyTarget")

function LastEnemyTarget:new(x, y, target)
    LastEnemyTarget.super.new(self, x, y)
    self:ref("target", target)
    self.z_index = 3
    self.duration = 0
end

function LastEnemyTarget:enter()
	self:add_tag("last_enemy_target")
end

function LastEnemyTarget:update(dt)
	if self.target == nil then
		self:queue_destroy()
		return
	end
	self:move_to(splerp_vec(self.pos.x, self.pos.y, self.target.pos.x, self.target.pos.y, 40, dt))
end

local ZOOM_TIME = 30
local ZOOM_AMOUNT = 30

function LastEnemyTarget:draw(elapsed, tick, t)

	if not self.target then return end
    for i = 1, 8 do
        local dir_x, dir_y
        if i == 1 then
            dir_x = 1
            dir_y = 1
        elseif i == 2 then
            dir_x = -1
            dir_y = 1
        elseif i == 3 then
            dir_x = 1
            dir_y = -1
        elseif i == 4 then
            dir_x = -1
            dir_y = -1
		elseif i == 5 then
			dir_x = 0
			dir_y = 1
		elseif i == 6 then
			dir_x = 0
            dir_y = -1
		elseif i == 7 then
			dir_x = 1
			dir_y = 0
		elseif i == 8 then
			dir_x = -1
			dir_y = 0
        end
		local dist_x = dir_x * (self.target.hurt_bubble_radius + 2)
        local dist_y = dir_y * (self.target.hurt_bubble_radius + 2)
        dist_x = dist_x * (1 + (sin01(self.elapsed / 10)) * 0.25)
        dist_y = dist_y * (1 + (sin01(self.elapsed / 10)) * 0.25)
        local extra_dist_t = max((ZOOM_TIME - self.elapsed) / ZOOM_TIME, 0)
		local extra_dist = extra_dist_t * ZOOM_AMOUNT
		dist_x = dist_x + extra_dist * dir_x
		dist_y = dist_y + extra_dist * dir_y
        local bx, by = self.target:get_body_center_local()
        local texture = textures.fx_last_enemy_target_corner
        if i >= 5 then
            texture = textures.fx_last_enemy_target_line
        end
		if self.elapsed > ZOOM_TIME and idivmod_eq_zero(tick, 5, 2) then
			return
		end


		local r = 0

        if dir_x == 0 then
			dist_y = dist_y * 1.25
            dir_x = 1
			r = tau / 4
        else
			dir_x = -dir_x
		end
        if dir_y == 0 then
			dist_x = dist_x * 1.25
			dir_y = 1
		else
			dir_y = -dir_y
		end
	
		graphics.draw_centered(texture, bx + dist_x, by + dist_y, r, dir_x, dir_y)
	end
end

return LastEnemyTarget
