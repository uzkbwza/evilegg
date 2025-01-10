conf = require "conf"


Object = require "lib.object"
table = require "lib.tabley"
string = require "lib.stringy"
filesystem = require "filesystem"

debug = require "debuggy"

-- if debug.enabled then
-- 	debug.fennel_compile()
-- end

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

bonglewunch = require "datastructure.bonglewunch"
makelist = require "datastructure.smart_array"

snakeify_functions_recursive(love)


ease = require "lib.ease"
usersettings = require "usersettings"
input = require "input"
conf = require "conf"
gametime = require "time"
graphics = require "graphics"
rng = require "lib.rng"
global_state = {}
nativefs = require "lib.nativefs"
signal = require "signal"
audio = require "audio"

require "lib.color"

tilesets = require "tile.tilesets"
GameObject = require "obj.game_object"
GameMap = require "map.GameMap"
World = require "world.game_world"
Effect = require "fx.effect"
Mixins = require "mixins" -- like mixins, but better!
SpriteSheet = require "lib.spritesheet"
CanvasLayer = require "screen.CanvasLayer"
Palette = require "lib.palette"

local fsm = require "lib.fsm"
StateMachine = fsm.StateMachine
State = fsm.State

Game = require "game"

Screens = filesystem.get_modules("screen")

local main_screen = "MainScreen"


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
    frame_length = frame_end - frame_start
end

function love.run()

	snakeify_functions_recursive(love)


	if love.math then
		love.math.set_random_seed(os.time())
	end

	local accumulated_time = 0
	local frame_time = 1 / conf.fixed_tickrate
	
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

    local dt = 0
	local min_delta = 1 / conf.max_fps

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
		accumulated_time = accumulated_time + dt

		local delta_frame = min(dt * TICKRATE, conf.max_delta_seconds * TICKRATE)
	
		if not conf.use_fixed_delta then
			step(delta_frame)
		else
			for i = 1, conf.max_fixed_ticks_per_frame do
				if accumulated_time < frame_time then
					break
				end
				
				step(frame_time * TICKRATE)
	
				accumulated_time = accumulated_time - frame_time
			end
		end


		gametime.time = gametime.time + delta_frame
        gametime.tick = floor(gametime.time)

		
        gametime.frames = gametime.frames + 1
        -- collectgarbage()


		
        if gametime.tick % 300 == 0 then
            if debug.enabled and not debug_printed_yet then
                local fps = love.timer.getFPS()
                -- if conf.use_fixed_delta and fps > conf.fixed_tickrate then
                --     fps = conf.fixed_tickrate
                -- end
                print("fps: " .. fps)
				debug_printed_yet = true
            end
        else
            debug_printed_yet = false
        end
		
		if frame_length < min_delta and not usersettings.vsync then
            love.timer.sleep(min_delta - frame_length)
			-- print(min_delta - frame_length)
		end

		manual_gc(0.001, math.huge, false)

	end
end

function love.load(...)
	
	-- fennel.dofile("main.fnl")

	if table.list_has(arg, "build_assets") then
		love.window.minimize()
	end

	game = Game()

    local args = { ... }
	table.pretty_print(args)

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
    game:load(main_screen)
end

function love.update(dt)
	if gametime.tick % 1 == 0 then 
		-- dbg("ticks", gametime.tick)
		local fps = love.timer.getFPS()
        if conf.use_fixed_delta and fps > conf.fixed_tickrate then
            fps = conf.fixed_tickrate
        end
		
		if debug.enabled then
			dbg("fps", fps)
			dbg("memory use (kB)", floor(collectgarbage("count")))
			dbg("frame length (ms)", string.format("%0.3f",  (1000 * frame_length)))
		end
	end

	dt = dt * gametime.scale

	input.update(dt)
	game:update(dt)
	graphics.update(dt)

	-- global input shortcuts
	if input.fullscreen_toggle_pressed then
		love.window.setFullscreen(not love.window.getFullscreen())
	end

    debug.update(dt)
	
	input.post_update()

end

function love.draw()
	-- graphics.interp_fraction = conf.interpolate_timestep and clamp(accumulated_time / frame_time, 0, 1) or 1
	-- graphics.interp_fraction = stepify(graphics.interp_fraction, 0.1)

    graphics.draw_loop()
	
	if debug.can_draw() then
		debug.printlines(0, 0)
    end
	if gametime.tick % 10 == 0 then
		if debug.enabled then
			dbg("draw calls", graphics.get_stats().drawcalls)
		end
		-- dbg("interp_fraction", graphics.interp_fraction)
	end
end

function love.joystickadded(joystick)
	input.joystick_added(joystick)
end

function love.joystickremoved(joystick)
	input.joystick_removed(joystick)
end

function love.keypressed(key)
	input.on_key_pressed(key)
end

function love.gamepadpressed(gamepad, button)
	input.on_joystick_pressed(gamepad, button)
end

function love.joystickpressed(joystick, button)
	input.on_joystick_pressed(joystick, button)
end

function love.mousepressed(x, y, button)
	input.on_mouse_pressed(x, y, button)
end

function love.mousereleased(x, y, button)
	input.on_mouse_released(x, y, button)
end

function love.textinput(text)
    input.on_text_input(text)
end

function love.wheelmoved(x, y)
	input.on_mouse_wheel_moved(x, y)
end
