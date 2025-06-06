---@class Signal
---@field emitters table<table, table<string|number, {listeners: table<table, table<string|number, {func: function, oneshot: boolean}>>}>>
---@field listeners table<table, table<table, table<string|number, table<string|number, {func: function, oneshot: boolean}>>>>>
local signal = {
    emitters = {},
	listeners = {},
	unnamed_connection_ids = {},
}

---@param t table
---@return boolean
local function is_empty(t)
    return next(t) == nil
end

---@param emitter table
---@param id string | number
function signal.register(emitter, id)
    signal.emitters[emitter] = signal.emitters[emitter] or {}
    assert(signal.emitters[emitter][id] == nil, "signal already registered")
    signal.emitters[emitter][id] = {
        listeners = {}
    }
end

---@param emitter table
---@param id string | number
---@return table?
function signal.get(emitter, id)
    if signal.emitters[emitter] == nil then return nil end
    return signal.emitters[emitter][id]
end

---@param emitter table
---@param id string | number
function signal.deregister(emitter, id)
    local sig = signal.get(emitter, id)

    if sig == nil then return end
    
    for listener, connection in pairs(sig) do
        for connection_name, _ in pairs(connection) do
            signal.disconnect(emitter, id, listener, connection_name)
        end
    end

    signal.emitters[emitter][id] = nil
    if is_empty(signal.emitters[emitter]) then signal.emitters[emitter] = nil end
end

---@param obj table
function signal.cleanup(obj)
    assert(type(obj) == "table", "obj is not a table")
    local lis = signal.listeners[obj]
    if lis ~= nil then
        for emitter, signals in pairs(lis) do
            for signal_name, functions in pairs(signals) do
                for connection_name, _ in pairs(functions) do
                    signal.disconnect(emitter, signal_name, obj, connection_name)
                end
            end
        end
    end

    local signals = signal.emitters[obj]

    if signals ~= nil then
        for signal_name, t in pairs(signals) do
            for listener, connection in pairs(t.listeners) do
                for connection_name, _ in pairs(connection) do
                    signal.disconnect(obj, signal_name, listener, connection_name)
                end
            end
        end
    end

    signal.emitters[obj] = nil
end

---@param emitter table
---@param signal_id string | number
---@param listener table
---@param connection_id string | number | nil
---@param func? function
---@param oneshot? boolean
---@return string | number
function signal.connect(emitter, signal_id, listener, connection_id, func, oneshot)
    assert(type(emitter) == "table", "emitter is not a table")
    assert(type(listener) == "table", "listener is not a table")

    local signal_id_type = type(signal_id)
    local connection_id_type = type(connection_id)

    if connection_id == nil then
        connection_id = rng:randi_range(0, 1000000000)
        while signal.unnamed_connection_ids[connection_id] do
            connection_id = rng:randi_range(0, 1000000000)
        end

        signal.unnamed_connection_ids[connection_id] = true
    end


    assert(signal_id_type == "string" or signal_id_type == "number", "signal_id is not a string or number")
    assert(connection_id_type == "string" or connection_id_type == "number", "connection_id is not a string or number")
    assert(emitter ~= nil, "emitter is nil")
    assert(listener ~= nil, "listener is nil")


    if oneshot == nil then oneshot = false end

    local sig = signal.get(emitter, signal_id)

    if sig == nil then
        error("signal `" .. tostring(signal_id) .. "` does not exist for object " .. tostring(emitter))
    end

    sig.listeners[listener] = sig.listeners[listener] or {}

    -- if a function is not provided, use the connection_id as a function

    if debug.enabled then
        if func == nil then
            if listener[connection_id] == nil then
                error("function `" .. tostring(connection_id) .. "` does not exist for object " .. tostring(listener))
            end
            func = function(...)
                listener[connection_id](listener, ...)
            end
        end
    else
        func = func or function(...)
            listener[connection_id](listener, ...)
        end
    end


    sig.listeners[listener][connection_id] = {
        func = func,
        oneshot = oneshot,
    }

    signal.listeners[listener] = signal.listeners[listener] or {}
    signal.listeners[listener][emitter] = signal.listeners[listener][emitter] or {}
    signal.listeners[listener][emitter][signal_id] = signal.listeners[listener][emitter][signal_id] or {}
    local lis = signal.listeners[listener][emitter][signal_id]

    assert(lis[connection_id] == nil, "connection already exists!")

    lis[connection_id] = {
        func = func,
        oneshot = oneshot,
    }
    return connection_id
