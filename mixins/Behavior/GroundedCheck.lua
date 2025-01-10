local GroundedCheck = Object:extend("GroundedCheck")

function GameObject:check_grounded(object)
	if object.vel and object.vel.y < 0 then return false end
	local cols = object:bump_check(0, 0.0001)
    for i, collision in ipairs(cols) do
        if collision.other.solid and collision.normal.y < 0 and collision.slide then
            return true
        end
    end
	return false
end

function GroundedCheck:__mix_init()
    self.is_grounded = true
	local check = function(self, dt)
		local old_grounded = self.is_grounded
        self.is_grounded = self:check_grounded(self)
        if (not old_grounded) and self.is_grounded then
            self:on_landed()
		elseif old_grounded and (not self.is_grounded) then
			self:on_takeoff()
		end
	end
    self:add_update_function(check)
	self:add_move_function(check)
end

function GroundedCheck:on_landed()
    -- override this
end

function GroundedCheck:on_takeoff()
	-- override this
end

return GroundedCheck
