local Tilemap = require "tile.tilemap"
local TextInputBox = require "ui.text_input"

local LevelEditor = CanvasLayer:extend("LevelEditor")

local TILE_SIZE = tilesets.TILE_SIZE

local DATA_EDITOR_WIDTH = 120

local SWATCH_NUM_COLS = 8
local SWATCH_PADDING = 2

local LAYER_DISPLAY_CURRENT_HIGHLIGHTED = 0
local LAYER_DISPLAY_CURRENT = 1
local LAYER_DISPLAY_ALL = 2

local LAYER_FADE_AMOUNT = 0.3

local PALETTE_HIDE_TIMER = 20

local SAVE_READABLE = false

local EDITING_MAP = "map2"

local no_tile_draw_paint_modes = {
	select = true,
    move = true,
	data = true,
}

function LevelEditor:new(x, y, width, height)
	self.prevmpos = Vec2(0, 0)
	self.mpos = Vec2(0, 0)	
	self.mpos_real = Vec2(0, 0)	
	self.screen_mpos = Vec2(0, 0)
	self.mdxy = Vec2(0, 0)
	self.mcell = Vec3(0, 0, 0)
	self.lmb = 0
	self.mmb = 0
    self.rmb = 0
	self.zoom_level = 1
	self.zoom = 1

    self.clipboard = {}
	self.clipboard_size = Vec2(0, 0)

	self.offset = Vec2(0, 0)
	self.offset_stepped = Vec2(0, 0)

	self.layer = 0

	self.layer_display_type = LAYER_DISPLAY_CURRENT_HIGHLIGHTED

	-- paint, fill, rectangle_start, rectangle_end
	self.paint_mode = "draw"

	self.painting = false
	self.erasing = false
	self.blocks_input = true

	self.tilesets = {}
	self.tiles = {}
    self.swatch_tiles = {}

	self.edit_history = {}
	self.edit_future = {}
    self.current_tile_changes = {}
	self.current_selection_changes = {}
    self.is_recording_changes = false
    self.is_applying_history = false

	self.room_size = conf.room_size
	
    self.painting_tile_changes = {}

	self.palette_select_rect_start = Vec2(0, 0)
    self.palette_selection_size = Vec2(0, 0)

    self.active_key = "1_1"
    self.active_brush = nil
	self.brush_start = Vec2(0, 0)

	self.hovered_tile = nil

    self.state = "draw"
	
	self.map_name = EDITING_MAP

	self.showing_palette = false
	self.palette_mouse_over_tile = nil
	self.palette_rect = Rect(0, 0, 0, 0)
	
	self.palette_scroll_offset = 0
	self.palette_rows = 0
	self.palette_hide_timer = 0

	self.paint_rect_start = Vec3(0, 0, 0)
	self.paint_rect_end = Vec3(0, 0, 0)

	self.select_start = nil
    self.select_rect_start = nil
    self.select_rect_end = nil
	self.pasting = false
	
    self.move_tiles = nil
	self.move_tile_offset = Vec2(0, 0)
	self.move_tile_size = Vec2(0, 0)

	self.layer_display_offset = 0

	self.notify_text = ""
	self.notify_text_alpha = 0
	
	self.showing_data_editor = false

	self.grid_bgcolor = Color.darkergrey

	self.showing_ui = true
	self.showing_grid = 1

    self.palette_changed = true
	self.old_key_repeat = love.keyboard.hasKeyRepeat()

	LevelEditor.super.new(self, x, y, width, height)

    love.mouse.set_visible(true)
	love.mouse.set_relative_mode(false)


	signal.connect(input, "key_pressed", self, "on_key_pressed", (
		function(key)
			-- global
			if self.input == input.dummy then
				return
			end


			local active_area = self:get_active_section()
			if active_area == "draw" or active_area == "palette" then
				self:on_key_pressed_drawing_area(key)
			end

		end))

		signal.connect(input, "mouse_wheel_moved", self, "on_mouse_wheel_moved", (
		function(x, y)
			if self.input == input.dummy then
				return
			end

			local active_area = self:get_active_section()


            if active_area == "draw" then
				if input.keyboard_held["lctrl"] or input.keyboard_held["rctrl"] then
                    self.layer = self.layer + y
				else 
					self:camera_zoom(y)
				end
			elseif active_area == "palette" then
				self.palette_scroll_offset = self.palette_scroll_offset + y
				self.palette_scroll_offset = clamp(self.palette_scroll_offset, -self.palette_rows, 0)
				-- print(self.palette_scroll_offset)
			end
		end))

	signal.connect(input, "mouse_pressed", self, "mouse_pressed", (
		function(x, y, button)
			if self.input == input.dummy then
				return
			end

			local active_area = self:get_active_section()
			if active_area == "draw" then
				self:on_mouse_pressed_drawing_area(x, y, button)
			elseif active_area == "palette" then
				-- if self.palette_mouse_over_tile then
				--     self.active_key = self.palette_mouse_over_tile
                -- end
            elseif active_area == "data" then
				self.tile_data_input_box:on_click(self.screen_mpos.x, self.screen_mpos.y)
			end
        end))
		
	self:load(EDITING_MAP)
	self:update_palette()
	
end

function LevelEditor:load(map_name)
		
    local map_string = filesystem.load_file_native("map/maps/" .. map_name .. "/tiles.lua")
	
    if not map_string then
		self:notify("Failed to load map " .. map_name)
        return
	end

	local map_data = table.deserialize(map_string)


	self.map_name = map_name

	self:build_from_level_data(map_data)
	self:notify("Loaded map " .. map_name)
end

function LevelEditor:camera_zoom(amount)
    local new_zoom_level = clamp(self.zoom_level - amount, 1, 4)
    local new_zoom = 1 / pow(2, new_zoom_level - 1)

    self.zoom_level = new_zoom_level
    self.zoom = new_zoom

    local new_offset_x = self.screen_mpos.x - self.zoom * self.mpos_real.x
    local new_offset_y = self.screen_mpos.y - self.zoom * self.mpos_real.y

    self:update_offset(new_offset_x, new_offset_y)

    self:update_mouse_positions()

    dbg("zoom_level", self.zoom_level)
    dbg("zoom", self.zoom)
end

function LevelEditor:build_from_level_data(level_data)
	if type(level_data) ~= "table" then
		return
	end

    self.tiles = {}

    local tile_map = Tilemap(level_data)
	
    for x, y, z, tile in tile_map:iter() do
		self:set_tile(x, y, z, tile)
	end

end

function LevelEditor:save(map_name)
    map_name = map_name or self.map_name
    self.map_name = map_name

    local data = table.serialize(self:get_level_data())
    filesystem.save_file_native(data, "map/maps/" .. map_name .. "/tiles.lua")
end

function LevelEditor.convert_to_map_format(tiles, width, height, indent, compressed)
    if not SAVE_READABLE then
        if compressed then
			local t = {}


			local s = "{\n"
			
            for id, runs in pairs(tiles) do
				if type(runs) ~= "function" then
					s = s .. indent .. "\t[\"" .. id .. "\"] = {"
					for _, run in ipairs(runs) do
						
						s = s ..  run[1] .. "," .. run[2] .. ","

					end
					s = s .. "},\n"
				end
			end
			
			s = s .. indent .. "}"

            return s
        else
			local t = {}
			for i, id in pairs(tiles) do
				if type(id) ~= "function" then
					t[id] = t[id] or {}
					table.insert(t[id], i)
				end
			end

			local s = "{\n"
			
			for id, t2 in pairs(t) do

				s = s .. indent .. "\t[\"" .. id .. "\"] = {"


				for _, location in pairs(t2) do
					s = s .. location .. ", "
				end

				s = s .. "},\n"
			end
			
			s = s .. indent .. "}"

            return s
		end
    end
	
	local longest_id = 0
	for i, id in pairs(tiles) do
		if type(id) == "string" then
			if string.len(id) > longest_id then
				longest_id = string.len(id)
			end
		end
	end
	longest_id = longest_id + 2
	
	local s = "{ \n" .. indent .. "  "
	for i = 1, width * height do
		local id = tiles[i]

		if id == nil then
			s = s .. string.format("%" .. longest_id .. "s", "nil") .. ","
		else
			s = s .. string.format("%" .. longest_id .. "s", "\"" .. id .. "\"") .. ","
		end
		if i % width == 0 then
			s = s .. "\n" .. indent .. "  "
		end
	end
	s = s .. " }"
	return s

end

-- override this function to process the map before it is saved
function LevelEditor:custom_map_process(tab)
	
end

