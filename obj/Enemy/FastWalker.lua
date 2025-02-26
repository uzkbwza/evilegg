local FastWalker = require("obj.Enemy.Walker"):extend("FastWalker")

function FastWalker:new(x, y)
    FastWalker.super.new(self, x, y)
    self.walk_speed = 0.11
end

function FastWalker:get_sprite()
    return textures.enemy_fastwalker
end

return FastWalker
