local FlyerEnemy = require("obj.Enemy.Enemy"):extend("FlyerEnemy")

local DeathFx = require("fx.death_effect")

local sheet = SpriteSheet(textures.enemy_crow, 16, 16)

function FlyerEnemy:new(x, y)
    FlyerEnemy.super.new(self, x, y)
    self.curve_amount = 1
    self.score = 250
    self.sprite = sheet:get_frame(1)
	self.spawn_fx = "enemy_birdspawn"
end

function FlyerEnemy:draw()
	-- if (not self.waiting) or floor(self.tick / 2) % 2 == 0 then
		FlyerEnemy.super.draw(self)
	-- end
end

function FlyerEnemy:update(dt)
    if self.waiting then
		if self.world.scrolling then
        	self:tp(0, self.world.scroll_speed * self.world.scroll_direction * dt)
		end
        if self.fx then
            self.fx:tp_to(self.pos.x, self.pos.y)
			if self.fx.tick > self.fx.duration - 10 then
				-- self.fx:set_visibility((not self.waiting) or floor(self.tick / 2) % 2 == 0)
			end
		end
	end
end

function FlyerEnemy:get_texture()
	return self.sprite
end

function FlyerEnemy:enter()

	local ydir = -self.world.scroll_direction
	if not self.world.scrolling then
		ydir = 1
	end
	self.pos.y = self.pos.y + 16 * ydir
	local cx, cy = self:get_cell()
	local endx = self.world.map.cell_to_world(self.world.map_width, cy, 0) + 16
	local startx = 0
	if cx == self.world.map_width then
		startx = endx
		endx = -16
	end
	local starty = self.pos.y
    local endy = self.pos.y + 80 * self.curve_amount * ydir

    local s = self.sequencer
	local fx = DeathFx(self.pos.x, self.pos.y, self.sprite, sign(endx - startx))
	self:ref("fx", fx)
    fx.reversed = true
	fx.flash = false
	fx.duration = 20
	self:spawn_object(fx)
	self:set_flip(sign(endx - startx))
	self:set_visibility(false)


    s:start(function()
		self.waiting = true
        s:wait(20)
        self:set_visibility(true)
        s:wait(15)
		self.world:play_sfx("enemy_birdswoop")
        local frame = 2
		if self.curve_amount * ydir < 0 then
			frame = 3
		end
		self.sprite = sheet:get_frame(frame)

		self.waiting = false
        s:tween(function(t)
			local curve = math.tent(t) * 16 * self.curve_amount * ydir
			self:tp_to(lerp(startx, endx, t), lerp(starty, endy, t) + curve)
        end, 0, 1, 75, "linear")
		self:queue_destroy()
    end)
end

return FlyerEnemy
