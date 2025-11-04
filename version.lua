
local function read_game_version()
	if love and love.filesystem and love.filesystem.read then
		local contents = love.filesystem.read("string", "version.txt")
		if contents and #contents > 0 then
			contents = contents:gsub("%s+$", "")
			return contents
		end
	end
	local f = io.open("version.txt", "r")
	if f then
		local c = f:read("*a")
		f:close()
		if c and #c > 0 then
			c = c:gsub("%s+$", "")
			return c
		end
	end
	return nil
end

return read_game_version()
