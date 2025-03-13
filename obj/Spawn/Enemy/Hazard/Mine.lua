local Mine = require("obj.Spawn.Enemy.BaseEnemy"):extend("Mine")

function Mine:new(x, y)
	self.max_hp = 1
	self.hit_bubble_damage = 2
	self.hit_bubble_radius = 3
    Mine.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.BulletPushable)
	-- self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    -- self.declump_radius = 10
	self.bullet_push_modifier = 1.0
	-- self.declump_mass = 10
	self.body_height = 0
	-- self.melee_both_teams = true
    self.self_declump_modifier = 0.0
	self.z_index = 0
end

function Mine:enter()
	self:hazard_init()
end

function Mine:get_palette()
	return nil, floor(self.world.tick / 3)
end

function Mine:get_sprite()
    return textures.enemy_mine
end

function Mine:normal_death_effect()
	self:flash_death_effect(1)
end

function Mine:on_landed_melee_attack()
	self:die()
end

return Mine
