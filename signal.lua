---@class Signal
---@field emitters table<table, table<string|number, {connections: table, lookup: table}>>
---@field listeners table<table, {connections: table}>
local signal = {}
-- Use weak keys so that when an emitter/listener object is garbage collected,
-- its entry in these tables is automatically removed.
signal.emitters = setmetatable({}, {__mode = "k"}) -- emitter -> signal_id -> { connections = {}, lookup = {} }
signal.listeners = setmetatable({}, {__mode = "k"}) -- listener -> { connections = {} }

local Pool = require("lib.pool")

bench.start_bench("signal.pools")
signal.pools = {
    connections = Pool((function() return {} end), 5000),
    lookup_tables = Pool((function() return {} end), 3000),
    listener_infos = Pool(function() return { connections = {} } end, 3000),
    signal_infos = Pool(function() return { connections = {}, lookup = {} } end, 5000),
    emitter_maps = Pool(function() return {} end, 3000)
}
bench.end_bench("signal.pools")

local function release_connection_to_pool(conn)
    -- Clear out fields for reuse
    conn.emitter = nil
    conn.signal_id = nil
    conn.listener = nil
    conn.connection_id = nil
    conn.func = nil
    conn.oneshot = nil
    conn.listener_list_index = nil -- New field
    signal.pools.connections:release(conn)
end

local unnamed_counter = 0

---@param t table
---@return boolean
local function is_empty(t)
    return next(t) == nil
end

---@param emitter table
---@param id string | number
function signal.register(emitter, id)
    local emitter_map = signal.emitters[emitter]
    if not emitter_map then
        emitter_map = signal.pools.emitter_maps:get()
        signal.emitters[emitter] = emitter_map
    end
    assert(emitter_map[id] == nil, "signal already registered")
    emitter_map[id] = signal.pools.signal_infos:get()
end

---@param emitter table
---@param id string | number
---@return table?
function signal.get(emitter, id)
    if not signal.emitters[emitter] then return nil end
    return signal.emitters[emitter][id]
end

---@param emitter table
---@param id string | number
function signal.deregister(emitter, id)
    local sig = signal.get(emitter, id)
    if sig == nil then return end

    while #sig.connections > 0 do
        local conn = sig.connections[1]
        signal.disconnect(conn.emitter, conn.signal_id, conn.listener, conn.connection_id)
    end
    
    assert(is_empty(sig.lookup), "deregister did not clear all lookups")

    local emitter_map = signal.emitters[emitter]
    if emitter_map then
        local sig_to_release = emitter_map[id]
        emitter_map[id] = nil
        if sig_to_release then
            signal.pools.signal_infos:release(sig_to_release)
        end
    end
end

---@param obj table
function signal.cleanup(obj)
    -- This function is now the primary mechanism for ensuring pooled objects are
    -- returned. The weak tables will prevent object leaks, but this must be
    -- called to prevent pool-object leaks.
    assert(type(obj) == "table", "obj is not a table")

    -- Clean up connections where obj is the LISTENER.
    local listener_info = signal.listeners[obj]
    if listener_info then
        while #listener_info.connections > 0 do
            local conn = listener_info.connections[1]
            signal.disconnect(conn.emitter, conn.signal_id, conn.listener, conn.connection_id)
        end
    end

    -- Clean up connections where obj is the EMITTER.
    local signals_emitted = signal.emitters[obj]
    if signals_emitted then
        local signal_ids = signal.pools.lookup_tables:get()
        for signal_id, _ in pairs(signals_emitted) do table.insert(signal_ids, signal_id) end
        for _, signal_id in ipairs(signal_ids) do signal.deregister(obj, signal_id) end
        while #signal_ids > 0 do table.remove(signal_ids, 1) end
        signal.pools.lookup_tables:release(signal_ids)

        if is_empty(signals_emitted) then
            signal.emitters[obj] = nil
            signal.pools.emitter_maps:release(signals_emitted)
        end
    end
end

