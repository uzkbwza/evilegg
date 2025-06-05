local stringy = setmetatable({}, {__index = string})
utf8 = require "utf8"

function stringy.startswith(s, e)
	return string.match(s, "^" .. e) ~= nil
end

function stringy.endswith(s, e)
	local result = string.match(s, e.."$")
  return result ~= nil
end

function stringy.interpolate(s, ratio)
	local result = s:sub(1, math.floor(ratio * #s))
	return result
end

function stringy.strip_whitespace(s, left, right)
	if left == nil then
		left = true
	end
	if right == nil then
		right = true
	end
	local result = s
	if left then
		result = string.match(result, "^%s*(.-)$")
	end
	if right then
		result = string.match(result, "^(.-)%s*$")
	end

	if result == nil then return s end
	-- local result = string.gsub(s, "^%s*(.-)%s*$", "%1")
	return result
end
-- Function to escape Lua pattern magic characters
local function pattern_escape(char)
    return char:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

function stringy.camelCase2snake_case(str)
    -- First handle consecutive uppercase letters (like "JSON")
    str = str:gsub("(%u)(%u+)", function(first, rest)
        return first .. rest:lower()
    end)
    
    -- Convert camelCase to snake_case, but don't add underscore at the start
    return str:gsub("(%u)", function(c)
        -- Only add underscore if it's not at the start of the string
        if str:find(c) > 1 then
            return "_" .. c
        end
        return c
    end):lower()
end

function stringy.strip_char(s, char, left, right)
    if left == nil then left = true end
    if right == nil then right = true end
    local result = s
    local p_char = pattern_escape(char)
    if left then
        result = string.match(result, "^" .. p_char .. "*(.-)$")
    end
    if right then
        result = string.match(result, "^(.-)" .. p_char .. "*$")
    end
    if result == nil then return s end
    return result
end

function stringy.number_of_lines(str)
	local lines = 0
	for line in str:gmatch("[^\n]+") do
		lines = lines + 1
	end
	return lines
end

function stringy.split(string, substr)
	local t = {}
    if substr == nil or substr == "" then
        string:gsub(".", function(c) table.insert(t, c) end)
        return t
    end
	for str in string.gmatch(string, "([^"..substr.."]+)") do
		table.insert(t, str)
	end
	return t
end

function stringy.join(t, separator)
    local stringy = ""
    local len = #t
    for i, v in ipairs(t) do
        stringy = stringy .. v
        if i < len then
            stringy = stringy .. separator
        end
    end
end

function stringy.filter(str, filter)
    local result = ""
	
    if type(filter) == "string" then
        local chars = filter
        filter = function(c)

            return string.find(chars, c, nil, true)
        end
    end
	
	for i = 1, #str do
		if filter(str:sub(i, i)) then
			result = result .. str:sub(i, i)
		end
	end
	return result
end

function utf8.sub(s, i, j)
    i = utf8.offset(s, i)
    j = utf8.offset(s, j + 1) - 1
    return string.sub(s, i, j)
end

function stringy.fraction(decimal_num, max_denominator)
    max_denominator = max_denominator or 10000

    -- Handle special cases
    if decimal_num == 0 then
        return "0/1"
    end

    -- Handle negative numbers
    local is_negative = decimal_num < 0
    decimal_num = math.abs(decimal_num)

    -- Extract integer part
    local integer_part = math.floor(decimal_num)
    local fractional_part = decimal_num - integer_part

    -- If no fractional part, return as whole number
    if fractional_part == 0 then
        local result = tostring(integer_part)
        return is_negative and "-" .. result or result
    end

    -- Find best fraction approximation using continued fractions method
    local best_numerator = 0
    local best_denominator = 1
    local best_error = math.abs(fractional_part)

    -- Try different denominators
    for denominator = 1, max_denominator do
        local numerator = math.floor(fractional_part * denominator + 0.5)
        local error = math.abs(fractional_part - numerator / denominator)

        if error < best_error then
            best_numerator = numerator
            best_denominator = denominator
            best_error = error

            -- If we found exact match, break
            if error < 1e-10 then
                break
            end
        end
    end

    -- Add integer part to numerator
    best_numerator = best_numerator + integer_part * best_denominator

    -- Simplify the fraction
    local gcd = gcd(best_numerator, best_denominator)
    best_numerator = best_numerator / gcd
    best_denominator = best_denominator / gcd

    -- Format result
    local result = best_numerator .. "/" .. best_denominator
    return is_negative and "-" .. result or result
end

return stringy
