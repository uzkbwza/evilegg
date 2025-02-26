local ScreenClear = require("obj.Misc.ScorePickup"):extend("ScreenClear")
local ScorePickupSpawnEffect = require("fx.score_pickup_effect")

local sheet = SpriteSheet(textures.object_bomb, 16, 16)

function ScreenClear:new(x, y)
    ScreenClear.super.new(self, x, y)
    self.score = 1500
    self.sprite = textures.friendly_placeholder1
    self.lifetime = 1200
	self.is_kebab = false
    self.z_index = 10
	self.my_sfx = "player_bomb"
end

function ScreenClear:update(dt)
    if self.world.scroll_direction == -1 then
        if self.pos.y > self.world.scroll + self.world.viewport_size.y - 32 then
            self:tp_to(self.pos.x, self.world.scroll + self.world.viewport_size.y - 32)
        end
    else
        if self.pos.y < self.world.scroll + 32 then
            self:tp_to(self.pos.x, self.world.scroll + 32)
        end
    end
    self.sprite = sheet:loop(self.tick, 3)
	if self.tick > self.lifetime then
		self:queue_destroy()
	end
end

function ScreenClear:pickup()
	ScreenClear.super.pickup(self)
    self:queue_destroy()
    local fx = self:spawn_object(ScorePickupSpawnEffect(self.pos.x, self.pos.y))
    fx.lines = 3
    fx.duration = 30
    local fx2 = require("fx.effect")(self.pos.x, self.pos.y)
    fx2.duration = 8
	fx2.z_index = -10
    fx2.draw = function(self)
		if floor(self.tick) % 2 == 0 then	
			if floor(self.tick) % 4 == 0 then
				graphics.set_color("ffff00")
			else
				graphics.set_color("0000ff")
			end
			graphics.rectangle("fill", -100000, -100000, 200000, 200000)
		end
    end

    self:spawn_object(fx2)
    for _, obj in self.world.objects:ipairs() do
        if obj.is_pickup and not obj == self then
            obj:pickup()
        end
        if obj.is_enemy then
            obj:die()
        end
    end
end

return ScreenClear
