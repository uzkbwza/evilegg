local EvilPlayer = BaseEnemy:extend("EvilPlayer")

local EvilPlayerSmallBullet = BaseEnemy:extend("EvilPlayerSmallBullet")
local EvilPlayerBigBullet = BaseEnemy:extend("EvilPlayerBigBullet")
local MAX_HISTORY_SIZE = 3
local HISTORY_TRAIL_RESOLUTION = 1

EvilPlayer.hurt_sfx = "enemy_evil_player_hurt"
EvilPlayer.hurt_sfx_volume = 0.6
EvilPlayer.spawn_cry = "enemy_evil_player_spawn"
EvilPlayer.death_cry = "enemy_evil_player_death"
EvilPlayerSmallBullet.death_sfx = "enemy_evil_player_small_bullet_death"
EvilPlayerSmallBullet.death_sfx_volume = 0.6
EvilPlayerBigBullet.death_sfx = "enemy_evil_player_big_bullet_death"
EvilPlayerBigBullet.death_sfx_volume = 1

function EvilPlayer:new(x, y)
	self.max_hp = 35
    self.body_height = 3
	self.hurt_bubble_radius = 12
	self.drag = 0.01
    EvilPlayer.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self.bullet_push_modifier = 0.2
    self.position_history = {}
	self.target_angle = 0
	self.melee_attacking = false
    self.intangible = true
	-- self.sfx_offset = rng:randi(-25, 25)
	self.sfx_offset = 0
end

function EvilPlayer:enter()
    self:add_tag("evil_player")
	for i=1, MAX_HISTORY_SIZE do
		table.insert(self.position_history, {
			x = self.pos.x,
			y = self.pos.y,
		})
	end
end

function EvilPlayer:wakeup()
	self.melee_attacking = true
	self.intangible = false
	self:change_state("Awake")
end

function EvilPlayer:update(dt)
    if self.is_new_tick then
        local len = #self.position_history
        table.insert(self.position_history, {
            x = self.pos.x,
            y = self.pos.y,
        })
        while len > MAX_HISTORY_SIZE do
            table.remove(self.position_history, 1)
            len = len - 1
        end
    end

    self.friends_killed = self.num_evil_players - self.world:get_number_of_objects_with_tag("evil_player")
	
	if (self.world.timescaled.tick + self.sfx_offset) % (120 - min(self.friends_killed, 5) * 20) == 0 then
		self:play_sfx("enemy_evil_player_swell", 0.6)
	end
	-- self:play_sfx_if_stopped("enemy_evil_player_noise", 0.2)


end

function EvilPlayer:get_sprite()
	return self:tick_pulse(4) and textures.enemy_evil_player1 or textures.enemy_evil_player2
end

function EvilPlayer:state_Dormant_enter()
end

function EvilPlayer:state_Dormant_exit()
end

function EvilPlayer:state_Awake_enter()
end

function EvilPlayer:get_xp()
	return 0
end

function EvilPlayer:get_score()
	return 0
end

function EvilPlayer:state_Awake_update(dt)
	self.target_angle = self.target_angle + (0.005 + min(self.friends_killed, 5) * 0.006) * dt * (self.guy_offset % 2 == 0 and 1 or -1)
    local target_x, target_y = vec2_from_polar(100, self.angle_offset + self.target_angle)
	-- print(target_x, target_y)
    
	local pbx, pby = self:closest_last_player_pos()
	target_x, target_y = target_x + pbx, target_y + pby
	self.target_x, self.target_y = target_x, target_y

	
	local closest
    local dx, dy = vec2_direction_to(self.pos.x, self.pos.y, target_x, target_y)
    dx, dy = vec2_normalized_times(dx, dy, 0.045)


    self:move_to(splerp_vec(self.pos.x, self.pos.y, target_x, target_y, 800, dt))
	
    if self.is_new_tick then
		
        if rng:percent(4) and not self:is_tick_timer_running("shooting") and not self:is_tick_timer_running("shooting_cooldown") then
            self:start_tick_timer("shooting", rng:randi(30, 90), function()
				self:start_tick_timer("shooting_cooldown", rng:randi(30, 90))
			end)
		end
		
        if self:is_tick_timer_running("shooting") and self.state_tick > 40 and (self.state_tick + self.guy_offset) % (max(20 - self.friends_killed * 7, 4)) == 0 then
            local impulse_x, impulse_y = vec2_from_polar(min(1.25 + self.friends_killed * 0.05, 2.0),
                self.elapsed * 0.04 * (self.guy_offset % 2 == 0 and -1 or 1))
			local bx, by = self:get_body_center()
			local shoot_dx, shoot_dy = vec2_direction_to(bx, by, pbx, pby)
			bx, by = vec2_add(bx, by, vec2_mul_scalar(shoot_dx, shoot_dy, 4))
            self:spawn_object(EvilPlayerSmallBullet(bx, by)):apply_impulse(impulse_x, impulse_y)
			self:play_sfx("enemy_evil_player_smallshoot")
        end
		
		if not self:is_tick_timer_running("shooting_big_bullet_cooldown") and rng:percent(0.08 + 0.09 * min(self.friends_killed, 5)) then
            self:start_tick_timer("shooting_big_bullet_cooldown", rng:randi(10, 30))
			local spread = deg2rad(17)
			
			self:play_sfx("enemy_evil_player_bigshoot")
            local bx, by = self:get_body_center()
            local shoot_dx, shoot_dy = vec2_direction_to(bx, by, pbx, pby)
			bx, by = vec2_add(bx, by, vec2_mul_scalar(shoot_dx, shoot_dy, 8))

			-- local dist = 16
			
			self:spawn_object(EvilPlayerBigBullet(bx, by)).spread = -spread

			self:spawn_object(EvilPlayerBigBullet(bx, by)).spread = spread
			
			self:spawn_object(EvilPlayerBigBullet(bx, by)).spread = 0
		end
	end
