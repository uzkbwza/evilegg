local SwordSlash = GameObject2D:extend("SwordSlash")

local RADIUS = 32

local OFFSET = 30

local SPEED = 5
local DRAG = 0.4

local BASE_DAMAGE = 2.5

local PUSH_IMPULSE = 2.2

local NUM_HIT_BUBBLES = 16
local HIT_BUBBLE_SIZE = 7.5
local ARC_DEGREES = deg2rad(210)


SwordSlash.reset_death_particle_hit_velocity = true
SwordSlash.center_out_velocity_multiplier = 1.0

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

function SwordSlash:get_death_particle_hit_velocity(target)
	return vec2_mul_scalar(self.direction.x, self.direction.y, 20)
end

function SwordSlash:get_death_particle_hit_point(other)
    -- Find overlap center between one of our capsule hitboxes and one of the other's hurtboxes.
    local obx, oby = other.pos.x, other.pos.y
    if other.get_body_center then
        obx, oby = other:get_body_center()
    end

    local best_x, best_y

    if self.bubbles and self.bubbles.hit and other.bubbles and other.bubbles.hurt then
        for _, bubble in pairs(self.bubbles.hit) do
            if bubble.shape_type == "capsule" then
                local sx, sy = bubble:get_position()
                local ex, ey = bubble:get_end_position()
                local sr = bubble.radius

                for _, hurt in pairs(other.bubbles.hurt) do
                    local hx, hy
                    if hurt.shape_type == "circle" then
                        local cx, cy = hurt:get_position()
                        local cr = hurt.radius
                        if circle_capsule_collision(cx, cy, cr, sx, sy, ex, ey, sr) then
                            hx, hy = capsule_circle_overlap_center(sx, sy, ex, ey, sr, cx, cy, cr)
                        end
                    elseif hurt.shape_type == "capsule" then
                        local cx, cy = hurt:get_position()
                        local dx_, dy_ = hurt:get_end_position()
                        local cr = hurt.radius
                        if capsule_capsule_collision(sx, sy, ex, ey, sr, cx, cy, dx_, dy_, cr) then
                            hx, hy = capsule_capsule_overlap_center(sx, sy, ex, ey, sr, cx, cy, dx_, dy_, cr)
                        end
                    elseif hurt.shape_type == "aabb" then
                        -- Fallback approximation: midpoint between capsule segment and AABB center
                        local rx, ry, rw, rh = hurt:get_rect()
                        local rcx, rcy = rx + rw * 0.5, ry + rh * 0.5
                        local qx, qy = closest_point_on_line_segment(rcx, rcy, sx, sy, ex, ey)
                        hx, hy = (qx + rcx) * 0.5, (qy + rcy) * 0.5
                    end

                    if hx then
                        best_x, best_y = hx, hy
                        break
                    end
                end
            end

            if best_x then break end
        end
    end

    if best_x then
        -- Convert to local space of other's body center
        return best_x, best_y
    end

    -- Fallback: direction away from sword towards target body center, clamped
    local diff_x, diff_y = vec2_sub(obx, oby, self.pos.x, self.pos.y)
    local lx, ly = vec2_limit_length(-diff_x, -diff_y, 16)
    return lx + obx, ly + oby
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
