-- === Anti-tamper (Windows/LuaJIT) ===
local AntiTamper = {}

local isWindows = (jit and jit.os == "Windows")
local ffi
if isWindows then
    local ok, mod = pcall(require, "ffi")
    if ok then
        ffi = mod
        ffi.cdef [[
      int IsDebuggerPresent(void);
      void* GetModuleHandleA(const char*);
    ]]
    end
end

-- Expand this list as new names are found
local suspicious = {"speedhack-i386.dll", "speedhack-x86_64.dll", "cheatengine-i386.dll", "cheatengine-x86_64.dll",
                    "cheatengine-x86_64-SSE4-AVX2.dll", "cheatengine-x86_64-SSE4-AVX2-Signed.dll", "speedhack.dll",
                    "cheatengine.dll"}

-- State for warning/exit
local active = false
local reasonText = ""
local countdown = 0
local scanTimer = 0
local scanPeriod = 2.0 -- seconds between scans when clean

local function flagSpeedHack(reason)
    if active then
        return
    end -- trigger only once
    active = true
    reasonText = tostring(reason or "Untrusted environment detected")
    countdown = 5.0 -- seconds until hard exit
end

local function antiTamperScan()
    if not (isWindows and ffi) then
        return
    end
    -- Debugger presence
    if ffi.C.IsDebuggerPresent() ~= 0 then
        flagSpeedHack("Debugger detected")
        return
    end
    -- Known CE/speedhack modules
    for _, m in ipairs(suspicious) do
        if ffi.C.GetModuleHandleA(m) ~= nil then
            flagSpeedHack("Suspicious module loaded: " .. m)
            return
        end
    end
end

-- === Core Update Loop
function AntiTamper.update(dt)
    if active then
        countdown = countdown - dt
        if countdown <= 0 then
            -- Close the game
            love.event.quit(0)
        end
        return
    end

    -- Periodic background scan while clean
    scanTimer = scanTimer + dt
    if scanTimer >= scanPeriod then
        scanTimer = 0
        antiTamperScan()
    end
end

-- === Cheat Detected Screen ===
function AntiTamper.draw()
    if not active then
        return
    end

    local w, h = love.graphics.getDimensions()
    love.graphics.push("all")
    -- dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- header
    love.graphics.setColor(1, 0.25, 0.25, 1)
    love.graphics.printf("WARNING: DO NOT CHEAT", 20, h * 0.30, w - 40, "center")

    -- body
    love.graphics.setColor(1, 1, 1, 1)
    local seconds = math.max(0, math.ceil(countdown))
    local msg = string.format("%s\n\nPlease close any debugging/cheat tools.\nThe game will exit in %d seconds.",
                              reasonText, seconds)
    love.graphics.printf(msg, 20, h * 0.40, w - 40, "center")

    love.graphics.pop()
end

-- manual trigger for testing
function AntiTamper._testTrigger()
    flagSpeedHack("Test trigger")
end
return AntiTamper
