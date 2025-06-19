local utf8 = require "utf8"
local read_png = require "lib.png"


require "lib.color"

local graphics = {
    canvas = nil,
	scaled_canvas = nil,
    pre_canvas_draw_function = nil,
	screen_shader_canvases = {},
	sequencer = Sequencer(),
	packer = nil,
	texture_paths = nil,
    texture_names = nil,
	palettized = nil,
	depalettized = nil,
	textures = nil,
    texture_data = nil,
	sprite_paths = nil,
	layer_tree = nil,
	interp_fraction = 0,
	shader = require "shader.shader",
	main_canvas_start_pos = Vec2(0, 0),
	main_canvas_size = Vec2(0, 0),
	main_canvas_scale = 1,
    main_viewport_size = Vec2(0, 0),
    window_size = Vec2(0, 0),
	screen_rumble_intensity = 0,
    bg_image = nil,
	circles = {},
	png_data = {},
}

graphics = setmetatable(graphics, { __index = love.graphics })

local window_width, window_height = 0, 0
local window_size = Vec2(window_width, window_height)
local viewport_size = Vec2(conf.viewport_size.x, conf.viewport_size.y)
local max_width_scale = 1
local max_height_scale = 1
local viewport_pixel_scale = 1
local canvas_size = viewport_size * viewport_pixel_scale
local canvas_pos = window_size / 2 - (canvas_size) / 2
local viewport_size_shader = { 0,  0} 
local canvas_pos_shader = { 0, 0 }
local canvas_size_shader = { 0, 0 }

function graphics.load_textures(texture_atlas)
	texture_atlas = texture_atlas or false

	local packer = nil

	local textures = {}
    local texture_data = {}
    local texture_names = {}
    local texture_paths = {}
	print("loading textures")
    local palettized = {}
	local depalettized = {}
	local sprite_paths = filesystem.get_files_of_type("assets/sprite", "png", true)
	local image_settings = {
		mipmaps = false,
		linear = false,
	}

	local texture_count = 0

	for _, path in ipairs(sprite_paths) do
		local tex = graphics.new_image(path, image_settings)
		local data = graphics.readback_texture(tex)
        local name = filesystem.filename_to_asset_name(path, "png", "sprite_")
		if textures[name] then
			asset_collision_error(name, path, texture_paths[name])
		end

        texture_names[name] = name
		texture_names[tex] = name
        texture_names[data] = name
        texture_names[path] = name
		
        texture_paths[tex] = path
		texture_paths[data] = path
		texture_paths[path] = path
        texture_paths[name] = path
		
		textures[tex] = tex
		textures[data] = tex
		textures[path] = tex
        textures[name] = tex
		
        texture_data[tex] = data
        texture_data[data] = data
        texture_data[path] = data
        texture_data[name] = data

		texture_count = texture_count + 1
	end

	dbg("num textures loaded", texture_count)


	if packer then
		packer:bake()
	end

	
    local palette_paths = filesystem.get_files_of_type("assets/sprite/palette", "png", true)

	Palette.paths = {}


	local texture_palette_file = filesystem.read("assets/sprite/data/texture_palettes.lua")


    if texture_palette_file then
		
		local texture_palettes = table.deserialize(texture_palette_file)

		for _, path in ipairs(palette_paths) do
			local palette = Palette.from_image_data(texture_data[path])
	
            local name = filesystem.filename_to_asset_name(path, "png", "sprite_palette_")
			if Palette[name] then
				-- asset_collision_error(name, path, Palette.paths[name])
			end
	
            if name:find("auto_") == 1 then
                local palette_id = tonumber(name:sub(6))
                if texture_palettes[palette_id] then
                    for _, ref_texture_path in ipairs(texture_palettes[palette_id]) do
                        local ref_texture = textures[ref_texture_path]
						if not ref_texture then
							print("ref_texture not found", ref_texture_path)
							goto continue
						end
                        local ref_texture_name = texture_names[ref_texture_path]
                        local ref_texture_data = texture_data[ref_texture_path]
                        local palettized_ref_texture_name = "palettized_" .. ref_texture_name
                        local palettized_ref_texture = textures[palettized_ref_texture_name]
                        if palettized_ref_texture == nil then
							goto continue
						end
                        local palettized_ref_texture_path = texture_paths[palettized_ref_texture_name]
						local palettized_ref_texture_data = texture_data[palettized_ref_texture_path]
						
                        Palette[palettized_ref_texture] = palette
                        Palette[palettized_ref_texture_path] = palette
                        Palette[palettized_ref_texture_name] = palette
                        Palette[palettized_ref_texture_data] = palette
                        Palette[ref_texture] = palette
                        Palette[texture_data[ref_texture_path]] = palette
                        Palette[ref_texture_name] = palette
                        Palette[ref_texture_path] = palette

						palettized[ref_texture_path] = palettized_ref_texture
                        palettized[ref_texture_name] = palettized_ref_texture
						palettized[ref_texture] = palettized_ref_texture
                        palettized[ref_texture_data] = palettized_ref_texture
						palettized[palettized_ref_texture_path] = palettized_ref_texture
						palettized[palettized_ref_texture_name] = palettized_ref_texture
                        palettized[palettized_ref_texture_data] = palettized_ref_texture
						palettized[palettized_ref_texture] = palettized_ref_texture
						
						depalettized[palettized_ref_texture] = ref_texture
						depalettized[palettized_ref_texture_path] = ref_texture
						depalettized[palettized_ref_texture_name] = ref_texture
                        depalettized[palettized_ref_texture_data] = ref_texture
						depalettized[ref_texture] = ref_texture
						depalettized[ref_texture_path] = ref_texture
						depalettized[ref_texture_name] = ref_texture
                        depalettized[ref_texture_data] = ref_texture
						::continue::
					end
				end
			end
	
			Palette[texture_paths[path]] = palette
			Palette[textures[path]] = palette
			Palette[texture_data[path]] = palette
			Palette[texture_names[path]] = palette
			Palette[palette] = palette
            Palette[name] = palette
            Palette.paths[name] = path
			Palette.paths[path] = path
			Palette.paths[textures[path]] = path
			Palette.paths[texture_data[path]] = path
			Palette.paths[texture_names[path]] = path
			Palette.paths[palette] = path
			palette.palette_image = textures[path]
			palette:make_readonly()
		end


	end

	graphics.packer = packer
	graphics.textures = textures
	graphics.texture_data = texture_data
    graphics.sprite_paths = sprite_paths
	graphics.texture_names = texture_names
	graphics.texture_paths = texture_paths
	graphics.palettized = palettized
	graphics.depalettized = depalettized
