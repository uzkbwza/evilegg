local HopperBullet = require("obj.Enemy.BaseEnemy"):extend("HopperBullet")


function HopperBullet:new(x, y)
	self.max_hp = 0.1

    HopperBullet.super.new(self, x, y)
    self.drag = 0.0
    self.hit_bubble_radius = 1
	self.hurt_bubble_radius = 3
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
    -- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
	self:lazy_mixin(Mixins.Behavior.PlayerFinder)
    self.z_index = 10
	-- self.floor_draw_color = Palette.rainbow:get_random_color()
end

function HopperBullet:get_sprite()
    return textures.enemy_hopper_bullet
end

function HopperBullet:get_palette()
	local palette, offset = HopperBullet.super.get_palette(self)

	offset = idiv(self.tick + self.bullet_index, 3)

	return palette, offset
end

-- function HopperBullet:collide_with_terrain()
-- 	return false
-- end

function HopperBullet:get_floor_sprite()
	-- local i = floor(self.tick / 3) % 4
    -- if i == 0 then
	-- 	return textures.enemy_enforcer_bullet1
	-- elseif i == 1 then
	-- 	return textures.enemy_enforcer_bullet2
	-- elseif i == 2 then
	-- 	return textures.enemy_enforcer_bullet3
	-- elseif i == 3 then
	-- 	return textures.enemy_enforcer_bullet4
	-- end
	return textures.enemy_enforcer_bullet_trail
end

function HopperBullet:update(dt)
    if vec2_magnitude(self.vel.x, self.vel.y) < 0.05 then
        self:die()
    end

	-- local player = self:get_closest_player()
	-- if player and self.tick < 120 then
    --     local pdx, pdy = vec2_direction_to(self.pos.x, self.pos.y, player.pos.x, player.pos.y)
	-- 	local homing_speed = HOMING_SPEED * (1.0 - self.tick / 120)
	-- 	self:apply_force(pdx * homing_speed, pdy * homing_speed)
	-- end
end

-- local COLOR_MOD = 0.9

-- function HopperBullet:floor_draw()
--     local scale = pow(1.0 - self.tick / 600, 1.5)
--     graphics.set_color(scale * COLOR_MOD, 0, 1.0 - scale * COLOR_MOD, 1)
--     if self.is_new_tick and self.tick % 4 == 0 and scale > 0.1 then
-- 		local palette, offset = self:get_palette()
--         local sprite = self:get_floor_sprite()
		
-- 		graphics.scale(scale, scale)
-- 		graphics.drawp_centered(sprite, palette, offset, 0, 0)
-- 	end
-- end

return HopperBullet
