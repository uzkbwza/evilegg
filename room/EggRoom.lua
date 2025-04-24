local EggRoom = require("room.Room"):extend("EggRoom")

-- local O = filesystem.get_modules("obj").Room

function EggRoom:new(...)
    EggRoom.super.new(self, ...)
	self.is_egg_room = true
end

function EggRoom:build(room_params)
    EggRoom.super.build(self, room_params)
end

function EggRoom:generate_waves()
    local waves = {}
    local rescue_waves = {}

    return waves, rescue_waves
end

function EggRoom:should_spawn_waves()
    return false
end

function EggRoom:initialize(world)
    local s = world.timescaled.sequencer
	s:start(function()
        s:wait(40)
		world:on_room_clear()
	end)

end

return EggRoom
