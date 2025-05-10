conf = require "conf"
usersettings = require "usersettings"
usersettings:initial_load()

require "lib.keyprocess"

function_style_key_process(love)
debug = require "debuggy"

table = require "lib.tabley"
Object = require "lib.object"

savedata = require "savedata"
savedata:initial_load()

nativefs = require "lib.nativefs"
filesystem = require "filesystem"

if conf.use_fennel then
	require "tools.fennelstart"
end

require "lib.mathy"
require "lib.vector"
require "lib.rect"

require "lib.random_crap"
require "lib.sequencer"
require "physics_layers"

require "lib.anim"

require "lib.collision"

require "datastructure.bst"
require "datastructure.bst2"

require "lib.func"

bench = require "lib.bench"

bonglewunch = require "datastructure.bonglewunch"
makelist = require "datastructure.smart_array"
circular_buffer = require "datastructure.circular_buffer"

ease = require "lib.ease"
usersettings = require "usersettings"
input = require "input"
conf = require "conf"
gametime = require "time"
graphics = require "graphics"
rng = require "lib.rng"
translator = require "translation"
global_state = {}

signal = require "signal"
audio = require "audio"

require "lib.color"

Mixins = require "mixins"
tilesets = require "tile.tilesets"

GameObject = require("obj.game_object").GameObject
GameObject2D = require("obj.game_object").GameObject2D
GameObject3D = require("obj.game_object").GameObject3D

GameMap = require "map.GameMap"
World = require "world.BaseWorld"
Effect = require "fx.effect"
SpriteSheet = require "lib.spritesheet"
CanvasLayer = require "screen.CanvasLayer"
local palette_lib = require "lib.palette"
Palette, PaletteStack = palette_lib.Palette, palette_lib.PaletteStack

local fsm = require "lib.fsm"
StateMachine = fsm.StateMachine
State = fsm.State
AutoStateMachine = require "lib.fsm.AutoStateMachine"

BaseGame = require "game.BaseGame"

Screens = filesystem.get_modules("screen")


for i, k in ipairs(conf.to_vec2) do
	conf[k] = Vec2(conf[k].x, conf[k].y)
end

---@diagnostic disable: lowercase-global

local function manual_gc(time_budget, memory_ceiling, disable_otherwise)
	time_budget = time_budget or 1e-3
	memory_ceiling = memory_ceiling or math.huge
	local max_steps = 1000
	local steps = 0
	local start_time = love.timer.get_time()
	while
		love.timer.get_time() - start_time < time_budget and
		steps < max_steps
	do
		if collectgarbage("step", 1) then
			break
		end
		steps = steps + 1
	end
	--safety net
	if collectgarbage("count") / 1024 > memory_ceiling then
		collectgarbage("collect")
	end
	--don't collect gc outside this margin
	if disable_otherwise then
		collectgarbage("stop")
	end
end

local frame_length = 0
local step_length = 0

local function step(dt)

	local frame_start = love.timer.get_time()

    if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

    if graphics and graphics.isActive() then
        graphics.origin()
        graphics.clear(graphics.getBackgroundColor())

        if love.draw then love.draw() end

        graphics.present()
    end

	local frame_end = love.timer.get_time()
	step_length = frame_end - frame_start

end

