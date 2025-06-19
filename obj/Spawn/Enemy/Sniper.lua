local Sniper = BaseEnemy:extend("Sniper")
local SniperAim = GameObject2D:extend("SniperAim")
local SniperLaser = BaseEnemy:extend("SniperLaser")

Sniper.spawn_cry = "enemy_sniper_spawn"
Sniper.spawn_cry_volume = 0.8

function SniperAim:new(x, y)
    self.aim_direction = Vec2()
	self.z_index = 1.0
	SniperAim.super.new(self, x, y)
	self:add_elapsed_ticks()
end

function SniperAim:update(dt)
    self.z_index = self.blinking and 1.2 or -0.1
end

function SniperLaser:new(x, y)
    self.no_hurt_bubble = true
	self.z_index = 1.2
    SniperLaser.super.new(self, x, y)
    self:lazy_mixin(Mixins.Behavior.EnemyLaser)
    self.direction = nil
    self.hit_bubble_radius = 2
    -- self.hit_bubble_damage = 3
end

function SniperLaser:enter()
	self.start_x, self.start_y = self.pos.x, self.pos.y
end

function SniperLaser:update(dt)
    self:movev(self.direction * 25 * dt)
    self:set_laser_head(self.pos.x, self.pos.y)
    if self.tick > 10 then
		self:set_laser_tail(splerp_vec(self.laser_tail_x, self.laser_tail_y, self.pos.x, self.pos.y, 500, dt))
    else
		self:set_laser_tail(self.start_x, self.start_y)
	end
    if self.tick > 60 then
        self:queue_destroy()
    end
end

function SniperLaser:draw()
	graphics.set_line_width(7)
    graphics.set_color(Color.black)
    graphics.line(self.laser_tail_local_x, self.laser_tail_local_y, self.laser_head_local_x, self.laser_head_local_y)
    graphics.set_color(Color.cyan)
	graphics.set_line_width(5)
    graphics.line(self.laser_tail_local_x, self.laser_tail_local_y, self.laser_head_local_x, self.laser_head_local_y)
	graphics.rectangle_centered("fill", self.laser_head_local_x, self.laser_head_local_y, 10, 10)
	-- graphics.set_line_width(1)
end

function SniperLaser:collide_with_terrain()
end

function SniperAim:draw()
	if self.off then return end
	if self.blinking and self:tick_pulse(2) then
		return
	end

	-- local aim_direction_x, aim_direction_y = vec2_normalized(vec2_sub(self.aim_target.x, self.aim_target.y, self.pos.x, self.pos.y))
	local aim_direction_x, aim_direction_y = self.aim_direction.x, self.aim_direction.y

	local x1 = (self.pos.x)
    local y1 = (self.pos.y)
	local x2 = (self.pos.x + aim_direction_x * 800)
    local y2 = (self.pos.y + aim_direction_y * 800)
	x1, y1 = self:to_local(x1, y1)
    x2, y2 = self:to_local(x2, y2)
    graphics.set_line_width(self.blinking and 5 or 3)
	graphics.set_color(Color.black)
	graphics.line(x1, y1, x2, y2)
	graphics.set_line_width(self.blinking and 3 or 1)
	graphics.set_color(self.blinking and Color.yellow or Color.red)
	graphics.line(x1, y1, x2, y2)
end

function Sniper:new(x, y)
    self.body_height = 4
    self.max_hp = 3
    self.hurt_bubble_radius = 5
    self.hit_bubble_radius = 2
    -- self.walk_toward_player_chance = 80
    -- self.follow_allies = true
    Sniper.super.new(self, x, y)
    self.roam_diagonals = true
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    -- self:lazy_mixin(Mixins.Behavior.Roamer)
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self.declump_radius = 8
    self.declump_mass = 0.5
    self.bullet_push_modifier = 1.0
    -- self.walk_frequency = 4
    -- self.roam_chance = 6
    -- self.walk_speed = self.walk_speed or 0.9
    self.aim_target = self.pos:clone()
    self.aim_target.x, self.aim_target.y = vec2_add(self.aim_target.x, self.aim_target.y, rng:random_vec2_times(1))
	self.aim_valid = false
	self.aim_direction = Vec2()
end

function Sniper:enter()
    self:bind_destruction(self:ref("sniper_aim", self:spawn_object(SniperAim(self.pos.x, self.pos.y))))
end

local BACK_SPEED = 0.05
local FORWARD_SPEED = 0.01

function Sniper:state_Waiting_enter()
	local s = self.sequencer
	s:start(function()
		s:wait(rng:randi(40, 120))
		while not self.aim_valid do
			s:wait(rng:randi(15, 60))
		end
		self:change_state("Shooting")
	end)
end

function Sniper:state_Waiting_update(dt)
	
	local dx, dy = self:get_body_direction_to_player()
    -- self.aim_direction = Vec2(dx, dy)
	local dist = self:get_body_distance_to_player()
    if dist < 120 then
        self:apply_force(-dx * BACK_SPEED, -dy * BACK_SPEED)
    else
        self:apply_force(dx * FORWARD_SPEED, dy * FORWARD_SPEED)
    end

	local closest_player = self:get_closest_player()
    if closest_player then
        local bx, by = closest_player:get_body_center()
        self.aim_target.x, self.aim_target.y = splerp_vec(self.aim_target.x, self.aim_target.y, bx, by, 100, dt)
        if self.is_new_tick then
			self.aim_valid = false
			self.aim_valid = self.world:get_number_of_objects_with_tag("shooting_snipers") < 3 and
            vec2_distance(bx, by, self.aim_target.x, self.aim_target.y) < 10
		end
    end
	local bx, by = self:get_body_center()
	self.aim_direction.x, self.aim_direction.y = vec2_normalized(vec2_sub(self.aim_target.x, self.aim_target.y, bx, by))
end

function Sniper:state_Shooting_enter()
	self:add_tag("shooting_snipers")
	local s = self.sequencer
    s:start(function()
		self:play_sfx("enemy_sniper_beep", 0.6)
        if self.sniper_aim then
			self.sniper_aim.blinking = true
		end
        s:wait(30)
		self:shoot()
		if self.sniper_aim then
			self.sniper_aim.off = true
		end
		s:wait(rng:randi(30, 90))
		self:change_state("Waiting")
	end)
end

function Sniper:shoot()
    self:play_sfx("enemy_sniper_shoot")
    local laser = self:spawn_object(SniperLaser(self:get_body_center()))
	laser.direction = self.aim_direction:clone()
end

function Sniper:state_Shooting_exit()
	self:remove_tag("shooting_snipers")
	if self.sniper_aim then
		self.sniper_aim.off = false
		self.sniper_aim.blinking = false
	end
end

function Sniper:update(dt)

    if self.sniper_aim then
		self.sniper_aim:move_to(self:get_body_center())
		self.sniper_aim.aim_direction.x, self.sniper_aim.aim_direction.y = self.aim_direction.x, self.aim_direction.y
		-- self.sniper_aim.aim_target.x, self.sniper_aim.aim_target.y = self.aim_target.x, self.aim_target.y
	end
end

function Sniper:get_sprite()
	return textures.enemy_sniper
end

function Sniper:debug_draw()
	local x, y, _ = self:to_local(self.aim_target.x, self.aim_target.y)
	graphics.set_color(self.aim_valid and Color.green or Color.red)
	graphics.circle("fill", x, y, 6)
end

function Sniper:draw()

	Sniper.super.draw(self)
end

AutoStateMachine(Sniper, "Waiting")

return Sniper
