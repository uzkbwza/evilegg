local Tile = require "tile.tile"

local Tileset = Object:extend("Tileset")

function Tileset:new(texture, tile_width, tile_height, tile_data)
    self.texture = texture
    self.tile_width = tile_width
    self.tile_height = tile_height

    local tex_width, tex_height = texture:getPixelDimensions()

    self.tile_count_x = floor(tex_width / tile_width)
	self.tile_count_y = floor(tex_height / tile_height)

	self.tiles = {}


    for y = 1, self.tile_count_y do
        for x = 1, self.tile_count_x do
            local quad = graphics.new_quad((x - 1) * tile_width, (y - 1) * tile_height, tile_width, tile_height, tex_width, tex_height)
			local id = self:xy_to_id(x, y)
			local tile = Tile(self, id, quad, texture)
			self.tiles[id] = tile
        end
    end
	
	if tile_data and tile_data.data then
		local data_table = {}
        local add_data_to_tile = function(data_id, key, value)
			
			data_table[data_id] = data_table[data_id] or {}
            data_table[data_id][key] = value
			
		end
        for key, list in pairs(tile_data.data) do
            for value, ids in pairs(list) do
                if type(ids) == "number" then
                    add_data_to_tile(ids, key, true)
				else
					for _, id in ipairs(ids) do
						add_data_to_tile(id, key, value)
					end
				end
            end
        end
        for id, data in pairs(data_table) do
			self:set_tile_data(data, id)
		end
	end

	self.tile_count = #self.tiles
end

function Tileset:xy_to_id(x, y)
    return (y - 1) * self.tile_count_x + x
end

function Tileset:id_to_xy(id)
	local x = id % self.tile_count_x
	local y = floor(id / self.tile_count_x)
	return x, y
end

function Tileset:set_tile_data(data, x, y)
	local id = y and self:xy_to_id(x, y) or x
	local tile = self.tiles[id]
    -- assert(self.tiles[id] ~= nil, "tile doesn't exist")
	if tile == nil then return end
	tile.data = data
end

function Tileset:get_tile(x, y)
	if y == nil then return self.tiles[x] end 
	return self.tiles[self:xy_to_id(x, y)]
end

return Tileset
