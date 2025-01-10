local GridTerrainQuery = Object:extend("GridTerrainQuery")

function GridTerrainQuery:get_cell(x, y, z)
    return self.world.map.world_to_cell(x or self.pos.x, y or self.pos.y, z or 0)
end

function GridTerrainQuery:cell_to_world(x, y, z)
	return self.world.map.cell_to_world(x, y, z)
end

function GridTerrainQuery:get_tile_relative(x, y, z)
	local cx, cy, cz = self:get_cell()
    return self.world.map:get_tile(cx + x, cy + y, cz + z)
end

function GridTerrainQuery:get_tile(x, y, z)
    return self.world.map:get_tile(x, y, z)
end

function GridTerrainQuery:get_bump_tile_relative(x, y, z)
	local cx, cy, cz = self:get_cell()
    return self.world.map:get_bump_tile(cx + x, cy + y, cz + z)
end

function GridTerrainQuery:get_bump_tile(x, y, z)
    return self.world.map:get_bump_tile(x, y, z)
end

function GridTerrainQuery:is_cell_solid(x, y, z)
	local bump_tile = self:get_bump_tile(x, y, z)
	return bump_tile and bump_tile.solid
end

function GridTerrainQuery:get_enemies_at_cell(x, y)
    local objects = self.world:get_enemies_at_cell(x, y)
	table.erase(objects, self)
    return objects
end

function GridTerrainQuery:any_object_at_cell(x, y)
    return self.world:any_object_at_cell(x, y)
end

return GridTerrainQuery
