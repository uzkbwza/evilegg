-- ===========================================================================
--  Evil Egg – Main Love2D bootstrap
--  Cleaned up for readability & maintenance, 2025‑05‑26
-- ===========================================================================

-- ---------------------------------------------------------------------------
--  Globals & Configuration
-- ---------------------------------------------------------------------------
GAME_VERSION = "0.1.0"

conf         = require "conf"
usersettings = require "usersettings"; usersettings:initial_load()

require "lib.keyprocess"
function_style_key_process(love)

debug          = require "debuggy"          ---@diagnostic disable: lowercase-global
table          = require "lib.tabley"       ---@diagnostic disable: lowercase-global
Object         = require "lib.object"       ---@diagnostic disable: lowercase-global
leaderboard    = require "leaderboard"      ---@diagnostic disable: lowercase-global
savedata       = require "savedata"; savedata:initial_load()
nativefs       = require "lib.nativefs"
filesystem     = require "filesystem"

if conf.use_fennel then require "tools.fennelstart" end

require "lib.mathy"
require "lib.vector"         ; require "lib.rect"
require "lib.random_crap"    ; require "lib.sequencer"
require "physics_layers"     ; require "lib.anim"
require "lib.collision"      ; require "datastructure.bst"
require "datastructure.bst2" ; require "lib.func"
require "lib.bench"

bonglewunch      = require "datastructure.bonglewunch"
makelist         = require "datastructure.smart_array"
circular_buffer  = require "datastructure.circular_buffer"

ease             = require "lib.ease"
input            = require "input"
gametime         = require "time"
graphics         = require "graphics"
rng              = require "lib.rng"
translator       = require "translation"
global_state     = {}

signal           = require "signal"
audio            = require "audio"
require "lib.color"

Mixins           = require "mixins"
tilesets         = require "tile.tilesets"

local GO         = require "obj.game_object"
GameObject, GameObject2D, GameObject3D = GO.GameObject, GO.GameObject2D, GO.GameObject3D

GameMap          = require "map.GameMap"
World            = require "world.BaseWorld"
Effect           = require "fx.effect"
SpriteSheet      = require "lib.spritesheet"
CanvasLayer      = require "screen.CanvasLayer"

local palette_lib = require "lib.palette"
Palette, PaletteStack = palette_lib.Palette, palette_lib.PaletteStack

local fsm = require "lib.fsm"
StateMachine, State = fsm.StateMachine, fsm.State
AutoStateMachine    = require "lib.fsm.AutoStateMachine"

BaseGame        = require "game.BaseGame"
Screens         = filesystem.get_modules("screen")

local min, floor = math.min, math.floor
local TICKRATE   = conf.tickrate or 60

for _, k in ipairs(conf.to_vec2) do conf[k] = Vec2(conf[k].x, conf[k].y) end

local function manual_gc(time_budget, memory_ceiling, disable_otherwise)
    time_budget    = time_budget or 1e-3
    memory_ceiling = memory_ceiling or math.huge
    local start_t  = love.timer.get_time()
    local steps    = 0
    while (love.timer.get_time()-start_t) < time_budget and steps < 1000 do
        if collectgarbage("step", 1) then break end
        steps = steps + 1
    end
    if collectgarbage("count")/1024 > memory_ceiling then collectgarbage("collect") end
    if disable_otherwise then collectgarbage("stop") end
end

local frame_length, step_length          = 0, 0
local accumulated_fixed_time, accumulated_cap_time = 0, 0
local fixed_frame_time                   = 1 / conf.fixed_tickrate
local FORCE_FIXED_TIME_SECONDS                     = 0.25
local FORCE_FIXED_TIME_LOW_FPS_THRESHOLD_SECONDS = 0.25
local force_fixed_time_left                        = 0.0
local force_fixed_time_buildup = 0.0

local function _step(frame_dt)
    local s = love.timer.get_time()
    if love.update then love.update(frame_dt) end
    if graphics and graphics.isActive() then
        graphics.origin()
        graphics.clear(graphics.getBackgroundColor())
        if love.draw then love.draw() end
        graphics.present()
    end
    step_length = love.timer.get_time() - s
end


