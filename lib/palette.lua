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
	self.color_indices = {}
	for _, color in ipairs(colors) do
		self.colors[#self.colors + 1] = color:clone()
		self.original_colors[#self.original_colors + 1] = color:clone()
		self.shader_vecs[#self.shader_vecs + 1] = { color.r, color.g, color.b }
	end
	self.length = #self.shader_vecs
	self.needs_update_shader = true
	self.cached_shader = nil
	self.cached_shader_offset = nil
	self.palette_image = nil
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
        self.shader_vecs[#self.shader_vecs + 1] = { color.r, color.g, color.b }
    end
	self.length = #self.shader_vecs
end

function Palette:to_shader_table()
        return unpack(self.shader_vecs)
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

function Palette:gradient_hsl(colors, steps_per_color, loop)
    steps_per_color = steps_per_color or 2
	error("not implemented")
end

function Palette:get_color(index)
    return self.colors[(index - 1) % self.length + 1]
end

function Palette:get_color_index_unpacked(r, g, b)
	for i, c in ipairs(self.colors) do
		if c.r == r and c.g == g and c.b == b then
			return i
		end
	end
end

function Palette:get_color_index(color)
	return Palette:get_color_index_unpacked(color.r, color.g, color.b)
end

function Palette:get_color_unpacked(index)
    local color = self.colors[(index - 1) % self.length + 1]
    return color.r, color.g, color.b
end

function Palette:color_to_index(color)
	return self.color_indices[color]
end

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

function Palette:set_color_unpacked(index, r, g, b)
	self.readonly = false
    local t = self.shader_vecs[index]
    local c = self.colors[index]
    t[1] = r
    t[2] = g
    t[3] = b
    c.r = r
    c.g = g
    c.b = b
	self.needs_update_shader = true
	self.color_indices[index] = c
end

function Palette:set_color(index, color)
    self:set_color_unpacked(index, color.r, color.g, color.b)
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
	return self.colors[rng.randi_range(1, self.length)]
end

function Palette:sub_cycle()
end

function Palette:get_shader(offset)
    offset = offset or 0
	offset = offset % self.length
	if self.cached_shader_offset ~= offset then
		rawset(self, "needs_update_shader", true)
	end
    if (not self.needs_update_shader) and self.cached_shader then
        return self.cached_shader
    end
    self.needs_update_shader = false
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

return Palette
