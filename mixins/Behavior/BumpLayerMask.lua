---@class BumpLayerMask
local BumpLayerMask = Object:extend("BumpLayerMask")

function BumpLayerMask:enable_bump_layer(...)
    for _, v in ipairs({ ... }) do
        self:set_bump_layer_value(v, true)
    end
end

function BumpLayerMask:enable_bump_mask(...)
    for _, v in ipairs({ ... }) do
        self:set_bump_mask_value(v, true)
    end
end

function BumpLayerMask:disable_bump_layer(...)
    for _, v in ipairs({ ... }) do
        self:set_bump_layer_value(v, false)
    end
end

function BumpLayerMask:disable_bump_mask(...)
	for _, v in ipairs({ ... }) do
		self:set_bump_mask_value(v, false)
	end
end

function BumpLayerMask:set_bump_layer_values(value, ...)
	self.bump_layer = 0
	for _, v in ipairs({...}) do
		self:set_bump_layer_value(v, value)
	end
end

function BumpLayerMask:set_bump_mask_values(value, ...)
	self.bump_mask = 0
	for _, v in ipairs({...}) do
		self:set_bump_mask_value(v, value)
	end
end

function BumpLayerMask:clear_bump_layers(...)
    for _, v in ipairs({ ... }) do
        self:disable_bump_layer(v)
    end
end

function BumpLayerMask:clear_bump_masks(...)
    for _, v in ipairs({ ... }) do
        self:disable_bump_mask(v)
    end
end

function BumpLayerMask:clear_all_bump_layers()
    self.bump_layer = 0
	self:bump_world_update()
end

function BumpLayerMask:clear_all_bump_masks()
	self.bump_mask = 0
	self:bump_world_update()
end

function BumpLayerMask:set_bump_mask_value(layerId, value)
	if value == nil then 
		value = true
	end
	self.bump_mask = self.bump_mask or 0
    local bitValue = to_layer_bit(layerId)
    if value then
        self.bump_mask = bit.bor(self.bump_mask, bitValue)
    else
        self.bump_mask = bit.band(self.bump_mask, bit.bnot(bitValue))
    end
	self:bump_world_update()
end

function BumpLayerMask:get_bump_layer_value(layerId)
    local bitValue = to_layer_bit(layerId)
    return bit.band(self.bump_layer or 0, bitValue) ~= 0
end

function BumpLayerMask:get_bump_mask_value(layerId)
    local bitValue = to_layer_bit(layerId)	
    return bit.band(self.bump_mask or 0, bitValue) ~= 0
end

function BumpLayerMask:set_bump_layer_value(layerId, value)
    if value == nil then
        value = true
    end
    self.bump_layer = self.bump_layer or 0
    local bitValue = to_layer_bit(layerId)	
    if value then
        self.bump_layer = bit.bor(self.bump_layer, bitValue)
    else
        self.bump_layer = bit.band(self.bump_layer, bit.bnot(bitValue))
    end

    self:bump_world_update()
end

return BumpLayerMask
