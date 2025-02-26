local Roamer = require("obj.Enemy.BaseEnemy"):extend("Roamer")

-- local ROAMER_SHEET = SpriteSheet(textures.enemy_roamer, 10, 14)

function Roamer:new(x, y)
	self.max_hp = 1
    Roamer.super.new(self, x, y)
	-- self.drag = 0.6
	self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self:lazy_mixin(Mixins.Behavior.PlayerFinder)
	self:lazy_mixin(Mixins.Behavior.Roamer)
	self.bullet_push_modifier = 1.0
	self.declump_radius = 5
	self.walk_toward_player_chance = 60
    self.walk_frequency = 6
	self.body_height = 5
	self.declump_mass = 2.5
	self.palette = Palette[textures.enemy_roamer1]:clone()
end

function Roamer:get_palette()
	local palette = self.palette
	if self.world then
		palette:set_color(3, Palette.roamer:tick_color(self.world.tick / 2))
	end
	return palette, 0
end

function Roamer:get_sprite()
	-- return ROAMER_SHEET:loop(self.tick, 10, 0)
	return (self:tick_pulse(self.walk_frequency) and textures.enemy_roamer1 or textures.enemy_roamer2)
end

function Roamer:draw()
	Roamer.super.draw(self)
	-- graphics.line(0, 0, self.roam_direction.x * 100, self.roam_direction.y * 100)
end

return Roamer
