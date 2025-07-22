
local filesystem = setmetatable({}, { __index = love.filesystem })

function filesystem.get_files_of_type(folder, extension, recursive)
	if type(folder) == "table" then
		local output = {}
		for _, v in ipairs(folder) do
			for _, v2 in ipairs(filesystem.get_files_of_type(v, extension, recursive)) do
				table.insert(output, v2)
			end
		end
		return output
	end
	extension = extension or "*"
	recursive = recursive or false
	folder = string.strip_whitespace(folder) or ""

	if folder == "" then
		print("root directory won't be scanned")
	end
	local all = filesystem.get_directory_items(folder)
	local output = {}
	for _,v in ipairs(all) do
		local file_path = folder.."/"..v
		local info = filesystem.get_info(file_path)
		if info then
			if info.type == "file" and folder ~= "" then

				if extension == "*" then
					table.insert(output, file_path)
				else if string.endswith(file_path, extension) then
						table.insert(output, file_path)
					end
				end
			elseif recursive and info.type == "directory" then
				for _, v2 in ipairs(filesystem.get_files_of_type(file_path, extension, true)) do
					table.insert(output, v2)
				end
			end
		end
		::continue::
	end
	return output
end

function filesystem.filename_to_asset_name(filename, extension, prefix)
	prefix = prefix or ""
	return string.sub(string.gsub(string.match(filename, "/(.+)." .. extension .. "$"), "/", "_"), #prefix + 1)
end

---@alias FileSystem.GetModulesRecursionType "none" | "all" | "init"
---@param path string
---@param recursive? FileSystem.GetModulesRecursionType
---@param t? table
---@param path_prefix? string
function filesystem.get_modules(path, recursive, t, path_prefix)
	recursive = recursive or "none"

    if recursive ~= "none" and recursive ~= "all" and recursive ~= "init" then
        error("incorrect recursion type: " .. tostring(recursive))
    end
	
    path_prefix = path_prefix or ""
	
	t = t or {}
	for _, v in ipairs(filesystem.get_directory_items(path)) do
        if (v:sub(-4) == ".lua") or (conf.use_fennel and v:sub(-4) == ".fnl") then
            local s = v:sub(1, -5)
            if s == "init" and path_prefix == "" then
                goto continue
            end

            if s ~= "init" and recursive == "init" then
                goto continue
            end
			
            local ok, mod = pcall(require, path:gsub("/", ".") .. "." .. s)
            if not ok then
                error("error loading module: " .. path:gsub("/", ".") .. "." .. s .. " " .. mod, 2)
                goto continue
            end
            
            local tab = string.split(path_prefix, ".")
			if s ~= "init" then
				table.insert(tab, s)
			end

			-- print(mod)
			if not type(mod) == "table" then
				error("module is not a table: " .. path:gsub("/", ".") .. "." .. s, 2)
			end

            table.insert(tab, mod)
            table.populate_recursive_from_table(t, tab)
        end
		if recursive then 
            local info = filesystem.getInfo(path .. "/" .. v)
            if info and info.type == "directory" then
                local prefix = v
				if path_prefix ~= "" then prefix = "." .. prefix end
				filesystem.get_modules(path .. "/" .. v, recursive, t, prefix)
			end
		end
		::continue::
	end
	return t
end

function filesystem.path_to_module_name(path)
    -- Remove leading slash if present
    path = path:gsub("^/", "")
    -- Remove file extension
    path = path:gsub("%.[^%.]+$", "")
    -- Replace slashes with dots
    path = path:gsub("/", ".")
    return path
end

function filesystem.get_directory_items(path)
	return love.filesystem.getDirectoryItems(path)	
end

function filesystem.read_file(path)
    local file = filesystem.open_file(path, "r")
    return file:read()
end


function filesystem.write_file(path, data)
    local file = filesystem.open_file(path, "w")
    file:write(data)
    file:close()
end

function filesystem.path_process(path)
    if love.system.getOS() == "Windows" then
        return string.gsub(path, "/", "\\")
    else
        return string.gsub(path, "\\", "/")
    end
end

function filesystem.get_native_separator()
	if love.system.getOS() == "Windows" then
		return "\\"
	else
		return "/"
	end
end

function filesystem.walk_directory_native(path, callback, filter)
    local files = filesystem.get_directory_items_native(path)
    for _, file in ipairs(files) do
        local fullpath = path .. filesystem.get_native_separator() .. file
        if not (filter and not filter(fullpath)) then
            -- print(fullpath)
            if nativefs.get_info(fullpath, "directory") then
                filesystem.walk_directory_native(fullpath, callback, filter)
            else
                callback(fullpath)
            end
        end
    end
end

function filesystem.walk_directory(path, callback, filter)
	local files = filesystem.get_directory_items(path)
	for _, file in ipairs(files) do
		local fullpath = path .. "/" .. file
		if love.filesystem.get_info(fullpath, "directory") then
			filesystem.walk_directory(fullpath, callback, filter)
		else
			callback(fullpath)
		end
	end
end

function filesystem.get_directory_items_native(path)
	local wd = nativefs.get_working_directory()
	local files = nativefs.get_directory_items(wd .. filesystem.path_process(path))
	return files
end

function filesystem.load_file_native(path)
    local wd = nativefs.get_working_directory()
	local fp = filesystem.path_process(wd .. filesystem.get_native_separator() .. path)
    local file = nativefs.new_file(fp)
    file:open("r")
	return file:read()
end

function filesystem.save_file(data, path)
	filesystem.write(path, data)
end

function filesystem.save_file_native(data, path)
    local wd = nativefs.get_working_directory()

	local dirs = string.split(filesystem.path_process(path), filesystem.get_native_separator())
    dirs[#dirs] = nil
	local p = ""
    for _, dir in ipairs(dirs) do
		p = p .. filesystem.get_native_separator() .. dir
		if not nativefs.get_info(wd .. p) then
			nativefs.create_directory(wd .. p)
		end
	end

	local fp = filesystem.path_process(wd .. filesystem.get_native_separator() .. path)
    local file = nativefs.new_file(fp)

	file:open("w")
	file:write(data)
	file:close()
end

function filesystem.remove_file_native(path)
    local wd = nativefs.get_working_directory()
    local fp = filesystem.path_process(wd .. filesystem.get_native_separator() .. path)
    nativefs.remove(fp)
end

function filesystem.remove_directory_native(path)
    local wd = nativefs.get_working_directory()
    local fp = filesystem.path_process(wd .. filesystem.get_native_separator() .. path)

    nativefs.remove_directory_recursive(fp)
end

function filesystem.save_image(image, name)
	local prevcanvas = graphics.get_canvas()
	local canvas = graphics.new_canvas(image:getWidth(), image:getHeight())
	graphics.set_canvas(canvas)
	graphics.clear(0, 0, 0, 0)
	graphics.draw(image)
	graphics.set_canvas(prevcanvas)
	graphics.readback_texture(canvas):encode("png", name .. ".png")
end

return filesystem
