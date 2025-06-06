local SwordSlash = GameObject2D:extend("SwordSlash")

local RADIUS = 32

local OFFSET = 30

local SPEED = 5
local DRAG = 0.4

local BASE_DAMAGE = 2.8

local PUSH_IMPULSE = 2.2

local NUM_HIT_BUBBLES = 16
local HIT_BUBBLE_SIZE = 7.5
local ARC_DEGREES = deg2rad(210)

function SwordSlash:new(x, y, direction, slash_direction)
	self.hit_cooldown = 90
    self.damage = BASE_DAMAGE

    if game_state.upgrades.damage then
        self.damage = self.damage + game_state.upgrades.damage * 0.5
    end


	self.offset = OFFSET
	
	if game_state.upgrades.range then
		self.offset = self.offset + game_state.upgrades.range * 5
	end

	self.speed = SPEED

	if game_state.upgrades.bullet_speed then
		self.speed = self.speed + game_state.upgrades.bullet_speed * 5
	end

	SwordSlash.super.new(self, x, y)
    self.direction = direction
	self.slash_direction = slash_direction
    self.z_index = 0.5
	self.team = "player"
    self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
    self.melee_attacking = true
	self.vel = Vec2(self.direction.x * self.speed, self.direction.y * self.speed)
end

-- function SwordSlash:get_damage(target)
    -- if target.is_enemy_bullet then
	-- 	return 999
	-- end
	-- return self.damage
-- end

function SwordSlash:get_death_particle_hit_velocity(target)
	return vec2_mul_scalar(self.direction.x, self.direction.y, 2)
end

function SwordSlash:hit_other(target, bubble)
    if target.apply_impulse and target.bullet_pushable then
		local impulse = PUSH_IMPULSE
        if target.bullet_push_modifier then
            impulse = impulse * target.bullet_push_modifier
        end
		if target.is_enemy_bullet then
			impulse = impulse * 2
		end
		
		impulse = impulse * (1 + game_state.upgrades.bullet_speed * 0.5) 

		target:apply_impulse(self.direction.x * impulse, self.direction.y * impulse)
	end

	self:play_sfx("player_sword_hit")
end

function SwordSlash:enter()
	self:play_sfx("player_sword_swing")
    self.hitbox_effects = {}

	for i = 1, NUM_HIT_BUBBLES do
        local offset = i - (NUM_HIT_BUBBLES + 1) / 2
        local angle = ARC_DEGREES * offset / NUM_HIT_BUBBLES + self.direction:angle()

        local bubble_x, bubble_y = vec2_from_polar(RADIUS, angle)
        local offset_x, offset_y = vec2_from_polar(self.offset, self.direction:angle())
		bubble_x = bubble_x + offset_x
		bubble_y = bubble_y + offset_y
        local bubble = self:add_hit_bubble(0, 0, HIT_BUBBLE_SIZE, "main" .. i, self.damage, bubble_x, bubble_y)
        local effect =
        {
			visible = false,
            bubble = bubble,
            t = 0,
			t2 = 0,
			show_smoke = false,
        }
		self.hitbox_effects[i] = effect
		local s = self.sequencer
        s:start(function()
			local divisor = 4
            local wait_time_offset = idiv(i, divisor)
            if self.slash_direction == 1 then
                wait_time_offset = idiv(NUM_HIT_BUBBLES - i, divisor)
            end
			
			s:wait(1 * wait_time_offset)
            effect.visible = true
            s:start(function()
				s:wait(2)
				effect.show_smoke = true
                s:tween_property(effect, "t2", 0, 1, 15, "linear")
				effect.show_smoke = false
            end)
			effect.show_pole = true
			s:start(function()
				s:wait(1)
				effect.show_pole = false
            end)
            s:tween_property(effect, "t", 0, 1, 60, "linear")
		end)
    end

    self:start_tick_timer("stop_attacking", 3, function()
        self.melee_attacking = false
	end)
    self:start_destroy_timer(120)
end

function SwordSlash:update(dt)
    self:move(self.vel.x * dt, self.vel.y * dt)
	self.vel.x, self.vel.y = vec2_drag(self.vel.x, self.vel.y, DRAG, dt)
end

function SwordSlash:floor_draw()
    if self.is_new_tick and self.tick >= 3 and self.tick <= 6 then
		graphics.set_color(Color.darkpurple)
        local points = {}
        local res = 3
		local offset = 5
        local start = self.slash_direction == 1 and offset or 1

		local finish = self.slash_direction == 1 and NUM_HIT_BUBBLES or NUM_HIT_BUBBLES - offset
        for i = start, finish, res do
            local effect = self.hitbox_effects[i]
            local bubble = effect.bubble
            local x, y = self:to_local(bubble:get_end_position())
            table.insert(points, x)
			table.insert(points, y)
        end
		graphics.line(points)
    end
end

function SwordSlash:draw()

	for i = 1, NUM_HIT_BUBBLES do
		local effect = self.hitbox_effects[i]

        local bubble = effect.bubble
		graphics.set_color(Color.white)
        local x, y = self:to_local(bubble:get_end_position())
		local scale_t = remap_clamp(effect.t, 0, 0.1, 0, 1)

		local damage_scale = 1 + (self.damage - BASE_DAMAGE) * 0.5

        local scale = 3
        if effect.visible then

            local scale2 = HIT_BUBBLE_SIZE * 2 * (1 - ease("outCubic")(scale_t)) * damage_scale
			-- graphics.set_color(Palette.rainbow:tick_color(gametime.tick, 0, 2))
			graphics.set_color(Color.purple)

			local num_rects = 5
			local distance = math.bump(i / NUM_HIT_BUBBLES) * 12
			for j=1, num_rects do
				local ratio = j / num_rects
				local x2, y2 = lerp(x, x - self.direction.x * distance, ratio), lerp(y, y - self.direction.y * distance, ratio)
                local scale3 = lerp(scale2, scale2 * (1 - ratio), 0.185)
                graphics.push()
                graphics.translate(x2, y2)
				-- graphics.rotate(tau / 8)
                graphics.rectangle_centered("fill", 0, 0, scale3, scale3)
				graphics.pop()
			end
			graphics.set_color(Color.white)

			graphics.rectangle_centered("fill", x, y, scale2, scale2)

        else
			graphics.set_color(Color.purple)

			graphics.rectangle_centered("fill", x, y, scale, scale)
		end

        if effect.show_smoke then
			scale = HIT_BUBBLE_SIZE * 1 * (1 - (effect.t2))
			graphics.set_color(Color.magenta)
			graphics.rectangle_centered("line", x, y - effect.t2 * 10, scale * damage_scale, scale * damage_scale)
		end
	end
end


return SwordSlash
