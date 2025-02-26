local EnemySpawn = GameObject2D:extend("EnemySpawn")

local TIME = 35
local SIZE = 15

function EnemySpawn:new(x, y, type)
    EnemySpawn.super.new(self, x, y)
	self.type = type
    self:add_elapsed_time()
    self:add_elapsed_ticks()
    self:add_signal("finished")
	self.z_index = 100
	-- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
end

function EnemySpawn:enter()
	self:play_sfx("enemy_spawn", 1.0)
    self:start_tick_timer("spawn", TIME)
	self:add_tag("wave_spawn")
end

function EnemySpawn:update(dt)
    if not self:is_tick_timer_running("spawn") then
		self:emit_signal("finished")
		self:queue_destroy()
	end
end

function EnemySpawn:draw()
	if idivmod(self.tick, 3, 2) == 0 then return end
	graphics.set_color(self.type == "enemy" and Color.red or (self.type == "hazard" and Color.orange) or Color.green, 1)
    if self.tick < 4 then
		graphics.set_color(1, 1, 1, 1)
	end
	self:do_rect()
end

function EnemySpawn:floor_draw()
	-- if self.is_new_tick and self.tick % 1 == 0 then
	-- 	local color = Palette.rainbow:tick_color(self.world.tick)
	-- 	local mod = 0.5
	-- 	graphics.set_color(color.r * mod, color.g * mod, color.b * mod)
	-- 	self:do_rect()
	-- end
end

function EnemySpawn:do_rect()
    local time_left = self:tick_timer_time_left("spawn")
    local size = 3 + (SIZE - 3) * 2 * (pow((time_left / TIME), 1.5))
    graphics.rectangle(self.tick < TIME - 25 and "line" or "fill", -size / 2, -size / 2, size, size)
end



return EnemySpawn