function love.run()
    if love.math then love.math.set_random_seed(os.time()) end
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
    if love.timer then love.timer.step() end
    love.keyboard.set_text_input(true)

    local dt, debug_printed_peak = 0, false
    return function()
        if love.event then
            love.event.pump()
            for name,a,b,c,d,e,f in love.event.poll() do
                if name=="quit" then if not love.quit or not love.quit() then return a or 0 end end
                love.handlers[name](a,b,c,d,e,f)
            end
        end
        if love.timer then dt = love.timer.step() end

        local delta_frame = min(dt*TICKRATE, conf.max_delta_seconds*TICKRATE)
        gametime.love_delta = dt
        gametime.love_time  = gametime.love_time + dt
        gametime.time       = gametime.time + delta_frame
        local prev_tick     = gametime.tick
        gametime.tick       = floor(gametime.time)
        gametime.frames     = gametime.frames + 1
        gametime.is_new_tick= (prev_tick~=gametime.tick)

        -- Dynamically enable fixed‑delta when a single frame stalls badly (>½ max allowed)
        if (dt > (conf.max_delta_seconds or 0) * 0.5) then
            force_fixed_time_buildup = approach(force_fixed_time_buildup, FORCE_FIXED_TIME_LOW_FPS_THRESHOLD_SECONDS, dt)
        else
			force_fixed_time_buildup = approach(force_fixed_time_buildup, 0, dt)
		end
        if force_fixed_time_buildup >= FORCE_FIXED_TIME_LOW_FPS_THRESHOLD_SECONDS then
            force_fixed_time_left = FORCE_FIXED_TIME_SECONDS
        else
            force_fixed_time_left = approach(force_fixed_time_left, 0, dt)
        end

		local force_fixed = force_fixed_time_left > 0
        local debug_ffwd  = debug.enabled and debug.fast_forward
        local fixed_enabled = conf.use_fixed_delta or force_fixed
        local cap_fps     = usersettings.cap_framerate and not debug_ffwd
		dbg("force_fixed", force_fixed, Color.cyan)
		dbg("debug_ffwd", debug_ffwd, Color.cyan)
		dbg("fixed_enabled", fixed_enabled, Color.cyan)
        if not fixed_enabled and not cap_fps and not debug_ffwd then
			dbg("fixed step", false, Color.cyan)
            gametime.delta, gametime.delta_seconds = delta_frame, delta_frame/TICKRATE
            _step(delta_frame)
        else
            if fixed_enabled or debug_ffwd then
				dbg("fixed step", true, Color.cyan)

				local fixed_delta_frame = fixed_frame_time * TICKRATE
				gametime.delta, gametime.delta_seconds = fixed_delta_frame, fixed_frame_time
				accumulated_fixed_time = accumulated_fixed_time + dt
				local loops = debug_ffwd and conf.max_fixed_ticks_per_frame or 1
			
				if force_fixed then
					loops = min(
						floor(accumulated_fixed_time / fixed_frame_time),
						conf.max_fixed_ticks_per_frame or 4
					)
				end
			
                if debug_ffwd then 
                    _step(fixed_frame_time * TICKRATE)
                else
                    for _ = 1, loops do
                        if accumulated_fixed_time < fixed_frame_time then break end
                        _step(fixed_delta_frame)
                        accumulated_fixed_time = accumulated_fixed_time - fixed_frame_time
                    end
                end
            else
				dbg("fixed step", false, Color.cyan)
                accumulated_cap_time = accumulated_cap_time + dt
                local cap_interval = 1 / usersettings.fps_cap
                if accumulated_cap_time >= cap_interval then
                    local capped_seconds = min(accumulated_cap_time, conf.max_delta_seconds)
                    local capped_frame   = capped_seconds*TICKRATE
                    gametime.delta, gametime.delta_seconds = capped_frame, capped_seconds
                    _step(capped_frame)
                    accumulated_cap_time = accumulated_cap_time - capped_seconds
                end
            end
        end

        if gametime.is_new_tick and gametime.tick % 300 == 0 then
            if debug.enabled and not debug_printed_peak then
                print("fps: "..love.timer.getFPS())
                debug_printed_peak = true
            end
        else debug_printed_peak = false end

        if conf.manual_gc then manual_gc(0.001, math.huge, false) end
        frame_length = step_length
        if cap_fps and not usersettings.vsync and not debug_ffwd then
            local min_frame_time = 1 / conf.max_fps
            local remaining = min_frame_time - frame_length
            if remaining > 0 then love.timer.sleep(remaining - 0.001) end
        end
    end
