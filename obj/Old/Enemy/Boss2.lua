local Boss2 = require("obj.Enemy.Enemy"):extend("Boss2")
local EnemyLaser = require("obj.Enemy.EnemyLaser")
local BossLaser = require("obj.Enemy.Enemy"):extend("BossLaser")
local BossGhost = require("obj.Enemy.BossGhost")
local DeathEffect = require"fx.death_effect"
local BulletHitSpriteSheet = SpriteSheet(textures.fx_bullethit, 16, 16)
local DeathFx = require("fx.death_effect")
local ObjectScore = require("fx.object_score")

local sheet = SpriteSheet("player_creator", 16, 16)

local hitbox_sensor_config = {
	collision_rect = Rect.centered(0, 0, 8, 8),
	entered_function = function(self, other)
        if other.is_hittable then
            other:on_hit(self)
		end
		self:hit_something()
	end,
    bump_layer = to_layer_bit(PHYSICS_HAZARD),

	hazard = true,
}

function Boss2:new(x, y)
    Boss2.super.new(self, x, y)
	self:add_bump_sensor(hitbox_sensor_config)
    self.state = "Idle"
	self:implement(Mixins.Behavior.AutoStateMachine)
    self.score = 50000
    self:init_health(300)
    -- self:init_health(2)
	self:disable_bump_layer(PHYSICS_HAZARD)
	self:enable_bump_mask(PHYSICS_TERRAIN)
    self.spawn_fx = nil
    self.sequence = {}
	self.state_counter = 1
	self.state_sequence_counter = 1
    self.phase = 1
	self.ignore_despawn = true
	self.player_pos = Vec2(0,0)
end

function Boss2:state_Idle_enter()
end


function Boss2:get_next_state()

	if self.phase ~= 4 then 
		if self.health <= self.max_health * 0.75 then
			self.phase = 2
		end
   		if self.health <= self.max_health * 0.45 then
       		self.phase = 3
		end
	end
	-- if self.health <= self.max_health * 0.25 then
	-- 	self.phase = 4
	-- end

	-- self.phase = 3

	if table.is_empty(self.sequence) then
        local sequence = {}
		self["phase"..tostring(self.phase)](self, sequence)
        self.sequence = sequence
		self.state_sequence_counter = self.state_sequence_counter + 1
	end
	-- table.pretty_print(self.sequence)
	self.state_counter = self.state_counter + 1

	local value = table.pop_front(self.sequence)

	return value
end