function LevelEditor:get_level_data()
	local min_x, min_y, min_z, max_x, max_y, max_z = self:get_bounds()
    local level_data = {
        layers = {},
		tilesets = {},
		compressed = not SAVE_READABLE,
    }

	for id, name in pairs(tilesets.tileset_names) do 
		level_data.tilesets[id] = name
	end
		

    for z = min_z, max_z do
		if not self.tiles[z] then
			goto continue
		end

        local layer_min_x, layer_min_y, layer_max_x, layer_max_y = self:get_layer_bounds(z)
        local layer_width = layer_max_x - layer_min_x + 1
		local layer_height = layer_max_y - layer_min_y + 1
		local layer = {
            offset = { x = layer_min_x, y = layer_min_y },
            width = layer_width,
            height = layer_height,
            tiles = {}
        }
        
		
		layer.tiles.__table_format = function(tiles, next_indent) return self.convert_to_map_format(tiles, layer_width, layer_height, next_indent, level_data.compressed) end

		if level_data.compressed then
            local current_run = nil
            local current_tile = nil
			local current_run_length = 0

			for y = 1, layer_height do
				for x = 1, layer_width do
					local tile = self:get_tile(layer_min_x + x - 1, layer_min_y + y - 1, z)
					local pos = xy_to_id(x, y, layer_width)
					
                    if tile and tile == current_tile then
                        if current_run == nil then
                            current_run_length = 0
                            current_run = { pos, current_run_length }
                            current_tile = tile
                        else
                            current_run[2] = current_run_length
                        end
                    else
                        if current_run and current_tile then
                            layer.tiles[current_tile] = layer.tiles[current_tile] or {}
                            table.insert(layer.tiles[current_tile], current_run)
                        end
                        if tile == nil then
                            current_run = nil
                            current_tile = nil
                        else
                            current_run_length = 0
                            current_run = { pos, current_run_length }
                            current_tile = tile
                        end
                    end
					current_run_length = current_run_length + 1
				end
			end
            if current_run and current_tile then
                layer.tiles[current_tile] = layer.tiles[current_tile] or {}
                table.insert(layer.tiles[current_tile], current_run)
            end
			
		else
			
			for y = 1, layer_height do
				for x = 1, layer_width do
					local tile = self:get_tile(layer_min_x + x - 1, layer_min_y + y - 1, z)
					local pos = xy_to_id(x, y, layer_width)
					if tile then
						layer.tiles[pos] = tile
					else
						layer.tiles[pos] = nil
					end
				end
			end
		end


		-- layer.tiles = self.tiles[z]

		level_data.layers[z] = layer
		
		::continue::
	end

	self:custom_map_process(level_data)

	return level_data
end


function LevelEditor:notify(text)
    self.notify_text = text
    local s = self.sequencer
    s:start(function()
        s:tween_property(self, "notify_text_alpha", 1, 0, 60, "inQuad")
    end)
end

function LevelEditor:clear_tiles()
    self:begin_action()
    -- Record deletions of all tiles
    for z, layer in pairs(self.tiles) do
        for y, row in pairs(layer) do
            for x, tile_id in pairs(row) do
                self:set_tile(x, y, z, nil)
            end
        end
    end
    self:end_action()
end

function LevelEditor:process_load_save_screen_text(text) 
	if self.loading then
		self.loading = false
		self:load(text)
	elseif self.saving then
		self.saving = false
		self:save(text)
		self:notify("Saved map " .. text)
	end
end

function LevelEditor:on_key_pressed_drawing_area(key)
	if input.keyboard_held["lctrl"] or input.keyboard_held["rctrl"] then
		if key == "l" then
			self.loading = true
			self.load_save_text = "load map"
			self.parent:insert_layer("Editor.LoadSaveScreen", 1)
		end
        if key == "s" then
            -- local string = self:get_level_string()
            -- if string == "invalidcharacters" then
            --     self:notify("can't copy, contains non-string tiles")
            -- else
            -- love.system.setClipboardText(string)
            self:save()
            self:notify("Saved")
            -- end
        elseif key == "delete" then
            self:clear_tiles()
            self:notify("Cleared")
        elseif key == "z" then
            if input.keyboard_held["lshift"] or input.keyboard_held["rshift"] then
                self:redo()
            else
                self:undo()
            end
        elseif key == "c" then
            if self.select_rect_start and self.select_rect_end then
                self:copy_selection()
                self:notify("Copied selection")
            end
        elseif key == "x" then
            if self.select_rect_start and self.select_rect_end then
                self:begin_action()
                self:copy_selection()
                self:delete_selection()
                self:end_action()
                self:notify("Cut selection")
            end
        elseif key == "v" then
            if self.clipboard then
                self:start_paste()
                self:notify("Pasted clipboard")
            end
        elseif key == "a" then
            local min_x, min_y, max_x, max_y = self:get_layer_bounds()
            self:set_selection_rect(min_x, min_y, max_x, max_y)
            self:notify("Selected All")
			-- self.paint_mode = "select"
		end
		return
	

	elseif input.keyboard_held["lshift"] or input.keyboard_held["rshift"] then
		if not self.painting then
			if key == "r" then
				self.paint_mode = "rectf"
				self:notify("Mode: Rectangle Filled")
			elseif key == "e" then
				self.paint_mode = "replg"
				self:notify("Mode: Replace Global")
			elseif key == "d" then
				self.paint_mode = "line"
				self:notify("Mode: Line")
				return
			end
		end
	else
        if not self.painting then
            if key == "d" then
                self.paint_mode = "draw"
                self:notify("Mode: Draw")
                return
            elseif key == "f" then
                self.paint_mode = "fill"
                self:notify("Mode: Fill")
                return
            elseif key == "r" then
                self.paint_mode = "rect"
                self:notify("Mode: Rectangle")
                return
            elseif key == "e" then
                self.paint_mode = "repl"
                self:notify("Mode: Replace In Layer")
                return
            elseif key == "s" then
                self.paint_mode = "select"
                self:notify("Mode: Select")
            elseif key == "delete" then
                self:begin_action()
                self:delete_selection()
                self:end_action()
                self:notify("Deleted selection")
            elseif key == "q" then
                -- in this mode you enter custom tile data values as text
                self.paint_mode = "data"
                self:notify("Mode: Tile Data")
            elseif key == "c" then
                self:notify("Centered")
                self:update_offset(self.room_size.x / 2, self.room_size.y / 2)
            end
        end
		
		if key == "t" then
			self:toggle_palette()
		elseif key == "kp+" then
			self.layer = self.layer - 1
		elseif key == "kp-" then
			self.layer = self.layer + 1
		elseif key == "l" then
			self.layer_display_type = (self.layer_display_type + 1) % 3
		elseif key == "g" then
            self.showing_grid = self.showing_grid + 1
            if self.showing_grid > 2 then
                self.showing_grid = 0
            end
		elseif key == "tab" then
			self.showing_ui = not self.showing_ui
			-- if self.showing_palette then
            self.showing_palette = false
        elseif key == "b" then
            if self.select_rect_start == nil and self.active_brush and (self.active_brush_size.x > 1 or self.active_brush_size.y > 1) then
				self:clear_brush()
				self:notify("Cleared Brush")
			elseif self.select_rect_start and self.select_rect_end then
                self.active_brush, self.active_brush_size = self:get_tile_rect(self.select_rect_start.x,
                    self.select_rect_start.y, self.select_rect_end.x, self.select_rect_end.y)
                self:notify("Set Brush")
				self:set_selection_rect(nil, nil)
				self.paint_mode = "draw"
			end
        elseif key == "escape" then
            if self.select_rect_start then	
				self:set_selection_rect(nil, nil)
                self.select_start = nil
				self:notify("Cleared Selection")
			elseif (self.active_brush_size and (self.active_brush_size.x > 1 or self.active_brush_size.y > 1)) then
				self:clear_brush()
				self:notify("Cleared Brush")
			end
		else
			-- local num = tonumber(key)
			-- if num then
			-- 	self.active_key = num
			-- end
		end
	end
end

function LevelEditor:toggle_palette()
	self.showing_palette = not self.showing_palette
	if not self.showing_ui then
		self.showing_ui = true
		self.showing_palette = false
	end
end

function LevelEditor:set_painting_tile_change(x, y, z, tile)
	if tile == nil then tile = " " end
	self.painting_tile_changes = self.painting_tile_changes or {}
	self.painting_tile_changes[z] = self.painting_tile_changes[z] or {}
	self.painting_tile_changes[z][y] = self.painting_tile_changes[z][y] or {}
	self.painting_tile_changes[z][y][x] = tile
end

function LevelEditor:get_painting_tile_change(x, y, z)
	if self.painting_tile_changes == nil then
		return nil
	end

	if self.painting_tile_changes[z] == nil then
		return nil
	end
	if self.painting_tile_changes[z][y] == nil then
		return nil
	end
	return self.painting_tile_changes[z][y][x]
end

function LevelEditor:on_mouse_pressed_drawing_area(x, y, button)
    if input.keyboard_held["lalt"] or input.keyboard_held["ralt"] then
        return
    end
    if input.keyboard_held["lctrl"] or input.keyboard_held["rctrl"] then
        return
    end
	
    if button == 1 or button == 2 then
        if self.paint_mode == "fill" then
            self:begin_action()
            self:flood_fill(self.mcell.x, self.mcell.y, self.layer, button == 1 and self.active_key or nil)
            self:end_action()
        elseif self.paint_mode == "repl" then
            self:begin_action()
            if self.tiles[self.layer] ~= nil then
                local min_x, min_y, max_x, max_y = self:get_layer_bounds(self.layer)
                for x = min_x, max_x do
                    for y = min_y, max_y do
                        local tile = self:get_tile(x, y, self.layer)
                        if tile == self.hovered_tile and self:is_in_selection(x, y) then
                            self:brush(x, y, self.layer, button == 1 and self.active_key or nil, false, true)
                        end
                    end
                end
            end
            self:end_action()
        elseif self.paint_mode == "replg" then
            self:begin_action()
            local min_x, min_y, min_z, max_x, max_y, max_z = self:get_bounds()
            for z = min_z, max_z do
                for y = min_y, max_y do
                    for x = min_x, max_x do
                        local tile = self:get_tile(x, y, z)
                        if tile == self.hovered_tile and self:is_in_selection(x, y) then
                            self:brush(x, y, z, button == 1 and self.active_key or nil, false, true)
                        end
                    end
                end
            end
            self:end_action()
        end
    end
end


function LevelEditor:get_tile(x, y, z)
    x = round(x)
    y = round(y)
	z = round(z or self.layer)

	if self.tiles[z] == nil then
		return nil
	end

	if self.tiles[z][y] == nil then
		return nil
	end

	return self.tiles[z][y][x] or nil
