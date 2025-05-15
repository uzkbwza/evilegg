local stringy = setmetatable({}, {__index = string})
utf8 = require "utf8"

function stringy.startswith(s, e)
	return string.match(s, "^" .. e) ~= nil
end

function stringy.endswith(s, e)
	local result = string.match(s, e.."$")
  return result ~= nil
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
		stringy = stringy..v
		if i < len then
			stringy = stringy..separator
		end
	end
end

function utf8.sub(s,i,j)
    i=utf8.offset(s,i)
    j=utf8.offset(s,j+1)-1
    return string.sub(s,i,j)
end

return stringy
