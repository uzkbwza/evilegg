local GridMovement = Object:extend("GridMovement")

function GridMovement:move_toward_cell(x, y, speed, immediate, noclip)
    speed = speed or 60
	if self.moving then return end
	local current_cell_x, current_cell_y = self:get_cell()
    local move_direction = Vec2(x - current_cell_x and sign(x - current_cell_x) or 0, y - current_cell_y and sign(y - current_cell_y) or 0)
    local next_cell = Vec2(current_cell_x + move_direction.x, current_cell_y + move_direction.y)
	if not noclip and self:is_cell_solid(next_cell.x, next_cell.y, 0) then
		next_cell = Vec2(current_cell_x, current_cell_y)
	end
	local wx, wy = self.world.map.cell_to_world(next_cell.x, next_cell.y, 0)
	local startx, starty = self.pos.x, self.pos.y
    local s = self.sequencer
    s:start(function()
        self.at_cell = false
        self.moving = true
		self.pos = Vec2(startx, starty)
		if not immediate then
			s:tween(function(t)
				local x = lerp(startx, wx, t)
				local y = lerp(starty, wy, t)
				self:tp_to(x, y)
				end, 0, 1, speed, "linear")
			end
        self:move_to(wx, wy)
		-- s:wait(speed)
		self.at_cell = true
		self.moving = false
	end)
end

return GridMovement
