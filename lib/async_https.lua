-- Written by Seb (using Ivy Sly's code as reference). Should work as a general purpose interface
-- for Lua HTTPS requests.
-- This takes advantage of the lua-https library, but creates a thread to make it async.
--
-- The lua-https library is a better choice than Love2D's built-in
-- luasocket. lua-https was apparently specifically built for Love and,
-- unlike luasocket, supports https, and doesn't require us to manually
-- build proper web requests with headers, form data etc. It has more
-- fully featured functions.
-- I was able to build it from here:
-- https://github.com/love2d/lua-https
-- The first CMake command had to be modified to include a path to the Lua folder:
--          cmake -Bbuild -S. -A x64 -DCMAKE_INSTALL_PREFIX=%CD%\install -DCMAKE_PREFIX_PATH=C:\Tools\lua
-- The second CMake command worked as is. Check the install folder for https.dll which is all you need.
-- If you put that DLL in the same folder as example.lua, you should be able to run it and it will confirm
-- that the DLL is working.

--require "lib/https_test"  -- tests that https.dll is working properly

local https = require "https"
local thread = require "love.thread"

local M = {}


local in_channel  = love.thread.getChannel("https_worker_in")   -- id, params, pass_to_callback
local out_channel = love.thread.getChannel("https_worker_out")  -- id, code, response, pass_to_callback

-- dictionary of thread ID to callback
local callbacks = {}

local idc = 0   -- thread ID counter
local function next_id() idc = idc + 1; return idc end

-- Return what the ID of the next request WILL be, so we can track it
function M.get_future_id() return idc+1 end

-- "params" should be a table of values equivalent to lua-https's parameters
-- for https.request. They will be unpacked later from within the worker thread.
-- "pass_to_callback" is anything you'll want to remember later in the callback. Can be nil
-- "callback" should have params code, response, pass_to_callback
function M.request(params, callback, pass_to_callback)
    local thread_id = next_id()
    callbacks[thread_id] = callback

    -- push these parameters into the channel so the thread can pick them up when it wakes up
    local in_dict = {}
    in_dict["id"] = thread_id
    in_dict["params"] = params
    in_dict["pass_to_callback"] = pass_to_callback
    in_channel:push(in_dict)

    -- start thread from worker function, data is passed via the ... syntax
    thread.newThread("lib/async_https_worker.lua"):start()
end



-- Polls for finished HTTP responses, and calls the appropriate callbacks from the main thread.
function M.poll()
    local output = out_channel:pop()

    if output ~= nil then
        callbacks[output["id"]](output["code"], output["response"], output["pass_to_callback"])
        callbacks[output["id"]] = nil     -- callback complete, remove from dict
    end
end


-- Returns amount of in-progress requests.
function M.count_requests()
    return #callbacks
end


function M.thread_is_working(thread_id)
    return callbacks[thread_id] ~= nil
end


return M