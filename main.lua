-- ===========================================================================
--  Evil Egg
-- ===========================================================================
---@diagnostic disable: lowercase-global

GAME_VERSION = "0.12.0" 
GAME_LEADERBOARD_VERSION = GAME_VERSION:match("^([^%.]+%.[^%.]+)")

print("Game version: " .. GAME_VERSION)
print("Leaderboard version: " .. GAME_LEADERBOARD_VERSION)
print("Love version: " .. love.getVersion())

conf         = require "conf"
usersettings = require "usersettings"; usersettings:initial_load()

require "lib.keyprocess"
function_style_key_process(love)
if steam then
    function_style_key_process(steam)
end

debug          = require "debuggy"
table          = require "lib.tabley"
Object         = require "lib.object"
leaderboard    = require "leaderboard"
rng            = require "lib.rng"
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

bench            = require "lib.bench"

bonglewunch              = require "datastructure.bonglewunch"
makelist                 = require "datastructure.smart_array"
circular_buffer          = require "datastructure.circular_buffer"
batch_remove_list        = require "datastructure.batch_remove_list"
array2d                  = require "datastructure.array2d"
grid2d                   = require "datastructure.grid2d"
static_spatial_grid      = require "datastructure.static_spatial_grid"
spatial_grid             = require "datastructure.spatial_grid"
-- spatial_grid             = require "lib.shash".new


ease             = require "lib.ease"
input            = require "input"
gametime         = require "time"
graphics         = require "graphics"
translator       = require "translation"
global_state = {}

modloader    = require "modding.modloader"()

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
Screens                                = filesystem.get_modules("screen")

TimeChecker                       = require "lib.timechecker"

time_checker = TimeChecker()

local min, floor = math.min, math.floor

local TICKRATE   = conf.tickrate or 60

for _, k in ipairs(conf.to_vec2) do conf[k] = Vec2(conf[k].x, conf[k].y) end

local function manual_gc(time_budget, memory_ceiling, disable_otherwise)
    time_budget    = time_budget or 1e-3
    memory_ceiling = memory_ceiling or math.huge
    local start_t  = love.timer.get_time()
    local steps    = 0
    while (love.timer.get_time() - start_t) < time_budget and steps < 1000 do
        if collectgarbage("step", 1) then break end
        steps = steps + 1
    end
	dbg("gc time", (love.timer.get_time() - start_t) * 1000, Color.cyan)
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
    if graphics and graphics.is_active() then
        graphics.origin()
        graphics.clear(graphics.get_background_color())
        if love.draw then love.draw() end
        graphics.present()
    end
    if usersettings:is_dirty() then
        usersettings:apply_buffer()
    end
    step_length = love.timer.get_time() - s
end


function love.run()
    if love.math then love.math.set_random_seed(os.time()) end
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
    if love.timer then love.timer.step() end
    love.keyboard.set_text_input(true)

    local dt, debug_printed_peak = 0, false

    usersettings:apply_settings()
    return function()
        if love.event then
            love.event.pump()
            for name,a,b,c,d,e,f,g,h in love.event.poll() do
                if name=="quit" then
                    if not love.quit or not love.quit(b) then return a or 0, b end
                end
                love.handlers[name](a,b,c,d,e,f,g,h)
            end
        end
        if love.timer then dt = love.timer.step() end

        time_checker:update(dt)

        local delta_seconds = min(dt, conf.max_delta_seconds)
        local delta_frame = delta_seconds * TICKRATE
        gametime.love_delta = dt
        gametime.love_time  = gametime.love_time + dt
        gametime.time       = gametime.time + delta_frame
        local prev_tick     = gametime.tick
        gametime.tick       = floor(gametime.time)
        gametime.frame     = gametime.frame + 1
        gametime.is_new_tick = (prev_tick ~= gametime.tick)
        

        -- if gametime.is_new_tick and rng:percent(1) and debug.enabled then
            -- love.timer.sleep(0.25)
        -- end

        -- Dynamically enable fixed‑delta when the game slows down (>=2x max fps allowed)
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
		-- local force_fixed = false
        local debug_ffwd  = debug.enabled and debug.fast_forward
        local fixed_enabled = conf.use_fixed_delta or force_fixed
        local cap_fps     = usersettings.cap_framerate and not debug_ffwd
		
		dbg("force_fixed", force_fixed, Color.cyan)
		dbg("debug_ffwd", debug_ffwd, Color.cyan)
		dbg("fixed_enabled", fixed_enabled, Color.cyan)
        dbg("delta", seconds_to_frames(dt), Color.cyan)
		dbg("dt", (delta_frame), Color.cyan)
        if not fixed_enabled and not cap_fps and not debug_ffwd then
			dbg("fixed step", false, Color.cyan)
            gametime.delta, gametime.delta_seconds = delta_frame, delta_frame/TICKRATE
            _step(delta_frame)
        else
            if fixed_enabled or debug_ffwd then
				dbg("fixed step", true, Color.cyan)

				local fixed_delta_frame = fixed_frame_time * TICKRATE
				gametime.delta, gametime.delta_seconds = fixed_delta_frame, fixed_frame_time
				accumulated_fixed_time = accumulated_fixed_time + delta_seconds
				local loops = debug_ffwd and conf.max_fixed_ticks_per_frame or 1
			
				if force_fixed then
					loops = min(
						floor(accumulated_fixed_time / fixed_frame_time),
						conf.max_fixed_ticks_per_frame or 1
					)
				end
			
                if debug_ffwd then 
                    _step(fixed_frame_time * TICKRATE)
                else
                    for _ = 1, loops do
                        if accumulated_fixed_time < fixed_frame_time then break end
                        _step(fixed_delta_frame)
                        accumulated_fixed_time = accumulated_fixed_time - fixed_frame_time
                        accumulated_fixed_time = accumulated_fixed_time % (fixed_frame_time * loops)
                    end
                end
            else
				dbg("fixed step", false, Color.cyan)
                accumulated_cap_time = accumulated_cap_time + delta_seconds
                dbg("accumulated_cap_time", accumulated_cap_time, Color.cyan)
                
                local cap_interval = 1 / usersettings.fps_cap
                if accumulated_cap_time >= cap_interval then
                    local capped_seconds                   = min(accumulated_cap_time, conf.max_delta_seconds)
                    local capped_frame                     = capped_seconds * TICKRATE
                    gametime.delta, gametime.delta_seconds = capped_frame, capped_seconds
                    _step(capped_frame)
                    accumulated_cap_time = accumulated_cap_time - capped_seconds
                    accumulated_cap_time = accumulated_cap_time % cap_interval
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
    local build_assets = table.list_has(arg, "build_assets") and not IS_EXPORT
	if build_assets then love.window.minimize() end
    modloader:load_mods()
    graphics.load()
    modloader:call("on_graphics_loaded", graphics)
    debug.load()
    modloader:call("on_debug_loaded", debug)
    if build_assets then
        require("tools.palletizer")()
        love.event.quit()
        return
	end
    Palette.load()
    audio.load()
    modloader:call("on_audio_loaded", audio)
    tilesets.load()
	input.load()
    modloader:call("on_input_loaded", input)
    game = filesystem.get_modules("game").MainGame()
    game:load()
    modloader:call("on_game_loaded", game)
