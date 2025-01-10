local TileMap = Object:extend("TileMap")

function TileMap:new(data)
    self.tiles = {}
	self:build_from_level_data(data)
end

function TileMap:get_all_tiles()
    local tiles = {}
    for z, layer in pairs(self.tiles) do
        for y, row in pairs(layer) do
            for x, tile in pairs(row) do
                table.insert(tiles, { x = x, y = y, z = z, tile = tile })
            end
        end
    end
    return tiles
end

function TileMap:iter()
    local z_iter, z_state, z_key = pairs(self.tiles) -- Initialize layer iterator
    local y_iter, y_state, y_key
    local x_iter, x_state, x_key
    local layer, row

    local function next_tile()
        -- If no row iterator exists, start a new layer
        if not y_iter then
            z_key, layer = z_iter(z_state, z_key)
            if not z_key then return nil end -- No more layers
            y_iter, y_state, y_key = pairs(layer)
        end

        -- If no tile iterator exists, start a new row
        if not x_iter then
            y_key, row = y_iter(y_state, y_key)
            if not y_key then
                -- If no more rows, reset and try next layer
                y_iter, y_state, y_key = nil, nil, nil
                return next_tile()
            end
            x_iter, x_state, x_key = pairs(row)
        end

        -- Iterate over tiles in the row
        local tile
		x_key, tile = x_iter(x_state, x_key)
        if not x_key then
            -- If no more tiles, reset and try next row
            x_iter, x_state, x_key = nil, nil, nil
            return next_tile()
        end

        return x_key, y_key, z_key, tile
    end

    return next_tile
end

function TileMap:build_from_level_data(level_data)
	self.tilesets = level_data.tilesets

	if type(level_data) ~= "table" then
		return
	end

    for z, layer in pairs(level_data.layers) do
        local tiles = layer.tiles
        if level_data.compressed then
			for id, runs in pairs(tiles) do 
                for i = 1, table.length(runs), 2 do
					local start = runs[i]
					for pos=0, runs[i+1] do
						self:process_tile_data(z, layer, start + pos, id)
					end
				end
			end
		else
			for k, v in pairs(tiles) do
				if type(k) == "number" then
					local id = k
					local tile = v
					self:process_tile_data(z, layer, id, tile)
				elseif type(k) == "string" then
					local tile = k
					for _, id in ipairs(v) do 
						self:process_tile_data(z, layer, id, tile)
					end
				end
			end
		end
	end
end

function TileMap:get_tile(x, y, z)

	if self.tiles[z] == nil then
		return nil
	end

	if self.tiles[z][y] == nil then
		return nil
	end

	return self.tiles[z][y][x] or nil
end

function TileMap:set_tile(x, y, z, tile_id)
    if self.tiles[z] == nil then
        if tile_id == nil then
            return
        end
        self.tiles[z] = {}
    end

    if self.tiles[z][y] == nil then
        if tile_id == nil then
            return
        end
        self.tiles[z][y] = {}
    end

    self.tiles[z][y][x] = tile_id

    if tile_id == nil then
        if table.is_empty(self.tiles[z][y]) then
            self.tiles[z][y] = nil
        end
        if table.is_empty(self.tiles[z]) then
            self.tiles[z] = nil
        end
    end
end

function TileMap:query_region(startx, starty, startz, endx, endy, endz)
    return table.query_region(self.tiles, startx, starty, startz, endx, endy, endz)
end

function TileMap:process_tile_data(z, layer, id, tile)
    local x, y = id_to_xy(id, layer.width)
    x = x + layer.offset.x - 1
    y = y + layer.offset.y - 1

	-- print(id, x, y, z, tile)

    if tilesets.object_tiles[tile] then
        self:set_tile(x, y, z, tile)
		return
    end
	
    local split = string.split(tile, "_")
    local tileset_id = tonumber(split[1])
    local tileset_tile_id = tonumber(split[2])

    local tileset_name = self.tilesets[tileset_id]

    tileset_id = tilesets.tileset_ids[tilesets[tileset_name]]

	local tile_string = tile
	
	if tileset_id ~= nil and tileset_tile_id ~= nil then
		tile_string = tostring(tileset_id) .. "_" .. tostring(tileset_tile_id)
	end

    self:set_tile(x, y, z, tile_string)
end

function TileMap:tile_from_string(tile_string)
	if tilesets.object_tiles[tile_string] then
		return tilesets.object_tiles[tile_string]
	end
    local split = string.split(tile_string, "_")
    local tileset_id = tonumber(split[1])
    local tileset_tile_id = tonumber(split[2])
    local tileset_name = self.tilesets[tileset_id]
    local tileset = tilesets[tileset_name]
	if tileset then
		return tileset:get_tile(tileset_tile_id)
	else
		return tile_string
	end
end

return TileMap