end

function LevelEditor:set_tile(x, y, z, tile_id)
  x = round(x)
    y = round(y)
    z = round(z)

	
    -- If we are recording changes and not applying history, record the change
    if not self.is_applying_history and self.is_recording_changes then
		local old_tile_id = self:get_tile(x, y, z)

		local change_key = x .. ',' .. y .. ',' .. z
        if self.current_tile_changes[change_key] == nil then
            self.current_tile_changes[change_key] = { x = x, y = y, z = z, old_tile = old_tile_id, new_tile = tile_id }
        else
            -- Update the new_tile to the latest tile_id
            self.current_tile_changes[change_key].new_tile = tile_id
        end
    end

    -- Rest of the set_tile function as before
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

function LevelEditor:clear_brush()
	self.active_brush = nil
    self.palette_select_rect_start = nil
    self.palette_selection_size = Vec2(0, 0)
    self.palette_select_rect_end = nil
	self.palette_select_start = nil
end

function LevelEditor:copy_selection()
    if self.select_rect_start == nil or self.select_rect_end == nil then
        return
    end

    self.clipboard, self.clipboard_size = self:get_tile_rect(self.select_rect_start.x,self.select_rect_start.y, self.select_rect_end.x, self.select_rect_end.y)
end

function LevelEditor:get_tile_rect(x1, y1, x2, y2)

    local w = x2 - x1
	local h = y2 - y1

	local tiles = {}

	for y = y1, y2 do
		tiles[y - y1] = {}
		for x = x1, x2 do
			tiles[y - y1][x - x1] = self:get_tile(x, y, self.layer)
		end
	end

	local size = Vec2(w, h)

	return tiles, size
end 

function LevelEditor:get_palette_tile_rect(x1, y1, x2, y2)
	local w = x2 - x1
	local h = y2 - y1

	local tiles = {}

	for y = y1, y2 do
		tiles[y - y1] = {}
		for x = x1, x2 do
			tiles[y - y1][x - x1] = self:get_palette_tile(x, y)
		end
	end

	local size = Vec2(w, h)

	return tiles, size
end

function LevelEditor:get_palette_tile(x, y)
    local index = y * SWATCH_NUM_COLS + x
	if self.palette_cells[x] and self.palette_cells[x][y] then
		return tilesets.tile_to_id[self.palette_cells[x][y].tile]
	end
end

function LevelEditor:delete_selection()
	if self.select_rect_start == nil or self.select_rect_end == nil then
		return
	end

	for y = self.select_rect_start.y, self.select_rect_end.y do
		for x = self.select_rect_start.x, self.select_rect_end.x do
			self:set_tile(x, y, self.layer, nil)
		end
	end
end

function LevelEditor:start_paste()
	if table.is_empty(self.clipboard) then
		return
	end

	
    -- if self.select_rect_start == nil then
	self:start_move(self.clipboard, self.clipboard_size)
    -- else
        -- self.select_rect_end = Vec2(self.select_rect_start.x + self.clipboard_size.x, self.select_rect_start.y + self.clipboard_size.y)
    -- end

end

function LevelEditor:is_in_selection(x, y)
	if self.select_rect_start == nil or self.select_rect_end == nil then
		return true
	end
	return x >= self.select_rect_start.x and x <= self.select_rect_end.x and y >= self.select_rect_start.y and y <= self.select_rect_end.y
end

function LevelEditor:start_move(move_tiles, move_tile_size)
    self.paint_mode = "move"

	
	self:begin_action()
	if move_tiles == nil then
		self.move_tiles, self.move_tile_size = self:get_tile_rect(self.select_rect_start.x, self.select_rect_start.y, self.select_rect_end.x, self.select_rect_end.y)
        self.move_tile_offset = Vec2(self.mcell.x - self.select_rect_start.x, self.mcell.y - self.select_rect_start.y)
		self:delete_selection()
    else
		self.move_tiles = move_tiles
		self.move_tile_size = move_tile_size
		self.move_tile_offset = Vec2(0, 0)
	end

end

function LevelEditor:end_move()
	local finished_moving_in_another_mode = self.mode_when_done_moving ~= nil
	self.paint_mode = self.mode_when_done_moving or "select"
    self.mode_when_done_moving = nil

    self:set_selection_rect(self.mcell.x - self.move_tile_offset.x, self.mcell.y - self.move_tile_offset.y,
        self.mcell.x - self.move_tile_offset.x + self.move_tile_size.x,
        self.mcell.y - self.move_tile_offset.y + self.move_tile_size.y)
    self:delete_selection()

    if self.move_tiles then
        -- self:update_history()
        for y = 0, self.move_tile_size.y do
            for x = 0, self.move_tile_size.x do
                local tile = self.move_tiles[y] and self.move_tiles[y][x]
                if tile then
                    self:set_tile(self.mcell.x + x - self.move_tile_offset.x,
                        self.mcell.y + y - self.move_tile_offset.y, self.layer, tile)
                end
            end
        end
    end

    if finished_moving_in_another_mode then
        if self.select_rect_end.x == self.select_rect_start.x and self.select_rect_end.y == self.select_rect_start.y then
            self.select_start = nil
			self:set_selection_rect(nil, nil, nil, nil)
		end
	end

    self:end_action()


    self.move_tiles = nil
end

function LevelEditor:brush(x, y, z, key, preview, single_tile)

    local startx = x
    local starty = y
	local endx = x
    local endy = y

	local erasing = key == nil

	if self.active_brush and not single_tile then
		endx = x + self.active_brush_size.x
		endy = y + self.active_brush_size.y
	end

    for cy = starty, endy do
		for cx = startx, endx do 
            if self:is_in_selection(cx, cy) then
                
                if not erasing and self.active_brush then
                    local astartx = self.active_brush_start.x
                    local astarty = self.active_brush_start.y
                    local aendx = astartx + self.active_brush_size.x
                    local aendy = astarty + self.active_brush_size.y
                    local bx = (cx - astartx) % (aendx - astartx + 1)
                    local by = (cy - astarty) % (aendy - astarty + 1)
					key = self.active_brush[by][bx]
                end
				
				if not preview then 
                    self:set_tile(cx, cy, z, key)
                else
					self:set_painting_tile_change(cx, cy, z, key)
				end
			end
		end
	end
end

function LevelEditor:initialize_brush_for_drawing()
	if self.active_brush then
		self.active_brush_start = Vec2(self.mcell.x, self.mcell.y)
	end
end

