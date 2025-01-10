local Enemy = require("obj.Enemy.Enemy")
local FlyerEnemy = require("obj.Enemy.Flyer")

local Boss1 = Enemy:extend("Boss1")
local ObjectScore = require("fx.object_score")


local Boss1Knife = Enemy:extend("Boss1Knife")

function Boss1Knife:new(x, y, direction_x, direction_y)
    Boss1Knife.super.new(self, x, y)
	self.collision_rect = Rect.centered(0, 0, 10, 10)
    self.texture = textures.enemy_knives
    self.speed = 3
	self.score = 0
    self.direction_x, self.direction_y = vec2_normalized(direction_x, direction_y)
    self:init_health(4)
	self:disable_bump_layer(PHYSICS_ENEMY)
	self.spawn_fx = "enemy_knifethrow"
	self.state_counter = 1
end

function Boss1Knife:get_texture()
	return self.texture
end

function Boss1Knife:update(dt)
	self:tp(self.speed * dt * self.direction_x, self.speed * dt * self.direction_y)
	self.rot = self.tick % 4 * tau / 4 * self.flip
	self:set_flip(self.direction_x < 0 and -1 or 1)
end

local DeathFx = require"fx.death_effect"

local sheet = SpriteSheet(textures.enemy_vendor, 64, 64)
local hitbox_sensor_config = {
	collision_rect = Rect.centered(0, 0, 24, 16),
	entered_function = function(self, other)
        if other.is_hittable then
            other:on_hit(self)
		end
		self:hit_something()
	end,
    bump_layer = to_layer_bit(PHYSICS_HAZARD),

	hazard = true,
}

function Boss1:new(x, y)
    Boss1.super.new(self, x, y)
	self.collision_rect = Rect(0, 0, 40, 24)
	
	self.hazard = false
    self.state = "Idle"
	self.spawn_fx = nil
	self.anim_coroutine = nil
    self.showing_cart = true
	self.wiggle_counter = 0
	self.ignore_despawn = true

	self.texture = textures.enemy_vendor_at_cart
    -- order kinda matters!
	self:implement(Mixins.Behavior.AutoStateMachine)
    self:init_health(200)
    -- self:init_health(2)
    self.player = nil
	self.score = 25000
    self:add_bump_sensor(hitbox_sensor_config)
    self:disable_bump_layer(PHYSICS_HAZARD)
	
    local sequence = {
		-- "Throw2",
		-- "Throw2",
		-- "Throw2",
		-- "Throw2",
		-- "Throw2",
		-- "Throw2",
    }


	self.phase = 1
	self.state_counter = 1

	self.sequence = sequence
end


function Boss1:die()
    local s = self.sequencer
	self.invuln = true
    s:clear_all()
	s:start(function()
		self:emit_signal("died")
        self.dying = true
		self:change_state("Dying")
		self:ref("dying_knife", self:spawn_object(Boss1Knife(self.pos.x + -self.flip * 16, self.pos.y, -self.flip, 1)))
		self.dying_knife.speed = 1.0
        s:wait(90)
		if self.dying_knife then
			self.dying_knife:die()
		end
		self:queue_destroy()
		self.world:play_sfx(self.death_fx or "enemy_die")
		local tex =  self:get_texture()
		self:spawn_object(DeathFx(self.pos.x, self.pos.y, tex, self.flip))
		-- if not noscore and self.score > 0 then
		self:spawn_object(ObjectScore(self.pos.x, self.pos.y, self.score))
		-- end
	end)
end

function Boss1:update(dt)
	self:ref_player()
end

function Boss1:change_state(state)
	if self.anim_coroutine then self.sequencer:stop(self.anim_coroutine) end
    Boss1.super.change_state(self, state)
end

function Boss1:explode_cart()
	self:change_state("PreFight")

	local s = self.sequencer
	s:start(function() 
        for i = 1, 60 do
            self.texture = floor(i/3) % 2 == 0 and sheet:get_frame(1) or textures.enemy_vendor_at_cart
			s:wait(1)
		end
	end)
	s:start(function() 
		s:wait(10)
		local fx = self:spawn_object(DeathFx(self.pos.x + 4, self.pos.y + 4, textures.enemy_cart))
		fx.flash = false
		-- fx.color_flash =
		self.world:play_sfx("enemy_cart_explosion")
		fx.size_mod = 1.0
		fx.duration = fx.duration * 2.0
		self.showing_cart = false
	end)
end

