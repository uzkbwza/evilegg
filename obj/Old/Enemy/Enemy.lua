local Enemy = GameObject:extend("Enemy")
local DeathFx = require("fx.death_effect")
local ObjectScore = require("fx.object_score")


-- local DeathFxSpriteSheet = SpriteSheet(textures.fx_enemydeath, 32, 32)
-- local DeathFxAnimation = DeathFxSpriteSheet:get_animation(4)

function Enemy:new(x, y)
    Enemy.super.new(self, x, y)

    local old_bump_filter = Mixins.Behavior.BumpCollision.default_bump_filter

    self.collision_rect = Rect(0, 0, 14, 14)
    self.collision_offset = Vec2(0, 0)

    self.bump_filter = function(item, other)
        local result = old_bump_filter(item, other)
        return result
    end

    self:add_elapsed_ticks()
    self:add_sequencer()

    self:implement(Mixins.Fx.RetroRumble)
    self:implement(Mixins.Behavior.Flippable)
    self:implement(Mixins.Behavior.FreezeFrames)
    self:implement(Mixins.Behavior.BumpCollision)
    self:implement(Mixins.Behavior.Hittable)
    self:implement(Mixins.Behavior.GridTerrainQuery)
    self:enable_bump_layer(PHYSICS_ENEMY, PHYSICS_HAZARD)

    self:set_flip(1)

    self.y_flip = 1
    self.hazard = true
    self.is_enemy = true

    self.z_index = 0
    self.hit_flash = false

    self.score = 150

    self.spawn_fx = "enemy_spawn"
	self.invuln = false

    self:init_health(1)
    self:add_signal("died")
end

function Enemy:ref_player()
	return self:ref("player", self:get_closest_object_with_tag("player"))
end

function Enemy:init_health(health)
	self.max_health = health
	self.health = health
end

function Enemy:on_hit(by)
	if self.invuln then return end
	self.health = self.health - by.damage
	if self.health <= 0 then
		self:die()
	else
        self:start_timer("hit_flash", 10)
	end
    self.world:play_sfx("enemy_hit_by_bullet")
	self:start_rumble(1, 7, "constant0", true, false)
end


function Enemy:die(noscore)
	self:queue_destroy()
	self.world:play_sfx(self.death_fx or "enemy_die")
	local tex =  self:get_texture()
    self:spawn_object(DeathFx(self.pos.x, self.pos.y, tex, self.flip))
	if not noscore and self.score > 0 then
		self:spawn_object(ObjectScore(self.pos.x, self.pos.y, self.score))
	end
	self:emit_signal("died")
end

function Enemy:enter_shared()
	Enemy.super.enter_shared(self)
	if self.spawn_fx then
		self.world:play_sfx(self.spawn_fx)
	end
end

function Enemy:enter()
    self:add_tag("enemy")
end


function Enemy:get_texture()
	return textures.enemy_placeholder1
end

function Enemy:get_player()
	return self.world:get_first_object_with_tag("player")
end

function Enemy:draw()
    if self:timer_running("hit_flash") and self.tick % 2 == 0 then
        return
    end
	
	if self.invuln and floor(self.tick/2) % 2 == 0 then
		return
	end
	

	graphics.draw_centered(self:get_texture(), 0, 0, 0, self.flip, self.y_flip, 0, 1)
end

return Enemy