local paint_start_functions = {
    draw = function(self, key)
        self:begin_action()

		self:initialize_brush_for_drawing()
		self:brush(self.mcell.x, self.mcell.y, self.layer, key)
	end,

	line = function(self, key)
		self:begin_action()
		self.paint_rect_start.x = self.mcell.x
        self.paint_rect_start.y = self.mcell.y
		-- if self:is_in_selection(self.mcell.x, self.mcell.y) then
		-- 	self:set_tile(self.mcell.x, self.mcell.y, self.layer, key)
        -- end
		self:initialize_brush_for_drawing()
		self:brush(self.mcell.x, self.mcell.y, self.layer, key)
	end,

	rect = function(self, key)
		self:begin_action()
        self:initialize_brush_for_drawing()
		
		self.paint_rect_start.x = self.mcell.x
		self.paint_rect_start.y = self.mcell.y
		self.paint_rect_start.z = self.layer
	end,
	rectf = function(self, key)
		self:begin_action()
        self:initialize_brush_for_drawing()
		
		self.paint_rect_start.x = self.mcell.x
		self.paint_rect_start.y = self.mcell.y
		self.paint_rect_start.z = self.layer
	end,
	
    select = function(self, key)
        if self.select_start and self:is_in_selection(self.mcell.x, self.mcell.y) then
			self:start_move()
			return
		end

        self.select_start = Vec2(self.mcell.x, self.mcell.y)
       	self:set_selection_rect(self.mcell.x, self.mcell.y, self.mcell.x, self.mcell.y)
    end,

    paste = function(self, key)
        self.pasting = false
        self.mode = "draw"
    end,
	
    move = function(self, key)
		self:end_move()
	end

}
local paint_functions = {
	draw = function(self, key)
		for _, point in ipairs(bresenham_line(self.prevmpos.x, self.prevmpos.y, self.mpos.x, self.mpos.y)) do
            local cx, cy = floor(point.x / TILE_SIZE), floor(point.y / TILE_SIZE)

			self:brush(cx, cy, self.layer, key)
		end
    end,
	
	rect = function(self, key)
		self.painting_tile_changes = {}
		self.paint_rect_end.x = self.mcell.x
		self.paint_rect_end.y = self.mcell.y
		self.paint_rect_end.z = self.layer
		local min_x, min_y, min_z = min(self.paint_rect_start.x, self.paint_rect_end.x), min(self.paint_rect_start.y, self.paint_rect_end.y),
			min(self.paint_rect_start.z, self.paint_rect_end.z)
		local max_x, max_y, max_z = max(self.paint_rect_start.x, self.paint_rect_end.x), max(self.paint_rect_start.y, self.paint_rect_end.y),
			max(self.paint_rect_start.z, self.paint_rect_end.z)
		for z = min_z, max_z do
            for y = min_y, max_y do

				self:brush(min_x, y, z, key, true)
				self:brush(max_x, y, z, key, true)
			end
			for x = min_x, max_x do

				self:brush(x, min_y, z, key, true)
				self:brush(x, max_y, z, key, true)

			end
		end
	end,
	rectf = function(self, key)
		self.painting_tile_changes = {}
		self.paint_rect_end.x = self.mcell.x
		self.paint_rect_end.y = self.mcell.y
		self.paint_rect_end.z = self.layer
		local min_x, min_y, min_z = min(self.paint_rect_start.x, self.paint_rect_end.x), min(self.paint_rect_start.y, self.paint_rect_end.y),
			min(self.paint_rect_start.z, self.paint_rect_end.z)
		local max_x, max_y, max_z = max(self.paint_rect_start.x, self.paint_rect_end.x), max(self.paint_rect_start.y, self.paint_rect_end.y),
			max(self.paint_rect_start.z, self.paint_rect_end.z)
		for z = min_z, max_z do
			for y = min_y, max_y do
                for x = min_x, max_x do
					self:brush(x, y, z, key, true)
				end
			end
		end
	end,

	line = function(self, key)
		self.paint_rect_end.x = self.mcell.x
		self.paint_rect_end.y = self.mcell.y
		if input.keyboard_held["lshift"] or input.keyboard_held["rshift"] then
			local dx, dy = vec2_snap_angle(self.paint_rect_end.x - self.paint_rect_start.x, self.paint_rect_end.y - self.paint_rect_start.y,
				tau / 8)
			self.paint_rect_end.x = self.paint_rect_start.x + round(dx)
			self.paint_rect_end.y = self.paint_rect_start.y + round(dy)
		end
        for _, point in ipairs(bresenham_line(self.paint_rect_start.x, self.paint_rect_start.y, self.paint_rect_end.x, self.paint_rect_end.y)) do
			self:brush(point.x, point.y, self.layer, key, true)
		end
    end,

    select = function(self, key)
		local rect_start = self.select_rect_start
		local rect_end = self.select_rect_end

		if self.select_start == nil then
			self.select_start = Vec2(self.mcell.x, self.mcell.y)
		end
		if rect_start == nil then
			rect_start = Vec2(self.mcell.x, self.mcell.y)
		end
		if rect_end == nil then
			rect_end = Vec2(self.mcell.x, self.mcell.y)
		end

        if (self.mcell.x == rect_start.x and self.mcell.y == rect_start.y) or (self.mcell.x == rect_end.x and self.mcell.y == rect_end.y) then
			self:set_selection_rect(rect_start, rect_end)
			return
		end

        if self.select_start.x <= self.mcell.x then
			rect_start.x = self.select_start.x
            rect_end.x = self.mcell.x
        else
			rect_start.x = self.mcell.x
            rect_end.x = self.select_start.x
        end
		
		if self.select_start.y <= self.mcell.y then
            rect_end.y = self.mcell.y
			rect_start.y = self.select_start.y
		else
            rect_end.y = self.select_start.y
			rect_start.y = self.mcell.y
		end

		self:set_selection_rect(rect_start, rect_end)
	end,

    move = function(self, key)
        if self.move_tiles == nil then
            self.paint_mode = "select"
        end
        if self.move_tiles then
            for y = 0, self.move_tile_size.y do
                for x = 0, self.move_tile_size.x do
                    local tile = self.move_tiles[y] and self.move_tiles[y][x]

					self:set_painting_tile_change(self.mcell.x + x - self.move_tile_offset.x,
						self.mcell.y + y - self.move_tile_offset.y, self.layer, tile)

                end
            end
        end

		self:set_selection_rect(self.mcell.x - self.move_tile_offset.x, self.mcell.y - self.move_tile_offset.y, self.mcell.x - self.move_tile_offset.x + self.move_tile_size.x, self.mcell.y - self.move_tile_offset.y + self.move_tile_size.y)
		
	end
}


local paint_end_functions = {

	draw = function(self, key)
		self:end_action()
    end,
	

	line = function(self, key)
        for _, point in ipairs(bresenham_line(self.paint_rect_start.x, self.paint_rect_start.y, self.paint_rect_end.x, self.paint_rect_end.y)) do
            local cx, cy = (point.x), (point.y)
            -- if self:is_in_selection(cx, cy) then
            --     self:set_tile(cx, cy, self.layer, key)
            -- end
			self:brush(cx, cy, self.layer, key)
        end
		self:end_action()
	end,

	rect = function(self, key)
		self.paint_rect_end.x = self.mcell.x
		self.paint_rect_end.y = self.mcell.y
		self.paint_rect_end.z = self.layer
		local min_x, min_y, min_z = min(self.paint_rect_start.x, self.paint_rect_end.x), min(self.paint_rect_start.y, self.paint_rect_end.y),
			min(self.paint_rect_start.z, self.paint_rect_end.z)
		local max_x, max_y, max_z = max(self.paint_rect_start.x, self.paint_rect_end.x), max(self.paint_rect_start.y, self.paint_rect_end.y),
			max(self.paint_rect_start.z, self.paint_rect_end.z)
		for z = min_z, max_z do
            for y = min_y, max_y do
                self:brush(min_x, y, z, key)
				self:brush(max_x, y, z, key)
			end
            for x = min_x, max_x do
                self:brush(x, min_y, z, key)
				self:brush(x, max_y, z, key)
			end
		end
		self:end_action()
	end,

	rectf = function(self, key)
		self.paint_rect_end.x = self.mcell.x
		self.paint_rect_end.y = self.mcell.y
		self.paint_rect_end.z = self.layer
		local min_x, min_y, min_z = min(self.paint_rect_start.x, self.paint_rect_end.x), min(self.paint_rect_start.y, self.paint_rect_end.y),
			min(self.paint_rect_start.z, self.paint_rect_end.z)
		local max_x, max_y, max_z = max(self.paint_rect_start.x, self.paint_rect_end.x), max(self.paint_rect_start.y, self.paint_rect_end.y),
			max(self.paint_rect_start.z, self.paint_rect_end.z)
        for z = min_z, max_z do
            for y = min_y, max_y do
                for x = min_x, max_x do
					self:brush(x, y, z, key)
                end
            end
        end
		self:end_action()
	end,

    move = function(self, key)
		self:end_move()
	end
}

local paint_hover_functions = {
	move = paint_functions.move,
}

function LevelEditor:update_mouse_drawing_area(dt)
    if self.mmb then
        self:update_offset((self.offset.x + self.mdxy.x), (self.offset.y + self.mdxy.y))
    end
	
    if self.lmb or self.rmb then
        if (input.keyboard_held["lctrl"] or input.keyboard_held["rctrl"]) and self.paint_mode ~= "select" and self.paint_mode ~= "move" and not self.painting then
            if not (self.select_start) or self.select_rect_end.x == self.select_rect_start.x and self.select_rect_end.y == self.select_rect_start.y then
				self:set_selection_rect(self.mcell.x, self.mcell.y, self.mcell.x, self.mcell.y)
            end
			if self:is_in_selection(self.mcell.x, self.mcell.y) then
				self.mode_when_done_moving = self.paint_mode
				self.paint_mode = "select"
				self.painting = false
				self.erasing = false
			end
		end

        -- Mouse is pressed
        if input.keyboard_held["lalt"] or input.keyboard_held["ralt"] then
            self.active_key = self:get_tile(self.mcell.x, self.mcell.y) or self.active_key
			self:clear_brush()
        else
            self.erasing = self.rmb
            if not self.painting then
                self.painting = true
                if paint_start_functions[self.paint_mode] ~= nil then
                    paint_start_functions[self.paint_mode](self, self.active_key or nil)
                end
            end

            if paint_functions[self.paint_mode] ~= nil then
                paint_functions[self.paint_mode](self, self.lmb and self.active_key or nil)
            end
        end
    else
        if self.painting then
            if paint_end_functions[self.paint_mode] ~= nil then
                paint_end_functions[self.paint_mode](self, (not self.erasing) and self.active_key or nil)
            end
        end
        self.painting = false
        self.erasing = false
    end

	if not self.painting then
		if paint_hover_functions[self.paint_mode] ~= nil then
			paint_hover_functions[self.paint_mode](self, self.active_key or nil)
		end
	end

	if self.screen_mpos.x < self.palette_rect.x then
		self.palette_hide_timer = self.palette_hide_timer - dt
	elseif self.showing_palette and self.screen_mpos.x >= self.palette_rect.x then
		self.palette_hide_timer = PALETTE_HIDE_TIMER
    elseif self.screen_mpos.x >= self.viewport_size.x - TILE_SIZE / 2 and not self.painting then
		if not no_tile_draw_paint_modes[self.paint_mode] then
			self.showing_palette = true
			self.palette_hide_timer = PALETTE_HIDE_TIMER
		end
	end
	
	if self.palette_hide_timer <= 0 then
		self.showing_palette = false
	end
    -- rest of the function...
end

function LevelEditor:on_palette_changed()
	self.palette_changed = true
end

function LevelEditor:palette_selection_update(x, y)
	local rect_start = self.palette_select_rect_start
    local rect_end = self.palette_select_rect_end

    if self.palette_select_start == nil then
        self.palette_select_start = Vec2(x, y)
    end
	
	if rect_start == nil then
		rect_start = Vec2(x, y)
	end
	if rect_end == nil then
		rect_end = Vec2(x, y)
	end

	if (x == rect_start.x and y == rect_start.y) or (x == rect_end.x and y == rect_end.y) then
		self:set_palette_selection_rect(rect_start, rect_end)
		return
	end

	if self.palette_select_start.x <= x then
		rect_start.x = self.palette_select_start.x
		rect_end.x = x
	else
		rect_start.x = x
		rect_end.x = self.palette_select_start.x
	end
	
    if self.palette_select_start.y <= y then
        rect_end.y = y
        rect_start.y = self.palette_select_start.y
    else
        rect_end.y = self.palette_select_start.y
        rect_start.y = y
    end
	
	self:set_palette_selection_rect(rect_start, rect_end)

	self.active_brush, self.active_brush_size = self:get_palette_tile_rect(self.palette_select_rect_start.x, self.palette_select_rect_start.y, self.palette_select_rect_end.x, self.palette_select_rect_end.y)