end

function signal.lazy_connect(emitter, signal_id, listener, connection_id, func, oneshot)
	if not signal.is_connected(emitter, signal_id, listener, connection_id) then
		signal.connect(emitter, signal_id, listener, connection_id, func, oneshot)
	end
end

---@param emitter table
---@param signal_id string | number
---@param listener table
---@param connection_id string | number
function signal.disconnect(emitter, signal_id, listener, connection_id)
    assert(type(emitter) == "table", "emitter is not a table")
    assert(type(listener) == "table", "listener is not a table")
    local signal_id_type = type(signal_id)
    local connection_id_type = type(connection_id)
    assert(signal_id_type == "string" or signal_id_type == "number", "signal_id is not a string or number")
    assert(connection_id_type == "string" or connection_id_type == "number", "connection_id is not a string or number")
    
    local sig = signal.get(emitter, signal_id)
    if (sig == nil) then error("signal " .. tostring(signal_id) .. " does not exist for object " .. tostring(emitter)) end
	-- if sig == nil then return end

    if sig.listeners[listener] ~= nil then  
        sig.listeners[listener][connection_id] = nil

        if is_empty(sig.listeners[listener]) then
            sig.listeners[listener] = nil
        end
    end

    local lis = signal.listeners[listener]

    if lis[emitter] ~= nil then
        if lis[emitter][signal_id] ~= nil then
            lis[emitter][signal_id][connection_id] = nil
            if is_empty(lis[emitter][signal_id]) then
                lis[emitter][signal_id] = nil
            end
        end
        if is_empty(lis[emitter]) then
            signal.listeners[listener][emitter] = nil
        end
    end

	if is_empty(lis) then
		signal.listeners[listener] = nil
	end

	signal.unnamed_connection_ids[connection_id] = nil
end

---@param emitter table
---@param signal_id string | number
---@param listener table
---@param connection_id string | number
---@return boolean
function signal.is_connected(emitter, signal_id, listener, connection_id)
	local sig = signal.get(emitter, signal_id)
    if sig == nil then return false end
	if sig.listeners[listener] == nil then return false end
	return sig.listeners[listener][connection_id] ~= nil
end

---@param emitter table
---@param signal_id string | number
---@param ... any
function signal.emit(emitter, signal_id, ...)
local sig = signal.get(emitter, signal_id)
    if sig == nil then error("no signal " .. tostring(signal_id) .. " for emitter " .. tostring(emitter)) end
	-- if sig == nil then return end
    for listener, connection in pairs(sig.listeners) do
        for func_name, t in pairs(connection) do
            local func = t.func
            func(...)
            if t.oneshot then
                signal.disconnect(emitter, signal_id, listener, func_name)
            end
        end
    end
end

---@param emitter table
---@param emitter_signal_id string | number
---@param listener table
---@param listener_signal_id string | number
function signal.pass_up(emitter, emitter_signal_id, listener, listener_signal_id)
    signal.connect(emitter, emitter_signal_id, listener, "pass_up_" .. tostring(listener_signal_id), function(...)
        signal.emit(listener, listener_signal_id, ...)
    end)
end

---@param signal_id string | number
---@param ... any
function signal.chain_connect(signal_id, ...)
    -- this function is used to chain signals together. as long as every object in the chain has a signal with the same id,
    -- emitting the signal from one object will emit the signal to the next object in the chain,
    -- repeating until the signal is emitted from the last object. this is useful when you have a hierarchy of objects
    -- and you want to emit a signal from the bottom of the hierarchy to the top of the hierarchy, with each layer
    -- responding in their own way.
    assert(type(signal_id) == "string" or type(signal_id) == "number",
        "signal_id must be a string or number")

    local objects = { ... }

    assert(#objects >= 2, "chain_connect requires at least 2 objects")

    -- local chain_id = "chain_connect_" .. tostring(signal_id)

    -- Connect each object to the next in chain
    for i = 1, #objects - 1 do
        local current = objects[i]
        local next_obj = objects[i + 1]
        -- Forward signal to next object in chain
        signal.pass_up(current, signal_id, next_obj, signal_id)
    end
end


---@type Signal
return signal

--[[
DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
Version 2, December 2004

Copyright (C) 2024 Ian Sly

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHAT THE FUCK YOU WANT TO.
--]]