function Boss1:get_texture()
    return self.texture
end

function Boss1:phase1(sequence)

	if rng.coin_flip() then
		table.insert(sequence, "ShortHover")
	else
		table.insert(sequence, "Hover")
	end
	if (self.state_counter % 4 == 0) or rng.percent(5) and self.state_counter ~= 1 then 
		table.insert(sequence, "Throw2")
		if rng.percent(50) then
			table.insert(sequence, "Charge")
		end
	else
		if rng.percent(35) then
			table.insert(sequence, "Charge")
			if rng.coin_flip() then
				if rng.coin_flip() then
					-- table.insert(sequence, "Charge")
				else
					table.insert(sequence, "Throw1")
				end
			end
			while rng.percent(25) do
				table.insert(sequence, rng.choose("Throw1", "Charge"))
			end
		else
			table.insert(sequence, "Throw1")
			if rng.coin_flip() then
				table.insert(sequence, "Throw1")
			else
				table.insert(sequence, "Charge")
			end
			while rng.percent(25) do
				table.insert(sequence, rng.choose("Throw1", "Charge"))
			end
		end
	end
end

function Boss1:get_next_state()
	if table.is_empty(self.sequence) then
		local sequence = {}
		if self.phase == 1 then
			self:phase1(sequence)
		end
		self.sequence = sequence
	end
	-- table.pretty_print(self.sequence)
	self.state_counter = self.state_counter + 1


	local value = table.pop_front(self.sequence)
	if value ~= "Throw2" then
		self:spawn_birds()
	end
	return value
end

function Boss1:spawn_birds(one)
	if self.health > (self.max_health * 0.5) then return end
	local s = self.sequencer	
	s:start(function()
		s:wait(30)
		local middle = self.world.scroll_center
		local chance = min(100 * (1 - self.health / self.max_health), 90)
		for i=1,one and 1 or 3 do
			if rng.percent((i>1 and 50) or chance) then
				local ydir = rng.sign()
				local y = middle.y
				if self.player then	
					y = self.player.pos.y
				end
				y = y + 96 * ydir + (i-1) * 16 * -ydir
				y = clamp(y, middle.y - 96, middle.y + 80)
				local x = middle.x + 80 * rng.sign()
				local f = FlyerEnemy(x, y)

				f.ignore_despawn = true
				f.score = 0
				f.curve_amount = f.curve_amount * 1.5 * -ydir
				if self.player then
					local cx, cy = self:get_cell(x, y)
					local pcx, pcy = self.player:get_cell()
					if cx == pcx then
						f.curve_amount = 0
					end
				end
				self:spawn_object(f)
				s:wait(8)
			else
				break
			end
		end
	end)
end
function Boss1:draw()
	if self.dying and floor(self.tick / 2) % 2 == 0 then return end
	graphics.push()
    if self.state == "Idle" then
		graphics.translate(7, 0)
	end
    Boss1.super.draw(self)
	graphics.pop()
	if self.showing_cart then
		graphics.draw_centered(textures.enemy_cart, 4, 4)
	end
end

function Boss1:get_next_boss_state()

end

--------------------------------
--- States
--------------------------------
function Boss1:state_PreFight_enter()
    local s = self.sequencer
    self.anim_coroutine = s:start(
        function()
            s:wait(75)
            s:tween(function(y) self:move_to(self.pos.x, y) end, self.pos.y, self.pos.y - 32, 60)
            self:change_state(self:get_next_state())
            self.y_hover_zone = self.pos.y
            self.x_hover_zone = self.pos.x
        end
    )
end


function Boss1:state_Charge_enter()
	self.wiggle_tick = 0
	local s = self.sequencer
	self.anim_coroutine = s:start(function()
		self.world:play_sfx("enemy_knifecharge_anticipation")
        for i = 1, 25 do
            self.texture = floor(i / 2) % 2 == 0 and sheet:get_frame(2) or sheet:get_frame(3)
            s:wait(1)
			self:move(0, -0.25)
        end
		self.world:play_sfx("enemy_knifecharge")
		self.texture = sheet:get_frame(4)
        s:tween(function(y) self:move_to(self.pos.x, y) end, self.pos.y, self.pos.y + 256, 45)
		self:move_to(self.x_hover_zone, self.y_hover_zone)
        for i = 1, 10 do
            self.texture = floor(i / 2) % 2 == 0 and sheet:get_frame(1) or nil
            s:wait(1)
        end
		self.texture = sheet:get_frame(1)
		self:change_state(self:get_next_state())
	end)
