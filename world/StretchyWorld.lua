local MainGameWorld = World:extend("MainGameWorld")
local O = require("obj")

function MainGameWorld:new()
	MainGameWorld.super.new(self)
	self.draw_sort = self.y_sort
end

function MainGameWorld:enter()
	-- Camera & View
	-- self.camera_pitch       = 0.8 -- 1 = top-down, 0 = horizontal
	-- self.camera_height      = 0 -- extra vertical offset (0 = center when horizontal)
	-- self.view_bottom        = 1
	-- self.view_top           = 0
	-- self.perspective_amount = 1
	-- self.perspective_power  = 0.5

	-- Player
	local player            = self:add_object(O.Player.PlayerCharacter(0, 0))
	self:ref("player", player)
	-- self.camera:follow(self.player)  -- If needed

	-- Update once to get initial draw params
	-- self:update_draw_params()

	-- Room boundaries
	self.room = {
		top_left_x     = -80,
		top_left_y     = -60,
		top_right_x    = 80,
		top_right_y    = -60,
		bottom_right_x = 80,
		bottom_right_y = 60,
		bottom_left_x  = -80,
		bottom_left_y  = 60,
	}
end

function MainGameWorld:update(dt)
	-- Get input only once per update; don't recreate extra tables in a loop
	local input = self:get_input_table()

	-- if input.keyboard_held["w"] then
	-- 	self.camera_pitch = self.camera_pitch + 0.025 * dt
	-- end
	-- if input.keyboard_held["s"] then
	-- 	self.camera_pitch = self.camera_pitch - 0.025 * dt
	-- end

	-- -- Clamp pitch
	-- self.camera_pitch = clamp(self.camera_pitch, 0.0001, 1)

	-- dbg("pitch", self.camera_pitch)

	-- Constrain player to room boundaries
	self:constrain_player(dt)
end

local function update_closest(px, py, ax, ay, bx, by, dist_so_far, best_x, best_y)
    -- Find the closest point on line segment (ax,ay)->(bx,by) to (px,py).
    local lx, ly = closest_point_on_line_segment(px, py, ax, ay, bx, by)
    local dist   = vec2_distance(px, py, lx, ly)
    if dist < dist_so_far then
        return dist, lx, ly
    end
    -- Return old best if this line is not closer
    return dist_so_far, best_x, best_y
end

function MainGameWorld:constrain_player(dt)
    if not (self.room and self.player) then
        return
    end

    local px, py = self.player.pos.x, self.player.pos.y
    local closest_dist, closest_x, closest_y = 1e6, nil, nil

    -- If the player is outside left boundary
    if px < self.room.top_left_x then
        closest_dist, closest_x, closest_y =
            update_closest(px, py,
                           self.room.top_left_x,    self.room.top_left_y,
                           self.room.bottom_left_x, self.room.bottom_left_y,
                           closest_dist, closest_x, closest_y)
    end

    -- If the player is outside right boundary
    if px > self.room.bottom_right_x then
        closest_dist, closest_x, closest_y =
            update_closest(px, py,
                           self.room.bottom_right_x, self.room.bottom_right_y,
                           self.room.top_right_x,    self.room.top_right_y,
                           closest_dist, closest_x, closest_y)
    end

    -- If the player is outside top boundary
    if py < self.room.top_left_y then
        closest_dist, closest_x, closest_y =
            update_closest(px, py,
                           self.room.top_left_x,  self.room.top_left_y,
                           self.room.top_right_x, self.room.top_right_y,
                           closest_dist, closest_x, closest_y)
    end

    -- If the player is outside bottom boundary
    if py > self.room.bottom_left_y then
        closest_dist, closest_x, closest_y =
            update_closest(px, py,
                           self.room.bottom_left_x,  self.room.bottom_left_y,
                           self.room.bottom_right_x, self.room.bottom_right_y,
                           closest_dist, closest_x, closest_y)
    end

    -- If we updated closest_x/closest_y, push player back inside
	if closest_x then
		self.player.drag = 0
        local dx, dy = vec2_normalized(closest_x - px, closest_y - py)
        local speed  = (closest_dist * dt)^2 * 0.05
        self.player:apply_force(dx * speed * dt, dy * speed * dt)
    else
		self.player.drag = self.player.default_drag
	end
end

function MainGameWorld:get_camera_offset()
	local x, y = MainGameWorld.super.get_camera_offset(self)
	-- return x, y + self.camera_height
	return x, y
end


