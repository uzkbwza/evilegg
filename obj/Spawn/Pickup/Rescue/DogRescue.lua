local DogRescue = require("obj.Spawn.Pickup.Rescue.BaseRescue"):extend("DogRescue")
-- local DogScaredParticle = Effect:extend("DogScaredParticle")

local FLEE_DISTANCE = 32
local FLEE_SPEED = 0.125
function DogRescue:new(x, y)
    self.walk_speed = self.walk_speed or 0.015
    -- self.team = "player"
    -- self.body_height = 4
    -- self.max_hp = self.max_hp or 3
    -- self.hurt_bubble_radius = self.hurt_bubble_radius or 3
    self.declump_radius = self.declump_radius or 20
    self.self_declump_modifier = self.self_declump_modifier or 1.0
    DogRescue.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.Roamer)
	
    -- self.roaming = false
    self.sprite = textures.ally_rescue_dog1
    self.spawn_cry = "ally_dog_rescue_bark"
    self.spawn_cry_volume = 0.6
	
end

function DogRescue:on_terrain_collision(normal_x, normal_y)
	self:terrain_collision_bounce(normal_x, normal_y)
end

function DogRescue:state_Roaming_enter()
    -- self.roaming = true
end

function DogRescue:state_Roaming_exit()
    -- self.roaming = false
end

function DogRescue:on_damaged(damage)
	DogRescue.super.on_damaged(self, damage)
	self:change_state("Fleeing")
end

function DogRescue:state_Roaming_update(dt)
    local px, py = self:closest_last_player_body_pos()
	local bx, by = self:get_body_center()
    if vec2_distance(bx, by, px, py) <= FLEE_DISTANCE and self.is_new_tick then
        self:change_state("Fleeing")
		return
    end
    self.sprite = iflicker(self.tick, 4, 2) and textures.ally_rescue_dog1 or textures.ally_rescue_dog2



	-- if self.roaming then
    --     if self.roam_direction.x ~= 0 then
    --         self:set_flip(self.roam_direction.x < 0 and -1 or 1)
    --     end
    -- else

	if self.target_ally == nil then
        local ally = self:get_random_ally()
        for i = 1, 10 do
            if ally ~= nil and ally ~= self then
                break
            end
            ally = self:get_random_ally()
        end
        if ally then
			self:ref("target_ally", ally)
		end
	end

	if self.target_ally then
		local ax, ay = self.target_ally:get_body_center()
		local dx, dy = vec2_normalized(ax - bx, ay - by)
		self:apply_force(dx * self.walk_speed, dy * self.walk_speed)
	end

	if self.vel.x ~= 0 then
		self:set_flip(self.vel.x < 0 and -1 or 1)
	end
	-- end
end

function DogRescue:state_Fleeing_enter()
    self.roaming = false
	self:play_sfx("ally_dog_rescue_bark2", 0.85)
	-- self:spawn_object(DogScaredParticle(self.pos.x, self.pos.y - 12))
end

function DogRescue:get_sprite()
	return self.sprite
end

function DogRescue:draw()
    DogRescue.super.draw(self)
	if self.state == "Fleeing" and self.state_tick < 40 then
		-- graphics.set_color(Color.white)
		if iflicker(gametime.tick, 4, 2) then
			graphics.drawp_centered(textures.ally_rescue_dog_exclamation_mark, nil, 0, 0, -12, 0, 1, 1)
		end
	end
end

function DogRescue:state_Fleeing_update(dt)
    local px, py = self:closest_last_player_body_pos()
    local bx, by = self:get_body_center()
    local dx, dy = vec2_normalized(bx - px, by - py)
    if self.state_tick > 45 and vec2_distance(px, py, bx, by) > FLEE_DISTANCE then
        self:change_state("Roaming")
		return
    else
        self:apply_force(dx * FLEE_SPEED, dy * FLEE_SPEED)
    end
    self.sprite = iflicker(self.tick, 3, 2) and textures.ally_rescue_dog1 or textures.ally_rescue_dog3
    if self.vel.x ~= 0 then
        self:set_flip(self.vel.x < 0 and -1 or 1)
    end
end

-- function DogScaredParticle:new(x, y)
-- 	DogScaredParticle.super.new(self, x, y)
-- 	self.z_index = 1
-- 	self.duration = 20
-- end

-- function DogScaredParticle:draw(elapsed, tick, t)
--     graphics.set_color(Color.white)
-- 	if iflicker(gametime.tick, 2, 2) then
-- 		graphics.drawp_centered(textures.ally_rescue_dog_exclamation_mark, nil, 0, 0, -t * 2, 0, 1, 1)
-- 	end
-- end

AutoStateMachine(DogRescue, "Roaming")

return DogRescue
