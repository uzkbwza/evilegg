local Palette = Object:extend("Palette")

Palette:override_class_metamethod("__index", function(self, key)
	if type(key) == "table" and key.__isquad then return rawget(self, key.texture) end
	if not rawget(self, key) then
		return self.super[key]
	end
end)

function Palette:new(colors)
    self.original_colors = {}
    self.colors = {}
    self.shader_vecs = {}
    -- self.color_indices = {}
    for _, color in ipairs(colors) do
        self.colors[#self.colors + 1] = color:clone()
        self.original_colors[#self.original_colors + 1] = color:clone()
        self.shader_vecs[#self.shader_vecs + 1] = { color.r, color.g, color.b, color.a }
    end
    self.length = #self.shader_vecs
    self.dirty = true
    self.cached_shader = nil
    self.cached_shader_offset = nil
    self.palette_image = nil
end

function Palette:add_color(color, index)
	color = color:clone()
    index = index or #self.colors + 1
	
    index = (index - 1) % self.length + 1
	
	local tinsert = table.insert
    tinsert(self.colors, index, color)
    tinsert(self.original_colors, index, color)
    tinsert(self.shader_vecs, index, { color.r, color.g, color.b, color.a })
    self.length = #self.shader_vecs
    self.dirty = true
	if self.readonly then
		error("Palette is readonly. use clone() to make a writable copy.")
	end
end

function Palette:remove_color(index)
	index = index or #self.colors + 1

	index = (index - 1) % self.length + 1

	if self.readonly then
		error("Palette is readonly. use clone() to make a writable copy.")
	end
	local tremove = table.remove
    tremove(self.colors, index)
    tremove(self.original_colors, index)
    tremove(self.shader_vecs, index)
    self.length = #self.shader_vecs
	self.dirty = true
end

function Palette:add_color_unpacked(r, g, b, a, index)
    local color = Color(r, g, b, a)
    self:add_color(color, index)
end

function Palette:make_readonly()
    self.colors = self.original_colors
	self.readonly = true
	self:override_instance_metamethod("__newindex", function(self, key, value)
		error("Palette is readonly. use clone() to make a writable copy.")
	end)
end

function Palette.from_image_data(image_data)
	local colors = {}
	
	for x = 0, image_data:getWidth() - 1 do
		colors[#colors + 1] = Color(image_data:getPixel(x, 0))
	end
	
	return Palette(colors)
end

function Palette:reset()
    self.colors = {}
    self.shader_vecs = {}
    for _, color in ipairs(self.original_colors) do
        self.colors[#self.colors + 1] = color:clone()
        self.shader_vecs[#self.shader_vecs + 1] = color:to_shader_table()
    end
	self.length = #self.shader_vecs
end

function Palette:to_shader_table()
	return unpack(self.shader_vecs)
end

function Palette:to_shader_table_manual_offset(offset)
	offset = offset or 0
	offset = offset % self.length
	if offset == 0 then return self.shader_vecs end
	local table = {}
    for i = offset, self.length do
        table[#table + 1] = self.shader_vecs[i]
    end
	for i = 1, offset do
		table[#table + 1] = self.shader_vecs[i]
	end
	return table
end

function Palette:__eq(other)
	if rawequal(self, other) then return true end
	for i = 1, math.max(self.length, other.length) do
		if self.colors[i] ~= other.colors[i] then
			return false
		end
	end
	return true
end

function Palette:clone(original)
	return Palette(original and self.original_colors or self.colors)
end

function Palette:get_length()
    return self.length
end

function Palette:get_color_clamped(index)
    return self.colors[clamp(index, 1, self.length)]
end

function Palette:gradient_hsl(colors, steps_per_color, loop)
    steps_per_color = steps_per_color or 2
	error("not implemented")
end

function Palette:get_color(index)
    return self.colors[(index - 1) % self.length + 1]
end

function Palette:get_valid_index(index)
    return (index - 1) % self.length + 1
end

function Palette:get_color_index_unpacked(r, g, b)
    for i, c in ipairs(self.colors) do
        if c.r == r and c.g == g and c.b == b then
            return i
        end
    end
end

function Palette:random_color()
    return self.colors[rng:randi(1, self.length)]
end

function Palette:interpolate(t)
	return self:get_color(round(t * self.length))
end

function Palette:interpolate_clamped(t)
    return self:get_color_clamped(round(t * self.length))
end

function Palette:interpolate_index(t)
	return round(clamp(t, 0, 1) * self.length)
end

function Palette:get_color_index(color)
	return Palette:get_color_index_unpacked(color.r, color.g, color.b)
end


function Palette:get_color_unpacked(index)
    local color = self.colors[(index - 1) % self.length + 1]
    return color.r, color.g, color.b, color.a
end

-- function Palette:color_to_index(color)
-- 	return self.color_indices[color]
-- end

function Palette:get_color_array(offset)
    local colors = {}
    offset = offset or 0
	offset = offset % self.length
    local start = offset + 1
    local stop = self.length

    for i = 1, self.length do
		local index = i + offset
		if index > self.length then
			index = index - self.length
		end
		colors[#colors + 1] = self.colors[index]
	end

	return colors
end

function Palette:set_color_unpacked(index, r, g, b, a)
	self.readonly = false
    local t = self.shader_vecs[index]
    local c = self.colors[index]
    t[1] = r
    t[2] = g
    t[3] = b
    t[4] = a or 1
    c.r = r
    c.g = g
    c.b = b
	c.a = a or 1
	self.dirty = true
	-- self.color_indices[index] = c
end

function Palette:set_color(index, color)
    self:set_color_unpacked(index, color.r, color.g, color.b, color.a)
end

function Palette:tick_color(tick, offset, tick_length)
    tick = tick or gametime.tick
    offset = offset or 0
    tick_length = tick_length or 1
    local color = self.colors[floor(((tick / tick_length) + offset) % self.length) + 1]
    return color
end

function Palette:get_swapped_color(color, other_palette, offset)
	offset = offset or 0
	local color_index = self:get_color_index(color)
	return other_palette:get_color(color_index + offset)
end

function Palette:get_swapped_color_unpacked(r, g, b, other_palette, offset)
	offset = offset or 0
    local color_index = self:get_color_index_unpacked(r, g, b)
	if color_index == nil then
		return Color(r, g, b, 1)
	end
	return other_palette:get_color(color_index + offset)
end

function Palette:new_mapped(mapping)
	local colors = {}
	for i, color in ipairs(self.colors) do
		colors[i] = mapping(color)
	end
    return Palette(colors)
end

function Palette:get_random_color()
	return self.colors[rng:randi(1, self.length)]
end

function Palette:sub_cycle()
end

function Palette:check_dirty(offset)
	if self.dirty then
		return true
	end

    if self.cached_shader_offset ~= offset then
        return true
    end
	return false
end

function Palette:get_shader(offset)
    offset = offset or 0
    offset = offset % self.length
	
    if self:check_dirty(offset) then
        rawset(self, "dirty", true)
    end
	
    if (not self.dirty) and self.cached_shader then
        return self.cached_shader
    end

	rawset(self, "dirty", false)
    local decode_palette_shader = self.palette_image and graphics.shader.decode_palette_with_image or graphics.shader.decode_palette
    decode_palette_shader:send("palette_size", self.length)
	if self.palette_image then
		decode_palette_shader:send("palette", self.palette_image)
	else
		decode_palette_shader:send("palette", self:to_shader_table())
	end
	decode_palette_shader:send("palette_offset", offset)
    rawset(self, "cached_shader", decode_palette_shader)
    return decode_palette_shader
end

function Palette.load()

end

local PaletteStack = Object:extend("PaletteStack")

function PaletteStack:new(...)
    self.palettes = {}
    self.offsets = {}
	self.cached_shader = nil
	self.cached_shader_table = {}
    self.dirty = false
	self.length = 0
	self.num_palettes = 0
	self.global_offset_to_palette = {}
	self.palette_to_palette_start_offset = {}
    self.palette_to_palette_index = {}
    local palettes = { ... }
    for i=1, #palettes do
		self:push(palettes[i])
	end
end

function PaletteStack:push(palette, length_in_stack)
    if Object.is(palette, Color) then
        palette = Palette({ palette })
    else
		palette = palette:clone()
	end
	length_in_stack = length_in_stack or palette.length
	local tinsert = table.insert
	tinsert(self.palettes, palette)
	tinsert(self.offsets, 0)
	local len = #self.global_offset_to_palette
	for i=len+1, len+length_in_stack do
		self.global_offset_to_palette[i] = palette
	end
	self.palette_to_palette_start_offset[palette] = len+1
	self.num_palettes = self.num_palettes+1
	self.palette_to_palette_index[palette] = self.num_palettes
    self.length = self.length + length_in_stack
	self.dirty = true
end

function PaletteStack:set_palette_offset(index, offset)
	self.offsets[floor(index)] = floor(offset)
	self.dirty = true
end

function PaletteStack:set_color(offset, color)
	offset = offset or 1
	offset = (offset - 1) % self.length + 1
	local palette = self.global_offset_to_palette[offset]
    local start_offset = self.palette_to_palette_start_offset[palette]
	offset = offset - start_offset + 1
	palette:set_color(offset, color)
	self.dirty = true
end

function PaletteStack:get_color(offset)
	offset = offset or 1
	offset = (offset) % self.length + 1
	local palette = self.global_offset_to_palette[offset]
	local start_offset = self.palette_to_palette_start_offset[palette]
	offset = offset - start_offset + 1
	return palette:get_color(offset + self.offsets[self.palette_to_palette_index[palette]])
end

function PaletteStack:get_shader(offset)
    local dirty = self.dirty

    local decode_palette_shader = graphics.shader.decode_palette
	
	local tinsert = table.insert
	if (dirty or not (self.cached_shader)) then
        self.cached_shader = nil
        self.cached_shader_table = {}
        for i = 1, self.length do
            tinsert(self.cached_shader_table, self:get_color(floor(i + offset - 1)):to_shader_table())
        end
    end
	
    decode_palette_shader:send("palette_size", self.length)
    decode_palette_shader:send("palette_offset", offset)
	-- table.pretty_print(self.cached_shader_table)
    decode_palette_shader:send("palette", unpack(self.cached_shader_table))
	-- table.pretty_print(self.cached_shader_table)

	self.dirty = false
	self.cached_shader = decode_palette_shader
    
	return decode_palette_shader
end

function PaletteStack:get_color_array(offset)
    local colors = {}
    -- for i = 1, self.num_palettes do
    -- 	local new_array = self.palettes[i]:get_color_array(self.offsets[i])
    -- 	table.extend(colors, new_array)
    -- end
	local tinsert = table.insert
    for i = 1, self.length do
        tinsert(colors, self:get_color(floor(i + offset - 1)))
    end
    return colors
end

return { Palette = Palette, PaletteStack = PaletteStack }
