local FreezeFrames = Object:extend("FreezeFrames")

function FreezeFrames:__mix_init()
    self.freeze_frames = 0
    local old_update = self.update_shared
	
    local new_update = function(self, dt)
        if self.freeze_frames > 0 then
            self.freeze_frames = self.freeze_frames - dt
            return
        end
        old_update(self, dt)
    end
	
	self.update_shared = new_update
end

function FreezeFrames:start_freeze_frames(ticks)
    self.freeze_frames = ticks
end

return {
    FreezeFrames = FreezeFrames,
}
