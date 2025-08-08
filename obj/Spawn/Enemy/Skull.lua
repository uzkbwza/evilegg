local Skull = BaseEnemy:extend("Skull")

function Skull:new(x, y)
    Skull.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    
end

function Skull:get_sprite()
    return textures.enemy_skull
end



return Skull
