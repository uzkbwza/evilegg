
local TwinStickEnemyBullet = Object:extend("TwinStickEnemyBullet")
function TwinStickEnemyBullet:__mix_init()
    if not self.enemy_bullet_can_touch_walls then
        self.wall_collision_ignore_vel = true
		self:add_terrain_collision_death()
    end

    self.is_enemy_bullet = true

    self.lifetime = self.lifetime or 6000
    self:add_update_function(function(self, dt)
        if self.elapsed > self.lifetime then
            self:on_lifetime_end()
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

function TwinStickEnemyBullet:on_lifetime_end()
end

function TwinStickEnemyBullet:add_terrain_collision_death()
	local old_on_terrain_collision = self.on_terrain_collision
	self.on_terrain_collision = function(self, ...)
		old_on_terrain_collision(self, ...)
        -- self.vel:mul_in_place(0.1)
		self:die()
	end
end

return TwinStickEnemyBullet