function love.run()

	-- function_style_key_process(love)


	if love.math then
		love.math.set_random_seed(os.time())
	end

    local accumulated_fixed_frame_rate_time = 0
	local accumulated_capped_frame_rate_time = 0
	local fixed_frame_time = 1 / conf.fixed_tickrate
	
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	love.keyboard.set_text_input(true)

    local dt = 0

    local debug_printed_yet = false
	
	-- Main loop time.
	return function()
		-- Process events.
		
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

		-- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end
		

		-- Call update and draw


        local delta_frame = min(dt * TICKRATE, conf.max_delta_seconds * TICKRATE)
        gametime.love_delta = dt
		gametime.love_time = gametime.love_time + dt


		gametime.time = gametime.time + delta_frame
		local old_tick = gametime.tick
        gametime.tick = floor(gametime.time)

		gametime.frames = gametime.frames + 1

		gametime.is_new_tick = false

		if old_tick ~= gametime.tick then
			gametime.is_new_tick = true
		end

		local frame_start = love.timer.get_time()

		local force_fixed_delta = (dt > conf.max_delta_seconds / 2)
		-- local force_fixed_delta = false

        if not (conf.use_fixed_delta or force_fixed_delta) and not usersettings.cap_framerate and not (debug.enabled and debug.fast_forward) then
            gametime.delta = delta_frame
            gametime.delta_seconds = delta_frame / TICKRATE
            step(delta_frame)
        else
			if conf.use_fixed_delta or force_fixed_delta or (debug.enabled and debug.fast_forward)then
				gametime.delta = fixed_frame_time * TICKRATE
				gametime.delta_seconds = fixed_frame_time
				accumulated_fixed_frame_rate_time = accumulated_fixed_frame_rate_time + dt

                if debug.enabled and debug.fast_forward then
                    step(fixed_frame_time * TICKRATE)
                else
                    for i = 1, conf.max_fixed_ticks_per_frame do
                        if accumulated_fixed_frame_rate_time < fixed_frame_time then
                            break
                        end

                        step(fixed_frame_time * TICKRATE)

                        accumulated_fixed_frame_rate_time = accumulated_fixed_frame_rate_time - fixed_frame_time
                    end
                end
            else -- fps cap is enabled
                accumulated_capped_frame_rate_time = accumulated_capped_frame_rate_time + dt
				if accumulated_capped_frame_rate_time >= 1 / usersettings.fps_cap then
                    local capped_delta_seconds = accumulated_capped_frame_rate_time
                    if capped_delta_seconds >= (conf.max_delta_seconds) then
                        capped_delta_seconds = conf.max_delta_seconds
                    end
                    local capped_delta_frame = capped_delta_seconds * TICKRATE
					gametime.delta = capped_delta_frame
					gametime.delta_seconds = capped_delta_seconds

                    step(capped_delta_frame)
						
				accumulated_capped_frame_rate_time = accumulated_capped_frame_rate_time - capped_delta_seconds
				end
			end
        end


        if gametime.is_new_tick and gametime.tick % 300 == 0 then
            if debug.enabled and not debug_printed_yet then
                local fps = love.timer.getFPS()

                print("fps: " .. fps)
                debug_printed_yet = true
            end
        else
            debug_printed_yet = false
        end
		
		if conf.manual_gc then
			manual_gc(0.001, math.huge, false)
		end

		local frame_end = love.timer.get_time()
        frame_length = frame_end - frame_start
		
		-- local min_delta = 1 / ((usersettings.cap_framerate) and min(usersettings.fps_cap, conf.max_fps) or conf.max_fps)
        local min_delta = 1 / (conf.max_fps)

        if (frame_length < min_delta and (usersettings.cap_framerate) and not usersettings.vsync) and not (debug.enabled and debug.fast_forward) then
            local sleep_start = love.timer.get_time()
			if min_delta - frame_length > 0 then
				love.timer.sleep((min_delta - frame_length) * 0.5)
			end
            local sleep_end = love.timer.get_time()
            local sleep_duration = sleep_end - sleep_start
			frame_length = frame_length + sleep_duration
            dbg("sleep duration (ms)", string.format("%0.3f", sleep_duration * 1000), Color.purple)
        end

	end
end

function love.load(...)
	


    -- fennel.dofile("main.fnl")

    if table.list_has(arg, "build_assets") then
        love.window.minimize()
    end

	
    -- local args = { ... }
    -- table.pretty_print(args)
	
    graphics.load()
	
    debug.load()
	
    if table.list_has(arg, "build_assets") then
        -- minimize window
        love.window.minimize()
        local pngs = require("tools.palletizer")()
        love.event.quit()
		
        return
    end
	
    Palette.load()
	
    audio.load()
    tilesets.load()
	input.load()
	
	game = filesystem.get_modules("game").MainGame()
	
    game:load()
end

local averaged_frame_length = 0

local average_fps = 0

