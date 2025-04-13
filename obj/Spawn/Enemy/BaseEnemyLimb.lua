local BaseEnemyLimb = BaseEnemy:extend("BaseEnemyLimb")

function BaseEnemyLimb:new(x, y, parent)
    BaseEnemyLimb.super.new(self, x, y, parent)
    self:ref("parent", parent)
end

function BaseEnemyLimb:damage(amount)
    self.parent:damage(amount)
end

return BaseEnemyLimb
