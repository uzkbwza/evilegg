local ModLoader = Object:extend("ModLoader")
local ExampleMod = require("modding.example_mod")

function ModLoader:new()
    self.mods = {}
    self.num_mods = 0
    self.callbacks = {}
end

function ModLoader:register_mod(mod)
    mod = mod()
    self.num_mods = self.num_mods + 1
    self.mods[self.num_mods] = mod

    for func, callback in pairs(mod:get_methods(true)) do
        if type(callback) == "function" and ExampleMod[func] then
            self.callbacks[func] = self.callbacks[func] or {}
            self.callbacks[func][0] = self.callbacks[func][0] or 0
            self.callbacks[func][0] = self.callbacks[func][0] + 1
            self.callbacks[func][self.callbacks[func][0]] = {mod, callback}
        end
    end
end

function ModLoader:call(func, ...)
    local callback_list = self.callbacks[func]
    if not callback_list then
        return
    end
    for i = 1, callback_list[0] do
        -- if debug.enabled then
            -- print("calling " .. func .. " on " .. tostring(callback_list[i][1]) .. " with " .. table.length(arg) .. " args")
        -- end
        callback_list[i][2](callback_list[i][1], ...)
    end
end

function ModLoader:load_mods()
    filesystem.create_directory("mods")
    local mod_dirs = filesystem.get_directory_items("mods")
    for _, dir in ipairs(mod_dirs) do
        local mod_path = "mods/" .. dir
        if filesystem.get_info(mod_path, "directory") then
            local init_path = mod_path .. "/init.lua"
            if filesystem.get_info(init_path, "file") then
                local mod_file = filesystem.load(init_path)
                self:register_mod(mod_file())
            end
        end
    end
    if debug.enabled then
        self:register_mod(ExampleMod)
    end
    self:call("on_load")
end

return ModLoader
