local Ghost = require("obj.Enemy.Enemy"):extend("Ghost")

local sheet = SpriteSheet("enemy_ghosty", 16, 16)

function Ghost:new(x, y)
    Ghost.super.new(self, x, y)
    self.direction = 1
    self.distance = 130
    self.speed = 3
	self.close_speed = 0.25
    self.frequency = 0.05
    self.frequency_gain = 0.0
    self.ignore_despawn = true
    self.circling = true
	self.start_angle = 0
    self.delay = 0
	self.spawn_fx = "enemy_ghost1"
	self.score = 100
    -- self.invuln = true
	self:disable_bump_layer(PHYSICS_HAZARD)
end

function Ghost:enter()
	self:update(1)
	self:set_visibility(false)
end

function Ghost:get_texture()
    return sheet:loop(self.elapsed, 10)
end

function Ghost:update(dt)
    local target = self.world.scroll_center
	self:set_visibility(true)

    if self.circling then
		self.aim_direction = self.pos:direction_to(target)

		if self.tick < 150 + self.delay then
			self:tp_to(target.x + self.distance * sin(self.elapsed * self.frequency + self.start_angle) * self.direction * -1,
				target.y + self.distance * cos(self.elapsed * self.frequency + self.start_angle))
		else
			self:tp(0, self.world.scroll_speed * self.world.scroll_direction * dt)
		end
        if self.tick < 150 then
            self.distance = self.distance - self.close_speed * dt
            self.distance = max(self.distance, 0)
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
            self:enable_bump_layer(PHYSICS_HAZARD)
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

function Ghost:draw()
    if self.tick < 200 + self.delay - 50 and floor(self.tick / 2) % 2 == 0 then
        return
    end
	Ghost.super.draw(self)
	if not debug.can_draw() then
		return
	end
    graphics.setColor(1, 0, 0)
	if self.aim_direction then
		graphics.line(0, 0, self.aim_direction.x * 100, self.aim_direction.y * 100)
	end
end

return Ghost
