local Tower = require "obj.Enemy.Enemy":extend("Tower")
local TowerProjectile = require "obj.Enemy.TowerProjectile"

local sheet = SpriteSheet(textures.enemy_tower, 16, 32)

function Tower:new(x, y)
    Tower.super.new(self, x, y)
    self.collision_rect = Rect.centered(0, 0, 16, 32)
    self.collision_offset = Vec2(0, -8)
    self:init_health(10)
	self.hazard = false
	self:disable_bump_layer(PHYSICS_HAZARD)
	self.score = 500
end

function Tower:get_texture()
    return sheet:loop(self.tick, 8)
end

function Tower:draw()
	graphics.translate(0, -8)
	Tower.super.draw(self)
end

function Tower:update(dt)
	if self.tick > 90 and not self:timer_running("shoot") then
        self:start_timer("shoot", 90)
		self:spawn_object(TowerProjectile(self.pos.x, self.pos.y - 8))
	end
end

return Tower