end

function LevelEditor:update_palette()
	local horizontal_space = SWATCH_NUM_COLS * TILE_SIZE + (SWATCH_PADDING * 2)
	self.palette_rect.x = self.viewport_size.x - horizontal_space
	self.palette_rect.y = 8
	self.palette_rect.width = horizontal_space
	self.palette_rect.height = self.viewport_size.y - 16

	self.palette_mouse_over_tile = nil

	local x = self.palette_rect.x + SWATCH_PADDING
	
    local y = self.palette_rect.y + SWATCH_PADDING + self.palette_scroll_offset * TILE_SIZE
	self.palette_x = x

	if self.palette_changed then
        self.swatch_tiles = {}
        self.palette_cells = {}
		self.palette_swatch_to_cell = {}
		self.palette_rows = 0
	end

	local current_tileset = tilesets.tileset_offsets[1]

	local row = 0

    local active_area = self:get_active_section()
	
    if not self.lmb then
		self.selecting_palette = false
	end

	local cell_x, cell_y = 1, 1
	local mcellx, mcelly = nil, nil

    for i, id in pairs(tilesets.tile_ids) do
        local tile = tilesets.tileset_tiles[id]

        if self.screen_mpos.x >= x and self.screen_mpos.x <= x + TILE_SIZE and self.screen_mpos.y >= y and self.screen_mpos.y <= y + TILE_SIZE then
            self.palette_mouse_over_tile = id

			if active_area == "palette" and self.lmb then
				-- if input.keyboard_held["lshift"] or input.keyboard_held["lshift"] then

                    if not self.selecting_palette then
                        self.selecting_palette = true
                        self.palette_select_rect_start = Vec2(cell_x, cell_y)
                        self.palette_select_rect_end = Vec2(cell_x, cell_y)
						self.palette_select_start = Vec2(cell_x, cell_y)
						self.active_brush = nil
                    else
                        self:palette_selection_update(cell_x, cell_y)
                    end
                -- else
                --     self.palette_select_rect_start = nil
                --     self.palette_select_rect_end = nil
				-- 	self.active_brush = nil
				-- end
				self.active_key = self.active_brush == nil and id or self.active_brush[0][0]
            end
        end


		if self.palette_changed then
			self.swatch_tiles[x] = self.swatch_tiles[x] or {}
            self.swatch_tiles[x][y] = tile
            self.palette_cells[cell_x] = self.palette_cells[cell_x] or {}
            self.palette_cells[cell_x][cell_y] = { x = x, y = y, tile = tile }
            self.palette_swatch_to_cell[tile] = Vec2(cell_x, cell_y)
		end
		
		
        local new_tileset = tilesets.tileset_offsets[i + 1] ~= nil and tilesets.tileset_offsets[i + 1] ~= current_tileset

        x = x + TILE_SIZE
		cell_x = cell_x + 1
        row = row + 1
        
		if row % SWATCH_NUM_COLS == 0 or new_tileset then
            row = 0
            x = self.palette_rect.x + SWATCH_PADDING
            y = y + TILE_SIZE
            cell_x = 1
			cell_y = cell_y + 1
            if self.palette_changed then
                self.palette_rows = self.palette_rows + 1
            end
        end
    end
	
	row = 0
	x = self.palette_rect.x + SWATCH_PADDING
    y = y + TILE_SIZE * 2
	self.palette_separator_y = y


    if self.palette_changed then
		self.object_tiles = {}

		for obj_name, sprite in pairs(tilesets.object_tiles) do
			table.insert(self.object_tiles, {name = obj_name, sprite = sprite})
		end
	
		table.sort(self.object_tiles, function(a, b)
			return a.name < b.name
		end)
	end

    for _,obj in ipairs(self.object_tiles) do
		local obj_name = obj.name
		local obj_sprite = obj.sprite

        if self.screen_mpos.x >= x and self.screen_mpos.x <= x + TILE_SIZE and self.screen_mpos.y >= y and self.screen_mpos.y <= y + TILE_SIZE then
            self.palette_mouse_over_tile = obj_name
            if active_area == "palette" and self.lmb then
                self.active_key = obj_name
            end
        end

        if self.palette_changed then
            self.swatch_tiles[x] = self.swatch_tiles[x] or {}
            self.swatch_tiles[x][y] = obj_name
        end
		
		x = x + TILE_SIZE
        row = row + 1
        if row % SWATCH_NUM_COLS == 0 then
            row = 0
            x = self.palette_rect.x + SWATCH_PADDING
            y = y + TILE_SIZE
            if self.palette_changed then
                self.palette_rows = self.palette_rows + 1
            end
        end
	end

	self.palette_changed = false
end

function LevelEditor:get_active_section()
	if self.state == "draw" then
		if self.painting then
            return "draw"
		elseif self.showing_data_editor and self.screen_mpos.x > self.viewport_size.x - DATA_EDITOR_WIDTH then
			return "data"
		elseif self.selecting_palette then
			return "palette"
		elseif self.screen_mpos.x >= self.viewport_size.x or self.screen_mpos.y >= self.viewport_size.y or self.viewport_size.x < 0 or self.viewport_size.y < 0 then
			return "none"
		elseif not self.showing_ui then
			return "draw"
		elseif self.showing_palette then
			if self.palette_rect:contains(self.screen_mpos.x, self.screen_mpos.y) then
				return "palette"
			end
		end
		return "draw"
	end
end

function LevelEditor:set_selection_rect(x1, y1, x2, y2)
    if x1 ~= nil and y1 ~= nil and x2 == nil then
        y2 = y1.y
        x2 = y1.x
        y1 = x1.y
        x1 = x1.x
    end

    if self.is_recording_changes and not self.is_applying_history then
        if not self.current_selection_changes then
            self.current_selection_changes = {
                old_start = self.select_rect_start and Vec2(self.select_rect_start.x, self.select_rect_start.y) or nil,
                old_finish = self.select_rect_end and Vec2(self.select_rect_end.x, self.select_rect_end.y) or nil,
            }
        end

        self.current_selection_changes.new_start = x1 ~= nil and Vec2(x1, y1) or nil
        self.current_selection_changes.new_finish = x2 ~= nil and Vec2(x2, y2) or nil
    end

    if x1 == nil and y1 == nil and x2 == nil and y2 == nil then
        self.select_rect_start = nil
        self.select_rect_end = nil
        self.select_start = nil
        return
    end

    if self.select_rect_start == nil then
        self.select_rect_start = Vec2(0, 0)
    end
    if self.select_rect_end == nil then
        self.select_rect_end = Vec2(0, 0)
    end
    if self.select_start == nil then
        self.select_start = Vec2(0, 0)
    end

    self.select_rect_start.x = x1
    self.select_rect_start.y = y1
    self.select_rect_end.x = x2
    self.select_rect_end.y = y2
end

function LevelEditor:set_palette_selection_rect(x1, y1, x2, y2)
	if x1 ~= nil and y1 ~= nil and x2 == nil then
		y2 = y1.y
		x2 = y1.x
		y1 = x1.y
		x1 = x1.x
	end

	if x1 == nil and y1 == nil and x2 == nil and y2 == nil then
		self.palette_select_rect_start = nil
		self.palette_select_rect_end = nil
		self.palette_select_start = nil
		return
	end

	if self.palette_select_rect_start == nil then
		self.palette_select_rect_start = Vec2(0, 0)
	end
	if self.palette_select_rect_end == nil then
		self.palette_select_rect_end = Vec2(0, 0)
	end
	if self.palette_select_start == nil then
		self.palette_select_start = Vec2(0, 0)
	end

	self.palette_select_rect_start.x = x1
	self.palette_select_rect_start.y = y1
	self.palette_select_rect_end.x = x2
	self.palette_select_rect_end.y = y2
end

function LevelEditor:update_history()
    if self.current_tile_changes or self.current_selection_changes then
        self.edit_future = {}
        local tile_changes_list = {}
        local changes_list = { tile = tile_changes_list }

        if self.current_tile_changes then
            for _, change in pairs(self.current_tile_changes) do
                table.insert(tile_changes_list, change)
            end
        end

        if self.current_selection_changes then
            changes_list.selection = {
                old_start = self.current_selection_changes.old_start,
                old_finish = self.current_selection_changes.old_finish,
                new_start = self.current_selection_changes.new_start,
                new_finish = self.current_selection_changes.new_finish
            }
        end

        table.insert(self.edit_history, changes_list)
        -- Limit history size to 100
        if #self.edit_history > 10000 then
            table.remove(self.edit_history, 1)
        end

        self.current_tile_changes = {}
        self.current_selection_changes = {}
    end
end

function LevelEditor:begin_action()
    self.current_tile_changes = {}
    self.current_selection_changes = {
        old_start = self.select_rect_start and Vec2(self.select_rect_start.x, self.select_rect_start.y) or nil,
        old_finish = self.select_rect_end and Vec2(self.select_rect_end.x, self.select_rect_end.y) or nil,
    }
    self.is_recording_changes = true
end

function LevelEditor:end_action()
    self.is_recording_changes = false
	self:update_history()

end