---@param emitter table
---@param signal_id string | number
---@param listener table
---@param connection_id string | number
---@param func? function
---@param oneshot? boolean
---@return string | number
function signal.connect(emitter, signal_id, listener, connection_id, func, oneshot)
    assert(type(emitter) == "table", "emitter is not a table")
    assert(type(listener) == "table", "listener is not a table")

    if connection_id == nil then
        unnamed_counter = unnamed_counter + 1
        connection_id = unnamed_counter
    end

    local signal_id_type = type(signal_id)
    local connection_id_type = type(connection_id)
    assert(signal_id_type == "string" or signal_id_type == "number", "signal_id is not a string or number")
    assert(connection_id_type == "string" or connection_id_type == "number", "connection_id is not a string or number")

    local sig = signal.get(emitter, signal_id)
    if sig == nil then
        error("signal `" .. tostring(signal_id) .. "` does not exist for object " .. tostring(emitter))
    end

    assert(not(sig.lookup[listener] and sig.lookup[listener][connection_id]), "connection already exists!")
    
    if debug.enabled and func == nil then
        if listener[connection_id] == nil then error("function `" .. tostring(connection_id) .. "` does not exist for object " .. tostring(listener)) end
    end

    local conn = signal.pools.connections:get()
    conn.emitter = emitter
    conn.signal_id = signal_id
    conn.listener = listener
    conn.connection_id = connection_id
    conn.func = func
    conn.oneshot = oneshot or false

    table.insert(sig.connections, conn)
    local index = #sig.connections

    sig.lookup[listener] = sig.lookup[listener] or signal.pools.lookup_tables:get()
    sig.lookup[listener][connection_id] = index

    local listener_info = signal.listeners[listener]
    if not listener_info then
        listener_info = signal.pools.listener_infos:get()
        signal.listeners[listener] = listener_info
    end
    table.insert(listener_info.connections, conn)
    conn.listener_list_index = #listener_info.connections

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
    local sig = signal.get(emitter, signal_id)
    if not sig then return end

    local listener_lookup = sig.lookup[listener]
    if not listener_lookup then return end
    
    local index_in_emitter_list = listener_lookup[connection_id]
    if not index_in_emitter_list then return end

    local conn_to_remove = sig.connections[index_in_emitter_list]

    local last_emitter_conn = table.remove(sig.connections)
    if conn_to_remove ~= last_emitter_conn then
        sig.connections[index_in_emitter_list] = last_emitter_conn
        sig.lookup[last_emitter_conn.listener][last_emitter_conn.connection_id] = index_in_emitter_list
    end

    listener_lookup[connection_id] = nil
    if is_empty(listener_lookup) then
        sig.lookup[listener] = nil
        signal.pools.lookup_tables:release(listener_lookup)
    end

    local listener_info = signal.listeners[listener]
    if listener_info then
        local index_in_listener_list = conn_to_remove.listener_list_index
        if listener_info.connections[index_in_listener_list] == conn_to_remove then
            local last_listener_conn = table.remove(listener_info.connections)
            if conn_to_remove ~= last_listener_conn then
                listener_info.connections[index_in_listener_list] = last_listener_conn
                last_listener_conn.listener_list_index = index_in_listener_list
            end
        end
        if is_empty(listener_info.connections) then
            signal.listeners[listener] = nil
            signal.pools.listener_infos:release(listener_info)
        end
    end
	
    release_connection_to_pool(conn_to_remove)
end

---@param emitter table
---@param signal_id string | number
---@param listener table
---@param connection_id string | number
---@return boolean
function signal.is_connected(emitter, signal_id, listener, connection_id)
	local sig = signal.get(emitter, signal_id)
    if not sig then return false end
	if not sig.lookup[listener] then return false end
	return sig.lookup[listener][connection_id] ~= nil
end

---@param emitter table
---@param signal_id string | number
---@param ... any
function signal.emit(emitter, signal_id, ...)
    local sig = signal.get(emitter, signal_id)
    if sig == nil then return end

    for i = #sig.connections, 1, -1 do
        local conn = sig.connections[i]
        if conn then -- Connection might have been destroyed during this loop
            if conn.func then
                conn.func(...)
            else
                local func = conn.listener[conn.connection_id]
                func(conn.listener, ...)
            end
            if conn.oneshot then
                signal.disconnect(emitter, signal_id, conn.listener, conn.connection_id)
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
    local n = select('#', ...)
    assert(n >= 2, "chain_connect requires at least 2 objects")
    for i = 1, n - 1 do
        local current = select(i, ...)
        local next_obj = select(i + 1, ...)
        signal.pass_up(current, signal_id, next_obj, signal_id)
    end
end

---@return table<string, {used: number, available: number, total: number}>
function signal.debug_get_pool_stats()
    local stats = {}
    for name, pool in pairs(signal.pools) do
        stats[name] = pool:get_stats()
    end
    return stats
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
