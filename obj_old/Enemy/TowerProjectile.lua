local TowerProjectile = require "obj.Enemy.Enemy":extend("TowerProjectile")

local sheet = SpriteSheet(textures.enemy_tower_projectile, 12, 12)

TowerProjectile.speed = 1.5

function TowerProjectile:new(x, y)
    self.collision_rect = Rect.centered(0, 0, 4, 4)
    TowerProjectile.super.new(self, x, y)
	-- self.invuln = true
	self:init_health(3)
    self.score = 150
	self.z_index = 1

end

function TowerProjectile:enter()
	self.direction = Vec2(0, self.world.scroll_direction)
    local player = self.world.player
    if player then
		self.direction = self.pos:direction_to(player.pos)
	end
end

function TowerProjectile:update(dt)
	self:movev_to(self.pos + self.direction * self.speed * dt)
	if self.tick > 300 then
		self:queue_destroy()
	end
end

function TowerProjectile:get_texture()
	return sheet:loop(self.tick, 6)
end

return TowerProjectile

