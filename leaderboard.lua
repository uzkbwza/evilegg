-- leaderboard.lua  ── async client for multi-category leaderboard
-- LÖVE 11/12, uses love.thread + luasocket + lib/json.lua

local socket = require "socket"
local json   = require "lib.json"
local thread = require "love.thread"

local LB = {}
LB.host, LB.port    = "168.235.104.144", 5000

LB.default_category = debug.enabled and "debug" or "normal"

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

        local c = socket.tcp(); c:settimeout(5)
        local okc, err = c:connect(job.host, job.port)
        if not okc then
            ok, data = false, "connect: "..tostring(err)
        else
            c:send(json.encode(job.payload).."\n")
            local line, rerr = c:receive("*l")
            if not line then ok, data = false, "recv: "..tostring(rerr)
            else
                local succ, obj = pcall(json.decode, line)
                ok, data = succ and true or false, succ and obj or "bad json"
            end
        end
        c:close(); resp.ok, resp.data = ok, data
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
local function cat(arg_cat) return arg_cat or LB.default_category end

----------------------------------------------------------------------
-- API ---------------------------------------------------------------
----------------------------------------------------------------------
function LB.submit(run, cb, category)
	local _run = table.deepcopy(run); _run.cmd="submit"; _run.category = cat(category)
	rpc(_run, cb)   -- here 'name' is the callback
end

function LB.fetch(page, per, category, cb)
    rpc({cmd="fetch", uid=savedata.uid, page=page, per=per, category=cat(category)}, cb)
end

function LB.lookup(uid, per, category, cb)
    if type(per) == "function" then cb, per, category = per, nil, category end
    rpc({cmd="lookup", user=uid, per=per, category=cat(category)}, cb)
end

function LB.page_with_user(uid, per, category, cb)
	LB.lookup(uid, per, category, function(ok, res)
		if not ok then
			cb(false, res)
		else
			LB.fetch(res.page, res.per, category, cb)
		end
	end)
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