function LevelEditor:undo()
    if table.is_empty(self.edit_history) then return end

    local changes = table.pop_back(self.edit_history)
    table.push_back(self.edit_future, changes)

    self.is_applying_history = true
    if changes.tile then
        for _, change in pairs(changes.tile) do
            self:set_tile(change.x, change.y, change.z, change.old_tile)
        end
    end

    if changes.selection then
        local old_start = changes.selection.old_start
        local old_finish = changes.selection.old_finish
        if old_start and old_finish then
            self:set_selection_rect(old_start.x, old_start.y, old_finish.x, old_finish.y)
        else
            self:set_selection_rect(nil, nil, nil, nil)
        end
    end

    self.is_applying_history = false
    self:notify("Undo")
end

function LevelEditor:redo()
    if table.is_empty(self.edit_future) then return end

    local changes = table.pop_back(self.edit_future)
    table.push_back(self.edit_history, changes)

    self.is_applying_history = true
    if changes.tile then
        for _, change in pairs(changes.tile) do
            self:set_tile(change.x, change.y, change.z, change.new_tile)
        end
    end

    if changes.selection then
        local new_start = changes.selection.new_start
        local new_finish = changes.selection.new_finish
        if new_start and new_finish then
            self:set_selection_rect(new_start.x, new_start.y, new_finish.x, new_finish.y)
        else
            self:set_selection_rect(nil, nil, nil, nil)
        end
    end

    self.is_applying_history = false
    self:notify("Redo")
end

function LevelEditor:update_offset(offset_x, offset_y)
	local step_size = TILE_SIZE * self.zoom
	self.offset.x = offset_x
	self.offset.y = offset_y
	self.offset_stepped.x = floor(self.offset.x / step_size) * step_size
    self.offset_stepped.y = floor(self.offset.y / step_size) * step_size
end

function LevelEditor:update_mouse_positions()

	self.screen_mpos.x = input.mouse.pos.x
	self.screen_mpos.y = input.mouse.pos.y
	self.mpos.x = (self.screen_mpos.x - self.offset_stepped.x) / self.zoom
    self.mpos.y = (self.screen_mpos.y - self.offset_stepped.y) / self.zoom
    self.mpos_real.x = (self.screen_mpos.x - self.offset.x) / self.zoom
	self.mpos_real.y = (self.screen_mpos.y - self.offset.y) / self.zoom
	self.mdxy.x = input.mouse.dxy.x
    self.mdxy.y = input.mouse.dxy.y

	if not self.mmb then
		self.mcell.x = floor(self.mpos.x / TILE_SIZE)
		self.mcell.y = floor(self.mpos.y / TILE_SIZE)
	end
	self.mcell.z = self.layer
end

function LevelEditor:update(dt)
	self.prevmpos.x = self.mpos.x
	self.prevmpos.y = self.mpos.y
	
	self:update_mouse_positions()

	self.lmb = input.mouse.lmb
	self.mmb = input.mouse.mmb
	self.rmb = input.mouse.rmb

	self.hovered_tile = self:get_tile(self.mcell.x, self.mcell.y, self.layer)

	self.layer_display_offset = splerp(self.layer_display_offset, self.layer, 90, dt)

    local active_area = self:get_active_section()
	
    if self.showing_palette then
        self:update_palette()
    elseif self.showing_data_editor then
		self:update_data_editor()
    end
	
	if no_tile_draw_paint_modes[self.paint_mode] then
		self.showing_palette = false
	end

	self.painting_tile_changes = nil

	if active_area == "draw" then
		self:update_mouse_drawing_area(dt)
	end

    if self.input.debug_editor_toggle_pressed then
        self:transition_to("MainScreen")
    end
	
	self.showing_data_editor = self.paint_mode == "data"

	if debug.enabled then
		dbg("self.offset", floor(self.offset.x) .. ", " .. floor(self.offset.y))
	end
end

function LevelEditor:flood_fill(cx, cy, cz, tile)
    cz = cz or self.layer
	
	if self.active_brush then
		self.active_brush_start = Vec2(cx, cy)
	end

	if self.tiles[cz] == nil then
		self.tiles[cz] = {}
	end

	local tile_to_change = self:get_tile(cx, cy, cz)

	tile = tile or nil


	if tile == tile_to_change then return end

	local min_x, min_y, min_z, max_x, max_y, max_z = self:get_bounds()

	local solid = {}

	local check_solid = function(c2x, c2y)
        
        local pairing = xy_to_pairing(c2x, c2y)
		if solid[pairing] then
			return true
		end
		
		if self.select_start then
            if not self:is_in_selection(c2x, c2y) then
                return true
            end
        elseif c2x < min_x or c2x > max_x or c2y < min_y or c2y > max_y then
            return true
        end
		
        local check_tile = self:get_tile(c2x, c2y, cz)
		
		if check_tile == tile_to_change then
            return false
        end

		return true
	end
    local fill = function(c2x, c2y)
        local pairing = xy_to_pairing(c2x, c2y)
		solid[pairing] = true
	end
    flood_fill(cx, cy, fill, check_solid, true)
	for pairing, _ in pairs(solid) do
		local x, y = pairing_to_xy(pairing)
		self:brush(x, y, cz, tile, false, true)
	end
end

function LevelEditor:world_to_tile(x, y)
	return floor(x / TILE_SIZE), floor(y / TILE_SIZE)
end

function LevelEditor:tile_to_world(x, y)
	return x * TILE_SIZE, y * TILE_SIZE
end

function LevelEditor:update_data_editor()
    local active_area = self:get_active_section()
    if active_area == "data" then
		self.tile_data_input_box:update()
    end
end

function LevelEditor:draw_data_editor()
    -- local x = self.viewport_size.x - DATA_EDITOR_WIDTH
    -- local y = 0
    -- graphics.set_color(Color.black, 0.25)
    -- graphics.rectangle("fill", x, y, DATA_EDITOR_WIDTH, self.viewport_size.y)
	self.tile_data_input_box:draw_shared()
end


function LevelEditor:get_painting_bounds()
	if self.painting_tile_changes == nil then
		return 0, 0, 0, 0, 0, 0
	end
	local min_x = math.huge
	local min_y = math.huge
	local min_z = math.huge
	local max_x = -math.huge
	local max_y = -math.huge
	local max_z = -math.huge

	for z, layer in pairs(self.painting_tile_changes) do
		for y, row in pairs(layer) do
			for x, _ in pairs(row) do
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				min_z = min(min_z, z)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
				max_z = max(max_z, z)
			end
		end
	end

	return min_x, min_y, min_z, max_x, max_y, max_z
end

function LevelEditor:get_layer_bounds(layer)
	layer = layer or self.layer
	local min_x = math.huge
	local min_y = math.huge
	local max_x = -math.huge
	local max_y = -math.huge

	if self.tiles[layer] == nil then
		return 0, 0, 0, 0
	end

	for y, row in pairs(self.tiles[layer]) do
		for x, _ in pairs(row) do
			if self:get_tile(x, y, layer) == nil then
				self:set_tile(x, y, layer, nil)
			else
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
			end
		end
	end
	return min_x, min_y, max_x, max_y
end

function LevelEditor:get_bounds(tiles)
	local min_x = math.huge
	local min_y = math.huge
	local min_z = math.huge
	local max_x = -math.huge
	local max_y = -math.huge
	local max_z = -math.huge

	for z, layer in pairs(tiles or self.tiles) do
		for y, row in pairs(layer) do
            for x, _ in pairs(row) do
				if tiles == self.tiles and self:get_tile(x, y, z) == nil then
					self:set_tile(x, y, z, nil)
				else
					min_x = min(min_x, x)
					min_y = min(min_y, y)
					min_z = min(min_z, z)
					max_x = max(max_x, x)
					max_y = max(max_y, y)
					max_z = max(max_z, z)
				end
			end
		end
	end

	return min_x, min_y, min_z, max_x, max_y, max_z
end

function LevelEditor:get_draw_bounds() -- includes painting bounds
	if self.painting_tile_changes == nil then
		return self:get_bounds()
	end
	local min_x, min_y, min_z, max_x, max_y, max_z = self:get_bounds()
	local pmin_x, pmin_y, pmin_z, pmax_x, pmax_y, pmax_z = self:get_painting_bounds()
	min_x = min(min_x, pmin_x)
	min_y = min(min_y, pmin_y)
	min_z = min(min_z, pmin_z)
	max_x = max(max_x, pmax_x)
	max_y = max(max_y, pmax_y)
	max_z = max(max_z, pmax_z)
	return min_x, min_y, min_z, max_x, max_y, max_z
end

function LevelEditor:enter()
    self:update_history()
    self.tile_data_input_box = self:add_object(TextInputBox(self.viewport_size.x - DATA_EDITOR_WIDTH, 8, DATA_EDITOR_WIDTH, self.viewport_size.y - 16))
    love.keyboard.setKeyRepeat(true)
	audio.stop_music()
end

function LevelEditor:exit()
	love.keyboard.setKeyRepeat(self.old_key_repeat)
end

function LevelEditor:tile_is_object(tile)
    return tile and tilesets.object_tiles[tile]
end

