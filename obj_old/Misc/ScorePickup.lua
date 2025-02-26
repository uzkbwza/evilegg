local ScorePickup = GameObject:extend("ScorePickup")
local ObjectScoreFx = require("fx.object_score")
local DeathFx = require("fx.death_effect")


local sheet = SpriteSheet(textures.object_kebab, 16, 16)

local SCORE = 750

local ScorePickupSpawnEffect = require("fx.score_pickup_effect")

function ScorePickup:new(x, y)
	ScorePickup.super.new(self, x, y)
    self.score = SCORE
    self.sprite = sheet:random()
    self.z_index = -1
	self.collision_rect = Rect.centered(0, 0, 16, 16)
    self:add_elapsed_ticks()
    self:implement(Mixins.Behavior.BumpCollision)
    self:enable_bump_layer(PHYSICS_OBJECT)
	self.is_pickup = true
    self.lifetime = 400
    self.my_sfx = "player_pickup"
	self.is_kebab = true
end

function ScorePickup:enter()
    self:spawn_object(ScorePickupSpawnEffect(self.pos.x, self.pos.y))
	self.world:play_sfx("pickup_spawn")
end

function ScorePickup:update(dt)
    self:move(0, 0)
	if self.tick > self.lifetime then
		self:queue_destroy()
	end
end

function ScorePickup:pickup()
    self:queue_destroy()
    self:spawn_object(ObjectScoreFx(self.pos.x, self.pos.y, self.score))
    self:spawn_object(DeathFx(self.pos.x, self.pos.y, self.sprite, self.flip))
	self.world:play_sfx(self.my_sfx)
	if self.is_kebab then
		global_state.kebabs = global_state.kebabs + 1
	end

end

function ScorePickup:draw()
	if floor(self.tick/2) % 2 == 0 or self.tick < self.lifetime / 2 then
		graphics.draw_centered(self.sprite, 0, 0)
	end
end

return ScorePickup
