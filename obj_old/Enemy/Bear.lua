local Bear = require "obj.Enemy.Enemy":extend("Bear")

Bear.speed = 0.5

local sheet = SpriteSheet(textures.enemy_bear, 32, 32)

local sensor_config = {
	collision_rect = Rect.centered(0, 0, 32, 32),
	entered_function = function(self, other)
        if other.is_wall then 
			other:die(true)
		end
	end,
    bump_mask = to_layer_bit(PHYSICS_TERRAIN),

}


function Bear:new(x, y)
    Bear.super.new(self, x, y)
	self.collision_rect = Rect.centered(0, 0, 24, 24)
    self.score = 350
    self:init_health(10)
    self.death_fx = "enemy_bear_die"
	self.spawn_fx = "enemy_bear_spawn"
	self:add_bump_sensor(sensor_config)
end

function Bear:update(dt)
    self:tp(0, self.speed * -self.world.scroll_direction * dt)
	self.y_flip = -self.world.scroll_direction
end

function Bear:get_texture()
    return sheet:loop(self.tick, 24)
end

return Bear
