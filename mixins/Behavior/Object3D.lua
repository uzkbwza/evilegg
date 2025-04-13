local Object3D = Object:extend("Object3D")

function Object3D:__mix_init(x, y, z)
    self:add_signal("moved")

	if x then
		if type(x) == "table" then
			self.pos = Vec3(x.x, x.y, x.z)
		else
			self.pos = Vec3(x, y, z)
		end
	else
		self.pos = Vec3(0, 0, 0)
	end
	
	self.static = false
		
	self.z_index = 0
end

function Object3D:init3D(x, y, z)
    Object3D.__mix_init(self, x, y, z)
end

function Object3D:move_toward(x, y, z, speed)
	local dx, dy, dz = x - self.pos.x, y - self.pos.y, z - self.pos.z

	local dist = sqrt(dx * dx + dy * dy + dz * dz)
	if dist < speed then
		self:move_to(x, y, z)
	else
		self:move(dx / dist * speed, dy / dist * speed, dz / dist * speed)
	end
end
	


---@diagnostic disable-next-line: duplicate-set-field
function Object3D:move_to(x, y, z)
	z = z or self.pos.z
	local old_x = self.pos.x
	local old_y = self.pos.y
	local old_z = self.pos.z


	self.pos.x = x
	self.pos.y = y
	self.pos.z = z

	if old_x ~= self.pos.x or old_y ~= self.pos.y or old_z ~= self.pos.z then
		self:on_moved()
	end
end

function Object3D:movev_to(v)
	self:move_to(v.x, v.y, v.z)
end

function Object3D:tp(x, y, z, ...)
    self:move_to(self.pos.x + x, self.pos.y + y, self.pos.z + z, true, ...)
end

function Object3D:tp_to(x, y, z, ...)
	-- old method from when interpolation was used
	self:move_to(x, y, z, true, ...)
end

function Object3D:tpv_to(v)
	self:tp_to(v.x, v.y, v.z)
end

return Object3D