function Boss2:phase1(sequence)
    table.insert(sequence, "Walking")
	local attacks = {
		"LaserBarrage",
		-- "LaserBarrage",
		"LaserCircle",
	}
    local i = ((self.state_sequence_counter - 1) % #attacks) + 1
    if rng.percent(50) then
		table.insert(sequence, "LaserBarrage")
	end
	table.insert(sequence, attacks[i])
end

function Boss2:phase2(sequence)
    -- if self.state_sequence_counter % 2 == 0 then
    --     self:phase1(sequence)
    --     return
    -- end
	
	table.insert(sequence, "Walking")
	local attacks = {
		"LaserBarrage",
		-- "LaserBarrage",
		"LaserCircle",
	}
    local i = ((self.state_sequence_counter - 1) % #attacks) + 1
	if rng.percent(50) then
		table.insert(sequence, "LaserBarrage")
	end
	table.insert(sequence, attacks[i])
end

function Boss2:phase3(sequence)
    table.insert(sequence, "Walking")
    local attacks = {
        "LaserBarrage",
        "BossLaser",
        "LaserCircle",
        "BossLaser",
    }
    local i = ((self.state_sequence_counter - 1) % #attacks) + 1
    if rng.percent(50) then
        table.insert(sequence, rng.choose("LaserCircle"))
    end
    table.insert(sequence, attacks[i])
end

function Boss2:phase4(sequence)
    table.insert(sequence, "Walking")
    local attacks = {
        "LaserBarrage",
        "BossLaser",
        "LaserCircle",
        "BossLaser",
    }
    local i = ((self.state_sequence_counter - 1) % #attacks) + 1
    if rng.percent(50) then
        table.insert(sequence, rng.choose("LaserCircle", "BossLaser"))
    end
    table.insert(sequence, attacks[i])
end



function Boss2:spawn_ghosts()
	local middle = self.pos
	local num_ghosts = 6
	for i = 1, num_ghosts do
		local angle = (i / num_ghosts) * tau
        local ghost = BossGhost(middle.x, middle.y)
		ghost.boss = self
		ghost.delay = floor(i/2 - 1) * 25
		ghost.start_angle = angle
		self:spawn_object(ghost)
	end
end

function Boss2:die(noscore)
    local s = self.sequencer
	s:clear_all()
	self:change_state("Idle")
	self:emit_signal("died")

end

function Boss2:do_laser_circle(angle)
	local vx, vy = angle_to_vec2_unpacked(angle)
    local bw = self.bump_world
	self.charge_aim_direction = Vec2(angle_to_vec2_unpacked(angle))

    local hit = bw:raycast(self.pos.x, self.pos.y, self.pos.x + vx * self.laser_distance, self.pos.y + vy * self.laser_distance, nil,
        to_layer_bit(PHYSICS_PLAYER, PHYSICS_TERRAIN))


	local hit_player = false
	if hit then
		local colx, coly = hit.x, hit.y
		self.laser_collision_x, self.laser_collision_y = colx, coly
        if self.tick % 4 == 0 then
            local death_effect = self:spawn_object(DeathEffect(self.pos.x + vx * 8, self.pos.y + vy * 8, BulletHitSpriteSheet:get_frame(1)))
            death_effect.flash = false
            death_effect.color_flash = { 0, 2 }
            death_effect.size_mod = 0.5
            death_effect.duration = death_effect.duration * 0.25
            death_effect = self:spawn_object(DeathEffect(colx, coly, BulletHitSpriteSheet:get_frame(1)))
            death_effect.flash = false
            death_effect.color_flash = { 0, 2 }
            death_effect.size_mod = 1.0
            death_effect.duration = death_effect.duration * 0.25
            if hit.item.is_player then
                hit.item:on_hit(self)
                hit_player = true
            end
        end
    else
		self.laser_collision_x, self.laser_collision_y = self.pos.x + vx * self.laser_distance, self.pos.y + vy * self.laser_distance
	end

    if not hit_player then
		local rect_size = 10
		local unit = Vec2(vx, vy):normalized()
        for i = -rect_size/2, rect_size/2 do
            local offsx, offsy = vec2_rotated(unit.x, unit.y, tau / 4)
			local startx, starty = self.pos.x + offsx * i, self.pos.y + offsy * i
			local endx, endy = startx + vx * self.laser_distance, starty + vy * self.laser_distance
			local hit = bw:raycast(startx, starty, endx, endy, nil,
			to_layer_bit(PHYSICS_PLAYER, PHYSICS_TERRAIN))

			
			if hit and hit.item and hit.item.is_player then
				hit.item:on_hit(self)
				hit_player = true
			end

			if hit_player then
				break
			end
		end
	end
end

function Boss2:update(dt)
	self:ref_player()
	if self.player then
		self.player_pos = self.player.pos
	end
end

function Boss2:state_LaserBarrage_enter()
	self.laser_barrage_counter = self.laser_barrage_counter or 0
    local s = self.sequencer
    s:start(function()
        s:wait(10)
        local num_lasers = 8
        local num_circles = 6
        for i = 1, num_circles do
			s:start(function() 
                for j = 1, num_lasers do
					local angle = 0
					-- if self.laser_barrage_counter % 2 == 0 then
						-- angle = self.pos:direction_to(self.player_pos):rotated(j * 0.1 - 0.):angle()
					-- else
						angle = (j - 1) * (tau / num_lasers) + (i - 1) * (tau / num_circles / 2)
					-- end
					local dx, dy = angle_to_vec2_unpacked(angle)
					local x = self.pos.x + 8 * dx
					local y = self.pos.y + 8 * dy
					local obj = self:spawn_object(EnemyLaser(x, y, dx, dy))
					self.world:play_sfx("enemy_boss2_laser1", 0.75)
                    obj.speed = 2.0
					obj.z_index = 1
					if self.laser_barrage_counter % 2 == 0 then
                        obj.noclip = true
						obj.speed = 2.0
						s:wait(5)
					end
				end
			end)
            s:wait(20)
        end
        s:wait(30)
        self:change_state(self:get_next_state())
    end)
	self.laser_barrage_counter = self.laser_barrage_counter + 1
end

function Boss2:state_LaserBarrage_update(dt)
	self:mirror_movement(0.25 * dt)
end

function Boss2:state_DashAttack_enter()
	local s = self.sequencer
	s:start(function()
        s:wait(10)
        while self.player == nil do
            s:wait(1)
        end

		self.dashing = true
		self:change_state(self:get_next_state())
	end)
end

function Boss2:state_BossLaser_enter()
	if self:get_first_object_with_tag("boss_laser") then
		self:change_state(self:get_next_state())
		return
	end
	local s = self.sequencer
	s:start(function()
        s:wait(30)

        s:start(function() 
			for i = 1, 5 do
				local obj = self:spawn_object(BossLaser(self.player_pos.x, self.player_pos.y))
				s:wait(30)
			end
        end)
		s:wait(90)
		self:change_state(self:get_next_state())
	end)
end

function Boss2:state_BossLaser_update(dt)
	self:mirror_movement(0.5 * dt)
end

function Boss2:state_LaserCircle_enter()

	self.laser_distance = 5
    local s = self.sequencer
    local dir = self.pos.x < self.world.scroll_center.x and -1 or 1
	-- print(dir)
	s:start(function()
        self.charging_big_laser = true
		local angle = tau/4 + tau / 4 * dir
        -- end
        self.world:play_sfx("enemy_boss2_laser3")
		
		self.charge_aim_direction = Vec2(angle_to_vec2_unpacked(angle))


        s:wait(60)
		self.firing_big_laser = true
        self.charging_big_laser = false
        self.world:play_sfx("enemy_boss2_laser2", 1.0, 1.0, true)
		
        s:tween(function(angle)
			self:do_laser_circle(angle)
        end, angle, angle + dir * tau, 90)

		self.firing_big_laser = false
		self.world:stop_sfx("enemy_boss2_laser2")
		self:change_state(self:get_next_state())
	end)
end

function Boss2:state_LaserCircle_update(dt)
	if self.firing_big_laser then
        self.laser_distance = self.laser_distance + dt * 5
		self.world.camera:frame_rumble(1)
	end
	self:mirror_movement(0.15 * dt)
	
end

function Boss2:state_LaserCircle_exit()
	self.firing_big_laser = false
	self.charging_big_laser = false
	self.world:stop_sfx("enemy_boss2_laser2")
	self.world:stop_sfx("enemy_boss2_laser3")
end

function Boss2:state_Walking_enter()
    self.walk_counter = self.walk_counter or 0
	if (self.phase == 2 and (self.walk_counter + 1) % (2) == 0) or (self.phase == 3 and rng.percent(50)) or self.phase == 4 then
		rng.choose{
			self.spawn_ghosts
		}(self)
	end
	self.walk_counter = self.walk_counter + 1
end

function Boss2:mirror_movement(speed)
	local tx = self.pos.x
	local ty = self.pos.y
	-- if player then
		local middle = self.world.scroll_center
		ty = middle.y - (self.player_pos.y - middle.y)
		tx = middle.x - (self.player_pos.x - middle.x + 16)
	-- end
	local x, y = vec2_approach(self.pos.x, self.pos.y, tx, ty, speed)
    self:move_to(x, y)
end

function Boss2:state_Walking_update(dt)
	self:mirror_movement(1.25 * dt)
    if self.state_tick == 120 then
		self:change_state(self:get_next_state())
	end
end

function Boss2:get_texture()
	return sheet:loop(self.tick, 10)
end

function Boss2:draw()
    Boss2.super.draw(self)
    if self.charging_big_laser then
        graphics.set_color(graphics.color_flash(0, -1))
        graphics.circle("fill", self.charge_aim_direction.x * 8, self.charge_aim_direction.y * 8, 5)
    end
    if self.firing_big_laser and floor(self.tick/2) % 2 == 0 then
		graphics.push("all")
        graphics.set_line_width(10)
        graphics.set_color(graphics.color_flash(0, -1))
        local endx, endy = self:to_local(self.laser_collision_x, self.laser_collision_y)
		local startx, starty = vec2_normalized(self.charge_aim_direction.x, self.charge_aim_direction.y)
		startx, starty = startx * 8, starty * 8
        graphics.line(startx, starty, endx, endy)
        graphics.circle("fill", startx, starty, 5)
		graphics.circle("fill", endx, endy, 5)
		graphics.pop()
	end
end

function BossLaser:new(x, y)
	BossLaser.super.new(self, x, y)
	self.spawn_fx = nil
	self.texture = textures.enemy_crosshair
    self.fired = false
	self.follow_time = 45
    self.fire_time = 1
	self.follow_speed = 1
	self.fire_time = 70
	self.z_index = 2
	self:disable_bump_layer(PHYSICS_HAZARD, PHYSICS_ENEMY)
end

function BossLaser:get_texture()
	return self.texture
end

function BossLaser:enter(dt)
	self:add_tag("boss_laser")
	self.world:play_sfx("enemy_boss2_laser4")
	local s = self.sequencer
	s:start(function()
		s:wait(self.fire_time)
		self.fired = true

		local death_effect = self:spawn_object(DeathEffect(self.pos.x, self.pos.y, BulletHitSpriteSheet:get_frame(1)))
		death_effect.flash = false
		death_effect.color_flash = { 0, 2 }
		death_effect.size_mod = 2.0
        death_effect.duration = death_effect.duration * 1.5
		self.world:play_sfx("enemy_boss2_laser5")
		self.z_index = 0
        self:enable_bump_layer(PHYSICS_HAZARD)
		self.world.camera:start_rumble(2, 5, "linear")
        s:start(function()
            s:wait(10)
			self:disable_bump_layer(PHYSICS_HAZARD)
        end)
		-- TODO: sfx
        s:tween_property(self, "fire_time", 1, 0, 30)
		self:queue_destroy()
	end)
end

function BossLaser:update(dt)
	if self.tick <= self.follow_time then
		self:ref_player()
		if self.player then
            self.player_pos = self.player.pos:clone() or self.player_pos
            self.player_pos.x = self.player.pos.x
            self.player_pos.y = self.player.pos.y
		end
	end
    if self.player_pos then
		self:tp_to(vec2_approach(self.pos.x, self.pos.y, self.player_pos.x, self.player_pos.y, dt * self.follow_speed))
	end
end

function BossLaser:draw()
    if not self.fired then
		if floor(self.tick / 1.5) % 2 == 0 then
            -- graphics.draw_centered(textures.enemy_crosshair, 0, 0)
            local t = clamp(self.elapsed / (self.fire_time - 15), 0, 1)
            local line_length = lerp(24*5, 24, t)
			local line_offset = lerp(-16*5, -10, t)
            local radius = lerp(300, 16, t)
            graphics.push("all")
            graphics.set_line_width(1)
			graphics.rotate(self.elapsed * 0.1)
			graphics.set_color("ff0000")
            graphics.circle("line", 0, 0, radius)
            graphics.line(radius + line_offset, 0, radius + line_length + line_offset, 0)
            graphics.line(-radius - line_offset, 0, -radius - line_length - line_offset, 0)
            graphics.line(0, radius + line_offset, 0, radius + line_length + line_offset)
            graphics.line(0, -radius - line_offset, 0, -radius - line_length - line_offset)
			graphics.pop()
		end
    else
        graphics.push("all")
		local radius = 10 * self.fire_time
		graphics.set_line_width(radius * 2)
		graphics.set_color(graphics.color_flash(0, -1))
        graphics.line(0, 0, 0, -1000)
		graphics.circle("fill", 0, 0, radius)
		graphics.pop()
	end
end

return Boss2
