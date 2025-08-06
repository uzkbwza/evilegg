local NormalRescue = require("obj.Spawn.Pickup.Rescue.BaseRescue"):extend("NormalRescue")

local RUN_SPEED = 1.6
local WALK_SPEED = 0.2

function NormalRescue:new(x, y)
    self.walk_speed = self.walk_speed or WALK_SPEED
    self.base_walk_speed = self.walk_speed
    -- self.team = "player"
    -- self.body_height = 4
    -- self.max_hp = self.max_hp or 3
    -- self.hurt_bubble_radius = self.hurt_bubble_radius or 3
    -- self.declump_radius = self.declump_radius or 20
    -- self.self_declump_modifier = self.self_declump_modifier or 0.3
    NormalRescue.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.Roamer)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
end

function NormalRescue:enter()
    NormalRescue.super.enter(self)
    if self.run_toward_player then
        -- self.roaming = false
        -- self:add_update_function(self.run_toward_player_func)
        self.walk_toward_player_chance = 100
        self.roam_chance = 100
        self.walk_speed = RUN_SPEED
        self.base_walk_speed = self.walk_speed
    end
end

function NormalRescue:run_toward_player_func()
    local player = self:get_closest_player()
    if player then
        local dx, dy = player.pos.x - self.pos.x, player.pos.y - self.pos.y
        self:apply_force(vec2_normalized_times(dx, dy, RUN_SPEED))
    end
end

function NormalRescue:update(dt)
    NormalRescue.super.update(self, dt)
    
    if self:is_tick_timer_running("fatigue") then
        self.walk_speed = self.base_walk_speed * 0.25
    else
        self.walk_speed = self.base_walk_speed
    end
end

return NormalRescue
