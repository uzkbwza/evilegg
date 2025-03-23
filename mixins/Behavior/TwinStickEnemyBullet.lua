
local TwinStickEnemyBullet = Object:extend("TwinStickEnemyBullet")
function TwinStickEnemyBullet:__mix_init()

	if not self.enemy_bullet_can_touch_walls then
		
		local old_on_terrain_collision = self.on_terrain_collision
		self.on_terrain_collision = function(self, ...)
			old_on_terrain_collision(self, ...)
			self:die()
		end
	end

    self.enemy_bullet = true

    self.lifetime = self.lifetime or 600
	self:add_update_function(function(self, dt)
		if self.elapsed > self.lifetime then
			self:die()
		end
    end)
    if self.z_index == 0 then
        self.z_index = 10
    end
	
	self:add_enter_function(function(self)
		self:add_tag("enemy_bullet")
	end)
end

return TwinStickEnemyBullet
