local Flippable = Object:extend("Flippable")

function Flippable:__mix_init()
    self.flip = 1
	self:add_signal("flipped")
end

---@param flip number
function Flippable:set_flip(flip)
    self.flip = self.flip or 1
	local old = self.flip
	if flip == nil then return end
	if flip == 0 then return end
    self.flip = sign(flip)
	if old ~= self.flip then
		self:emit_signal("flipped", self.flip)
	end
end

return Flippable