end


local png_data_temp = {}
function graphics.get_png_data(sprite)
    local name = graphics.texture_names[sprite]
    local texture = graphics.textures[sprite]
	local path = graphics.texture_paths[sprite]
	local data = graphics.texture_data[sprite]

	if graphics.png_data[name] then
		return graphics.png_data[name]
	end

	table.clear(png_data_temp)

	local status, err = pcall(function(t)
        local png_data = read_png(path)
		t.png_data = png_data
        graphics.png_data[name] = png_data
		graphics.png_data[texture] = png_data
        graphics.png_data[path] = png_data
        graphics.png_data[data] = png_data
        graphics.texture_data[png_data] = data
        graphics.textures[png_data] = texture
		graphics.texture_paths[png_data] = path
		graphics.texture_names[png_data] = name
	end, png_data_temp)
    if not status then
        print(err)
    else
        print("read png info for " .. name)
    end
	
	return png_data_temp.png_data
end

function graphics.load()
    graphics.shader.load()
    graphics.set_default_filter("nearest", "nearest", 0)
    graphics.canvas = graphics.new_canvas(conf.viewport_size.x, conf.viewport_size.y)


    graphics.set_canvas(graphics.canvas)

    graphics.clear(0, 0, 0, 0)
    graphics.set_blend_mode("alpha")
    graphics.set_line_style("rough")
    graphics.set_canvas()

    graphics.load_textures(false)

    graphics.initialize_screen_shader_presets()
	graphics.set_screen_shader_from_preset(usersettings.screen_shader_preset)

	graphics.load_font_paths()
	
	graphics.load_fonts{
		["PixelOperator"] = 16,
		["PixelOperator-Bold"] = 16,
		["PixelOperatorHB"] = 16,
		["PixelOperatorHBSC"] = 16,
		["PixelOperatorMono"] = 16,
		["PixelOperatorMono-Bold"] = 16,
		["PixelOperatorMonoHB"] = 16,
		["PixelOperatorSC"] = 16,
		["PixelOperatorSC-Bold"] = 16,
		["PixelOperatorHB8"] = 8,
		["PixelOperatorMonoHB8"] = 8,
		["PressStart2P-8"] = 8,
		["PixelOperator8"] = 8,
		["PixelOperator8-Bold"] = 8,
		["PixelOperatorMono8"] = 8,
		["PixelOperatorMono8-Bold"] = 8,
		-- ["videotype"] = 34,
	}
    textures = graphics.textures
	fonts = graphics.font
end

function graphics.load_font_paths()
	local font_paths = filesystem.get_files_of_type("assets/font", "ttf", true)
	graphics.font_path = {
	}
	graphics.font = {
	}

	for _, v in ipairs(font_paths) do
		graphics.font_path[filesystem.filename_to_asset_name(v, "ttf", "font_")] = v
	end
end

function graphics.load_font(path, size)
	local font = graphics.new_font(graphics.font_path[path], size)
	local double = graphics.new_font(graphics.font_path[path], size * 2)
	graphics.font[path] = font
	graphics.font[path .. "_double"] = double
	return font
end

function graphics.load_fonts(tab)
	for path, size in pairs(tab) do
		graphics.load_font(path, size)
	end
end

function graphics.load_image_font(name, sprite, glyphs)
	local depalettized_sprite = graphics.depalettized[sprite]
	sprite = graphics.palettized[sprite]
    local data = graphics.texture_data[sprite]
    fonts[name] = graphics.new_image_font(data, glyphs)
	graphics.font_images = graphics.font_images or {}
	graphics.font_images[name] = sprite
    graphics.font_images[fonts[name]] = sprite
	fonts.depalettized = fonts.depalettized or {}
	fonts.depalettized[name] = graphics.new_image_font(graphics.texture_data[depalettized_sprite], glyphs)
	return fonts[name]
end

