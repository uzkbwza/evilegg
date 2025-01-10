local Robot = require("obj.Enemy.Enemy"):extend("Ghost")
local EnemyLaser = require("obj.Enemy.EnemyLaser")

local sheet = SpriteSheet("enemy_robot", 16, 16)

function Robot:new(x, y)
	Robot.super.new(self, x, y)
	self.speed = 0.25
	self.y_direction = -1
    self:init_health(4)
    self.score = 250
	self.spawn_fx = "enemy_robot"
	self:enable_bump_mask(PHYSICS_TERRAIN)
end

function Robot:enter()
    Robot.super.enter(self)
	self:start_timer("shoot", 30, function()
		self:shoot()
	end)
end

function Robot:shoot()
	local laser = self:spawn_object(EnemyLaser(self.pos.x, self.pos.y, 0, self.y_direction))
	laser = self:spawn_object(EnemyLaser(self.pos.x, self.pos.y, -0.5, self.y_direction))
	laser = self:spawn_object(EnemyLaser(self.pos.x, self.pos.y, 0.5, self.y_direction))
	self:start_timer("shoot", 90, function()
        self:shoot()
	end)
	self.world:play_sfx("enemy_robot2")
end

function Robot:get_texture()
	return sheet:loop(self.elapsed, 10)
end

function Robot:update(dt)
    self:move(0, self.speed * dt * self.y_direction)
	-- table.pretty_print(self.timers)
end

function Robot:process_collision(col)
	if col.other.solid then
		self.y_direction = -self.y_direction
	end
end

return Robot
