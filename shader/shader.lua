local shader = {}

function shader.load()
    shader.fragment_shader_paths = filesystem.get_files_of_type("shader", "frag", true)
	shader.update()
end

function shader.update()
	print("Updating shaders")
	for _, v in ipairs(shader.fragment_shader_paths) do
		local name = filesystem.filename_to_asset_name(v, "frag")
		-- assert(shader[name] == nil, "Shader name collision: " .. name) 
		shader[name] = love.graphics.new_shader(v)
	end
end


return shader