function graphics.initialize_screen_shader_presets()
	graphics.screen_shader_presets = {
		
        {
            "shader_preset_none",
			{ shader = graphics.shader.nothing, args = {} },
			-- graphics.shader.basic
			-- { shader = graphics.shader.none, args = {} },
		},

		{
			
			"shader_preset_soft",
			-- graphics.shader.basic
			{ shader = graphics.shader.blur, args = { pre_blur_size = 0.06, pre_blur_samples = 7 } },

			-- { shader = graphics.shader.screenfilter, args = {} },
			-- { shader = graphics.shader.lcd, args = { pixel_texture = graphics.textures.pixeltexture2, effect_strength = 0.3, brightness = 1.8 } },
			{ shader = graphics.shader.aberration, args = {aberration_amount = 0.3, aberration_strength = 0.6 }, },
			{ shader = graphics.shader.glow, args = { pre_blur_size = 0.2, pre_blur_samples = 8, intensity = 0.25, glow_curve = 1.5, glow_boost = 0.025 } },

			-- { shader = graphics.shader.blur, args = {} },
			-- graphics.shader.lcd,
		},
		
		{
			
			"shader_preset_glow",
			-- graphics.shader.basic
			{ shader = graphics.shader.blur, args = { pre_blur_size = 0.045, pre_blur_samples = 8 } },

			-- { shader = graphics.shader.screenfilter, args = {} },
			-- { shader = graphics.shader.lcd, args = { pixel_texture = graphics.textures.pixeltexture2, effect_strength = 0.3, brightness = 1.8 } },
			-- { shader = graphics.shader.aberration, args = {aberration_amount = 0.3, aberration_strength = 0.6 }, },
			-- { shader = graphics.shader.glow, args = { pre_blur_size = 0.2, pre_blur_samples = 16, intensity = 0.5, glow_curve = 1, glow_boost = 0.55 } },
            { shader = graphics.shader.glow, args = { pre_blur_size = 0.2, pre_blur_samples = 8, intensity = 0.35, glow_curve = 1, glow_boost = 0.0 } },
            { shader = graphics.shader.glow, args = { pre_blur_size = 0.35, pre_blur_samples = 10, intensity = 0.25, glow_curve = 1, glow_boost = 0.0 } },
			-- { shader = graphics.shader.blur, args = {} },
			-- graphics.shader.lcd,
		},

		{
			"shader_preset_scanline",
			-- graphics.shader.basic
			{ shader = graphics.shader.blur, args = { pre_blur_size = 0.08, pre_blur_samples = 7 } },
			-- { shader = graphics.shader.screenfilter, args = {} },

			{ shader = graphics.shader.lcd, args = { pixel_texture = graphics.textures.pixeltexture4, effect_strength = 0.6, brightness = 1.4 } },
			{ shader = graphics.shader.aberration, args = {aberration_amount = 0.1, aberration_strength = 0.6} },
			{ shader = graphics.shader.glow, args = { pre_blur_size = 0.2, pre_blur_samples = 8, intensity = 0.25, glow_curve = 1. , glow_boost = 0.35  } },
			-- { shader = graphics.shader.blur, args = {} },
			-- graphics.shader.lcd,

		},

		{
			"shader_preset_lcd",
			-- graphics.shader.basic
			{ shader = graphics.shader.blur, args = { pre_blur_size = 0.08, pre_blur_samples = 7 } },
			-- { shader = graphics.shader.screenfilter, args = {} },
			{ shader = graphics.shader.lcd, args = { pixel_texture = graphics.textures.pixeltexture2, effect_strength = 0.6, brightness = 1.2 } },
			{ shader = graphics.shader.aberration, args = {aberration_amount = 0.4, aberration_strength = 0.6} },
			-- { shader = graphics.shader.blur, args = {} },
			{ shader = graphics.shader.glow, args = { pre_blur_size = 0.1, pre_blur_samples = 8, intensity = 0.25, glow_curve = 1. , glow_boost = 0.35 } },

			-- graphics.shader.lcd,
		},
		
		{
			"shader_preset_ledboard",
			{
				shader = graphics.shader.led,
				args = {
					pixel_texture = graphics.textures.pixeltexture,
					effect_strength = 1,
					brightness = 1.0,
					min_brightness = 0.025,
					overlay_power = 0.3,
					boost = 0.00,
					luminance_modifier = 1.1,
					saturation_modifier = 1.00,
					contrast_modifier = 1.00,
				},
			},
			-- { shader = graphics.shader.led,  args = { pixel_texture = graphics.textures.pixeltexture, effect_strength = 0.5, brightness = 4, min_brightness = 0.00 } },
			
			{ shader = graphics.shader.glow, args = { pre_blur_size = 0.2, pre_blur_samples = 16, intensity = 0.5, glow_curve = 1, glow_boost = 0.55 } },
            { shader = graphics.shader.glow, args = { pre_blur_size = 0.1, pre_blur_samples = 8, intensity = 0.4, glow_curve = 1, glow_boost = 0.35 } },
			
			-- { shader = graphics.shader.bloom, args = { } }

			-- { shader = graphics.shader.aberration, args = {} },
			-- { shader = graphics.shader.lcd,  args = { pixel_texture = graphics.textures.pixeltexture, effect_strength = 0.5, brightness = 2.0 } },
        },


	}

    graphics.adjustment_shader_options = graphics.adjustment_shader_options or {
		brightness = usersettings.brightness,
		saturation = usersettings.saturation,
		hue = usersettings.hue,
		invert_colors = usersettings.invert_colors,
	}

	for i, shader_table in ipairs(graphics.screen_shader_presets) do
		-- if shader_table[1] == "shader_preset_none" then
			-- graphics.set_screen_shaders(shader_table)
        -- end
        table.insert(shader_table, 2, {
			shader = graphics.shader.adjustment,
			args = graphics.adjustment_shader_options,
		})
	end
end

function graphics.set_screen_shader_from_preset(preset)
	-- if preset == "shader_preset_none" then
		-- graphics.set_screen_shaders(nil)
		-- return
	-- end

	if graphics.current_screen_shader_preset == preset then
		return
	end
	graphics.current_screen_shader_preset = preset
	graphics.initialize_screen_shader_presets()
	for i, shader_table in ipairs(graphics.screen_shader_presets) do
		if shader_table[1] == preset then
			graphics.set_screen_shaders(shader_table)
		end
	end
end

function graphics.update(dt)
	graphics.sequencer:update(dt)
end

function graphics.game_draw()
    graphics.push()

    local update_interp = true

    local layer = game.layer_tree

    layer.interp_fraction = update_interp and graphics.interp_fraction or layer.interp_fraction
    layer:draw_shared()

    graphics.pop()
end

function graphics.new_image_data(path)
    return love.image.newImageData(path)
end

function graphics.set_screen_shaders(shaders)
	graphics.screen_shader_canvases = {}
	graphics.screen_shaders = shaders
end


function graphics.set_bg_image(image)
	if graphics.bg_image then
		graphics.bg_image:release()
	end
	local data = graphics.texture_data[image]
	local cloned = graphics.new_image(data, { mipmaps = false, linear = true })
	cloned:setFilter("linear", "linear")
	graphics.bg_image = cloned
