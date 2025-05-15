local EnemySpawn = GameObject2D:extend("EnemySpawn")
local BigEnemySpawn = EnemySpawn:extend("BigEnemySpawn")

local TIME = 45
local SIZE = 15

function EnemySpawn:new(x, y, type)
    EnemySpawn.super.new(self, x, y)
	self.type = type
    self:add_elapsed_time()
    self:add_elapsed_ticks()
    self:add_signal("finished")
	-- self:lazy_mixin(Mixins.Behavior.RandomOffsetPulse)
	self.z_index = 100
	self.random_offset = rng(0, tau)
	-- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
end

function EnemySpawn:enter()
	self:play_sfx("enemy_spawner_spawn", 1.0)
    self:start_tick_timer("spawn", TIME)
	self:add_tag("wave_spawn")
end

function EnemySpawn:update(dt)

	if game_state.game_over then
		self:queue_destroy()
		return
	end

	if (debug.enabled and input.debug_skip_wave_held and self.tick > 1)
	or (not self:is_tick_timer_running("spawn")) then
        self:emit_signal("finished")
        self:queue_destroy()
        -- if self.type == "enemy" then
        self:play_sfx("enemy_spawn", 0.45)
        -- elseif self.type == "hazard" then
        -- self:play_sfx("hazard_spawn", 0.5)
        -- end
    end

end

function EnemySpawn:draw()
	graphics.set_color(self.type == "enemy" and Color.red or (self.type == "hazard" and Color.orange) or Color.green, 1)
	if self.tick > TIME - 10 and idivmod(self.tick, 2, 2) == 0 then return end
    if self.tick < 4 or self.tick > TIME - 4 then
        graphics.set_color(1, 1, 1, 1)
    end

	graphics.push()
	graphics.rotate(tau/8)

	
	self:do_rect()
	graphics.pop()
end

function EnemySpawn:get_scale() 
	return 1
end

function EnemySpawn:get_min_size()
	return 0
end

function EnemySpawn:do_rect()
	local cross_time = 30
	local fill = self.tick < TIME - 25 and "line" or "fill"
	local scale = self:get_scale()
    if self.tick > TIME - cross_time then
		local rect_size = 5 * scale
		local cross_distance = 10 * scale
        local t = ease("outExpo")((self.tick - (TIME - cross_time)) / cross_time)
		t = remap(t, 0, 1, 0.25, 1)
        local distance = cross_distance * (1 - t)
		rect_size = max(rect_size, self:get_min_size())
        graphics.rectangle(fill, -distance - rect_size / 2, -distance - rect_size / 2, rect_size, rect_size)
        graphics.rectangle(fill, distance - rect_size / 2, distance - rect_size / 2, rect_size, rect_size)
        graphics.rectangle(fill, -distance - rect_size / 2, distance - rect_size / 2, rect_size, rect_size)
        graphics.rectangle(fill, distance - rect_size / 2, -distance - rect_size / 2, rect_size, rect_size)
		graphics.rectangle(fill, -distance - rect_size / 2, -rect_size / 2, rect_size, rect_size)
        graphics.rectangle(fill, distance - rect_size / 2, -rect_size / 2, rect_size, rect_size)
		graphics.rectangle(fill, -rect_size / 2, -distance - rect_size / 2, rect_size, rect_size)
		graphics.rectangle(fill, -rect_size / 2, distance - rect_size / 2, rect_size, rect_size)
    end
    local time_left = self:tick_timer_time_left("spawn")
    local size = (5 + (SIZE - 3) * 2 * (pow((time_left / TIME), 1.5))) * scale
	size = max(size, self:get_min_size())
    graphics.rectangle(fill, -size / 2, -size / 2, size, size)
end

function BigEnemySpawn:get_scale()
	return 2
end

function BigEnemySpawn:get_min_size()
	return 32
end

return {
    EnemySpawn = EnemySpawn,
    BigEnemySpawn = BigEnemySpawn,
} 
