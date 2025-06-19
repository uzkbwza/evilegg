local TileMap = require "tile.tilemap"

---@class GameMap
local GameMap = Object:extend("GameMap")

---@param map_name string
---@return GameMap
function GameMap.load(map_name)
    local success, errmsg = unrequire("map.maps." .. map_name .. ".tiles")
    if not success then
        error(errmsg)
    end
	
    success, errmsg = unrequire("map.maps." .. map_name .. ".data")
    if not success then
        error(errmsg)
    end
	
	local map_tiles = require("map.maps." .. map_name .. ".tiles")

    local _, map_data = pcall(function() return require("map.maps." .. map_name .. ".data") end)

    return GameMap {
        tiles = map_tiles,
        data = map_data or nil
    }
end

function GameMap:new(map)
    self.tile_map = TileMap(map.tiles)
	self.data = map.data

    self.static_batches = nil
	self.dynamic_batches = nil
    self.objects = nil
    self.collision_objects = nil
	self.tile_info = nil
		
	self.min_layer = math.huge
	self.max_layer = -math.huge
	
    self.min_x = math.huge
    self.max_x = -math.huge
    self.min_y = math.huge
    self.max_y = -math.huge
end

function GameMap:get_bounds()
	return self.min_x, self.min_y, self.max_x, self.max_y, self.min_layer, self.max_layer
end

function GameMap:get_tile_from_world_space(x, y, z)
	z = z or 0
    return self:get_tile(self.world_to_cell(x, y, z))
end

function GameMap:get_tile(x, y, z)
    z = z or 0
    return self.tile_info[self.tile_map:get_tile(x, y, z)]
end

function GameMap:set_tile(x, y, z, tile_id)
    z = z or 0
    self.tile_map:set_tile(x, y, z, tile_id)
end

function GameMap:get_bump_tile_from_world_space(x, y, z)
    z = z or 0
    return self:get_bump_tile(self.world_to_cell(x, y, z))
end

function GameMap:get_bump_tile(x, y, z)
    z = z or 0
	
    if not self.collision_objects[z] then return end
	if not self.collision_objects[z][y] then return end
	
	local tile = self.collision_objects[z][y][x]
	if tile then
		return tile
	end
end

function GameMap:query_tiles(startx, starty, endx, endy, startz, endz)
    startx = startx or self.min_x
    endx = endx or self.max_x
    starty = starty or self.min_y
    endy = endy or self.max_y
    startz = startz or self.min_layer
    endz = endz or self.max_layer
    return table.query_region(self.tile_objects, startx, starty, startz, endx, endy, endz)
end

function GameMap:query_objects(startx, starty, endx, endy, startz, endz)
    startx = startx or self.min_x
    endx = endx or self.max_x
    starty = starty or self.min_y
    endy = endy or self.max_y
    startz = startz or self.min_layer
    endz = endz or self.max_layer
    return table.query_region(self.objects, startx, starty, startz, endx, endy, endz)
end

function GameMap:query_tiles_world_space(startx, starty, endx, endy, startz, endz)
	startx = startx or self.world_to_cell(self.cell_to_world(self.min_x))
	endx = endx or self.world_to_cell(self.cell_to_world(self.max_x))
	starty = starty or self.world_to_cell(self.cell_to_world(self.min_y))
	endy = endy or self.world_to_cell(self.cell_to_world(self.max_y))
    startz = startz or self.min_layer
    endz = endz or self.max_layer

    return table.query_region(self.tile_objects, startx, starty, startz, endx, endy, endz, self.cell_to_world)
end

function GameMap:query_objects_world_space(startx, starty, endx, endy, startz, endz)
	startx = self.world_to_cell(startx or self.cell_to_world(self.min_x))
	endx = self.world_to_cell(endx or self.cell_to_world(self.max_x))
	starty = self.world_to_cell(starty or self.cell_to_world(self.min_y))
	endy = self.world_to_cell(endy or self.cell_to_world(self.max_y))
	startz = startz or self.min_layer
	endz = endz or self.max_layer

	return table.query_region(self.objects, startx, starty, startz, endx, endy, endz, self.cell_to_world)
end

function GameMap.cell_to_world(x, y, z)
	return x * tilesets.TILE_SIZE + tilesets.TILE_SIZE / 2, y and y * tilesets.TILE_SIZE + tilesets.TILE_SIZE / 2, z
end

function GameMap.world_to_cell(x, y, z)
	return math.floor(x / tilesets.TILE_SIZE), y and math.floor(y / tilesets.TILE_SIZE), z
end

function GameMap:erase_tiles()
	self.tile_map = nil
	self.tile_objects = nil
	self.tile_info = nil
end

function GameMap.bump_tile_tostring()
	return "GameMapBumpTile"
end

GameMap.bump_tile_mt = {
	__tostring = GameMap.bump_tile_tostring
}

