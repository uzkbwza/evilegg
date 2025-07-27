local RingOfLoyaltyBullet = require("obj.Player.Bullet.BasePlayerBullet"):extend("RingOfLoyaltyBullet")

RingOfLoyaltyBullet.palette = Palette.loyalty_bullet
RingOfLoyaltyBullet.draw_scale_modifier = 2.0

function RingOfLoyaltyBullet:new(x, y)
	local extra_bullet = true
	self.use_artefacts = true
    self.use_upgrades = true
    -- self.die_on_hit = false
    self.lifetime = 10
	self.push_modifier = 15.0
    self.hit_vel_multip = 40
    -- self.hp = 1
    -- self.hp = 1 + game_state.upgrades.range
    self.damage = 7.5
    RingOfLoyaltyBullet.super.new(self, x, y, extra_bullet)
    if game_state.upgrades.range == 1 then
        self.lifetime = 13
        self.lifetime = self.lifetime * (self.base_speed / self.speed)
    elseif game_state.upgrades.range == 2 then
        self.lifetime = 16
        self.lifetime = self.lifetime * (self.base_speed / self.speed)
    end
	-- print(self:get_damage())
    self.radius = 12
end

-- function RingOfLoyaltyBullet:update(dt)
--     RingOfLoyaltyBullet.super.update(self, dt)
--     if self.tick >= 7 and not self.reduced_hp_yet then
--         self.reduced_hp_yet = true
--         self.hp = 1
--     end
-- end

-- function RingOfLoyaltyBullet:on_hit_blocking_objects_this_frame()
--     self.hp = self.hp - 1
--     if self.hp <= 0 then
--         if not self:is_timer_running("stop_hitting") then
--             self:start_timer("stop_hitting", 1, function()
--                 self:die()
--             end)
--         end
--     end
-- end

return RingOfLoyaltyBullet