function LevelEditor:draw()
	self.clear_color = (self.showing_grid == 2) and self.grid_bgcolor or Color.black
	LevelEditor.super.draw(self)
	graphics.push()
	graphics.origin()
    graphics.set_color(Color.white)
    graphics.translate(floor(self.offset_stepped.x), floor(self.offset_stepped.y))
	graphics.scale(self.zoom, self.zoom)
	graphics.set_font(fonts["PixelOperatorMono8-Bold"])

	-- if debug.can_draw() then
	-- end
	local active_section = self:get_active_section()

	self:draw_tiles()

	if (self.showing_grid ~= 0) then
		self:draw_level_grid()
	end

	local tile_at_mouse = self:get_tile(self.mcell.x, self.mcell.y, self.layer)


    if active_section == "draw" then
        graphics.set_color(Color.black)
        -- graphics.print(key_string, self.mpos.x + 2, self.mpos.y + 2)
        -- graphics.points(self.mpos.x + 1, self.mpos.y + 1)


        graphics.set_color(1, 1, 1, 0.25)

        graphics.set_color(Color.white)
        -- if tilesets.tileset_tiles[self.active_key] then

        if not no_tile_draw_paint_modes[self.paint_mode] then
            if self.active_brush then
                if not self.painting then
                    self.active_brush_start = self.active_brush_start or Vec2(self.mcell.x, self.mcell.y)
                    self.active_brush_start.x = self.mcell.x
                    self.active_brush_start.y = self.mcell.y
                    for y = 0, self.active_brush_size.y do
                        for x = 0, self.active_brush_size.x do
                            local tile = self.active_brush[y] and self.active_brush[y][x]
                            if tile then
                                self:tile_draw(tile, (self.mcell.x + x) * TILE_SIZE, (self.mcell.y + y) * TILE_SIZE)
                            end
                        end
                    end
                end
            else
                self:tile_draw(self.active_key, self.mcell.x * TILE_SIZE, self.mcell.y * TILE_SIZE)
            end
        end

        graphics.set_color(Color.white, 0.75)
        -- tilesets.tileset_tiles[self.active_key]:draw(self.mcell.x * TILE_SIZE, self.mcell.y * TILE_SIZE)
        graphics.set_color(Color.white, 0.35)

        graphics.rectangle("line", self.mcell.x * TILE_SIZE, self.mcell.y * TILE_SIZE, TILE_SIZE + 1, TILE_SIZE + 1)
    end

	self:draw_selection()
	

	graphics.set_color(Color.white)

	-- graphics.points(self.mpos.x, self.mpos.y)

	graphics.origin()

    if debug.enabled then
        dbg("mcell", self.mcell)
        dbg("mpos", self.mpos)
    end
	
	graphics.set_font(fonts["PixelOperator8"])
	if self.showing_ui then
		graphics.set_color(Color.black, 0.5)
		graphics.rectangle("fill", 0, 0, self.viewport_size.x, 8)

		graphics.set_color(Color.white)
		graphics.print(self.paint_mode, 0, 0)
		graphics.push("all")
        graphics.set_font(fonts["PixelOperatorMono8"])
		graphics.set_color("3ae")
        local roomx, roomy = world_to_room(self.mpos.x, self.mpos.y)
		local room_id = world_to_room_id(self.mpos.x, self.mpos.y)
		graphics.print(string.format("%+4i,%+4i,%+3i,%+3i,%3i", self.mcell.x, self.mcell.y, roomx, roomy, room_id), 32, 0)
		graphics.pop()

        if self.palette_mouse_over_tile then
			graphics.set_color(Color.pink)
		end
		graphics.printf(tostring(self.palette_mouse_over_tile and self.palette_mouse_over_tile or self.active_key), 0, 0, self.viewport_size.x, "right")

		graphics.set_color(Color.black, 0.5)
		graphics.rectangle("fill", 0, self.viewport_size.y - 8, self.viewport_size.x, 8)

		self:draw_layer_offset()

        if self.showing_palette then
            self:draw_palette()
		elseif self.showing_data_editor then 
			self:draw_data_editor()
		end
		
	end

	if self.notify_text ~= "" then
		graphics.set_color(Color.white, self.notify_text_alpha)
		graphics.print(self.notify_text, 0, self.viewport_size.y - 8)
		
	end


	graphics.pop()
end

function LevelEditor:draw_selection()
    if self.select_rect_end == nil or self.select_rect_start == nil then
        return
    end

    local start_x = self.select_rect_start.x * TILE_SIZE
    local start_y = self.select_rect_start.y * TILE_SIZE
    local end_x = self.select_rect_end.x * TILE_SIZE
    local end_y = self.select_rect_end.y * TILE_SIZE

    if end_x >= start_x then
        end_x = end_x + TILE_SIZE
    else
        start_x = start_x + TILE_SIZE
    end
    if end_y >= start_y then
        end_y = end_y + TILE_SIZE
    else
        start_y = start_y + TILE_SIZE
    end

    graphics.push("all")
    graphics.origin()
    graphics.translate(self.offset_stepped.x, self.offset_stepped.y)
    graphics.scale(1, 1)
    graphics.set_color(floor(self.tick / 5) % 2 == 0 and Color.black or Color.white)
    local x, y, w, h = min(start_x, end_x) * self.zoom, min(start_y, end_y) * self.zoom, abs(end_x - start_x) * self
    .zoom, abs(end_y - start_y) * self.zoom
    graphics.rectangle("line", x, y, w, h)
    graphics.set_color(floor(self.tick / 5) % 2 == 0 and Color.white or Color.black)
    graphics.dashrect(x, y, w, h, 2, 2)

    graphics.pop()
end

function LevelEditor:draw_palette_selection()
	if self.palette_select_rect_start == nil or self.palette_select_rect_end == nil then
        return
    end

	if self.palette_select_rect_start == self.palette_select_rect_end then
		return
	end
	
    local start_x = self.palette_select_rect_end.x * TILE_SIZE
    local start_y = self.palette_select_rect_end.y * TILE_SIZE
    local end_x = (self.palette_select_rect_start.x) * TILE_SIZE
    local end_y = (self.palette_select_rect_start.y) * TILE_SIZE

    if end_x >= start_x then
        end_x = end_x + TILE_SIZE
    else
		start_x = start_x + TILE_SIZE
	end
    if end_y >= start_y then
        end_y = end_y + TILE_SIZE
    else
		start_y = start_y + TILE_SIZE
	end

    graphics.set_color(floor(self.tick / 5) % 2 == 0 and Color.black or Color.white)
	local x, y, w, h = min(start_x, end_x), min(start_y, end_y), abs(end_x - start_x), abs(end_y - start_y)
	graphics.rectangle("line", x, y, w, h)
    graphics.set_color(floor(self.tick / 5) % 2 == 0 and Color.white or Color.black)
	graphics.dashrect(x, y, w, h, 2, 2)

end

function LevelEditor:draw_palette()
	graphics.push()
	graphics.origin()
	graphics.set_color(Color.black, 0.5)
	graphics.rectangle("fill", self.palette_rect.x, self.palette_rect.y, self.palette_rect.width,
		self.palette_rect.height)
	graphics.set_color(Color.white)
	local hover_x, hover_y = nil, nil
	local active_x, active_y = nil, nil
	local print_x, print_y = nil, nil
    local print_text = nil
    local object_selected = nil
	local object_hovered = nil

	
	for object, _ in pairs(tilesets.object_tiles) do
		if self.active_key == object then
			object_selected = object
			break
		end
	end

	for object, _ in pairs(tilesets.object_tiles) do
		if self.palette_mouse_over_tile == object then
			object_hovered = object
			break
		end
	end
	for x, row in pairs(self.swatch_tiles) do
        for y, tile in pairs(row) do
			if y + self.palette_scroll_offset * TILE_SIZE <= 1 then goto continue end
            y = y + self.palette_scroll_offset * TILE_SIZE
            if type(tile) == "string" then
                local sprite = textures[tilesets.object_tiles[tile]]
					if sprite then
					local w = sprite:getWidth()
					local h = sprite:getHeight()
					local scale_x = TILE_SIZE / w
					local scale_y = TILE_SIZE / h
                    graphics.draw(sprite, x, y, 0, min(scale_x, 1), min(scale_y, 1))
                else
					graphics.print(tilesets.object_tiles[tile], x, y)
				end
			else
				tile:draw(x, y)
			end 
			if tile == tilesets.tileset_tiles[self.palette_mouse_over_tile] or (object_hovered and tile == self.palette_mouse_over_tile) then

				hover_x, hover_y = x, y
				print_x, print_y = x, y
                print_text = tostring(self.palette_mouse_over_tile)
                if not object_hovered then
                    print_text = print_text:sub(3)
				end
			end

			if tile == tilesets.tileset_tiles[self.active_key] or object_selected == tile then
				active_x, active_y = x, y
			end

			::continue::
		end
	end


	graphics.set_color(Color.white, 0.25)
	graphics.line(self.palette_rect.x, self.palette_separator_y - TILE_SIZE, self.palette_rect.x + self.palette_rect.width, self.palette_separator_y - TILE_SIZE)


	if hover_x and hover_y then
		graphics.set_color(Color.white, 0.5)
		graphics.rectangle("line", hover_x, hover_y, TILE_SIZE + 1, TILE_SIZE + 1)
	end

	if active_x and active_y then
		graphics.set_color(Color.white, 0.5)
		graphics.rectangle("line", active_x, active_y, TILE_SIZE + 1, TILE_SIZE + 1)
	end

    if print_x and print_y and print_text then
        graphics.set_color(Color.white)
        graphics.print_outline(Color.black, print_text, print_x, print_y)
    end
	
	

	if self.palette_select_rect_start and self.palette_select_rect_end then
	
        graphics.push("all")
		graphics.origin()
        graphics.translate(self.palette_x - TILE_SIZE, self.palette_rect.y + SWATCH_PADDING + self.palette_scroll_offset * TILE_SIZE - TILE_SIZE)
		
        self:draw_palette_selection()
		
		graphics.pop()

	end


	graphics.pop()
end