end

function love.load(...)
    if table.list_has(arg, "build_assets") then love.window.minimize() end
    graphics.load(); debug.load()
    if table.list_has(arg, "build_assets") then require("tools.palletizer")(); love.event.quit(); return end
    Palette.load(); audio.load(); tilesets.load(); input.load()
    game = filesystem.get_modules("game").MainGame(); game:load()
end

local averaged_frame_length = 0
function love.update(dt)
    leaderboard.poll()
    if debug.enabled then
        local flen = step_length*1000
        averaged_frame_length = (flen>averaged_frame_length) and flen or splerp(averaged_frame_length, flen, 1000.0, dt)
        dbg("fps", love.timer.getFPS(), Color.pink)
        debug.memory_used = collectgarbage("count")/1024
        dbg("memory use (mB)", stepify_safe(debug.memory_used,0.001), Color.green)
        dbg("step length (ms)", string.format("%.3f", flen), Color.pink)
        dbg("step peak (ms)", string.format("%.3f", averaged_frame_length), Color.pink)
        dbg("frame len (ms)", string.format("%.3f", frame_length*1000), Color.pink)
    end
    dt = dt * gametime.scale
    input.update(dt)
    if debug.enabled and debug.frame_advance then
        if input.debug_frame_advance_pressed then game:update(dt); audio.update(dt) end
    else
        local scaled_dt = debug.slow_motion and dt*0.1 or dt
        game:update(scaled_dt); audio.update(scaled_dt)
    end
    graphics.update(dt)
    if input.fullscreen_toggle_pressed then
        usersettings:set_setting("fullscreen", not (debug.enabled and usersettings.fullscreen or love.window.getFullscreen()))
    end
    debug.update(dt); input.post_update()
end

function love.draw()
    graphics.draw_loop()
    if debug.enabled and gametime.tick % 10 == 0 then dbg("draw calls", graphics.get_stats().drawcalls, Color.magenta) end
    if debug.can_draw() then
        debug.printlines(0,0)
        if debug.drawing_dt_history then
            local w,h = love.graphics.getDimensions()
            local cw,ch = w*0.25, h*0.125
            graphics.translate(w-cw,1)
            graphics.set_color(0,0,0,0.5)
            graphics.rectangle("fill",0,0,cw,ch)
            graphics.set_color(1,1,1,1)
            debug.draw_dt_history(cw,ch)
        end
    end
end

function love.quit()
    usersettings:save(); savedata:save(); return false
end

function love.joystickadded(joystick)   input.joystick_added(joystick); input.last_input_device="gamepad" end
function love.joystickremoved(joystick) input.joystick_removed(joystick)                                       end
function love.keypressed(key)           input.on_key_pressed(key); input.last_input_device="mkb"             end
function love.gamepadpressed(g,b)       input.on_joystick_pressed(g,b); input.last_input_device="gamepad"     end
function love.joystickpressed(j,b)      input.on_joystick_pressed(j,b); input.last_input_device="gamepad"     end
function love.gamepadaxis()             input.last_input_device="gamepad"                                     end
function love.gamepadreleased()         input.last_input_device="gamepad"                                     end
function love.joystickreleased()        input.last_input_device="gamepad"                                     end
function love.joystickhat()             input.last_input_device="gamepad"                                     end
function love.mousepressed(x,y,b)       input.on_mouse_pressed(x,y,b); input.last_input_device="mkb"          end
function love.mousereleased(x,y,b)      input.on_mouse_released(x,y,b); input.last_input_device="mkb"         end
function love.textinput(t)              input.on_text_input(t); input.last_input_device="mkb"                end
function love.mousemoved(x,y,dx,dy,ist) input.read_mouse_input(x,y,dx,dy,ist); input.last_input_device="mkb"  end
function love.wheelmoved(x,y)           input.on_mouse_wheel_moved(x,y); input.last_input_device="mkb"        end
