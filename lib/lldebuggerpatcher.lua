local protectedContextCount = 0

local function start()
    local pcall_old = pcall
    local xpcall_old = xpcall
    local error_old = error
    local assert_old = assert

    _G.pcall = function(...)
        protectedContextCount = protectedContextCount + 1
        local results = { pcall_old(...) }
        protectedContextCount = protectedContextCount - 1

        return unpack(results)
    end

    _G.xpcall = function(...)
        protectedContextCount = protectedContextCount + 1
        local results = { xpcall_old(...) }
        protectedContextCount = protectedContextCount - 1

        return unpack(results)
    end

    local lldebugger = require("lldebugger").start()
    local error_lldebugger = error
    local assert_lldebugger = assert

    _G.error = function(...)
        if (protectedContextCount == 0) then
            return error_lldebugger(...)
        end

        return error_old(...)
    end

    _G.assert = function(...)
        if (protectedContextCount == 0) then
            return assert_lldebugger(...)
        end

        return assert_old(...)
    end

    return lldebugger
end

local function useLove()
    protectedContextCount = protectedContextCount - 1
end

return {
    start = start,
    useLove = useLove
}
