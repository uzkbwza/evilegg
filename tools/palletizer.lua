-- Remove these as we won't need them anymore
-- local ffi = require('ffi')
-- local is_windows = package.config:sub(1,1) == '\\'
-- local list_command = is_windows and 'dir /b "' or 'ls "'
-- local ffi = require('ffi')
-- ... existing code ...

local decode_png = require("lib.png")

local SEPARATOR = "/"  -- LÖVE always uses forward slashes internally

-- Remove the ffi.cdef blocks as we won't need them

local function get_png_files(directory, png_files)
	-- print(directory)
    png_files = png_files or {}
    if directory == "assets/sprite/palettized" then
        return png_files
    end
	if directory == "assets/sprite/palette" then
		return png_files
	end
    
    -- Use love.filesystem.getDirectoryItems instead of io.popen
    local files = love.filesystem.getDirectoryItems(directory)
    for _, file in ipairs(files) do
        local full_path = directory .. SEPARATOR .. file
        if string.lower(string.sub(file, -4)) == ".png" then
            -- Use love.filesystem.getInfo instead of io.open
            if love.filesystem.getInfo(full_path, "file") then
                table.insert(png_files, full_path)
            end
        end
		if love.filesystem.getInfo(full_path, "directory") then
			get_png_files(full_path, png_files)
		end
    end
    
    return png_files
end

local function check_indexed_color(png_path)
    -- Use love.filesystem.read instead of io.open
    local contents = love.filesystem.read(png_path)
    if not contents then
        print(string.format("Error opening %s", png_path))
        return false
    end

    local success, result = pcall(function()
        local pos = 9  -- skip PNG signature (8 bytes)

        -- Read IHDR chunk length (4 bytes)
        local length = (string.byte(contents, pos) * 16777216) +
                      (string.byte(contents, pos + 1) * 65536) +
                      (string.byte(contents, pos + 2) * 256) +
                      string.byte(contents, pos + 3)
        pos = pos + 4

        -- Check chunk type
        local chunk_type = contents:sub(pos, pos + 3)
        if chunk_type ~= "IHDR" then
            return false
        end

        pos = pos + 12  -- Skip chunk type (4) + width and height (8)

        -- Read bit depth and color type
        local bit_depth = string.byte(contents, pos)
        local color_type = string.byte(contents, pos + 1)
        
        return color_type == 3
    end)

    if not success then
        print(string.format("Error reading %s: %s", png_path, result))
        return false
    end

    return result
end

