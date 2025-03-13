local FastWalker = require("obj.Spawn.Enemy.Walker"):extend("FastWalker")

function FastWalker:new(x, y)
	self.max_hp = 2
    FastWalker.super.new(self, x, y)
    self.walk_speed = 0.1
	self.bullet_push_modifier = 4.5
end

function FastWalker:get_sprite()
    return textures.enemy_fastwalker
end

return FastWalker