function love.update(dt)
	if gametime.tick % 1 == 0 then 
		-- dbg("ticks", gametime.tick)
        -- if conf.use_fixed_delta and fps > conf.fixed_tickrate then
            -- fps = conf.fixed_tickrate
        -- end

		
		if debug.enabled then
			local flen = (1000 * step_length)
	
            if flen > averaged_frame_length then
                averaged_frame_length = flen
            else
                averaged_frame_length = splerp(averaged_frame_length, flen, 1000.0, dt)
            end
			
            -- local fps = round(1000 / (1000 * frame_length))
			
			-- if fps < average_fps then
			-- 	average_fps = fps
			-- else
			-- 	average_fps = splerp(average_fps, fps, 1000.0, dt)
			-- end

            dbg("fps", love.timer.getFPS(), Color.pink)
			debug.memory_used = (collectgarbage("count")) / 1024
			dbg("memory use (mB)", stepify_safe(debug.memory_used, 0.001), Color.green)
            dbg("step length (ms)", string.format("%0.3f", flen), Color.pink)
            dbg("step length (ms) peakdecay", string.format("%0.3f", averaged_frame_length), Color.pink)
			dbg("frame_length (ms)", string.format("%0.3f", frame_length * 1000), Color.pink)
			-- dbg("id counter", GameObject.id_counter, Color.orange)
		end
	end

	dt = dt * gametime.scale

	input.update(dt)
	game:update(dt)
    graphics.update(dt)
	audio.update(dt)

	-- global input shortcuts
	if input.fullscreen_toggle_pressed then
		usersettings:set_setting("fullscreen", not love.window.getFullscreen())
	end

    debug.update(dt)
	
	input.post_update()

end

function love.draw()
    -- graphics.interp_fraction = conf.interpolate_timestep and clamp(accumulated_fixed_frame_rate_time / fixed_frame_time, 0, 1) or 1
    -- graphics.interp_fraction = stepify(graphics.interp_fraction, 0.1)

    graphics.draw_loop()

    if gametime.tick % 10 == 0 then
        if debug.enabled then
            dbg("draw calls", graphics.get_stats().drawcalls, Color.magenta)
            -- dbg("interp_fraction", graphics.interp_fraction)
        end
    end
    if debug.can_draw() then
        debug.printlines(0, 0)
        if debug.drawing_dt_history then
            local screen_width, screen_height = love.graphics.getDimensions()
            local width, height = screen_width * 0.25, screen_height * 0.125
            graphics.translate(screen_width - width, 1)
            graphics.set_color(0, 0, 0, 0.5)
            graphics.rectangle("fill", 0, 0, width, height)
            graphics.set_color(1, 1, 1, 1)
            debug.draw_dt_history(width, height)
        end
    end
end

function love.quit()
    usersettings:save()
	return false
end

function love.joystickadded(joystick)
	input.joystick_added(joystick)
	input.last_input_device = "gamepad"
end

function love.joystickremoved(joystick)
	input.joystick_removed(joystick)
end

function love.keypressed(key)
    input.on_key_pressed(key)
	input.last_input_device = "mkb"
end

function love.gamepadpressed(gamepad, button)
	input.on_joystick_pressed(gamepad, button)
	input.last_input_device = "gamepad"
end

function love.joystickpressed(joystick, button)
	input.on_joystick_pressed(joystick, button)
	input.last_input_device = "gamepad"
end

function love.gamepadaxis(gamepad, axis, value)
    -- input.on_joystick_axis(gamepad, axis, value)
    input.last_input_device = "gamepad"
end

function love.gamepadreleased(gamepad, button)
	-- input.on_joystick_released(gamepad, button)
	input.last_input_device = "gamepad"
end

function love.joystickreleased(joystick, button)
    -- input.on_joystick_released(joystick, button)
    input.last_input_device = "gamepad"
end

function love.joystickhat(joystick, hat, value)
    -- input.on_joystick_hat(joystick, hat, value)
    input.last_input_device = "gamepad"
end

function love.mousepressed(x, y, button)
	input.on_mouse_pressed(x, y, button)
	input.last_input_device = "mkb"
end

function love.mousereleased(x, y, button)
	input.on_mouse_released(x, y, button)
	input.last_input_device = "mkb"
end

function love.textinput(text)
    input.on_text_input(text)
	input.last_input_device = "mkb"
end

function love.mousemoved(x, y, dx, dy, istouch)
	input.read_mouse_input(x, y, dx, dy, istouch)
	input.last_input_device = "mkb"
end

function love.wheelmoved(x, y)
	input.on_mouse_wheel_moved(x, y)
	input.last_input_device = "mkb"
end
