local Effect = require("fx.effect")

local DeathEffect = Effect:extend()

local NUM_STARS = 8
local NUM_STARS_2 = floor(NUM_STARS / 2)
local NUM_PUFFS = 8
local DURATION = 14

local STAR_DISTANCE = 90
local PUFF_DISTANCE = 50

local STAR_OFFSET = 30
local PUFF_OFFSET = 0

local easing = ease("outCubic")
local easing2 = ease("outCubic")
local easing3 = ease("inExpo")

function DeathEffect:new(x, y)
	DeathEffect.super.new(self, x, y)
	self.duration = DURATION
	self.starting_rot = 0
	self.rot = self.starting_rot
	self.star_angle_offset = 0
	self.dir = 1
	
end

function DeathEffect:draw(elapsed, ticks, t)

	local e = easing(t)
    local e2 = e
	

	local fill = "fill"
	-- if t < 0.5 then fill = "fill" end
	-- if t > 0.5 and floor(ticks / 2) % 2 == 0 then
	-- 	fill = "line"
	-- 	graphics.set_color(Color.seagreen)
	-- end
    -- if t > 0.6 then fill = "line" end
	
	-- if not (ticks > 15 and floor(ticks / 2) % 4 == 0) then
	graphics.set_color(Color.turquoise)
    for i = 1, NUM_PUFFS do
        local angle = (tau / NUM_PUFFS * i) + rad(PUFF_OFFSET) + ((tau / NUM_PUFFS / 2) * (floor(ticks / 2)))
        local dist = PUFF_DISTANCE * e2
        local x, y = vec2_from_polar(dist, angle)
        graphics.circle(fill, x, y, ticks < 1 and 60 or 17 + (1 - e) * 10)
    end

	graphics.set_color(Color.white)

	graphics.circle(fill, 0, 0, ticks < 1 and 100 or 28 + (1 - e) * 10 )

	local star_size = 17 + (1 - e) * 10

	if t > 0.5 and floor(ticks / 2) % 2 == 0 then
		return
	end

	for i = 1, NUM_STARS do
		local angle = ((tau / NUM_STARS) * i) + rad(STAR_OFFSET) + self.star_angle_offset
		local dist = STAR_DISTANCE * e2
		local x, y = vec2_from_polar(dist, angle)
		graphics.set_color(Color.turquoise)
		-- if floor(ticks / 5) % 2 == 0 then
			-- graphics.set_color(Color.white)
		-- end
		graphics.push()
        graphics.translate(x, y)
		graphics.rotate(e2 * tau * 2 * -self.dir + (tau / NUM_STARS) * i)
		graphics.rectangle("fill", -star_size/2, -star_size/2, star_size, star_size)
		graphics.pop()
	end

end

return DeathEffect
