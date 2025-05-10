local audio = {
    sfx = nil,
    music = nil,
	playing_music = nil,
    -- sfx_volume = 1.0,
    -- music_volume = 1.0,
    default_rolloff = 0.00000001,
    default_z_index = 0,
    sound_objects = {},
    object_sounds = {},
	-- max_volume = 1.0,
}

audio = setmetatable(audio, { __index = love.audio })

-- TODO: audio bus? sound pool? volume control, etc

function audio.load()
    local sfx = {}
    local music = {}
    audio.sfx = sfx
    audio.music = music

    local wav_paths = filesystem.get_files_of_type("assets/audio", "wav", true)
    local ogg_paths = filesystem.get_files_of_type("assets/audio", "ogg", true)

	for _, v in ipairs(wav_paths) do
		local sound = audio.newSource(v, "static")
		local name = filesystem.filename_to_asset_name(v, "wav", "audio_")
		if sfx[name] then
			asset_collision_error(name, v, wav_paths[name])
		end
		sfx[name] = sound
	end
	
	dbg("num sfx loaded", table.length(sfx))


    for _, v in ipairs(ogg_paths) do
        local sound = audio.newSource(v, "stream")
        local name = filesystem.filename_to_asset_name(v, "ogg", "audio_")
        if music[name] then
            asset_collision_error(name, v, ogg_paths[name])
        end
        music[name] = sound
    end

	audio.set_volume(1.0)

end

function audio.update(dt)
    for src_name, objects in pairs(audio.sound_objects) do
		local src = audio.get_global_sfx(src_name)
        if not src:isPlaying() then
            for object, _ in pairs(objects) do
                audio.remove_object_sound(object, src_name)
            end
        end
    end
    if debug.enabled then
		-- dbg("audio.object_sounds", table.length(audio.sound_objects))
	end
end

function audio.set_position(x, y, z)
    -- love.audio.set_position(x, y, z or audio.default_z_index)
end

function audio.play_sfx_monophonic(name, volume, pitch, loop)
    local src = audio.get_global_sfx(name)
    audio.play_sfx(src, volume, pitch, loop)
end

function audio.stop_sfx_monophonic(name)
    local src = audio.get_global_sfx(name)
    audio.stop_sfx(src)
end


function audio.play_sfx(src, volume, pitch, loop)
    if src:isPlaying() then
        src:stop()
    end
    if loop == nil then loop = false end
    src:setVolume(volume and (volume * usersettings.sfx_volume) or usersettings.sfx_volume)
    src:setPitch(pitch or 1.0)
    src:setLooping(loop)
    src:play()
end

function audio.stop_sfx(src)
    src:stop()
end

function audio.cleanup_sound_objects(src_name)
	for object, _ in pairs(audio.sound_objects[src_name]) do
		audio.sound_objects[src_name][object] = nil
	end
end

function audio.play_sfx_object_if_stopped(object, src_name, volume, pitch, loop)
	local src = audio.get_global_sfx(src_name)
	if not src:isPlaying() then
		audio.play_sfx_object(object, src_name, volume, pitch, loop)
	end
end

function audio.play_sfx_object(object, src_name, volume, pitch, loop)
	local src = audio.get_global_sfx(src_name)

    if not audio.sound_objects[src_name] then
        audio.sound_objects[src_name] = {}
    end
	audio.object_sounds[object] = audio.object_sounds[object] or {}
    audio.sound_objects[src_name][object] = true
    audio.object_sounds[object][src_name] = true
    if not signal.is_connected(object, "destroyed", audio, "cleanup_object") then
        signal.connect(object, "destroyed", audio, "cleanup_object", function()
            audio.cleanup_object(object)
        end)
    end
	audio.play_sfx(src, volume, pitch, loop)
end

function audio.cleanup_object(object)
	if audio.object_sounds[object] then
		for src, _ in pairs(audio.object_sounds[object]) do
			audio.remove_object_sound(object, src)
		end
	end
end

function audio.remove_object_sound(object, src_name)
    if audio.object_sounds[object] then
        if audio.object_sounds[object][src_name] then
            audio.object_sounds[object][src_name] = nil
        end
    end
	if audio.sound_objects[src_name] then
		if audio.sound_objects[src_name][object] then
            audio.sound_objects[src_name][object] = nil
		end
	end
    if audio.object_sounds[object] and table.is_empty(audio.object_sounds[object]) then
        audio.object_sounds[object] = nil
    end
	if audio.sound_objects[src_name] and table.is_empty(audio.sound_objects[src_name]) then
		audio.sound_objects[src_name] = nil
	end
end

function audio.stop_sfx_object(object, src_name)
    audio.remove_object_sound(object, src_name)
    if (audio.sound_objects[src_name] == nil) then
		audio.stop_sfx_monophonic(src_name)
	end
end


function audio.get_global_sfx(name)
    if not audio.sfx[name] then
        error("SFX not found: " .. tostring(name))
    end
    return audio.sfx[name]
end

function audio.get_music(name)
    if not audio.music[name] then
        error("Music not found: " .. name) 
    end
    return audio.music[name]
end

function audio.get_sfx(name)
	if not audio.sfx[name] then
		error("SFX not found: " .. name)
	end
	return audio.sfx[name]:clone()
end

function audio.play_music_if_stopped(src, volume)

	if type(src) == "string" then
		src = audio.get_music(src)
	end

    if audio.playing_music == src then
        return
    end
	
	audio.play_music(src, volume)
end

function audio.play_music(src, volume)
    if debug.enabled and debug.disable_music then
		return
	end
	
	if type(src) == "string" then
		src = audio.get_music(src)
	end
	audio.stop_music()
    src:setVolume(volume and (volume * usersettings.music_volume) or usersettings.music_volume)
    src:setLooping(true)
    src:play()
    audio.playing_music = src
	audio.playing_music_volume = volume or 1
end

function audio.usersettings_update()
    if audio.playing_music then
        audio.playing_music:setVolume(usersettings.music_volume * audio.playing_music_volume)
    end
end

function audio.stop_music()

	if audio.playing_music then
		audio.playing_music:stop()
		audio.playing_music = nil
	end
end

return audio
