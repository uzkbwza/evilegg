local audio = {
    sfx = nil,
    music = nil,
    playing_music = nil,
	base_master_volume = 1.0,
    -- sfx_volume = 1.0,
    -- music_volume = 1.0,
    default_rolloff = 0.00000001,
    default_z_index = 0,
    sound_objects = {},
    object_sounds = {},
    sfx_names = {},
	object_started_sources = {},
	sources_to_remove = {},
	screen_sounds = {},
	sound_screens = {},
	-- max_volume = 1.0,
}

audio = setmetatable(audio, { __index = love.audio })

-- TODO: audio bus? sound pool? volume control, etc

function audio.load()
    local sfx = {}
    local music = {}
    audio.sfx = sfx
    audio.music = music

    -- audio.set_effect("global", {
	-- type = "equalizer",
	-- highcut = 9000,
	-- highgain = 0.8,
	-- 	lowgain = 1.2
	-- })
	-- print("i'm a global lowpass, don't forget about me!")
    -- audio.set_volume(0.5)
	
    local wav_paths = filesystem.get_files_of_type("assets/audio", "wav", true)
    local ogg_paths = filesystem.get_files_of_type("assets/audio", "ogg", true)

	for _, v in ipairs(wav_paths) do
        local sound = audio.newSource(v, "static")
		sound:setEffect("global")
		local name = filesystem.filename_to_asset_name(v, "wav", "audio_")
		if sfx[name] then
			asset_collision_error(name, v, wav_paths[name])
		end
		sfx[name] = sound
		audio.sfx_names[sound] = name
	end
	
	dbg("num sfx loaded", table.length(sfx))
	
	
    for _, v in ipairs(ogg_paths) do
        local sound = audio.newSource(v, "stream")
		sound:setEffect("global")
        local name = filesystem.filename_to_asset_name(v, "ogg", "audio_")
        if music[name] then
            asset_collision_error(name, v, ogg_paths[name])
        end
        music[name] = sound
    end



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
	
	-- Clean up object_started_sources for sources that are no longer playing
	table.clear(audio.sources_to_remove)
	for src_name, _ in pairs(audio.object_started_sources) do
		local src = audio.get_global_sfx(src_name)
		if not src:isPlaying() then
			table.insert(audio.sources_to_remove, src_name)
		end
	end
	
	-- Remove the sources that are no longer playing
	for _, src_name in ipairs(audio.sources_to_remove) do
		audio.object_started_sources[src_name] = nil
		if audio.sound_screens and audio.sound_screens[src_name] then
			for screen, _ in pairs(audio.sound_screens[src_name]) do
				if audio.screen_sounds[screen] then
					audio.screen_sounds[screen][src_name] = nil
					if table.is_empty(audio.screen_sounds[screen]) then
						audio.screen_sounds[screen] = nil
					end
				end
			end
			audio.sound_screens[src_name] = nil
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

function audio.play_sfx_object_if_stopped(object, src_name, volume, pitch, loop, screen)
	local src = audio.get_global_sfx(src_name)
	if not src:isPlaying() then
		audio.play_sfx_object(object, src_name, volume, pitch, loop, screen)
	end
end

function audio.play_sfx_object(object, src_name, volume, pitch, loop, screen)
	local src = audio.get_global_sfx(src_name)

    if not audio.sound_objects[src_name] then
        audio.sound_objects[src_name] = {}
    end
	audio.object_sounds[object] = audio.object_sounds[object] or {}
    audio.sound_objects[src_name][object] = true
    audio.object_sounds[object][src_name] = true
	
	-- Track that this source was started by an object
	audio.object_started_sources[src_name] = true
	
    if screen then
        audio.screen_sounds[screen] = audio.screen_sounds[screen] or {}
        audio.screen_sounds[screen][src_name] = true

        audio.sound_screens[src_name] = audio.sound_screens[src_name] or {}
        audio.sound_screens[src_name][screen] = true

        if not signal.is_connected(screen, "destroyed", audio, "cleanup_screen") then
            signal.connect(screen, "destroyed", audio, "cleanup_screen", function()
                audio.cleanup_screen(screen)
            end)
        end
    end

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

function audio.stop_all_object_sfx(screen)
	if screen then
		-- Stop only sounds on a specific screen
		if not audio.screen_sounds or not audio.screen_sounds[screen] then
			return
		end

		local sources_to_stop = {}
		for src_name, _ in pairs(audio.screen_sounds[screen]) do
			table.insert(sources_to_stop, src_name)
		end

		for _, src_name in ipairs(sources_to_stop) do
			audio.stop_sfx_monophonic(src_name)
		end
	else
		-- Stop all sources that were ever started by objects
		local sources_to_stop = {}
		for src_name, _ in pairs(audio.object_started_sources) do
			table.insert(sources_to_stop, src_name)
		end
		for _, src_name in ipairs(sources_to_stop) do
			audio.stop_sfx_monophonic(src_name)
		end

		-- Clear the tracking table since all sources are now stopped
		table.clear(audio.object_started_sources)
		
		-- Also clear the object tracking tables since all sources are stopped
		table.clear(audio.sound_objects)
		table.clear(audio.object_sounds)
		table.clear(audio.screen_sounds)
		table.clear(audio.sound_screens)
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
	audio.set_volume(usersettings.master_volume * audio.base_master_volume)
end

function audio.stop_music()

	if audio.playing_music then
		audio.playing_music:stop()
		audio.playing_music = nil
	end
end

function audio.cleanup_screen(screen)
    if audio.screen_sounds[screen] then
        for src_name, _ in pairs(audio.screen_sounds[screen]) do
            if audio.sound_screens[src_name] then
                audio.sound_screens[src_name][screen] = nil
                if table.is_empty(audio.sound_screens[src_name]) then
                    audio.sound_screens[src_name] = nil
                end
            end
        end
        audio.screen_sounds[screen] = nil
    end
end

return audio
