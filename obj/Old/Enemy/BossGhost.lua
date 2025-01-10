local BossGhost = require("obj.Enemy.Enemy"):extend("BossGhost")

local sheet = SpriteSheet("enemy_ghosty", 16, 16)

function BossGhost:new(x, y)
    BossGhost.super.new(self, x, y)
    self.direction = 1
    self.distance = 600
    self.speed = 3
	self.close_speed = 5
    self.frequency = 0.05
    self.frequency_gain = 0.0
    self.ignore_despawn = true
    self.circling = true
	self.start_angle = 0
    self.delay = 0
	self.boss = nil
	self.spawn_fx = "enemy_ghost1"
	self.score = 0
    -- self.invuln = true
	self:disable_bump_layer(PHYSICS_HAZARD)
end

function BossGhost:enter()
	self:update(1)
	self:set_visibility(false)
	-- self.invuln = true
end

function BossGhost:get_texture()
    return sheet:loop(self.elapsed, 10)
end

function BossGhost:update(dt)
    local target = self.boss.pos
	self:set_visibility(true)

    if self.circling then
        self:ref_player()
		if self.player then
			self.aim_direction = self.pos:direction_to(self.player.pos)
		end
		-- self.aim_direction = -self.pos:direction_to(self.boss.pos)

		if self.tick < 150 + self.delay then
			self:tp_to(target.x + self.distance * sin(self.elapsed * self.frequency + self.start_angle) * self.direction * -1,
				target.y + self.distance * cos(self.elapsed * self.frequency + self.start_angle))
		else
			self:tp(0, self.world.scroll_speed * self.world.scroll_direction * dt)
		end
        if self.tick < 150 then
            self.distance = self.distance - self.close_speed * dt
            self.distance = max(self.distance, 64)
        else
			self:enable_bump_layer(PHYSICS_HAZARD, PHYSICS_ENEMY)
        end
        self.frequency = self.frequency + dt * self.frequency_gain
        if self.distance <= 0 then
            self:queue_destroy()
        end
        if self.tick > 200 + self.delay then
            -- local target = self.world.scroll_center

            -- local player = self:get_closest_object_with_tag("player")
            -- if player then
            -- target = player.pos
            -- end

            self.invuln = false
            self.circling = false
			self.world:play_sfx("enemy_ghost2")

        end
    else
        self:tp_to(self.pos.x + self.aim_direction.x * self.speed * dt,
            self.pos.y + self.aim_direction.y * self.speed * dt)

		if self.tick - self.delay > 270 then
			self:queue_destroy()
		end
		self:tp(0, self.world.scroll_speed * self.world.scroll_direction * dt)
    end
end

function BossGhost:draw()
    if (self.tick < 200 + self.delay - 50) and floor(self.tick / 2) % 2 == 0 then
        return
    end
	BossGhost.super.draw(self)
	if not debug.can_draw() then
		return
	end
    graphics.setColor(1, 0, 0)
	if self.aim_direction then
		graphics.line(0, 0, self.aim_direction.x * 100, self.aim_direction.y * 100)
	end
end

return BossGhost
