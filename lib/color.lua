Color = Object:extend("Color")

function Color:new(r, g, b, a)
    self.r = r or 1
    self.g = g or 1
    self.b = b or 1
    self.a = a or 1
end

function Color:clone()
	return Color(self.r, self.g, self.b, self.a)
end

function Color:unpack()
    return self.r, self.g, self.b, self.a
end

function Color:to_shader_table()
    return {self.r, self.g, self.b, self.a}
end

function Color:__tostring()
    return "Color: [" .. tostring(self.r) .. ", " ..
    tostring(self.g) .. ", " .. tostring(self.b) .. ", " .. tostring(self.a) .. "]"
end

function Color.from_hex(str)
    return Color(
        Color.from_hex_unpack(str))
end

local hex_color_cache = {}
local hex_color_cache_order = bonglewunch()
local hex_color_cache_size = 0
local hex_color_cache_max_size = 100

function Color.from_hex_unpack(str)

	local original_str = str

    if hex_color_cache[original_str] then
		local c = hex_color_cache[original_str]
		return c.r, c.g, c.b, c.a
	end


    if str:sub(1, 1) == "#" then
        str = str:sub(2)
    end
	
    if #str == 3 then
		-- local new_str = str
        local new_str = str:sub(1, 1) .. str:sub(1, 1) .. str:sub(2, 2) .. str:sub(2, 2) .. str:sub(3, 3) .. str:sub(3, 3)
		str = new_str
	end

    local r,g,b,a = tonumber("0x" .. string.sub(str, 1, 2)) / 255,
           tonumber("0x" .. string.sub(str, 3, 4)) / 255,
           tonumber("0x" .. string.sub(str, 5, 6)) / 255,
           1


    hex_color_cache[original_str] = Color(r, g, b, a)
	hex_color_cache_order:push(original_str)
    hex_color_cache_size = hex_color_cache_size + 1

    while hex_color_cache_size > hex_color_cache_max_size do
		local oldest_str = hex_color_cache_order:pop_at(1)
		hex_color_cache[oldest_str] = nil
		hex_color_cache_size = hex_color_cache_size - 1
	end
	
	return r, g, b, a
end


function Color:__add(other)
	if type(other) == "number" then
		return Color(self.r + other, self.g + other, self.b + other, self.a)
	end
	return Color(self.r + other.r, self.g + other.g, self.b + other.b, self.a + other.a)
end

function Color:__sub(other)
	if type(other) == "number" then
		return Color(self.r - other, self.g - other, self.b - other, self.a)
	end
    return Color(self.r - other.r, self.g - other.g, self.b - other.b, self.a - other.a)
end

function Color:__mul(other)
	if type(other) == "number" then
		return Color(self.r * other, self.g * other, self.b * other, self.a)
	end
    return Color(self.r * other.r, self.g * other.g, self.b * other.b, self.a * other.a)
end

function Color:__div(other)
	if type(other) == "number" then
		return Color(self.r / other, self.g / other, self.b / other, self.a)
	end
    return Color(self.r / other.r, self.g / other.g, self.b / other.b, self.a / other.a)
end

function Color:__eq(other)
    return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a
end

function Color:__lt(other)
	if type(other) == "number" then
		return self.r < other and self.g < other and self.b < other and self.a < other
	end
    return self.r < other.r and self.g < other.g and self.b < other.b and self.a < other.a
end

function Color:__le(other)
	if type(other) == "number" then
		return self.r <= other and self.g <= other and self.b <= other and self.a <= other
	end
    return self.r <= other.r and self.g <= other.g and self.b <= other.b and self.a <= other.a
end

function Color:replace(r, g, b, a)
	return Color(r or self.r, g or self.g, b or self.b, a or self.a)
end


function Color:lerp(other, t)
	return Color(self.r + (other.r - self.r) * t, self.g + (other.g - self.g) * t, self.b + (other.b - self.b) * t, self.a + (other.a - self.a) * t)
end

function Color:distance_to(other)
    return vec3_distance_to(self.r, self.g, self.b, other.r, other.g, other.b)
end

function Color:distance_squared_to(other)
    return vec3_distance_squared(self.r, self.g, self.b, other.r, other.g, other.b)
end

function Color:is_approx_equal(other, threshold)
    local threshold = threshold or 0.01
    return self:distance_squared_to(other) < threshold
end

function Color.is_approx_equal_unpacked(r, g, b, r2, g2, b2, threshold)
    local threshold = threshold or 0.001
    return vec3_distance_squared(r, g, b, r2, g2, b2) < threshold
end

function Color.encode_palette_unpacked(r, g, b, a, palette)
    if a == 0 then
        return 0, 0, 0, 0
    end

    local index = -1

    for i, p in ipairs(palette) do
        if Color.is_approx_equal_unpacked(r, g, b, p.r, p.g, p.b) then
            index = i
            break
        end
    end

    return 0, index / 255, 0, 1
