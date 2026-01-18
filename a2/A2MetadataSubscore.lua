
local M = {}


function M.new(name_, value_, username_)
    local ret = {}

    -- String identifier for the subscore
    ret.name = ""  
    if name_ ~= nil then ret.name = name_ end

    -- Value of the subscore
    ret.value = 0
    if value_ ~= nil then ret.value = value_ end


    -- Optional. Subscores are allowed to be attached to individual players in a multiplayer run, or by default
    -- they attach to all players.
    ret.username = ""  
    if username_ ~= nil then ret.username = username_ end

    return ret
end



return M