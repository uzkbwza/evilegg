local audio = {
    sfx = nil,
    music = nil,
	playing_music = nil,
    sfx_volume = 1.0,
    music_volume = 1.0,
    default_rolloff = 0.0001,
	default_z_pos = 0
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
        sfx[name] = sound
    end
	
    for _, v in ipairs(ogg_paths) do
        local sound = audio.newSource(v, "stream")
        local name = filesystem.filename_to_asset_name(v, "ogg", "audio_")
        music[name] = sound
    end
end

function audio.set_position(x, y, z)
	-- love.audio.set_position(x, y, z or audio.default_z_pos)
end

function audio.play_sfx(src, volume, pitch, loop)
	if src:isPlaying() then
		src:stop()
	end
	if loop == nil then loop = false end
    src:setVolume(volume and (volume * audio.sfx_volume) or audio.sfx_volume)
    src:setPitch(pitch or 1.0)
	src:setLooping(loop)
	src:play()
end

function audio.get_sfx(name)
	if not audio.sfx[name] then
		error("SFX not found: " .. name)
	end
	return audio.sfx[name]:clone()
end

function audio.play_music(src, volume)
	audio.stop_music()
    src:setVolume(volume and (volume * audio.music_volume) or audio.music_volume)
    src:setLooping(true)
    src:play()
	audio.playing_music = src
end

function audio.stop_music()

	if audio.playing_music then
		audio.playing_music:stop()
		audio.playing_music = nil
	end
end

return audio
