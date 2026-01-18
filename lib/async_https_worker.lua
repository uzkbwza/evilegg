local https = require "https"

local in_channel  = love.thread.getChannel("https_worker_in")   -- takes thread ID and params to https.request.
local out_channel = love.thread.getChannel("https_worker_out")  -- outputs thread ID and result of https.request.

local input_dict = in_channel:pop()

if input_dict ~= nil then
    local thread_id, params, pass_to_callback = input_dict["id"], input_dict["params"], input_dict["pass_to_callback"]

    code, response = https.request(unpack(params))

    -- test: report immediate success, pass along params
    out_channel:push({id=thread_id, code=code, response=response, pass_to_callback=pass_to_callback})
else
    print("WARNING: async_https_worker.lua couldn't find input_dict from in_channel.")
end

