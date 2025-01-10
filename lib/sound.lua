local SoundPool = Object:extend("SoundPool")

function SoundPool:new(source, polyphony)
    if type(source) == "string" then
        if audio.sfx[source] == nil then
            error("nonexistent sound: " .. tostring(source))
        end
        source = audio.sfx[source]
    end

    polyphony = polyphony or 1
    if polyphony < 1 then polyphony = 1 end

	self.polyphony = polyphony
    self.pool = {}
	self.playing = {}
    self.pool_index = 1

    for i = 1, polyphony do
        local s = source:clone()
		s:setRelative(false)
        table.insert(self.pool, s)
    end

end

function SoundPool:update(dt)
    for sound in pairs(self.playing) do
        if not sound:isPlaying() then
            self.playing[sound] = nil
            goto continue
        end
        ::continue::
    end
end

function SoundPool:play(x, y, z)
    local src = self:get()
    src:setPosition(x, y, z)
    audio.play_sfx(src)
	return src
end


function SoundPool:get()
	local sound = self.pool[self.pool_index]
    self.pool_index = self.pool_index + 1
	if self.pool_index > self.polyphony then self.pool_index = self.pool_index - self.polyphony end
	return sound
end

function SoundPool:destroy()
    for _, value in ipairs(self.pool) do
        value:release()
    end
end

return SoundPool
