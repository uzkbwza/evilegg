-- leaderboard.lua  ── async client for multi-category leaderboard
-- LÖVE 11/12, uses love.thread + luasocket + lib/json.lua

-- this code is mostly LLM generated. it probably sucks! 
-- please do not use it to make my life harder.


local socket = require "socket"
local json   = require "lib.json"
local thread = require "love.thread"


local LB = {}
LB.NUM_TRIES        = 5

LB.host, LB.port    = "168.235.104.144", 5000

LB.default_category = (debug.enabled and "debug" or "normal")

LB.categories = {
	"normal",
}

if debug.enabled then
	table.insert(LB.categories, 1, "debug")
end

----------------------------------------------------------------------
-- internal async plumbing ------------------------------------------
----------------------------------------------------------------------
local IN  = thread.getChannel("lb_in")
local OUT = thread.getChannel("lb_out")
local idc = 0
local cbs = {}

local worker_code = [[
    local socket = require "socket"
    local json   = require "lib.json"
    local thread = require "love.thread"
    local IN  = thread.getChannel("lb_in")
    local OUT = thread.getChannel("lb_out")

    while true do
        local job = IN:demand()
        if job == "__quit__" then break end
        local resp = {id = job.id}
        local ok, data

        local ok_tcp, c = pcall(socket.tcp)
        if not ok_tcp then
            print("Worker error: TCP creation failed -", tostring(c))
            ok, data = false, "tcp creation failed: " .. tostring(c)
        else
            local ok_timeout, timeout_err = pcall(function() c:settimeout(5) end)
            if not ok_timeout then
                print("Worker error: Timeout setting failed -", tostring(timeout_err))
                ok, data = false, "timeout setting failed: " .. tostring(timeout_err)
            else
                local okc, err = pcall(function() return c:connect(job.host, job.port) end)
                if not okc or err == false then
                    print("Worker error: Connection failed -", tostring(err))
                    ok, data = false, "connect: " .. tostring(err)
                else
                    local ok_send, send_err = pcall(function()
                        return c:send(json.encode(job.payload).."\n")
                    end)
                    if not ok_send then
                        print("Worker error: Send failed -", tostring(send_err))
                        ok, data = false, "send failed: " .. tostring(send_err)
                    else
                        local ok_recv, line, rerr = pcall(function()
                            return c:receive("*l")
                        end)
                        if not ok_recv then
                            print("Worker error: Receive operation failed -", tostring(line))
                            ok, data = false, "recv failed: " .. tostring(line)
                        elseif not line then
                            print("Worker error: No data received -", tostring(rerr))
                            ok, data = false, "recv: " .. tostring(rerr)
                        else
                            local succ, obj = pcall(json.decode, line)
                            if not succ then
                                print("Worker error: JSON decode failed -", tostring(obj))
                            end
                            ok, data = succ and true or false, succ and obj or "bad json"
                        end
                    end
                end
            end
            pcall(function() c:close() end)
        end
        resp.ok, resp.data = ok, data
        OUT:push(resp)
    end
]]
thread.newThread(worker_code):start()

local function next_id() idc = idc + 1; return idc end
local function rpc(tbl, cb)
    local id = next_id(); cbs[id] = cb
    IN:push{ id=id, host=LB.host, port=LB.port, payload=tbl }
end

----------------------------------------------------------------------
-- public poll (call in love.update) ---------------------------------
----------------------------------------------------------------------
function LB.poll()
    while true do
        local msg = OUT:pop()
        if not msg then break end
        local cb = cbs[msg.id]; if cb then cbs[msg.id]=nil; cb(msg.ok,msg.data) end
    end
end

----------------------------------------------------------------------
-- helpers to add category or default it -----------------------------
----------------------------------------------------------------------
local function cat(arg_cat)
    local c = arg_cat or LB.default_category
    return c .. "_" .. GAME_LEADERBOARD_VERSION
end

LB.cat = cat

----------------------------------------------------------------------
-- API ---------------------------------------------------------------
----------------------------------------------------------------------
function LB.submit(run, category, process_name, cb)
	category = (process_name or category == nil) and cat(category) or category
	local _run = table.deepcopy(run); _run.cmd="submit"; _run.category = (category)
	rpc(_run, cb)   -- here 'name' is the callback
end

function LB.submit_many(runs, category, process_name, cb)
    category = process_name and cat(category) or category
    local payload = {cmd = "submit_many", category = category, runs = runs}
    rpc(payload, cb)
end

function LB.fetch(page, per, category, sort_by, period, process_name, cb)
    category = process_name and cat(category) or category
    local payload = {cmd="fetch", uid=savedata:get_uid(), page=page, per=per, category=(category), period=period}
    if sort_by then payload.sort_by = sort_by end
    rpc(payload, cb)
end

function LB.lookup(uid, per, category, sort_by, period, process_name, cb)
	category = process_name and cat(category) or category
    local payload = {cmd="lookup", user=uid, per=per, category=(category), period=period}
    if sort_by then payload.sort_by = sort_by end
    rpc(payload, cb)
end

function LB.page_with_user(uid, per, category, sort_by, period, process_name, cb)
    category = process_name and cat(category) or category
	LB.lookup(uid, per, category, sort_by, period, false, function(ok, res)
		if not ok then
			if cb then cb(false, res) end
		else
			LB.fetch(res.page, res.per, category, sort_by, period, false, cb)
		end
	end)
end

function LB.submit_queued_runs(cb)
    local run_upload_queue = savedata.run_upload_queue[GAME_LEADERBOARD_VERSION]
    -- local run_upload_queue_tries = savedata.run_upload_queue_tries[GAME_LEADERBOARD_VERSION]
    if not run_upload_queue or next(run_upload_queue) == nil then
        if cb then cb(true, { status = "noop" }) end
        return
    end

    -- if not run_upload_queue_tries or next(run_upload_queue_tries) == nil then
    --     if cb then cb(true, { status = "noop" }) end
    --     return
    -- end

    local runs_by_category = {}
    for key, run in pairs(run_upload_queue) do
        local category = run.category or LB.default_category
        if not runs_by_category[category] then
            runs_by_category[category] = {}
        end
        table.insert(runs_by_category[category], run)
    end

    local any_runs = false
    for category, runs in pairs(runs_by_category) do
        any_runs = true
        LB.submit_many(runs, category, true, function(ok, res)
            if ok and res and res.status == "ok" then
                for _, run in ipairs(runs) do
                    -- if not run_upload_queue_tries[run.run_key] then
                    --     run_upload_queue_tries[run.run_key] = LB.NUM_TRIES
                    -- end
                    -- run_upload_queue_tries[run.run_key] = run_upload_queue_tries[run.run_key] - 1
                    -- if run_upload_queue_tries[run.run_key] <= 0 then
                        run_upload_queue[run.run_key] = nil
                        -- run_upload_queue_tries[run.run_key] = nil
                    -- end
                end
            end
            savedata:save()
            if cb then cb(ok, res) end
        end)
    end

    if not any_runs then
        if cb then cb(true, { status = "noop" }) end
    end
end

function LB.add_death(cb)
    rpc({cmd="add_death"}, cb)
end
function LB.get_deaths(cb)
    rpc({cmd="get_deaths"}, cb)
end

----------------------------------------------------------------------
-- shutdown (optional) ----------------------------------------------
----------------------------------------------------------------------
function LB.quit() IN:push("__quit__") end

return LB