function MainGameWorld:update_draw_params()
	-- self.screen_center_x    = self.viewport_size.x * 0.5
	-- self.screen_center_y    = self.viewport_size.y * 0.5
	-- self.view_bottom        = self.viewport_size.y * (0.5 + self.camera_pitch * 0.5)
	-- self.view_bottom_cam    = self.view_bottom - self.screen_center_y
	-- self.view_top           = self.viewport_size.y * (0.5 - self.camera_pitch * 0.5)
	-- self.view_top_cam       = self.view_top - self.screen_center_y
	-- self.perspective_amount = 1 - pow(self.camera_pitch, self.perspective_power)
	-- self.camera_height      = (1 - self.camera_pitch) * 25
end

function MainGameWorld:draw_shared(...)
	-- self:update_draw_params()
	MainGameWorld.super.draw_shared(self, ...)
end

function MainGameWorld:draw()
	if debug.can_draw() then
		graphics.set_color(1, 1, 1, 0.5)
		-- graphics.line(0, self.view_bottom, self.viewport_size.x, self.view_bottom)
		-- graphics.line(0, self.view_top, self.viewport_size.x, self.view_top)
		-- graphics.line(self.screen_center_x, 0, self.screen_center_x, self.viewport_size.y)
		-- graphics.line(0, self.screen_center_y, self.viewport_size.x, self.screen_center_y)
	end

	graphics.set_color(1, 1, 1, 1)
	self:draw_room_bounds()

	MainGameWorld.super.draw(self)
end

function MainGameWorld:draw_room_bounds()
	local r = self.room
	local px, py = self.player.pos.x, self.player.pos.y

	-- Transformed corners
	local tlx, tly = self:get_draw_position(r.top_left_x, r.top_left_y)
	local trx, try = self:get_draw_position(r.top_right_x, r.top_right_y)
	local blx, bly = self:get_draw_position(r.bottom_left_x, r.bottom_left_y)
	local brx, bry = self:get_draw_position(r.bottom_right_x, r.bottom_right_y)

	-- Player draw position
	local pdx, pdy = self:get_draw_position(px, py)

	-- Right boundary
	if px > r.top_right_x then
		graphics.set_color(1, 1, 1, 0.5)
		graphics.line(trx, try, brx, bry)
		graphics.set_color(1, 1, 1, 1)
		if py > r.top_right_y then
			graphics.line(trx, try, pdx, pdy)
		end
		if py < r.bottom_right_y then
			graphics.line(brx, bry, pdx, pdy)
		end
	else
		graphics.set_color(1, 1, 1, 1)
		graphics.line(trx, try, brx, bry)
	end

	-- Left boundary
	if px < r.top_left_x then
		graphics.set_color(1, 1, 1, 0.5)
		graphics.line(tlx, tly, blx, bly)
		graphics.set_color(1, 1, 1, 1)
		if py > r.top_left_y then
			graphics.line(tlx, tly, pdx, pdy)
		end
		if py < r.bottom_left_y then
			graphics.line(blx, bly, pdx, pdy)
		end
	else
		graphics.set_color(1, 1, 1, 1)
		graphics.line(tlx, tly-1, blx, bly)
	end

	-- Top boundary
	if py < r.top_left_y then
		graphics.set_color(1, 1, 1, 0.5)
		graphics.line(tlx, tly, trx, try)
		graphics.set_color(1, 1, 1, 1)
		if px < r.top_right_x then
			graphics.line(trx, try, pdx, pdy)
		end
		if px > r.top_left_x then
			graphics.line(tlx, tly, pdx, pdy)
		end
	else
		graphics.set_color(1, 1, 1, 1)
		graphics.line(tlx-1, tly, trx, try)
	end

	-- Bottom boundary
	if py > r.bottom_left_y then
		graphics.set_color(1, 1, 1, 0.5)
		graphics.line(brx, bry, blx, bly)
		graphics.set_color(1, 1, 1, 1)
		if px > r.bottom_left_x then
			graphics.line(blx, bly, pdx, pdy)
		end
		if px < r.bottom_right_x then
			graphics.line(brx, bry, pdx, pdy)
		end
	else
		graphics.set_color(1, 1, 1, 1)
		graphics.line(brx, bry, blx, bly)
	end
end

-- function MainGameWorld:get_draw_position(x, y, z)
-- 	local camPos                = self.camera.pos
-- 	local scx, scy              = self.screen_center_x, self.screen_center_y
-- 	local top                   = self.view_top_cam
-- 	local bottom                = self.view_bottom_cam

-- 	local dx, dy, dz            = x - camPos.x, y - camPos.y, (z or 0) - camPos.z
-- 	local newy                  = dy * self.camera_pitch

-- 	-- "distance_from_horizon" factor
-- 	local distance_from_horizon = (newy - top) / (bottom - top)
-- 	local persp_amount          = self.perspective_amount * (1 - distance_from_horizon)

-- 	local newx                  = dx * (1 - persp_amount)
-- 	return newx + scx, newy + scy + dz
-- end

return MainGameWorld
