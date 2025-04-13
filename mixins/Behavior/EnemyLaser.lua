local EnemyLaser = Object:extend("EnemyLaser")

function EnemyLaser:__mix_init()
    self:add_enter_function(EnemyLaser.enemy_laser_hitbox_enter)
	self.laser_head_local_x = 0
	self.laser_head_local_y = 0
	self.laser_tail_local_x = 0
	self.laser_tail_local_y = 0

end

function EnemyLaser:enemy_laser_hitbox_enter()
	if not self.no_hurt_bubble then
		self:add_hurt_bubble(0, 0, self.hurt_bubble_radius, "main", 0, 0)
	end
    self:add_hit_bubble(0, 0, self.hit_bubble_radius, "main", 1, 0, 0)
end

function EnemyLaser:set_laser_head(x, y)
	self.laser_head_x, self.laser_head_y = x, y
	x, y = self:to_local(x, y)
	self.laser_head_local_x = x
    self.laser_head_local_y = y
    -- global coordinates
	if not self.no_hurt_bubble then
		self:set_bubble_position("hurt", "main", x, y)
	end
	self:set_bubble_position("hit", "main", x, y)
end

function EnemyLaser:set_laser_tail(x, y)
	self.laser_tail_x, self.laser_tail_y = x, y
	x, y = self:to_local(x, y)
	self.laser_tail_local_x = x
	self.laser_tail_local_y = y
	if not self.no_hurt_bubble then
		self:set_bubble_capsule_end_points("hurt", "main", x, y)
	end
	self:set_bubble_capsule_end_points("hit", "main", x, y)
end

return EnemyLaser