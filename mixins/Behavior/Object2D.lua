local Object2D = Object:extend("Object2D")

function Object2D:__mix_init(x, y)
    self:add_signal("moved")

	if x then
		if type(x) == "table" then
			self.pos = Vec2(x.x, x.y)
		else
			self.pos = Vec2(x, y)
		end
	else
		self.pos = Vec2(0, 0)
	end
	
	self.static = false
end

function Object2D:init2D(x, y)
	Object2D.__mix_init(self, x, y)
end

function Object2D:move_toward(x, y, speed)
	local dx, dy = x - self.pos.x, y - self.pos.y
	local dist = sqrt(dx * dx + dy * dy)
	if dist < speed then
		self:move_to(x, y)
	else
		self:move(dx / dist * speed, dy / dist * speed)
	end
end
	


---@diagnostic disable-next-line: duplicate-set-field
function Object2D:move_to(x, y)
	local old_x = self.pos.x
	local old_y = self.pos.y

	self.pos.x = x
	self.pos.y = y

	if old_x ~= self.pos.x or old_y ~= self.pos.y then
		self:on_moved()
	end
end

function Object2D:movev_to(v)
	self:move_to(v.x, v.y)
end

function Object2D:tp(x, y, ...)
    self:move_to(self.pos.x + x, self.pos.y + y, nil, true, ...)
end

function Object2D:tp_to(x, y, ...)
	-- old method from when interpolation was used
	self:move_to(x, y, nil, true, ...)
end

function Object2D:tpv_to(v)
	self:tp_to(v.x, v.y)
end

return Object2D