end

function Boss1:state_Dying_enter()
	self.texture = sheet:get_frame(6)
end

function Boss1:state_Hover_enter()
	self.texture = sheet:get_frame(1)
    self.wiggle_counter = self.wiggle_counter + 1
	self.hover_time = 120
	self.wiggle_tick = self.wiggle_tick or 0
end

function Boss1:state_Hover_update(dt)

	local x_wiggle_speed = 2.5
	local y_wiggle_speed = x_wiggle_speed * 2.0
	local x_wiggle_amount = 64
	local y_wiggle_amount = 32
    local x_wiggle = frames_to_seconds(self.wiggle_tick) * x_wiggle_speed
	local y_wiggle = frames_to_seconds(self.wiggle_tick) * y_wiggle_speed
	self.wiggle_tick = self.wiggle_tick + dt
    local mod = (self.wiggle_counter % 2 == 0 and 1 or -1)
	-- print(mod)
	local tx, ty = self.x_hover_zone + sin(x_wiggle) * x_wiggle_amount * mod, self.y_hover_zone + sin(y_wiggle) * y_wiggle_amount * mod
	local x, y = vec2_approach(self.pos.x, self.pos.y, tx, ty, 2 * dt)
	-- print(tx, ty, x, y)
	self:move_to(x, y)
	
	if self.player and self.state_tick > self.hover_time then
        local cx, cy = self:get_cell()
		local pcx, pcy = self.player:get_cell()
		if cx == pcx then
			self:change_state(self:get_next_state())
		end
	end
end

function Boss1:state_ShortHover_enter()
	self:state_Hover_enter()
	self.hover_time = 30
end

function Boss1:state_ShortHover_update(dt) 
	self:state_Hover_update(dt)
end

function Boss1:state_Throw1_enter()
	local s = self.sequencer
	local player = self.player
	local throw_anim = function() 
		s:start(function()
			self.texture = sheet:get_frame(5)
			s:wait(5)
			self.texture = sheet:get_frame(2)
			s:wait(5)
			self.texture = sheet:get_frame(1)
		end)
	end
	s:start(function()
		self.texture = sheet:get_frame(1)
		s:wait(10)
		local dir = 1
		if player then 
			dir = player.pos.x < self.pos.x and -1 or 1
		end
		self:set_flip(-dir)
		throw_anim()
		s:wait(12)
		self:spawn_object(Boss1Knife(self.pos.x - 16 * dir, self.pos.y, 0.1 * -dir, 1))
		throw_anim()
		s:wait(12)
		self:spawn_object(Boss1Knife(self.pos.x, self.pos.y, 0.1 * dir, 1))
		throw_anim()
		s:wait(12)
		self:spawn_object(Boss1Knife(self.pos.x + 16 * dir, self.pos.y, 0.2 * dir, 1))
		throw_anim()
		s:wait(12)
		self:spawn_object(Boss1Knife(self.pos.x + 32 * dir, self.pos.y, 0.3 * dir, 1))
		s:wait(12)
		self:change_state(self:get_next_state())
	end)
end

function Boss1:state_Throw1_exit()
	self:set_flip(1)
end

function Boss1:state_Throw2_enter()
	local s = self.sequencer
	local player = self.player
	local throw_anim = function() 
		s:start(function()
			self.texture = sheet:get_frame(5)
			s:wait(5)
			self.texture = sheet:get_frame(2)
			s:wait(5)
			self.texture = sheet:get_frame(1)
		end)
	end
	s:start(function()
		self.texture = sheet:get_frame(1)
		s:wait(10)
		local dir = 1
		if player then 
			dir = player.pos.x < self.pos.x and -1 or 1
		end
		self:set_flip(-dir)
		
		local num = 4
		if rng.percent(50) then
			num = num + 4
		end

		for i=1, num do
			-- if (i + 1) % 2 == 0 then
			throw_anim()
			s:wait(18)
			-- end
			for j=-3, 3 do
				local knife = self:spawn_object(Boss1Knife(self.pos.x + j * dir * 40 + ((i % 3) * 40/3), self.pos.y, 0, 1))
				knife.speed = 2
			end
			if i == 6 then 
				self:spawn_birds(true)
			end
		end

		s:wait(20)
		self:change_state(self:get_next_state())
	end)
end

function Boss1:state_Throw2_exit()
	self:set_flip(1)
end

return Boss1