local function main()
    local sprites_dir = "assets/sprite"
    
    if not love.filesystem.getInfo(sprites_dir, "directory") then
        print(string.format("Directory not found: %s", sprites_dir))
        return
    end

    local png_files = get_png_files(sprites_dir)
    local indexed_pngs = {}

    for _, png_file in ipairs(png_files) do
        if check_indexed_color(png_file) then
            table.insert(indexed_pngs, png_file)
        end
    end

	local png_data = {}

    if #indexed_pngs > 0 then
        -- print("Found indexed color PNGs:")
        -- for _, png in ipairs(indexed_pngs) do
            -- print("- " .. png)
        -- end
        for _, png in ipairs(indexed_pngs) do
			local new_png = decode_png(png, nil, false, false, true)
			new_png.path = png
            table.insert(png_data, new_png)
        end
    else
        print("No indexed color PNG files found")
        return {}
    end


	local encode_palette_shader = graphics.shader.encode_palette
	local decode_palette_shader = graphics.shader.decode_palette

	-- local custom_palette = {
    --     Color.red,
	-- 	Color.red:lerp(Color.orange, 0.5),
    --     Color.orange,
	-- 	Color.orange:lerp(Color.yellow, 0.5),
    --     Color.yellow,
	-- 	Color.yellow:lerp(Color.white, 0.5),
    --     Color.white,
	-- 	Color.white:lerp(Color.green, 0.5),
	-- 	Color.green,
	-- 	Color.green:lerp(Color.blue, 0.5),
	-- 	Color.blue,
	-- 	Color.blue:lerp(Color.purple, 0.5),
	-- 	Color.purple,
	-- 	Color.purple:lerp(Color.red, 0.5),
    -- }
	
    -- local custom_palette_object = Palette(custom_palette)
	
    local palette_cache = {}
	local texture_palettes = {}

	filesystem.remove_directory_native("assets/sprite/palette/auto")
	filesystem.remove_directory_native("assets/sprite/palettized")

	-- filesystem.create_directory("assets/sprite/palette/auto")
	-- filesystem.create_directory("assets/sprite/palettized")

    for i, png in ipairs(png_data) do
		-- TODO: shader instead?
        local original_image = graphics.textures[png.path]
		local name = graphics.texture_names[png.path]
        local width, height = original_image:getWidth(), original_image:getHeight()
		-- print("processing " .. name)
        local canvas = graphics.new_canvas(width, height)
		canvas:setFilter("nearest", "nearest")

        local palette_size = min(256, #png.palette)

		local palette_table = {}

        local palette_image_data = love.image.new_image_data(palette_size, 1)
        for j, color in ipairs(png.palette) do
            palette_table[j] = color
            palette_image_data:setPixel(j - 1, 0, color.r, color.g, color.b, color.a)
        end
        
        local palette_object = Palette(palette_table)

		local existing_palette = false
		local palette_index = -1

		for i, v in ipairs(palette_table) do
			if palette_cache[i] == palette_object then
				-- print("palette already exists")
				existing_palette = true
				palette_index = i
				break
			end
		end

        if not existing_palette then
			palette_index = #palette_cache + 1
			palette_cache[palette_index] = palette_object
		end

		texture_palettes[palette_index] = texture_palettes[palette_index] or {}
		table.insert(texture_palettes[palette_index], png.path)

		local localized_path = string.gsub(png.path, "assets/sprite/", "")

		if not existing_palette then
			filesystem.save_file_native(palette_image_data:encode("png"):getString(), "assets/sprite/palette/auto/" .. tostring(palette_index) .. ".png")
		end
		
		graphics.push("all")
		graphics.set_canvas(canvas)
        graphics.clear()
		encode_palette_shader:send("palette", palette_object:to_shader_table())
		encode_palette_shader:send("palette_size", palette_size)
		graphics.set_shader(encode_palette_shader)
        graphics.draw(original_image)
		graphics.set_shader()

		graphics.set_canvas()

        local processed_image_data = graphics.readback_texture(canvas)
		

        graphics.pop()
		
        -- print("saving " .. "assets/sprite/palettized/" .. localized_path)
		filesystem.save_file_native(processed_image_data:encode("png"):getString(), "assets/sprite/palettized/" .. localized_path)

		-- local decoded_image = graphics.new_image(processed_image_data)

		-- custom_palette_object = palette_object
		
        -- local custom_palette_length = custom_palette_object:get_length()
        -- for j = 0, (custom_palette_length * 1) - 1 do

		-- 	graphics.push("all")
		-- 	graphics.set_canvas(canvas)
		-- 	graphics.clear()
		-- 	decode_palette_shader:send("palette", custom_palette_object:to_shader_table())
		-- 	decode_palette_shader:send("palette_size", custom_palette_length)
		-- 	decode_palette_shader:send("palette_offset", j)
		-- 	graphics.set_shader(decode_palette_shader)
		-- 	graphics.draw(decoded_image)
		-- 	graphics.set_shader()
		-- 	graphics.set_canvas()
			
		-- 	graphics.pop()

		-- 	local decoded_image_data = graphics.readback_texture(canvas)
		-- 	filesystem.save_file_native(decoded_image_data:encode("png"):getString(), "tools/sprites/indexed_" .. name .. "_decoded_" .. tostring(j) .. ".png")
		-- end
        -- Second pass with palette lookup
        -- local new_data_2 = processed_image_data:clone()
        -- local pointer2 = ffi.cast("uint8_t*", new_data_2:getFFIPointer())
        
        -- for j = 0, 4*(width * height)-1, 4 do
        --     local r, g, b, a = pointer2[j], pointer2[j+1], pointer2[j+2], pointer2[j+3]
        --     r, g, b, a = Color.decode_palette_unpacked(r/255, g/255, b/255, a/255, png.palette)
        --     -- Convert back to bytes (0-255)
        --     pointer2[j] = r * 255
        --     pointer2[j+1] = g * 255
        --     pointer2[j+2] = b * 255
        --     pointer2[j+3] = a * 255
        -- end

        -- local bytes_2 = new_data_2:encode("png")
        -- filesystem.save_file_native(bytes_2:getString(), "tools/sprites/indexed_" .. tostring(i) .. "_decoded.png")
    end

	filesystem.save_file_native(table.serialize(texture_palettes), "assets/sprite/data/texture_palettes.lua")

	print("palettized sprites")
    return png_data
end

return main
