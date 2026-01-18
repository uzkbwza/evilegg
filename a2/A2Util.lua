local M = {}


-- does an array contain a value?
function M.array_contains(array, element)
    for i, val in ipairs(array) do
        if val == element then
            return true
        end
    end
    return false
end


function M.md5(str)
    -- this spawns a deprecation warning but I can't figure out what version of the function it wants me to use!
    -- turning off deprecation warnings altogether
    love.setDeprecationOutput(false)

    local raw = love.data.hash("md5", str)

    -- convert from raw bytes to string
    local hex = ""    
    for i = 1, #raw do
        hex = hex .. string.format("%02x", string.byte(raw, i))
    end
    return hex
end


function M.file_md5(filename)
    return M.md5(love.filesystem.read(filename))
end


-- Turns an array into a comma-delimited string (without JSON brackets)
function M.comma_delimited_str(arr)
	local ret = ""
	local first = true
	for i,o in ipairs(arr) do
		if not first then
			ret = ret .. ","
        end
		first = false
		ret = ret .. tostring(o)
    end
	return ret
end


-- Returns false if string is null or empty, true if it's "truthy"
function M.str_bool(str)
    return str ~= nil and str ~= ""
end

return M