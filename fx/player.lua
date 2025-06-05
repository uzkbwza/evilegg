local JetpackDust = Effect:extend("JetpackDust")

function JetpackDust:new(x, y, flip)
    JetpackDust.super.new(self, x, y)
    if flip == nil then error("flip must be provided") end
    
	self:implement(Mixins.Behavior.Flippable)
    self:set_flip(flip)

    self.drag = 0.01
    self.z_index = -1
    self.radius = rng:randfn(2.0, 0.65)

    self:implement(Mixins.Behavior.SimplePhysics)

    local ix, iy = vec2_rotated(-1, 2, rng:randf(-tau / 10, tau / 10))
    local speed = rng:randfn(0.5, 0.25)
    self:apply_impulse(flip * ix * speed, iy * speed)
    self.duration = round(rng:randfn(8, 2))

    self:implement(Mixins.Behavior.BumpCollision)
    self:enable_bump_mask(PHYSICS_TERRAIN)
end

function JetpackDust:bump_filter(other)
	if xtype(other) == "SpaceGuy" then
		return "cross"
	end
	return "slide"
end

function JetpackDust:update(dt)
    JetpackDust.super.update(self, dt)
end

function JetpackDust:draw()
    local t = self.t
	graphics.set_color(Color.white)
	if t < 0.30 then
		graphics.set_color(Color.yellow)
	elseif t < 0.60 then
        graphics.set_color(Color.orange)
	-- elseif t < 0.80 then
	else
		graphics.set_color(Color.red)
		-- graphics.set_color(Color.darkgreyblue)
	end
	graphics.circle("fill", 0, 0, self.radius * (1 - self.t))
end

return {
    JetpackDust = JetpackDust,
	BulletHitEffect = require("fx.bullet_hit_effect")
}
