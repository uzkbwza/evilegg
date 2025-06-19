local Effect = GameObject2D:extend("Effect")

function Effect:new(x, y)
	Effect.super.new(self, x, y)
	self:add_elapsed_time()
	self:add_elapsed_ticks()
    self.duration = self.duration or 1
	self.t = 0
end

function Effect:update(dt)
end

function Effect:update_shared(dt)
	if self.duration > 0 then
		self.t = self.elapsed / self.duration
		if self.elapsed > self.duration then
			self.elapsed = self.duration
			self:queue_destroy()
			return
		end
	end
	Effect.super.update_shared(self, dt)
end

function Effect:draw_shared()
														         -- t = 0.0 to 1.0
	Effect.super.draw_shared(self, self.elapsed, self.tick, self.elapsed / self.duration )
end	

return Effect
