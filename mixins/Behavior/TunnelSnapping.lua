local TunnelSnapping = Object:extend("TunnelSnapping")

function TunnelSnapping:__mix_init()

	local old_move_to = self.move_to
    self.move_to = function(self, x, y, filter, noclip)

		local startx, starty = self.pos.x, self.pos.y
        old_move_to(self, x, y, filter, noclip)
		if noclip then
			return
		end

		local west_tile = self:get_bump_tile_relative(-1, 0, 0)
		local east_tile = self:get_bump_tile_relative(1, 0, 0)
		local north_tile = self:get_bump_tile_relative(0, -1, 0)
		local south_tile = self:get_bump_tile_relative(0, 1, 0)

		local cx, cy, cz = self:get_cell()
		local wx, wy = self:cell_to_world(cx, cy, cz)

		self.snapped_west = false
		self.snapped_east = false
		self.snapped_north = false
        self.snapped_south = false

		if west_tile and west_tile.solid and self.pos.x < wx and x <= startx then
            self:tp_to(wx, self.pos.y)
			self.snapped_west = true
		end
	
		if east_tile and east_tile.solid and self.pos.x > wx and x >= startx then
			self:tp_to(wx, self.pos.y)
			self.snapped_east = true
		end
	
		if north_tile and north_tile.solid and self.pos.y < wy + 1 and y <= starty then
			self:tp_to(self.pos.x, wy)
			self.snapped_north = true
		end
	
		if south_tile and south_tile.solid and self.pos.y > wy  and y >= starty then
			self:tp_to(self.pos.x, wy)
			self.snapped_south = true
		end

	end
end

return TunnelSnapping
