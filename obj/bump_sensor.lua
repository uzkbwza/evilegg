---@diagnostic disable: redundant-parameter
---@class BumpSensor
local BumpSensor = Object:extend("BumpSensor")

local DEFAULT_CONFIG = {
    bump_layer = 0,
    bump_mask = 0,
    filter = nil,
    entered_function = nil,
    update_function = nil,
    exit_function = nil,
	sense_objects = true,
    sense_sensors = false,
    collision_rect = Rect(0, 0, 1, 1),
	static = false
}

function BumpSensor:new(owner, config)
    config = config or {}

    for k, v in pairs(DEFAULT_CONFIG) do
        if config[k] == nil then
            config[k] = v
        end
    end

	local rect = config.collision_rect

    self.rect = rect:clone()
    self.offset = Vec2(rect.x + rect.width / 2, rect.y + rect.height / 2)
    self.bump_rect = Rect.centered(self.offset.x, self.offset.y, rect.width, rect.height) + owner.pos:clone()
    self.bump_layer = config.bump_layer
    self.bump_mask = config.bump_mask
    self.owner = owner
    self.monitoring = config.entered_function ~= nil or config.update_function ~= nil or config.exit_function ~= nil
	self.static = config.static
    self.query_table = {}

	for k, v in pairs(config) do
		if self[k] == nil then
			self[k] = v
		end
	end

	self:implement(Mixins.Behavior.BumpLayerMask)

	local base_filter = BumpSensor.base_filter(config.sense_objects, config.sense_sensors)

    if config.filter then
        self.filter = function(other)
            return base_filter(other) and config.filter(other)
        end
    else
        self.filter = base_filter
    end

    self:set_monitorable(self.bump_layer ~= 0)
	
    self.monitored_objects = {}

    self.bump_world = owner.bump_world
    self.is_sensor = true
    self.entered_function = config.entered_function or self.dummy
    self.update_function = config.update_function or self.dummy
    self.exit_function = config.exit_function or self.dummy
end

function BumpSensor.base_filter(sense_objects, sense_sensors)
    return function(other)
        return (sense_objects and Object.is(other, GameObject)) or
            (sense_sensors and other.is_sensor and other.monitorable)
    end
end

function BumpSensor:bump_world_update()
    if self.bump_world then
        self.bump_world:update(
            self,
            self.bump_rect.x,
            self.bump_rect.y,
            self.bump_rect.width,
            self.bump_rect.height,
            self.bump_layer,
            self.bump_mask
        )
    end
end

function BumpSensor:set_monitorable(monitorable)
	self.monitorable = monitorable
	if monitorable then
		self:set_bump_world(self.owner.bump_world)
	else
		if self.bump_world then
			self.bump_world:remove(self)
		end
	end
end

function BumpSensor:set_bump_world(bump_world)
	if self.bump_world then
		if self.bump_world:hasItem(self) then
			self.bump_world:remove(self)
		end
	end
	self.bump_world = bump_world
	if bump_world then
		bump_world:add(self, self.bump_rect.x, self.bump_rect.y, self.bump_rect.width, self.bump_rect.height, self.bump_layer, self.bump_mask)
	end
end

function BumpSensor:update(dt)
	if self.monitoring then
		self:monitor()
	end
end

function BumpSensor.dummy(...)
end

function BumpSensor:monitor()
    local items, len = self.bump_world:queryRect(self.bump_rect.x, self.bump_rect.y, self.bump_rect.width, self.bump_rect.height, self.filter, self.query_table, self.bump_mask)
    local monitored = self.monitored_objects or {}
    self.monitored_objects = monitored

    -- if len > 0 then
    --     local items, len = self.bump_world:queryRect(self.bump_rect.x, self.bump_rect.y, self.bump_rect.width,
    --     self.bump_rect.height, self.filter, self.query_table, self.bump_mask)
	-- 	print(len)
	-- end

	for i=1, len do
		local item = items[i]
		if item.is_sensor then
			items[i] = item.owner
		end
	end


    for item, _ in pairs(monitored) do
        monitored[item] = false
    end


    for i = 1, len do
        local item = items[i]
        if monitored[item] == false then
        
            monitored[item] = true
            self.update_function(self.owner, item)
        elseif monitored[item] == nil then
        
            monitored[item] = true
			signal.connect(item, "destroyed", self, "monitored_item_destroyed", function()
				monitored[item] = nil
			end)
            self.entered_function(self.owner, item)
            self.update_function(self.owner, item)
        end
    
    end

    for item, is_monitored in pairs(monitored) do
        if is_monitored == false then
            monitored[item] = nil
            self.exit_function(self.owner, item)
			signal.disconnect(item, "destroyed", self, "monitored_item_destroyed")
        end
    end
	
	dbg("num_monitored", len)
end

function BumpSensor:get_monitored_objects()
	return self.monitored_objects or {}
end

function BumpSensor:move_to_local(x, y)
	self.offset.x = x
	self.offset.y = y
	self.rect = self.rect:center_to(x, y, self.rect.width, self.rect.height)

	self:move_to(self.owner.offset.x * (self.owner.flip or 1), self.owner.offset.y)
end

function BumpSensor:move_to(x, y)
	self.bump_rect = self.bump_rect:center_to(x + self.offset.x, y + self.offset.y, self.rect.width, self.rect.height)

	if self.monitorable and self.bump_world then
		self.bump_world:update(self, self.bump_rect.x, self.bump_rect.y, self.bump_rect.width, self.bump_rect.height)
	end
end

return BumpSensor
