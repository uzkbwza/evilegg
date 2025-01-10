Animation = Object:extend("Animation")
--[[
local a = Animation(
		1, textures.ball1,
		5, textures.ball2,
		9, textures.ball3,
		13, "end"
)

-- same as above
local a2 = Animation.from_sequence("ball", 1, 3, 4) 

a:get_frame(1) -- returns textures.ball1
a:get_frame(14) -- returns nil
a:get_frame(14, "loop") -- returns textures.ball1
a:get_frame(14, "clamp") -- returns textures.ball3
]]

function Animation:new(...)
	local frame_table = {}
	local args = {...}
	if type(args[1]) == "table" then 
		frame_table = args[1]
	else
		for i=1,table.length(args),2 do 
			local frame = args[i]
			local tex = args[i+1]
			if type(tex) == "string" and tex ~= "end" then tex = textures[tex] end
			frame_table[frame] = tex
		end
		
	end

	assert(frame_table[1] ~= nil, "animation must start on frame 1")
	assert(not table.is_empty(frame_table), "no frames passed")
	self.data = self:process_frame_table(frame_table)

end

function Animation.from_sequence(tex_name, start_tex, finish_tex, frame_duration)
	local frames = {}
	local num_frames = finish_tex - start_tex
	for i=1, (num_frames + 2) do 
		frames[1 + ((i - 1) * frame_duration)] = i == num_frames + 2 and "end" or textures[tex_name .. i]
	end
	return Animation(frames)
end

function Animation:get_frame(delta, loop_type)
    if delta < 1 then
        error("delta must be greater than or equal to 1")	
	end
	local frame_number = 1
	if loop_type == nil then
		frame_number = floor(delta)
	elseif loop_type == "loop" then
		frame_number = 1 + floor(delta) % self.data.anim_length
	elseif loop_type == "clamp" then
		frame_number = clamp(floor(delta), 1, self.data.anim_length)
	else
		error("invalid loop type passed: " .. tostring(loop_type))
	end

	return self.data.frames[frame_number]
end

function Animation:process_frame_table(frames)
	local frame_updates = {}
	local output_table = {
		frames = {}
	}
	local end_index = math.huge
	for frame, tex in pairs(frames) do
		assert(type(frame) == "number", "invalid frame value passed: " .. tostring(frame))
		table.insert(frame_updates, frame)
		::continue::
	end
	
	table.sort(frame_updates)

	local anim_length = 1
	for update, current in ipairs(frame_updates) do
		local next = frame_updates[update+1]
		if next then 
			for j=current,next - 1 do 
				output_table.frames[j] = frames[current]
				anim_length = j
			end
		end
	end

	output_table.anim_length = anim_length

	return output_table
end


return Animation
