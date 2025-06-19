local Health = Object:extend("Health")

function Health:__mix_init(hp)
    self:initialize_hp((hp or self.max_hp) or 1)
    self:add_signal("health_changed")
    self:add_signal("damaged")
    self:add_signal("healed")
    self:add_signal("health_reached_zero")
    self:add_signal("max_health_changed")
end

function Health:on_health_reached_zero()
    -- self:queue_destroy()
end

function Health:on_max_health_changed(max_hp)
end


function Health:on_health_changed(difference, new_hp)
end


function Health:on_damaged(difference, new_hp)
end

function Health:on_healed(difference, new_hp)
end

function Health:damage(amount)
	self:update_health_relative(-amount)
end

function Health:update_health_relative(amount, allow_overflow)
    local new_hp = self.hp + amount
    self:set_hp(new_hp, allow_overflow)
end

function Health:initialize_hp(new_hp)
    self.hp = new_hp
	self.max_hp = new_hp
end

function Health:set_hp(new_hp, allow_overflow)
	if not allow_overflow then
		new_hp = clamp(new_hp, 0, self.max_hp)
	end
    local different = new_hp ~= self.hp
    local difference = self.hp - new_hp
	local abs_difference = abs(difference)
    self.hp = new_hp
	if new_hp > self.max_hp then
		self.max_hp = new_hp
	end

    if different then
		self:on_health_changed(difference, new_hp)
        self:emit_signal("health_changed", difference, new_hp)
		if difference < 0 then
			self:on_healed(abs_difference, new_hp)
            self:emit_signal("healed", abs_difference, new_hp)
		else
			self:on_damaged(abs_difference, new_hp)
			self:emit_signal("damaged", abs_difference, new_hp)
		end

		if new_hp <= 0 then
			self:on_health_reached_zero()
			self:emit_signal("health_reached_zero")
		end
    end
end

function Health:set_max_hp(amount)
	self.max_hp = amount
	self:on_max_health_changed(self.max_hp)
    self:emit_signal("max_health_changed", self.max_hp)
end

function Health:reset_hp()
	self:set_hp(self.max_hp)
end

function Health:heal(amount, allow_overflow)
    self:update_health_relative(amount, allow_overflow)
end

return Health
