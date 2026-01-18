local M = {}

M.A2ErrorCode = {CONNECTION_ERROR=0, WRONG_PASSWORD=1, USER_BANNED=2, VIDEO_API_ERROR=3, BAD_RESPONSE=4, BAD_REQUEST=5}



-- Returned from functions when something goes wrong.
function M.new(func_name_, code_, user_description_, detailed_description_, call_info_)
    local ret = {}

    -- Name of the A2 function where the error occurred.
    ret.func_name = ""
    if func_name_ ~= nil then ret.func_name = func_name_ end


    -- You can use this to respond to errors in your own way,
    ret.code = 0
    if code_ ~= nil then ret.code = code_ end

    -- User-friendly description of the error, can be printed onscreen in your game.
    -- e.g. "The username already exists. Please supply a password."
    ret.user_description = ""
    if user_description_ ~= nil then ret.user_description = user_description_ end

    -- More detailed dev-friendly description of the error.
    ret.detailed_description = ""
    if detailed_description_ ~= nil then ret.detailed_description = detailed_description_ end

    -- Optional details from when the original request was made
    ret.call_info = {}
    if call_info_ ~= nil then ret.call_info = call_info_ end

    return ret
end


return M