end

function graphics.draw_bg_image(image)
	graphics.draw_cover(image, 0, 0, graphics.window_size.x, graphics.window_size.y)
end

function graphics.set_pre_canvas_draw_function(func)
	graphics.pre_canvas_draw_function = func
end

function graphics.screen_pos_to_canvas_pos(sposx, sposy)
	return ((sposx - graphics.main_canvas_start_pos.x) / graphics.main_canvas_scale),
		((sposy - graphics.main_canvas_start_pos.y) / graphics.main_canvas_scale)
end

local flash_table = {
    Color.from_hex("ff0000"),
    Color.from_hex("ff8000"),
    Color.from_hex("ffff00"),
    Color.from_hex("80ff00"),
    Color.from_hex("00ff00"),
    Color.from_hex("00ff80"),
    Color.from_hex("00ffff"),
    Color.from_hex("0080ff"),
    Color.from_hex("0000ff"),
    Color.from_hex("8000ff"),
    Color.from_hex("ff00ff"),
    Color.from_hex("ff0080"),
}

function graphics.color_flash(offset, tick_length)
    local color = flash_table[floor(((gametime.tick / tick_length) + offset) % #flash_table) + 1]
	return color
end

function graphics.frame_rumble(intensity)
    local s = graphics.sequencer
    if graphics.rumble_coroutine then
        s:stop(graphics.rumble_coroutine)
    end
	local func = function()	
        s:tween_property(graphics, "screen_rumble_intensity", intensity * usersettings.screen_shake_amount, 0, 1, "constant0")
        graphics.rumble_coroutine = nil
		graphics.screen_rumble_intensity = 0
    end
	graphics.rumble_coroutine = s:start(func)
end

function graphics.start_rumble(intensity, duration, easing_function)
    local s = graphics.sequencer
    if graphics.rumble_coroutine then
        s:stop(graphics.rumble_coroutine)
    end

    easing_function = easing_function or ease("outQuad")
    local func = function()
        s:tween_property(graphics, "screen_rumble_intensity", intensity * usersettings.screen_shake_amount, 0, duration,
            easing_function)
        graphics.rumble_coroutine = nil
        graphics.screen_rumble_intensity = 0
    end
	
    graphics.rumble_coroutine = s:start(func)
end

function graphics.draw_loop()


	local wsx, wsy = graphics.get_dimensions()
    graphics.window_size.x = wsx
    graphics.window_size.y = wsy


    graphics.set_canvas(graphics.canvas)
	
	graphics.game_draw()

	graphics.set_color(1, 1, 1)
    graphics.set_canvas()
	

    local process_scale = usersettings.pixel_perfect and math.floor or identity_function

	window_width, window_height = graphics.get_dimensions()
    window_size.x = window_width
	window_size.y = window_height
    viewport_size.x = conf.viewport_size.x
	viewport_size.y = conf.viewport_size.y
	max_width_scale = process_scale(window_size.x / viewport_size.x)
	max_height_scale = process_scale(window_size.y / viewport_size.y)
    viewport_pixel_scale = max(process_scale(math.min(max_width_scale, max_height_scale) * usersettings.zoom_level), 1)

	if conf.expand_viewport then
		local scaled_width = round(window_width / viewport_pixel_scale) 
		local scaled_height = round(window_height / viewport_pixel_scale)
		viewport_size.x = stepify_floor_safe(scaled_width, 2)
		viewport_size.y = stepify_floor_safe(scaled_height, 2)
	end


	canvas_size.x = floor(viewport_size.x * viewport_pixel_scale)
	canvas_size.y = floor(viewport_size.y * viewport_pixel_scale)
    canvas_pos.x = window_size.x / 2 - (canvas_size.x) / 2
    canvas_pos.y = window_size.y / 2 - (canvas_size.y) / 2

	if debug.enabled then
        dbg("viewport_size", viewport_size)
        dbg("hue", graphics.adjustment_shader_options.hue)
		dbg("brightness", graphics.adjustment_shader_options.brightness)
		dbg("saturation", graphics.adjustment_shader_options.saturation)
	end
	
    if (abs(graphics.canvas:getWidth() - viewport_size.x) >= 1 or abs(graphics.canvas:getHeight() - viewport_size.y) >= 1) then
        graphics.canvas:release()
        graphics.canvas = graphics.new_canvas(viewport_size.x, viewport_size.y)
    end

	if graphics.screen_rumble_intensity > 0 then
		local dx, dy = rng:random_vec2()
		local rumble_offset_x, rumble_offset_y = (dx * rng:randf(graphics.screen_rumble_intensity*0.5, graphics.screen_rumble_intensity)), (dy * rng:randf(graphics.screen_rumble_intensity*0.5, graphics.screen_rumble_intensity))
        canvas_pos.x = canvas_pos.x + rumble_offset_x * viewport_pixel_scale
		canvas_pos.y = canvas_pos.y + rumble_offset_y * viewport_pixel_scale
	end

    viewport_size_shader[1] = viewport_size.x
    viewport_size_shader[2] = viewport_size.y
    canvas_pos_shader[1] = canvas_pos.x
    canvas_pos_shader[2] = canvas_pos.y
    canvas_size_shader[1] = canvas_size.x
	canvas_size_shader[2] = canvas_size.y

	graphics.main_canvas_start_pos.x = canvas_pos.x
	graphics.main_canvas_start_pos.y = canvas_pos.y
	graphics.main_canvas_size.x = canvas_size.x
	graphics.main_canvas_size.y = canvas_size.y
	graphics.main_canvas_scale = viewport_pixel_scale
	graphics.main_viewport_size = viewport_size
	graphics.window_size.x = window_size.x
	graphics.window_size.y = window_size.y

    if graphics.pre_canvas_draw_function then
        graphics.pre_canvas_draw_function()
    elseif graphics.bg_image then
        graphics.draw_bg_image(graphics.bg_image)
    end

	local canvas_to_draw = graphics.canvas

	if viewport_pixel_scale > 1 then
		if gametime.tick % 10 == 0 then
			-- pcall(graphics.shader.update)
		end


		
		for i = 2, #(graphics.screen_shaders or dummy_table) do
			
            local shader_table = graphics.screen_shaders[i]
            local shader = shader_table.shader
			local args = shader_table.args
			local shader_canvas = graphics.screen_shader_canvases[i]

			if not shader_canvas then
				shader_canvas = graphics.new_canvas(canvas_size.x, canvas_size.y)
				graphics.screen_shader_canvases[i] = shader_canvas
			end

			if shader_canvas:getWidth() ~= canvas_size.x or shader_canvas:getHeight() ~= canvas_size.y then
				shader_canvas:release()
				shader_canvas = graphics.new_canvas(canvas_size.x, canvas_size.y)
				graphics.screen_shader_canvases[i] = shader_canvas
			end

			graphics.set_canvas(shader_canvas)

			if shader:hasUniform("viewport_size") then
				shader:send("viewport_size", viewport_size_shader )
			end
			if shader:hasUniform("canvas_size") then
				shader:send("canvas_size", canvas_size_shader )
			end
			if shader:hasUniform("canvas_pos") then
				shader:send("canvas_pos", canvas_pos_shader )
			end

            for arg, value in pairs(args) do
				if shader:hasUniform(arg) then
					shader:send(arg, value)
				end 
			end
				
            
			graphics.set_shader(shader)
			graphics.push()
            graphics.origin()

			graphics.draw(canvas_to_draw, 0, 0, 0, viewport_pixel_scale, viewport_pixel_scale)
			graphics.pop()

			canvas_to_draw = shader_canvas
			viewport_pixel_scale = 1
		end
	end

    graphics.set_canvas()
	
    -- if conf.pixel_perfect then
	graphics.draw(canvas_to_draw, math.floor(canvas_pos.x), math.floor(canvas_pos.y), 0, viewport_pixel_scale,
		viewport_pixel_scale)
    -- else
    --     local scaled_canvas = graphics.scaled_canvas
		
    --     local wsx, wsy = canvas_size.x, canvas_size.y
    --     if scaled_canvas == nil or scaled_canvas:getWidth() ~= wsx or scaled_canvas:getHeight() ~= wsy then
    --         if scaled_canvas then
    --             scaled_canvas:release()
    --         end
    --         scaled_canvas = graphics.new_canvas(wsx, wsy)
    --         scaled_canvas:setFilter("linear", "linear")
    --         graphics.scaled_canvas = scaled_canvas
    --     end
	-- 	-- TODO: apply shader *after* scaling
	-- 	graphics.set_canvas(scaled_canvas)
	-- 	graphics.clear(0, 0, 0, 0)
	-- 	graphics.draw(canvas_to_draw, 0, 0, 0, viewport_pixel_scale, viewport_pixel_scale)
	-- 	graphics.set_canvas()
	-- 	graphics.draw_fit(scaled_canvas, 0, 0, graphics.window_size.x, graphics.window_size.y)
    -- end
	
	graphics.set_shader()

	graphics.set_canvas()

	debug.printlines(0, 0)
end

--- love API wrappers
function graphics.set_color(r, g, b, a)
	if type(r) == "string" then
		graphics.set_color(Color.from_hex_unpack(r))
		return
	end
	if type(r) == "table" then
		if g ~= nil then
			a = g
		else
			if a == nil then
				a = r.a
			end
		end
		g = r.g
		b = r.b
		r = r.r
		if a == nil then
			a = 1.0
		end
	end
	love.graphics.set_color(r, g, b, a)
end

-- graphics["set-color"] = graphics.set_color

function graphics.draw_cover(texture, start_x, start_y, end_x, end_y)
	local tex_width = texture:getWidth()
	local tex_height = texture:getHeight()
	local tex_ratio = tex_width / tex_height
	local screen_ratio = (end_x - start_x) / (end_y - start_y)

	-- Calculate the scale factor
	local scale
	if tex_ratio > screen_ratio then
		-- If the texture is wider than the screen, scale by height
		scale = (end_y - start_y) / tex_height
	else
		-- If the texture is taller than the screen, scale by width
		scale = (end_x - start_x) / tex_width
	end

	-- Calculate new texture dimensions
	local new_tex_width = tex_width * scale
	local new_tex_height = tex_height * scale

	-- Calculate the offsets to center the texture within the rectangle
	local offset_x = (new_tex_width - (end_x - start_x)) / 2
	local offset_y = (new_tex_height - (end_y - start_y)) / 2

	-- Draw the texture, adjusting the position to center it if necessary
	graphics.draw(texture, start_x - offset_x, start_y - offset_y, 0, scale, scale)
end

function graphics.draw_fit(texture, start_x, start_y, end_x, end_y)
	local tex_width = texture:getWidth()
	local tex_height = texture:getHeight()
	local tex_ratio = tex_width / tex_height
	local screen_ratio = (end_x - start_x) / (end_y - start_y)

	-- Calculate the scale factor
	local scale
	if tex_ratio < screen_ratio then
		-- If the texture is wider than the screen, scale by height
		scale = (end_y - start_y) / tex_height
	else
		-- If the texture is taller than the screen, scale by width
		scale = (end_x - start_x) / tex_width
	end

	-- Calculate new texture dimensions
	local new_tex_width = tex_width * scale
	local new_tex_height = tex_height * scale

	-- Calculate the offsets to center the texture within the rectangle
	local offset_x = (new_tex_width - (end_x - start_x)) / 2
	local offset_y = (new_tex_height - (end_y - start_y)) / 2

	-- Draw the texture, adjusting the position to center it if necessary
	graphics.draw(texture, start_x - offset_x, start_y - offset_y, 0, scale, scale)
end

function graphics.get_quad_table(texture, quad, width, height)
    return {
        texture = texture,
		__isquad = true,
        quad = quad,
		width = width,
		height = height,
    }
end


function graphics.draw(texture, x, y, r, sx, sy, ox, oy, kx, ky)
    -- -- remove this if you arent using sprite sheets
	if texture == nil then return end
	if texture.__isquad then
		love.graphics.draw(texture.texture, texture.quad, x, y, r, sx, sy, ox, oy, kx, ky)
	else
		love.graphics.draw(texture, x, y, r, sx, sy, ox, oy, kx, ky)
	end
end

function graphics.draw_quad_table(tab, x, y, r, sx, sy, ox, oy, kx, ky)
    love.graphics.draw(tab.texture, tab.quad, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics._auto_palette(texture, palette, offset)
    if palette == nil then
		if offset == 0 or offset == nil then
			return nil
        else
            local p = Palette[texture]
			if floor(offset) % p.length == 0 then
				return nil
			else
				return p
			end
		end
	elseif (palette == Palette[texture]) and floor(offset) % palette.length == 0 then 
		return nil
	elseif type(palette) == "string" then
		palette = Palette[palette]
	end
	return palette
end

function graphics.drawp(texture, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
	if texture == nil then return end
    palette = graphics._auto_palette(texture, palette, offset)
	if palette == nil then
		return graphics.draw(graphics.depalettized[texture], x, y, r, sx, sy, ox, oy, kx, ky)
	end

	graphics.set_shader(palette:get_shader(offset))
	graphics.draw(graphics.palettized[texture], x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.set_shader()
end


function graphics.drawp_centered(texture, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
	if texture == nil then return end
    palette = graphics._auto_palette(texture, palette, offset)
	if palette == nil then
		return graphics.draw_centered(graphics.depalettized[texture], x, y, r, sx, sy, ox, oy, kx, ky)
	end
	
	graphics.set_shader(palette:get_shader(offset))
	graphics.draw_centered(graphics.palettized[texture], x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.set_shader()
end

function graphics.draw_quad_centered(texture, quad, width, height, x, y, r, sx, sy, ox, oy, kx, ky)
    ox = ox or 0
    oy = oy or 0
    local offset_x = width / 2
    local offset_y = height / 2
    graphics.draw(texture, quad, x, y, r, sx, sy, ox + offset_x, oy + offset_y, kx, ky)
end

function graphics.draw_outline(color, texture, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.push("all")
	graphics.set_color(color)
	graphics.draw(texture, x + 1, y + 1, r, sx, sy, ox, oy, kx, ky)
	graphics.draw(texture, x - 1, y - 1, r, sx, sy, ox, oy, kx, ky)
	graphics.draw(texture, x + 1, y - 1, r, sx, sy, ox, oy, kx, ky)
	graphics.draw(texture, x - 1, y + 1, r, sx, sy, ox, oy, kx, ky)
	graphics.draw(texture, x + 1, y, r, sx, sy, ox, oy, kx, ky)
	graphics.draw(texture, x - 1, y, r, sx, sy, ox, oy, kx, ky)
	graphics.draw(texture, x, y + 1, r, sx, sy, ox, oy, kx, ky)
	graphics.draw(texture, x, y - 1, r, sx, sy, ox, oy, kx, ky)
    graphics.pop()
	graphics.draw(texture, x, y, r, sx, sy, ox, oy, kx, ky)
end


function graphics.draw_centered(texture, x, y, r, sx, sy, ox, oy, kx, ky)
	
	if texture == nil then return end
	
	if texture.__isquad then
		return graphics.draw_quad_centered(texture.texture, texture.quad, texture.width, texture.height, x, y, r, sx, sy, ox, oy, kx, ky)
	end
	
	ox = ox or 0
	oy = oy or 0
	local offset_x = round(texture:getWidth() / 2)
	local offset_y = round(texture:getHeight() / 2)
	graphics.draw(texture, x, y, r, sx, sy, ox + offset_x, oy + offset_y, kx, ky)
end

function graphics.draw_centered_outline(color, texture, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.push("all")
	graphics.set_color(color)
	graphics.draw_centered(texture, x + 1, y + 1, r, sx, sy, ox, oy, kx, ky)
	graphics.draw_centered(texture, x - 1, y - 1, r, sx, sy, ox, oy, kx, ky)
	graphics.draw_centered(texture, x + 1, y - 1, r, sx, sy, ox, oy, kx, ky)
	graphics.draw_centered(texture, x - 1, y + 1, r, sx, sy, ox, oy, kx, ky)
	graphics.draw_centered(texture, x + 1, y, r, sx, sy, ox, oy, kx, ky)
	graphics.draw_centered(texture, x - 1, y, r, sx, sy, ox, oy, kx, ky)
	graphics.draw_centered(texture, x, y + 1, r, sx, sy, ox, oy, kx, ky)
	graphics.draw_centered(texture, x, y - 1, r, sx, sy, ox, oy, kx, ky)
	graphics.pop()
	graphics.draw_centered(texture, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.drawp_outline(color, texture, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.push("all")
	graphics.set_color(color)
	graphics.draw_outline(color, texture, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.pop()
	graphics.drawp(texture, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.drawp_centered_outline(color, texture, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.push("all")
	graphics.set_color(color)
	graphics.draw_centered_outline(color, texture, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.pop()
	graphics.drawp_centered(texture, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.set_clear_color(color)
	graphics.clear_color = color
end

function graphics.clear(r, g, b, a)
	if type(r) == "table" then
		if g ~= nil then
			a = g
		else
			if a == nil then
				a = r.a
			end
		end
		g = r.g
		b = r.b
		r = r.r
		if a == nil then
			a = 1.0
		end
	end
	love.graphics.clear(r, g, b, a)
end


function graphics.rect(mode, rect)
	love.graphics.rectangle(mode, rect.x, rect.y, rect.width, rect.height)
end

function graphics.rectangle_centered(mode, x, y, width, height)
    love.graphics.rectangle(mode, x - width / 2, y - height / 2, width, height)
end


function graphics.debug_capsule(x1, y1, x2, y2, radius, draw_rect)
    graphics.circle("line", x1, y1, radius)
    graphics.circle("line", x2, y2, radius)
    local angle = vec2_angle_to(x1, y1, x2, y2)
    local length = vec2_distance(x1, y1, x2, y2)
    local offsx, offsy = vec2_rotated(radius, 0, angle + tau / 4)
    local endx, endy = x1 + cos(angle) * length, y1 + sin(angle) * length
    graphics.line(x1 + offsx, y1 + offsy, endx + offsx, endy + offsy)
    graphics.line(x1 - offsx, y1 - offsy, endx - offsx, endy - offsy)
	if draw_rect then
		graphics.rectangle("line", x1 - radius, y1 - radius, x2 - x1 + radius * 2, y2 - y1 + radius * 2)
	end
end


function graphics.poly_rect(fill, x, y, width, height, rotation, scale_x, scale_y)
	local left_x, top_y = -width / 2, -height / 2
    local right_x, bottom_y = width / 2, height / 2
	
	local x1, y1 = left_x, top_y
	local x2, y2 = right_x, top_y
	local x3, y3 = right_x, bottom_y
	local x4, y4 = left_x, bottom_y



	x1, y1 = vec2_rotated(x1, y1, rotation)
	x2, y2 = vec2_rotated(x2, y2, rotation)
	x3, y3 = vec2_rotated(x3, y3, rotation)
	x4, y4 = vec2_rotated(x4, y4, rotation)

	x1 = x1 * scale_x
	x2 = x2 * scale_x
	x3 = x3 * scale_x
	x4 = x4 * scale_x

	y1 = y1 * scale_y
	y2 = y2 * scale_y
	y3 = y3 * scale_y
	y4 = y4 * scale_y

	x1 = x1 + x
	x2 = x2 + x
	x3 = x3 + x
	x4 = x4 + x
	y1 = y1 + y
	y2 = y2 + y
	y3 = y3 + y
	y4 = y4 + y

	graphics.polygon(fill, x1, y1, x2, y2, x3, y3, x4, y4)
end


function graphics.poly_rect_sides(x, y, width, height, rotation, scale_x, scale_y, side1, side2, side3, side4)
	local left_x, top_y = -width / 2, -height / 2
    local right_x, bottom_y = width / 2, height / 2
	
	local x1, y1 = left_x, top_y
	local x2, y2 = right_x, top_y
	local x3, y3 = right_x, bottom_y
	local x4, y4 = left_x, bottom_y



	x1, y1 = vec2_rotated(x1, y1, rotation)
	x2, y2 = vec2_rotated(x2, y2, rotation)
	x3, y3 = vec2_rotated(x3, y3, rotation)
	x4, y4 = vec2_rotated(x4, y4, rotation)

	x1 = x1 * scale_x
	x2 = x2 * scale_x
	x3 = x3 * scale_x
	x4 = x4 * scale_x

	y1 = y1 * scale_y
	y2 = y2 * scale_y
	y3 = y3 * scale_y
	y4 = y4 * scale_y

	x1 = x1 + x
	x2 = x2 + x
	x3 = x3 + x
	x4 = x4 + x
	y1 = y1 + y
	y2 = y2 + y
	y3 = y3 + y
	y4 = y4 + y

	if side1 then
		graphics.line(x1, y1, x2, y2)
	end
    if side2 then
        graphics.line(x2, y2, x3, y3)
    end
	if side3 then
		graphics.line(x3, y3, x4, y4)
	end
	if side4 then
		graphics.line(x4, y4, x1, y1)
	end
	
end

function graphics.print_right_aligned(text, font, end_x, y, r, sx, sy, ox, oy, kx, ky)
	local width = font:getWidth(text)
	local start = end_x - width
	graphics.print(text, start, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.printp_right_aligned(text, font, palette, offset, end_x, y, r, sx, sy, ox, oy, kx, ky)
	local width = font:getWidth(text)
	local start = end_x - width
	graphics.printp(text, font, palette, offset, start, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.printp(text, font, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
    local texture = graphics.font_images[font]
    if texture == nil then
		graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
		return
	end
	if text == nil then return end
    palette = graphics._auto_palette(texture, palette, offset)
    if palette == nil then
		graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
		return
	end

	graphics.set_shader(palette:get_shader(offset))
	graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.set_shader()
end

function graphics.printp_centered(text, font, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
    local offset_x, offset_y = graphics.text_center_offset(text, font)
    x = round(x + offset_x)
    y = round(y + offset_y)
    graphics.printp(text, font, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.text_center_offset(text, font)
	local width, height = font:getWidth(text), font:getHeight(text)
	return -width / 2, -height / 2
end

function graphics.print_centered(text, font, x, y, r, sx, sy, ox, oy, kx, ky)
    local offset_x, offset_y = graphics.text_center_offset(text, font)
    graphics.print(text, round(x + offset_x), round(y + offset_y), r, sx, sy, ox, oy, kx, ky)
end


function graphics.print_outline_centered(outline_color, text, font, x, y, r, sx, sy, ox, oy, kx, ky)
    local offset_x, offset_y = graphics.text_center_offset(text, font)
	x = x + offset_x
    y = y + offset_y
	graphics.print_outline(outline_color, text, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.print_multicolor(font, x, y, ...)
	local width = 0
    for i = 1, select("#", ...), 2 do
        local text, color = select(i, ...)
		graphics.set_color(color)
		graphics.print(text, x + width, y)
		width = width + font:getWidth(text)
	end
end

function graphics.print_outline(outline_color, text, x, y, r, sx, sy, ox, oy, kx, ky)
    graphics.push("all")
    graphics.set_color(outline_color)
    graphics.print(text, x + 1, y + 1, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x - 1, y - 1, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x + 1, y - 1, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x - 1, y + 1, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x + 1, y, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x - 1, y, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x, y + 1, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x, y - 1, r, sx, sy, ox, oy, kx, ky)
    graphics.pop()
    graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.printp_outline(outline_color, text, font, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
    graphics.push("all")
    graphics.set_color(outline_color)
    graphics.print(text, x + 1, y + 1, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x - 1, y - 1, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x + 1, y - 1, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x - 1, y + 1, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x + 1, y, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x - 1, y, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x, y + 1, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x, y - 1, r, sx, sy, ox, oy, kx, ky)
    graphics.pop()
    graphics.printp(text, font, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.printp_outline_centered(outline_color, text, font, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
    graphics.push("all")
    graphics.set_color(outline_color)
    local offset_x, offset_y = graphics.text_center_offset(text, font)
    x = x + offset_x
    y = y + offset_y
    graphics.printp_outline(outline_color, text, font, palette, offset, x, y, r, sx, sy, ox, oy, kx, ky)
    graphics.pop()
end

function graphics.print_outline_no_diagonals(outline_color, text, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.push("all")
    graphics.set_color(outline_color)
    graphics.print(text, x + 1, y, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x - 1, y, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x, y + 1, r, sx, sy, ox, oy, kx, ky)
    graphics.print(text, x, y - 1, r, sx, sy, ox, oy, kx, ky)
    graphics.pop()
    graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.dashline(p1x, p1y, p2x, p2y, dash, gap)
    local dy, dx = p2y - p1y, p2x - p1x
    local an, st = math.atan2(dy, dx), dash + gap
    local len    = math.sqrt(dx * dx + dy * dy)
    local nm     = (len - dash) / st
    graphics.push()
    graphics.translate(p1x, p1y)
    graphics.rotate(an)
    for i = 0, nm do
        graphics.line(i * st, 0, i * st + dash, 0)
    end
    graphics.line(nm * st, 0, nm * st + dash, 0)
    graphics.pop()
end
 
function graphics.dashrect(x, y, w, h, dash, gap)
	graphics.dashline(x, y, x + w, y, dash, gap)
	graphics.dashline(x + w, y, x + w, y + h, dash, gap)
	graphics.dashline(x + w, y + h, x, y + h, dash, gap)
	graphics.dashline(x, y + h, x, y, dash, gap)
end

function graphics.dashrect_centered(x, y, w, h, dash, gap)
	graphics.dashrect(x - w / 2, y - h / 2, w, h, dash, gap)
end

function graphics.draw_collision_box(rect, color, alpha)
    alpha = alpha or 1
    graphics.push("all")
    graphics.set_color(color.r, color.g, color.b, alpha * 0.25)
    graphics.rectangle("fill", rect.x + 1, rect.y + 1, rect.width - 1, rect.height - 1)
    graphics.set_color(color.r, color.g, color.b, alpha * 0.5)
    graphics.rectangle("line", rect.x + 1, rect.y + 1, rect.width - 1, rect.height - 1)
    graphics.pop()
end


function graphics.axis_quantized_line(x0, y0, x1, y1, width, height, inverted, cap_size, dash, dash_gap, tab)
	local points = tab or {}

	table.clear(points)
	for x, y in bresenham_line_iter(round(x0 / width), round(y0 / height), round(x1 / width), round(y1 / height)) do
		table.insert(points, {x * width, y * height})
	end

	cap_size = (cap_size or 1) * love.graphics.getLineWidth()

	if dash then
        for i = 1, #points - 1 do
			local p1 = points[i]
            local p2 = points[i + 1]
			local p1_x, p1_y = vec2_rounded(p1[1], p1[2])
			local p2_x, p2_y = vec2_rounded(p2[1], p2[2])

			graphics.rectangle("fill", p1_x - cap_size / 2, p1_y - cap_size / 2, cap_size, cap_size)
			graphics.rectangle("fill", p2_x - cap_size / 2, p2_y - cap_size / 2, cap_size, cap_size)
			if inverted then
				graphics.rectangle("fill", p1_x - cap_size / 2, p2_y - cap_size / 2, cap_size, cap_size)
				graphics.dashline(p1_x, p1_y, p1_x, p2_y, dash, dash_gap)
				graphics.dashline(p1_x, p2_y, p2_x, p2_y, dash, dash_gap)
			else
				graphics.dashline(p1_x, p1_y, p2_x, p1_y, dash, dash_gap)
				graphics.rectangle("fill", p2_x - cap_size / 2, p1_y - cap_size / 2, cap_size, cap_size)
				graphics.dashline(p2_x, p1_y, p2_x, p2_y, dash, dash_gap)
			end
			::continue::
		end
	else
		for i=1, #points - 1 do
			local p1 = points[i]
			local p2 = points[i + 1]
			local p1_x, p1_y = vec2_rounded(p1[1], p1[2])
			local p2_x, p2_y = vec2_rounded(p2[1], p2[2])

			graphics.rectangle("fill", p1_x - cap_size / 2, p1_y - cap_size / 2, cap_size, cap_size)
			graphics.rectangle("fill", p2_x - cap_size / 2, p2_y - cap_size / 2, cap_size, cap_size)
			if inverted then
				graphics.rectangle("fill", p1_x - cap_size / 2, p2_y - cap_size / 2, cap_size, cap_size)
				graphics.line(p1_x, p1_y, p1_x, p2_y)
				graphics.line(p1_x, p2_y, p2_x, p2_y)
			else
				graphics.line(p1_x, p1_y, p2_x, p1_y)
				graphics.rectangle("fill", p2_x - cap_size / 2, p1_y - cap_size / 2, cap_size, cap_size)
				graphics.line(p2_x, p1_y, p2_x, p2_y)
			end
		end
	end
end


return graphics
