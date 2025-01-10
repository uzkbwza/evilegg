local ScorePickupSpawnEffect = require("fx.effect"):extend("ScorePickupSpawnEffect")

function ScorePickupSpawnEffect:new(x, y)
    ScorePickupSpawnEffect.super.new(self, x, y)
    self.duration = 50
	self.lines = 1
	self.z_index = -10
end

function ScorePickupSpawnEffect:draw(elapsed, tick, t)
	if tick % 2 == 0 and self.lines > 1 then
		return
	end
    local startup = 0
    local e = elapsed - startup
	local tick = floor(elapsed)
	local t2 = e / (self.duration - startup)

	if elapsed < startup then
		return
	end
	local size = 360 * t2
	for i=1, self.lines do
		graphics.set_color(graphics.color_flash(3 + i * 5, 2))
        graphics.rectangle("line", -size / 2 + i* 6, -size / 2 + i* 6, size - i * 12, size - i * 12, 0, 0, 0)
		graphics.rectangle("line", -size/2 + i* 6 - 1, -size/2 + i* 6 - 1, size - i * 12 + 2, size - i * 12 + 2, 0, 0, 0)

	end
end

return ScorePickupSpawnEffect
