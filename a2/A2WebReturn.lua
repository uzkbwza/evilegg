local M = {}

local A2ErrorReturn = require "a2.A2ErrorReturn"


function M.new(func_name_, progress_, error_, payload_, headers_, call_info_)

    local ret = {}

    -- Returned from asynchronous web functions via get_web_return.
    -- If error is null, it was a success.
    -- If error isn't null, it failed


    -- The function you called to create this web return.
    ret.func_name = ""
    if func_name_ ~= nil then ret.func_name = func_name_ end

    -- Progress of this web return, from 0 to 1. If it's lower
    -- than 1, error and payload will be null.
    ret.progress = 0.0
    if progress_ ~= nil then ret.progress = progress_ end

    -- If non-null, an error occurred with this web request.
    ret.error = nil
    if error_ ~= nil then ret.error = error_ end

    -- The return of the function. It varies per-function.
    -- A payload may be present even if an error occurs (in the case of a server error it'd be the error response)
    ret.payload = nil
    if payload_ ~= nil then ret.payload = payload_ end

    -- Raw headers from the server response (THESE ARE CURRENTLLY UNUSED IN LUA)
    ret.headers = {}  --array
    if headers_ ~= nil then ret.headers = headers_ end

    -- In some cases we need to preserve some info about the way the request was made (resource ID, etc) and that
    -- info gets passed along here.	
    ret.call_info = {}
    if call_info_ ~= nil then ret.call_info = call_info_ end

    return ret
end




-- returns a json parse error response
function M.json_parse_error(_func_name)
    return M.new(_func_name, 1.0,
        A2ErrorReturn.new(_func_name, A2ErrorReturn.A2ErrorCode.BAD_RESPONSE, "Server-side error. Please try again later!", "Error parsing JSON from the server side.")
    )
end        


return M