local Object = {
	__class_type_name = "Object",
}
Object.__index = Object

Object.__tostring = function()
	return Object.__class_type_name
end

Object.__type_name = Object.__tostring


function Object:new()
end

function Object:extend(name)
	local cls = {}
	for k, v in pairs(self) do
		if k:find("__") == 1 then
			cls[k] = v
		end
	end
    cls.__index = cls
	cls.class = cls
	cls.super = self
	if name then
		cls.__tostring = function()
			return name
		end
		cls.__type_name = cls.__tostring
		cls.__class_type_name = name
	end

	setmetatable(cls, self)

    local mixins = {}
	
    if cls.mixins then
        for k, v in pairs(cls.mixins) do
            mixins[k] = v
        end
    end
	
    cls.mixins = mixins
	setmetatable(mixins, {__index = self.mixins})

	return cls
end

function Object.get_metamethods(cls)
	local mt = getmetatable(cls)
	local methods = {}
	for k, v in pairs(mt) do
		if k:find("__") == 1 then
			methods[k] = v
		end
	end
	return methods
end

function Object:extend_self(metatable)
    local mt = getmetatable(self)
    mt.__index = metatable
end

-- dynamic mixin on an instance. also covers initialization
function Object:dyna_mixin(cls, ...)
	if debug.enabled then
		if not self.is_instance then
			error("Object:dyna_mixin can only be called on an instance")
		end
	end

	if rawget(self, "mixins") and rawget(self, "mixins")[cls] then
		error("dynamic mixin already implemented on instance of" .. tostring(self))
	end

    local my_class = getmetatable(self)
    local mixins = my_class.mixins

	if (mixins) and (mixins[cls]) then
		error("mixin already implemented on class " .. tostring(self) .. ", use mix_init instead")
	end

    if not ((mixins) and (mixins[cls])) then
        for k, v in pairs(cls) do
            if type(v) == "function" and k:find("__mix_init") ~= 1 then
                if self[k] == nil then
                    self[k] = v
                end
            end
        end
    end

    if cls.__mix_init then
        if mixins and mixins[cls] then
            local args = { ... }
            local len = #args

            if args[1] == nil then
                cls.__mix_init(self, unpack(args), unpack(mixins[cls], len + 1))
            else
                cls.__mix_init(self, ...)
            end
        else
            cls.__mix_init(self, ...)
        end
    end
	
	self.mixins = self.mixins or setmetatable({}, {__index = getmetatable(self).mixins})
	self.mixins[cls] = true
end

-- mixin init. must be implemented on the class first
function Object:mix_init(cls, ...)
    if debug.enabled then
        if not self.is_instance then
            error("Object:mix_init can only be called on an instance")
        end
    end

    local my_class = getmetatable(self)
    local mixins = my_class.mixins

    if not ((mixins) and (mixins[cls])) then
        error("mixin used in Object:mix_init must be implemented on class " .. tostring(self) .. " first", 2)
    end

    if cls.__mix_init then
        if mixins and mixins[cls] then
            local args = { ... }
            local len = #args

            if args[1] == nil then
                cls.__mix_init(self, unpack(args), unpack(mixins[cls], len + 1))
            else
                cls.__mix_init(self, ...)
            end
        else
            cls.__mix_init(self, ...)
        end
    end
end

function Object:global_mix_init(cls, ...)
	if cls.__global_mix_init then
		cls.__global_mix_init(self, ...)
	end
end


function Object:lazy_mixin(cls, ...)
	if debug.enabled then
		if not self.is_instance then
			error("Object:lazy_mixin can only be called on an instance")
		end
	end
	local myclass = getmetatable(self)
	
	local mixins = myclass.mixins

    if not (mixins and mixins[cls]) then
		myclass:implement(cls, ...)
    end
	
	self:mix_init(cls, ...)
end

function Object:implement(cls, ...)
	if debug.enabled then
		if self.is_instance then
			error("Object:implement can only be called on a class")
		end
	end
	
    self.mixins = self.mixins or {}
    local mixins = self.mixins

	if mixins[cls] then
		error("Object already implements " .. tostring(cls))
	end

    if not mixins[cls] then
        for k, v in pairs(cls) do
            if type(v) == "function" and k:find("__mix_init") ~= 1 then
                if self[k] == nil then
                    self[k] = v
                end
            end
        end
		mixins[cls] = {...}
    end

	self:global_mix_init(cls, ...)
end

function Object:override_class_metamethod(name, func)

    
    -- Set the new metatable while preserving inheritance

	local mt = {
        __index = getmetatable(self).__index,  -- Preserve inheritance
    }

	for k, v in pairs(Object.get_metamethods(self)) do
		mt[k] = v
	end

	mt[name] = func

	setmetatable(self, mt)

    return self

end

function Object:override_instance_metamethod(name, func)
    -- if not name:find("__") == 1 then
    --     error("Invalid metamethod name: " .. name)
    -- end
    local mt = getmetatable(self)
    if not mt then
        mt = {}
        setmetatable(self, mt)
    end

    -- Create a new metatable that inherits from the class metatable
    if mt == self.__index then  -- If using the class's metatable
        local new_mt = {}
        for k, v in pairs(mt) do
            new_mt[k] = v
        end
        new_mt.__index = mt
        mt = new_mt
        setmetatable(self, mt)
    end
    mt[name] = func
end

function Object:get_methods(recursive, methods)

	local m = methods or {}
    
    for k, v in pairs(self) do
        if type(v) == "function" then
            m[k] = v
        end
    end

	local super = self.super

    -- Check if metatable exists and has an __index table
    if recursive and super and type(super) == "table" then
        super:get_methods(true, m)
    end
    
    return m
end

function Object:is(T)
	-- if type(T) ~= "table" then return false end
	-- return self.__type_name == T.__type_name
	local mt = getmetatable(self)
	while mt do
		if mt == T then
			return true
		end
		mt = getmetatable(mt)
	end
	return false
end


if debug.enabled then
    function Object:__call(...)
        local obj = setmetatable({ is_instance = true }, self)
        obj:new(...)
        return obj
    end
else
    function Object:__call(...)
        local obj = setmetatable({}, self)
        obj:new(...)
        return obj
    end
end

Object.__type_name = Object.__tostring

return Object
