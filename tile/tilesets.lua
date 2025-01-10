local Tileset = require "tile.tileset"
local tileset_data = require "tile.tileset_data"

local tilesets = {
    TILE_SIZE = tileset_data.TILE_SIZE,
}

function tilesets.add(name, tileset)
	assert(type(name) == "string", "tileset name must be a string")
    tilesets[name] = tileset
    tilesets[#tilesets + 1] = tileset
    tileset.name = name
    tilesets.num_tiles = tilesets.num_tiles or 0
	
	local c = 0
	tilesets.tileset_offsets[tilesets.num_tiles + 1] = tileset
	tilesets.num_tilesets = tilesets.num_tilesets or 0
	tilesets.num_tilesets = tilesets.num_tilesets + 1
	for i, tile in ipairs(tileset.tiles) do
		local id = tostring(tilesets.num_tilesets) .. "_" .. tostring(i)
		tilesets.tileset_tiles[id] = tile
        tilesets.tile_ids[i + tilesets.num_tiles] = id
		tilesets.tile_to_id[tile] = id
		c = c + 1
	end
	tilesets.tileset_names[tilesets.num_tilesets] = name
	tilesets.tileset_ids[tileset] = tilesets.num_tilesets
    tilesets.num_tiles = tilesets.num_tiles + c

end

function tilesets.load()
	tilesets.tileset_tiles = {}
	tilesets.tile_ids = {}
	tilesets.tileset_ids = {}
    tilesets.tileset_names = {}
    tilesets.tileset_offsets = {}
	tilesets.tile_to_id = {}
	
    for _, data in ipairs(tileset_data.TILESETS) do
        local name = data.name
        local t = Tileset(textures["tileset_" .. name], tilesets.TILE_SIZE, tilesets.TILE_SIZE, data)
        tilesets.add(name, t)
    end
	
	tilesets.object_tiles = tileset_data.OBJECT_TILES
end

function tilesets.get_all()
	local t = {}
    for i, v in ipairs(tilesets) do
        if Object.is(v, Tileset) then
			table.insert(t, {name = v.name, tileset = v})
        end
    end
	return t
end

return tilesets