end

local averaged_frame_length = 0

local cached_window_size = Vec2(0, 0)

function love.update(dt)
    leaderboard.poll()
    if steam then
        steam.run_callbacks()
    end

    if debug.enabled and debug.can_draw() then
        local flen = step_length*1000
        averaged_frame_length = (flen>averaged_frame_length) and flen or splerp(averaged_frame_length, flen, 1000.0, dt)
        dbg("fps", love.timer.getFPS(), Color.pink)
        debug.memory_used = collectgarbage("count")/1024
        dbg("memory use (mB)", stepify_safe(debug.memory_used,0.001), Color.green)
        dbg("step length (ms)", string.format("%.3f", flen), Color.pink)
        dbg("step peak (ms)", string.format("%.3f", averaged_frame_length), Color.pink)
        dbg("frame len (ms)", string.format("%.3f", frame_length * 1000), Color.pink)
        dbg("signal emitters", table.length(signal.emitters), Color.green)
        dbg("signal listeners", table.length(signal.listeners), Color.green)
		local stats = signal.debug_get_pool_stats()
        -- for name, s in pairs(stats) do
            -- dbg("pool: " .. name, string.format("%d/%d", s.used, s.total), Color.green)
        -- end
        dbg("retry_cooldown", savedata:get_seconds_until_retry_cooldown_is_over(), Color.magenta)
    end
    dt = dt * gametime.scale
    input.update(dt)
    if debug.enabled and debug.frame_advance then
        if input.debug_frame_advance_pressed then
            game:update(dt); audio.update(dt)
        end
    else
        local scaled_dt = debug.slow_motion and dt*0.1 or dt
        game:update(scaled_dt); audio.update(scaled_dt)
    end
    graphics.update(dt)
    if input.fullscreen_toggle_pressed then
        usersettings:set_setting("fullscreen", not love.window.get_fullscreen())
    end
    debug.update(dt); input.post_update()

    local window_width, window_height = love.window.get_mode()
    if not love.window.get_fullscreen() and not love.window.is_maximized() and (window_width ~= cached_window_size.x or window_height ~= cached_window_size.y) then
        cached_window_size.x = window_width
        cached_window_size.y = window_height
        usersettings:set_setting("window_size", { x = cached_window_size.x, y = cached_window_size.y })
        usersettings:apply_settings()
    end
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
    usersettings:save()
    savedata:save()
	if steam then
		steam.shutdown()
	end
	return false
end


if IS_EXPORT then
    love.errorhandler = require("error")
end


function love.joystickadded(joystick)   input.joystick_added(joystick); input.last_input_device="gamepad" end
function love.joystickremoved(joystick) input.joystick_removed(joystick)                                       end
function love.keypressed(key)           input.on_key_pressed(key); input.last_input_device="mkb"             end
function love.gamepadpressed(g,b)       input.on_joystick_pressed(g,b); input.last_input_device="gamepad"     end
function love.joystickpressed(j,b)      input.on_joystick_pressed(j,b); input.last_input_device="gamepad"     end
function love.gamepadaxis(joystick, axis, value)
    if abs(value) > TRIGGER_DEADZONE then
        input.last_input_device = "gamepad"
    end
end
function love.gamepadreleased()         input.last_input_device="gamepad"                                     end
function love.joystickreleased()        input.last_input_device="gamepad"                                     end
function love.joystickhat()             input.last_input_device="gamepad"                                     end
function love.mousepressed(x,y,b)       input.on_mouse_pressed(x,y,b); input.last_input_device="mkb"          end
function love.mousereleased(x,y,b)      input.on_mouse_released(x,y,b); input.last_input_device="mkb"         end
function love.textinput(t)              input.on_text_input(t); input.last_input_device="mkb"                end
function love.mousemoved(x,y,dx,dy,ist) input.read_mouse_input(x,y,dx,dy,ist); input.last_input_device="mkb"  end
function love.wheelmoved(x,y)           input.on_mouse_wheel_moved(x,y); input.last_input_device="mkb"        end