end

function Color.decode_palette_unpacked(r, g, b, a, palette)
    local index = (g * 255)
	local col = palette[((index - 1) % #palette) + 1]
	return col.r, col.g, col.b, a
end

-- slower version, makes things easier to see in the output image
-- function Color.encode_palette_unpacked(r, g, b, a, palette)
--     if a == 0 then
--         return 0, 0, 0, 0
--     end
--     local index = -1
--     for i, p in ipairs(palette) do
--         if Color.is_approx_equal_unpacked(r, g, b, p.r, p.g, p.b) then
--             index = i
-- 			break
--         end

--     end
--     if index == -1 then
--         return Color.magenta.r, Color.magenta.g, Color.magenta.b, a
--     end

--     local r = bit.band(bit.rshift(index, 5), 0x07) / 8.0 -- 0111
--     local g = bit.band(bit.rshift(index, 2), 0x07) / 8.0
--     local b = bit.band(index, 0x03) / 4.0

--     --[[
	
-- 	given index = 109 (01101100)
	
-- 	r = 01101101
-- 		>> 5
-- 	  = 00000011
-- 	  	&   0111
-- 	  = 00000011
-- 	  = 3

-- 	g = 01101101
-- 		>> 2
-- 	  = 00011011
-- 	    &   0111
-- 	  = 00000011
-- 	  = 3

-- 	b = 01101101
-- 		&   0001
-- 	  = 00000001
-- 	  = 1

-- 	r / 8 = 0.375
-- 	g / 8 = 0.375
-- 	b / 4 = 0.125

-- 	]]

--     return r, g, b, a
-- end

-- function Color.decode_palette_unpacked(r, g, b, a, palette)
--     r = bit.lshift(round(r * 8.0), 5)
--     g = bit.lshift(round(g * 8.0), 2)
--     b = round(b * 4.0)
--     local index = bit.bor(r, g, b)
-- 	local col = palette[((index - 1) % #palette) + 1]
-- 	return col.r, col.g, col.b, a
-- end

function Color:encode_palette(palette)
    local r, g, b, a = Color.encode_palette_unpacked(self.r, self.g, self.b, self.a, palette)
    return Color(r, g, b, a)
end

function Color:decode_palette(palette)
    local r, g, b, a = Color.decode_palette_unpacked(self.r, self.g, self.b, self.a, palette)
    return Color(r, g, b, a)
end


-----------------------------
--- HSL
-----------------------------

function Color:to_hsl()
    local r, g, b = self.r, self.g, self.b
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l
    
    l = (max + min) / 2
    
    if max == min then
        h = 0
        s = 0
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        
        h = h / 6
    end
    
    return h, s, l
end

function Color:get_hue()
    local h, _, _ = self:to_hsl()
    return h
end

function Color:get_saturation()
    local _, s, _ = self:to_hsl()
    return s
end

function Color:get_lightness()
    local _, _, l = self:to_hsl()
    return l
end
function Color.hue_to_rgb(p, q, t)
	if t < 0 then t = t + 1 end
	if t > 1 then t = t - 1 end
	if t < 1/6 then return p + (q - p) * 6 * t end
	if t < 1/2 then return q end
	if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
	return p
end
function Color.from_hsl(h, s, l, a)
	return Color(Color.from_hsl_unpacked(h, s, l, a))
end

function Color.from_hsl_unpacked(h, s, l, a)
    if s == 0 then
        return l, l, l, a
    end
	
	local r, g, b

	local q = l < 0.5 and l * (1 + s) or l + s - l * s
	local p = 2 * l - q

	r = Color.hue_to_rgb(p, q, h + 1/3)
	g = Color.hue_to_rgb(p, q, h)
	b = Color.hue_to_rgb(p, q, h - 1/3)

    return r, g, b, a
end

function Color:with_hue(h)
    local _, s, l = self:to_hsl()
    return Color.from_hsl(h, s, l, self.a)
end

function Color:with_saturation(s)
    local h, _, l = self:to_hsl()
    return Color.from_hsl(h, s, l, self.a)
end

function Color:with_lightness(l)
    local h, s, _ = self:to_hsl()
    return Color.from_hsl(h, s, l, self.a)
end

function Color:adjust_hue(amount)
    local h, s, l = self:to_hsl()
    return Color.from_hsl((h + amount) % 1, s, l, self.a)
end

function Color:adjust_saturation(amount)
    local h, s, l = self:to_hsl()
    return Color.from_hsl(h, math.max(0, math.min(1, s + amount)), l, self.a)
end

function Color:adjust_lightness(amount)
    local h, s, l = self:to_hsl()
    return Color.from_hsl(h, s, math.max(0, math.min(1, l + amount)), self.a)
end

function Color:lerp_hsl(other, t)
    local h, s, l = self:to_hsl()
    local h2, s2, l2 = other:to_hsl()
    return Color.from_hsl(h + (h2 - h) * t, s + (s2 - s) * t, l + (l2 - l) * t, self.a)
end


function Color.to_hsl_unpacked(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l
    
    l = (max + min) / 2
    
    if max == min then
        h = 0
        s = 0
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        
        h = h / 6
    end
    
    return h, s, l
end

function Color.hsl_to_rgb_unpacked(h, s, l)
    local r, g, b

    -- if s == 0 then
    --     r, g, b = l, l, l
    -- else
	local function hue_to_rgb(p, q, t)
		if t < 0 then t = t + 1 end
		if t > 1 then t = t - 1 end
		if t < 1/6 then return p + (q - p) * 6 * t end
		if t < 1/2 then return q end
		if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
		return p
	end

	local q = l < 0.5 and l * (1 + s) or l + s - l * s
	local p = 2 * l - q

	r = hue_to_rgb(p, q, h + 1/3)
	g = hue_to_rgb(p, q, h)
	b = hue_to_rgb(p, q, h - 1/3)
    -- end

    return r, g, b
end

function Color.adjust_hue_unpacked(r, g, b, amount)
    local h, s, l = Color.to_hsl_unpacked(r, g, b)
    return Color.hsl_to_rgb_unpacked((h + amount) % 1, s, l)
end

function Color.adjust_saturation_unpacked(r, g, b, amount)
    local h, s, l = Color.to_hsl_unpacked(r, g, b)
    return Color.hsl_to_rgb_unpacked(h, math.max(0, math.min(1, s * amount)), l)
end

function Color.adjust_lightness_unpacked(r, g, b, amount)
    local h, s, l = Color.to_hsl_unpacked(r, g, b)
    return Color.hsl_to_rgb_unpacked(h, s, math.max(0, math.min(1, l * amount)))
end

function Color.with_hue_unpacked(r, g, b, new_hue)
    local _, s, l = Color.to_hsl_unpacked(r, g, b)
    return Color.hsl_to_rgb_unpacked(new_hue, s, l)
end

function Color.with_saturation_unpacked(r, g, b, new_saturation)
    local h, _, l = Color.to_hsl_unpacked(r, g, b)
    return Color.hsl_to_rgb_unpacked(h, new_saturation, l)
end

function Color.with_lightness_unpacked(r, g, b, new_lightness)
    local h, s, _ = Color.to_hsl_unpacked(r, g, b)
    return Color.hsl_to_rgb_unpacked(h, s, new_lightness)
end

function Color.lerp_hsl_unpacked(h1, s1, l1, h2, s2, l2, t)
    return Color.hsl_to_rgb_unpacked(h1 + (h2 - h1) * t, s1 + (s2 - s1) * t, l1 + (l2 - l1) * t)
end

local interval = 1/6
Color.black = Color.from_hex("000000")
Color.nearblack = Color.from_hex("101010")
-- Color.darkergrey = Color.from_hsl(0, 0, ease("inOutCirc")(interval))
Color.darkergrey = Color.from_hex("202020")
-- Color.darkgrey = Color.from_hsl(0, 0, ease("inOutCirc")(interval * 2))
Color.darkgrey = Color.from_hex("404040")
-- Color.grey = Color.from_hsl(0, 0, ease("inOutCirc")(interval * 3))
Color.grey = Color.from_hex("808080")
-- Color.lightgrey = Color.from_hsl(0, 0, ease("inOutCirc")(interval * 4))
Color.lightgrey = Color.from_hex("bfbfbf")
-- Color.lightergrey = Color.from_hsl(0, 0, ease("inOutCirc")(interval * 5))
Color.lightergrey = Color.from_hex("e0e0e0")
Color.white = Color.from_hex("FFFFFF")
Color.red = Color.from_hex("FF0000")
Color.skyblue = Color.from_hex("0080ff")
Color.cyan = Color.from_hex("00FFFF")
Color.blue = Color.from_hex("0000FF")
Color.green = Color.from_hex("00FF00")
Color.yellow = Color.from_hex("FFFF00")
Color.orange = Color.from_hex("FF8000")
Color.purple = Color.from_hex("8000FF")
Color.magenta = Color.from_hex("FF00FF")
Color.pink = Color.from_hex("ff80ff")
Color.brown = Color.from_hex("804000")
Color.darkyellow = Color.from_hex("808000")
Color.darkblue = Color.from_hex("000080")
Color.darkskyblue = Color.from_hex("004280")
Color.darkgreen = Color.from_hex("008000")
Color.darkergreen = Color.from_hex("004000")
Color.darkmagenta = Color.from_hex("800080")
Color.darkcyan = Color.from_hex("008080")
Color.darkred = Color.from_hex("800000")
Color.darkpurple = Color.from_hex("400080")
Color.navyblue = Color.from_hex("000080")
Color.alpha_mask = Color.from_hex("ffffff")
Color.transparent = Color(0, 0, 0, 0)
