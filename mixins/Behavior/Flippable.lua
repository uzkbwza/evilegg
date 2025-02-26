local Flippable = Object:extend("Flippable")

function Flippable:__mix_init()
	self.flip = 1
end

---@param flip number
function Flippable:set_flip(flip)
	self.flip = self.flip or 1
	if flip == nil then return end
	if flip == 0 then return end
	self.flip = sign(flip)
end

return Flippable