function LevelEditor:draw_layer_offset()
	graphics.push("all")
	graphics.origin()
	local font = fonts["PixelOperator8"]
	graphics.set_font(font)

	local height = 80
	local bar_separation = 6
	local bar_thickness = 2
	local bar_width = 3
	local total_bar_height = bar_thickness + bar_separation
	local num_bars = floor(height / total_bar_height)

	local top = self.viewport_size.y / 2 - (height / 2)
	local bottom = self.viewport_size.y / 2 + (height / 2)
	local horiz = TILE_SIZE / 2

	graphics.set_color(Color.black, 0.5)
	graphics.rectangle("fill", horiz - 4, top - 4, 8, height + 8)

	graphics.push()
	for i = ceil(-num_bars / 2), floor(num_bars / 2) do
		local bar_layer = (-i + self.layer)
		local yoffs = ((i + num_bars / 2 + (self.layer_display_offset - self.layer)) * total_bar_height) -
			total_bar_height / (num_bars * 2) - bar_thickness / 2

		if abs(yoffs - height) < 0.01 then yoffs = 0 end
		if yoffs < -2 or yoffs > height then
			goto continue
		end

		local y = top + yoffs


		local color = Color.grey

		if bar_layer == self.layer then
			color = Color.white
		end

		if bar_layer % 10 == 0 or bar_layer == self.layer then
			local string = tostring(bar_layer)
			graphics.set_color(Color.black, 0.5)
			graphics.rectangle("fill", horiz + 4, y - 4, font:getWidth(string) + 1, 8)
			graphics.set_color(Color.white, 0.5)
			graphics.print(string, horiz + 4, y - 4)
		end
		graphics.push("all")
		if self.tiles[bar_layer] == nil or table.is_empty(self.tiles[bar_layer]) then
			graphics.set_color(color, 0.05)
			graphics.rectangle("fill", horiz - bar_width / 2, y, bar_width, bar_thickness)
		else
			graphics.set_color(color, 1)
			graphics.rectangle("fill", horiz - bar_width / 2, y, bar_width, bar_thickness)
		end
		graphics.pop()

		::continue::
	end
	graphics.pop()

	graphics.set_color(Color.white, 0.25)


	graphics.line(horiz, top, horiz, bottom)


	graphics.points(horiz, top - 2)

	graphics.push("all")
	graphics.set_color(Color.white, 1)

	graphics.points(horiz - 3, (top + bottom) / 2)
	graphics.points(horiz - 3, (top + bottom) / 2 + 1)

	graphics.pop()

	graphics.points(horiz, bottom + 3)

	graphics.pop()
end

function LevelEditor:tile_draw(tile_id, x, y)
	graphics.set_font(fonts["PixelOperatorMono8-Bold"])
	local sprite = tilesets.tileset_tiles[tile_id]
	if sprite then
		if sprite.draw then
			sprite:draw(x, y)
		else
			graphics.draw(tilesets.tileset_tiles[tile_id], x, y)
		end
    elseif type(tile_id) == "string" then
        if tilesets.object_tiles[tile_id] then
            if not textures[tilesets.object_tiles[tile_id]] then
				graphics.print(tilesets.object_tiles[tile_id], x, y)
			else
				graphics.draw_centered(textures[tilesets.object_tiles[tile_id]], x + TILE_SIZE / 2, y + TILE_SIZE / 2)
			end
        else 
			graphics.print(tile_id, x, y)
		end
    else
		graphics.print(tostring(tile_id), x, y)
	end
end

function LevelEditor:tile_color(tile_id)
	if tilesets.tileset_tiles[tile_id] then
		return Color.white
	end
	if type(tile_id) == "number" then
		return Color.red
	end
	if tile_id == nil then
		return Color.black
	end
	if tile_id == "#" or tile_id == "." then
		return Color.grey
	end
	if string.match("0123456789", tile_id) then
		return Color.green
	end
	return Color.white
end

function LevelEditor:draw_tiles()
	graphics.push()
	local camera_min_x, camera_min_y, camera_max_x, camera_max_y = -self.offset_stepped.x / self.zoom, -self.offset_stepped.y / self.zoom,
		(self.viewport_size.x) / self.zoom - self.offset_stepped.x / self.zoom, (self.viewport_size.y) / (self.zoom) - self.offset_stepped.y / self.zoom
	local min_x = floor(camera_min_x / TILE_SIZE)
	local min_y = floor(camera_min_y / TILE_SIZE)
	local max_x = floor(camera_max_x / TILE_SIZE)
	local max_y = floor(camera_max_y / TILE_SIZE)


	local bounds_min_x, bounds_min_y, bounds_min_z, bounds_max_x, bounds_max_y, bounds_max_z = self:get_draw_bounds()

	-- if x >= bounds_min_x and x <= bounds_max_x and y >= bounds_min_y and y <= bounds_max_y then
	graphics.set_color(Color.black, 1)
	graphics.rectangle("fill", bounds_min_x * TILE_SIZE, bounds_min_y * TILE_SIZE,
		(bounds_max_x - bounds_min_x + 1) * TILE_SIZE, (bounds_max_y - bounds_min_y + 1) * TILE_SIZE)

	local show_all_layers = (self.layer_display_type == LAYER_DISPLAY_CURRENT_HIGHLIGHTED or self.layer_display_type == LAYER_DISPLAY_ALL)
	local min_z = show_all_layers and bounds_min_z or self.layer
	local max_z = show_all_layers and bounds_max_z or self.layer
	local fade_layers = self.layer_display_type == LAYER_DISPLAY_CURRENT_HIGHLIGHTED

	if debug.enabled then
		dbg("bounds",
			tostring(min_x) ..
			", " ..
			tostring(min_y) ..
			", " .. tostring(min_z) .. ", " .. tostring(max_x) .. ", " .. tostring(max_y) .. ", " .. tostring(max_z))
	end

	local object_print_at = {}

	for y = min_y, max_y do
		for x = min_x, max_x do
			for z = min_z, max_z do
				local tile = self:get_tile(x, y, z)
				local painting_tile = self:get_painting_tile_change(x, y, z)

				if painting_tile then
					tile = painting_tile
				end

                if tile then
                    local color = self:tile_color(tile)

                    graphics.set_color(color)

                    if fade_layers then
                        local dist = abs(z - self.layer)
                        local fade = pow(LAYER_FADE_AMOUNT, dist)
                        graphics.set_color(color, fade)
                    end

                    self:tile_draw(tile, x * TILE_SIZE, y * TILE_SIZE)
                end
				if self:tile_is_object(tile) and tilesets.object_tiles[tile] and textures[tilesets.object_tiles[tile]] and x == self.mcell.x and y == self.mcell.y then
					object_print_at[#object_print_at + 1] = {
						tile = tile,
						x = x,
						y = y,
						z = z
					}
				end
			end
		end
	end

    graphics.push("all")
    graphics.set_color(Color.white)
	graphics.set_font(fonts["PixelOperatorMono8-Bold"])
    for i, t in pairs(object_print_at) do
		if t.z == self.layer then
			graphics.print_outline(Color.black, tostring(t.tile), t.x * TILE_SIZE, t.y * TILE_SIZE)
		end
	end
	graphics.pop()
	graphics.pop()
end

function LevelEditor:draw_level_grid()
	graphics.push()
	graphics.set_color(1, 1, 1, 0.05)

	local start_x = floor((floor(-self.offset.x / TILE_SIZE - 2) * TILE_SIZE) / self.zoom)
	local end_x = floor(start_x + floor(graphics.main_viewport_size.x / TILE_SIZE + 4) * TILE_SIZE / self.zoom)
	local start_y = floor((floor(-self.offset.y / TILE_SIZE - 2) * TILE_SIZE) / self.zoom)
	local end_y = floor(start_y + floor(graphics.main_viewport_size.y / TILE_SIZE + 4) * TILE_SIZE / self.zoom)
    for i = 1, (graphics.main_viewport_size.x / self.zoom) / TILE_SIZE + 3 / self.zoom do
		
		graphics.set_color(1, 1, 1, 0.02)
        if floor((start_x + (i) * TILE_SIZE)) % self.room_size.x == 0 then
            graphics.set_color(1, 1, 1, 0.10)
            if floor((start_x + (i) * TILE_SIZE)) % (self.room_size.x * 4) == 0 then
                graphics.set_color(1, 1, 1, 0.25)
            end
			if floor((start_x + (i) * TILE_SIZE)) % (self.room_size.x * 16) == 0 then
				graphics.set_color(1, 1, 1, 0.50)
			end
        elseif self.zoom_level >= 3 or self.showing_grid == 1 then
            goto continue
        end
		for j=1, (self.zoom_level) do 
			graphics.line(start_x + i * TILE_SIZE+j, start_y, start_x + i * TILE_SIZE+j, end_y)
		end
		::continue::
	end
	for i = 1, (graphics.main_viewport_size.y / self.zoom) / TILE_SIZE + 3 / self.zoom do
		graphics.set_color(1, 1, 1, 0.02)
        if floor((start_y + (i) * TILE_SIZE)) % self.room_size.y == 0 then
            graphics.set_color(1, 1, 1, 0.10)
            if floor((start_y + (i) * TILE_SIZE)) % (self.room_size.y * 4) == 0 then
                graphics.set_color(1, 1, 1, 0.25)
            end
            if floor((start_y + (i) * TILE_SIZE)) % (self.room_size.y * 16) == 0 then
                graphics.set_color(1, 1, 1, 0.50)
            end
        elseif self.zoom_level >= 3 or self.showing_grid == 1 then
            goto continue
        end


		for j=1, (self.zoom_level) do 
			graphics.line(start_x, start_y + i * TILE_SIZE+j, end_x, start_y + i * TILE_SIZE+j)
		end
	    ::continue::
	end

	graphics.pop()
end



return LevelEditor