end

function EvilPlayer:state_Awake_exit()
end

function EvilPlayer:debug_draw()
    if self.target_x and self.target_y then
		local x, y = self:to_local(self.target_x, self.target_y)
		graphics.circle("line", x, y, 10)
	end
end

function EvilPlayer:draw()

	if self.state == "Dormant" and self.tick % 2 == 0 then return end

    graphics.push("all")
    self:body_translate()

	local rect_size = min(19 + sin(self.elapsed * 0.08) * 2, self.elapsed * 0.5)
    graphics.push()
    local color = iflicker(self.tick, 2, 2) and Color.white or Color.magenta
    local palette = self:get_palette_shared()
	if palette then
		color = palette:tick_color(self.elapsed, 0, 2)
	end
	graphics.set_color(color)
	graphics.rotate(self.elapsed * 0.06)
	graphics.rectangle_centered("line", 0, 0, rect_size, rect_size)
	graphics.pop()

    if self:tick_pulse(2) then
        for i = 1, #self.position_history, HISTORY_TRAIL_RESOLUTION do
            local pos = self.position_history[i]
            local x, y = self:to_local(pos.x, pos.y)
            graphics.drawp_centered(self:get_sprite(), nil, -idiv(self.tick, 7) + i, x, y)
        end
    end

    graphics.pop()

    EvilPlayer.super.draw(self)
end

function EvilPlayer:floor_draw()
    if not self.is_new_tick then
        return
    end

	if self.state == "Dormant" then
		return
	end
	
    graphics.push("all")
    self:body_translate()

    if self:tick_pulse(2) then
        for i = 1, #self.position_history, HISTORY_TRAIL_RESOLUTION do
            local pos = self.position_history[i]
            local x, y = self:to_local(pos.x, pos.y)
            graphics.drawp_centered(self:get_sprite(), Palette.evil_player_trail, -idiv(self.tick, 7) + i, x, y)
        end
    end

    graphics.pop()
end


-- EvilPlayerBullet.death_sfx = "enemy_cube_bullet_die"
-- EvilPlayerBullet.death_sfx_volume = 0.6

function EvilPlayer:exit()
	-- self:stop_sfx("enemy_evil_player_noise")
end

function EvilPlayerSmallBullet:new(x, y)
	self.max_hp = 2
	EvilPlayerSmallBullet.super.new(self, x, y)
    self.drag = 0.0
    self.hit_bubble_radius = 3
	self.hurt_bubble_radius = 6
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)

	self.bullet_push_modifier = 0.45

    self.z_index = 1
end

function EvilPlayerSmallBullet:get_palette()
	return nil, idiv(self.tick, 6)
end

function EvilPlayerSmallBullet:get_sprite()
    return self:tick_pulse(6) and textures.enemy_evil_player_small_bullet1 or textures.enemy_evil_player_small_bullet2
end


EvilPlayerBigBullet.bullet_speed = 2.5

function EvilPlayerBigBullet:new(x, y)
	self.max_hp = 10
	EvilPlayerBigBullet.super.new(self, x, y)
    self.drag = 0.0
    self.hit_bubble_radius = 4
	self.hurt_bubble_radius = 7
    self:lazy_mixin(Mixins.Behavior.TwinStickEnemyBullet)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self.bullet_push_modifier = 0.35
	self.spawning = true
	

    self.z_index = 1
end

function EvilPlayerBigBullet:enter()
	self.intangible = true
	self.melee_attack = false
	local s = self.sequencer
    s:start(function()
		s:wait(45)
		self.spawning = false
		self.intangible = false
		self.melee_attack = true
        local pbx, pby = self:closest_last_player_body_pos()
		local bx, by = self:get_body_center()
		local dx, dy = vec2_direction_to(bx, by, pbx, pby)
        local target_x, target_y = vec2_rotated(dx, dy, self.spread)
		self:play_sfx("enemy_evil_player_big_bullet_shoot")
		self:apply_impulse(target_x * EvilPlayerBigBullet.bullet_speed, target_y * EvilPlayerBigBullet.bullet_speed)
	end)
	
end

function EvilPlayerBigBullet:get_palette()
	return nil, idiv(self.tick, 2)
end

function EvilPlayerBigBullet:get_sprite()
    if self.spawning then
		return self:tick_pulse(3) and textures.enemy_evil_player_big_bullet3 or textures.enemy_evil_player_big_bullet4
	end
    return self:tick_pulse(3) and textures.enemy_evil_player_big_bullet1 or textures.enemy_evil_player_big_bullet2
end

function EvilPlayerBigBullet:floor_draw()
	if not (self.is_new_tick and self.tick % 5 == 0) then
        return	
	end
	graphics.push("all")
	self:body_translate()
	graphics.drawp_centered(self:get_sprite(), Palette.evil_player_big_bullet_trail, -idiv(self.tick, 3), 0, 0)
	graphics.pop()

end


AutoStateMachine(EvilPlayer, "Dormant")

return EvilPlayer
