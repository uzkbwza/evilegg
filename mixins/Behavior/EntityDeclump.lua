local EntityDeclump = Object:extend("EntityDeclump")

function EntityDeclump:__mix_init()
    self.declump_radius = self.declump_radius or 4
	
    self.declump_force = (self.declump_force or 0.025)
    self.self_declump_modifier = (self.self_declump_modifier or 1)
	

	-- self.declump_same_class_only = true

	
    self.declump_mass = self.declump_mass or 1

	self:add_enter_function(EntityDeclump.declump_enter)

	self:add_update_function(EntityDeclump.do_declump)
end

function EntityDeclump:declump_enter()
	self.world:add_to_spatial_grid(self, "declump_objects", self.get_declump_rect)
end

function EntityDeclump:get_declump_rect()
	local pos = self.pos
	local declump_radius = self.declump_radius
	return pos.x - declump_radius, pos.y - declump_radius, declump_radius * 2, declump_radius * 2
end

function EntityDeclump:entity_declump_filter(other)
	return true
end


function EntityDeclump.try_declump(other, self, dt)
    if not self:entity_declump_filter(other) then return end
	if not other:entity_declump_filter(self) then return end
	local dx, dy = vec2_sub_table(other.pos, self.pos)
	local dist_squared = vec2_magnitude_squared(dx, dy)
	local my_radius = self.declump_radius
	local other_radius = other.declump_radius
    local rs = (my_radius + other_radius)
    if dist_squared < (rs * rs) then
        local distance = sqrt(dist_squared)
        local dirx, diry = vec2_normalized(dx, dy)
        local amount_x, amount_y = dirx, diry
        local my_force = self.declump_force * other.self_declump_modifier
        -- local other_force = other.declump_force * self.self_declump_modifier * 0.5
        local overlap_amount = (rs - distance)
        -- local my_amount = overlap_amount / my_radius
        local other_amount = overlap_amount / other_radius
        local my_mass = self.declump_mass
        local other_mass = other.declump_mass
        other:apply_force(amount_x * my_force * my_mass * other_amount / other_mass,
            amount_y * my_force * my_mass * other_amount / other_mass)
        -- self:apply_force(-amount_x * other_force * other_mass * my_amount / my_mass,
        --     -amount_y * other_force * other_mass * my_amount / my_mass)
        return true
    end
	return false
end

function EntityDeclump:do_declump(dt)
	self.world.declump_objects:each(self, self.try_declump, self, dt)
end

return EntityDeclump