function GameMap:build(build_spritebatches, build_collision)

    local layer_static_batches = {}
    local layer_dynamic_batches = {}

    self.objects = {}
    self.collision_objects = {}
    self.tile_info = {}
    self.tile_objects = {}
    self.dynamic_batches = {}
    self.static_batches = {}


    for x, y, z, tile_string in self.tile_map:iter() do
        if z < self.min_layer then self.min_layer = z end
        if z > self.max_layer then self.max_layer = z end
        if x < self.min_x then self.min_x = x end
        if x > self.max_x then self.max_x = x end
        if y < self.min_y then self.min_y = y end
        if y > self.max_y then self.max_y = y end

        if tilesets.object_tiles[tile_string] then
            table.populate_recursive(self.objects, z, y, x, tile_string)
            goto continue
        end

        local tile = self.tile_info[tile_string] or self.tile_map:tile_from_string(tile_string)
        self.tile_info[tile_string] = self.tile_info[tile_string] or tile

        if type(tile) == "string" then goto continue end

        table.populate_recursive(self.tile_objects, z, y, x, tile)

		
        -- static
        if build_spritebatches then
            local sprite_batch_table = table.populate_recursive(layer_static_batches, z, tile.texture, {})
			
        	table.populate_recursive(layer_dynamic_batches, z, tile.texture, {})
			
        	table.insert(sprite_batch_table, { x = x, y = y, tile = tile })
		end
		
        -- collisions
		if build_collision then
			local data = tile.data
			if data and data.collision_rect then
				local collision_rect = Rect(x * tilesets.TILE_SIZE + data.collision_rect.x,
					y * tilesets.TILE_SIZE + data.collision_rect.y, data.collision_rect.width, data.collision_rect.height)

				local collision_data = {
					x = x,
					y = y,
					layer = z,
					tile = tile,
					solid = not data.passable,
					collision_rect = collision_rect,
				}
				setmetatable(collision_data, GameMap.bump_tile_mt)

				table.populate_recursive(self.collision_objects, z, y, x, collision_data)
			end
		end
        ::continue::
    end

	if build_spritebatches then
		self.static_batches = {}
		self.dynamic_batches = {}

		for layer, texture_table in pairs(layer_dynamic_batches) do
			self.dynamic_batches[layer] = self.dynamic_batches[layer] or {}
			for texture, _ in pairs(texture_table) do
				local sprite_batch = graphics.new_sprite_batch(texture, 1000, "dynamic")
				self.dynamic_batches[layer][texture] = self.dynamic_batches[layer][texture] or {}
				self.dynamic_batches[layer][texture] = sprite_batch
			end
		end

		for layer, texture_table in pairs(layer_static_batches) do
			self.static_batches[layer] = self.static_batches[layer] or {}
			for texture, batch_table in pairs(texture_table) do
				local sprite_batch = graphics.new_sprite_batch(texture, 1000, "static")
				for _, tile_info in ipairs(batch_table) do
					sprite_batch:add(tile_info.tile.quad, tile_info.x * tilesets.TILE_SIZE, tile_info.y * tilesets.TILE_SIZE)
				end
				table.insert(self.static_batches[layer], sprite_batch)
			end
		end
	end
end

---@alias GameMap.DrawMode string | "static" | "dynamic"
---@param mode GameMap.DrawMode
function GameMap:draw_world_space(mode, startx, starty, endx, endy, startz, endz)
    startx, starty = startx and self.world_to_cell(startx, starty) or self.min_x, self.min_y
    endx, endy = endx and self.world_to_cell(endx, endy) or self.max_x, self.max_y
    startz = startz or self.min_layer
    endz = endz or self.max_layer
	self:draw(mode, startx, starty, endx, endy, startz, endz)
end

---@param mode GameMap.DrawMode
function GameMap:draw(mode, startx, starty, endx, endy, startz, endz)

    if mode ~= "static" and mode ~= "dynamic" then
        error("Invalid draw type: " .. mode)
    end

	startz = floor(startz or self.min_layer)
	endz = floor(endz or self.max_layer)
	
    if mode == "dynamic" then

		startx = (startx or self.min_x)
        endx = (endx or self.max_x)
        starty = (starty or self.min_y)
        endy = (endy or self.max_y)


        for z, textures in pairs(self.dynamic_batches) do
			if z >= startz and z <= endz then
				for texture, batch in pairs(textures) do
					batch:clear()
				end
			end
		end
		
        for x, y, z, tile in self:query_tiles(startx, starty, endx, endy, startz, endz) do
            local texture = tile.texture
            local sprite_batch = self.dynamic_batches[z][texture]
            if sprite_batch then
				sprite_batch:add(tile.quad, x * tilesets.TILE_SIZE, y * tilesets.TILE_SIZE)
            end
        end

	end

    if mode == "static" then
        if startx or starty or endx or endy then error "Static draw mode does not support region drawing." end
    end
	
    for layer =startz, endz do
		if startz and endz then
			if layer < startz or layer > endz then
				goto continue
			end
		end
        self:draw_layer(mode, layer)
		::continue::
	end
end

function GameMap:draw_layer(mode, layer)

    if mode ~= "static" and mode ~= "dynamic" then
        error("Invalid draw type: " .. mode)
    end

    if mode == "dynamic" then
		if self.dynamic_batches[layer] then
            local batches = self.dynamic_batches[layer]
			for _, batch in pairs(batches) do
				love.graphics.draw(batch)
			end
		end
	end

	if mode == "static" then 
		if self.static_batches[layer] then
			local batches = self.static_batches[layer]
			for _, batch in ipairs(batches) do 
				love.graphics.draw(batch)
			end
		end
	end
end

function GameMap:bump_init(bump_world, min_x, min_y, max_x, max_y, min_layer, max_layer)
	self:bump_clear()
    self.bump_world = bump_world
	for x, y, z, collision_object in table.query_region(self.collision_objects, min_x or self.min_x, min_y or self.min_y, min_layer or self.min_layer, max_x or self.max_x, max_y or self.max_y, max_layer or self.max_layer ) do
		self.bump_world:add(collision_object, collision_object.collision_rect.x, collision_object.collision_rect.y, collision_object.collision_rect.width, collision_object.collision_rect.height, PHYSICS_TERRAIN)
	end
end

function GameMap:bump_clear()
	if not self.bump_world then return end

	for x, y, z, collision_object in table.query_region(self.collision_objects, self.min_x, self.min_y, self.min_layer, self.max_x, self.max_y, self.max_layer ) do
		if self.bump_world:hasItem(collision_object) then
			self.bump_world:remove(collision_object)
		end
	end
end

return GameMap
