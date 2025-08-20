local ExampleMod = Object:extend("ExampleMod")
-- if you want to reference a GameObject (including Worlds and CanvasLayers) make sure you clean up the reference when the object is destroyed.
-- for example:

-- self.world = world
-- print("example mod referencing world: " .. tostring(world))
-- signal.connect(world, "destroyed", self, "on_world_destroyed", function()
--     print("example mod unreferencing world: " .. tostring(world))
--     self.world = nil
-- end)

function ExampleMod:on_load()
end

function ExampleMod:on_graphics_loaded(graphics)
end

function ExampleMod:on_debug_loaded(debug)
end

function ExampleMod:on_audio_loaded(audio)
end

function ExampleMod:on_input_loaded(input)
end

function ExampleMod:on_game_loaded(game)
end

function ExampleMod:on_game_started(game_state)
end

-- global update callback, always called every frame. 1 dt = 1/60th of a second. dt can be lower but not higher than 1.
function ExampleMod:update(dt)
end

function ExampleMod:on_world_created(world)
end

-- prefer this if you want to do anything that should be affected by the time scale of objects in the game world.
function ExampleMod:world_update_timescaled(timescaled, dt)
    -- reference the world with timescaled.world
end

-- this is for stuff that does not care about the time scale.
function ExampleMod:world_update(world, dt)
end

function ExampleMod:player_update(player, dt)
end

function ExampleMod:on_screen_changed(screen)
end

function ExampleMod:on_player_spawned(player)
end

function ExampleMod:on_player_died(world)
end

-- if you want to hook into more things, you can do a lot with GameObject:add_update_function(), GameObject:add_enter_function(), GameObject:add_draw_function(), etc...
-- you can also look at how signals are used to react to specific events.
-- i am lazy and probably won't be adding a bunch more hooks for now.
return ExampleMod
