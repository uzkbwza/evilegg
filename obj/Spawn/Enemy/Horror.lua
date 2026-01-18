local Horror = BaseEnemy:extend("Horror")
local HorrorTentacle = BaseEnemy:extend("HorrorTentacle")

local MAX_TENTACLE_DEPTH = 16
local SLOW_AFTER_DEPTH = 6
local TENTACLE_GROW_FREQ = 5
local SLOW_TENTACLE_GROW_FREQ = 20
local MAX_TENTACLE_ANGLE = deg2rad(70)

-- Glitch effect parameters
local GLITCH_STRIP_HEIGHT = 3
local GLITCH_PERIOD = 2
local GLITCH_MAX_OFFSET = 3

-- Visibility/fade-in parameters (distance outside stage bounds)
local HORROR_INVISIBLE_DISTANCE = 7  -- Don't draw if further than this outside stage
local HORROR_FADE_DISTANCE = 1  -- Use fade palette if between this and invisible distance
local HORROR_FADE_RANDOM_RANGE = 0    -- Random offset applied to fade distances per entity

-- Cache for horizontal strip quads (lazy initialized)
local glitch_strip_cache = {}

local function get_glitch_strips(texture)
    if glitch_strip_cache[texture] then
        return glitch_strip_cache[texture]
    end
    
    local data = graphics.texture_data[texture]
    local width = data:getWidth()
    local height = data:getHeight()
    
    local strips = {}
    local y = 0
    while y < height do
        local strip_height = min(GLITCH_STRIP_HEIGHT, height - y)
        local quad = love.graphics.newQuad(0, y, width, strip_height, width, height)
        table.insert(strips, {
            quad = quad,
            y = y,
            width = width,
            height = strip_height,
        })
        y = y + GLITCH_STRIP_HEIGHT
    end
    
    glitch_strip_cache[texture] = strips
    return strips
end

-- Returns positive distance if outside stage, 0 or negative if inside
local function get_distance_from_stage(self)
    local room = self.world.room
    local half_w = room.room_width / 2
    local half_h = room.room_height / 2
    -- Calculate how far outside the bounds the entity is
    local dx = max(abs(self.pos.x) - half_w, 0)
    local dy = max(abs(self.pos.y) - half_h, 0)
    return vec2_magnitude(dx, dy)
end

-- Returns "normal", "fade", or nil (don't draw)
local function get_draw_state(self)
    -- Once entered stage, always draw normally (don't fade back out)
    if self.has_entered_stage then
        return "normal"
    end
    
    local dist = get_distance_from_stage(self)
    local fade_offset = self.fade_distance_offset or 0
    if dist > HORROR_INVISIBLE_DISTANCE + fade_offset then
        return nil
    elseif dist > HORROR_FADE_DISTANCE + fade_offset then
        return "fade"
    else
        return "normal"
    end
end

local function get_palette(self)
    -- Check if fading in due to distance from stage
    local draw_state = get_draw_state(self)
    if draw_state == "fade" then
        return Palette.horror_fade_in, 0
    end
    
    if self.tick <= 3 then 
        return Palette.white, 0
    end
    if iflicker(self.tick + self.random_offset * 3, 6, 2) or iflicker(self.tick + self.random_offset * 3, 4, 3) then
        return nil, idiv(self.tick + self.random_offset, 5)
    end
    return nil, 0
end

Horror.get_palette = get_palette
HorrorTentacle.get_palette = get_palette
Horror.max_hp = 16
Horror.spawn_cry = "enemy_horror_spawn"
Horror.spawn_cry_volume = 0.8
Horror.death_cry = "enemy_horror_die"
Horror.death_cry_volume = 0.8
HorrorTentacle.death_sfx = "enemy_horror_tentacle_death"
-- HorrorTentacle.spawn_sfx = "enemy_horror_grow_tentacle"
-- HorrorTentacle.spawn_sfx_volume = 0.6
HorrorTentacle.death_sfx_volume = 0.6

local function glitch_draw_sprite(self)
	local palette, palette_index = self:get_palette_shared()
	local h_flip, v_flip = self:get_sprite_flip()
	local texture = self:get_sprite()
	local strips = get_glitch_strips(texture)
	
	-- Get palettized texture and set up shader
	local auto_palette = graphics._auto_palette(texture, palette, palette_index)
	local palettized_texture = graphics.palettized[texture]
	
	if auto_palette then
		graphics.set_shader(auto_palette:get_shader(palette_index))
	end
	
	local irng = self.irng
	irng:set_seed(idiv(self.world.timescaled.tick + self.random_offset, GLITCH_PERIOD) + self.random_offset)
	
	local tex_width = strips[1].width
	local data = graphics.texture_data[texture]
	local tex_height = data:getHeight()
	local center_x = tex_width / 2
	local center_y = tex_height / 2
	
	local sx = h_flip
	local sy = v_flip
	
	local draw_texture = auto_palette and palettized_texture or texture
	
	for _, strip in ipairs(strips) do
		local glitch_offset = irng:randi(-GLITCH_MAX_OFFSET, GLITCH_MAX_OFFSET)
		-- Draw at glitch offset, using origin to center sprite at (0,0) and enable proper flipping
		-- Origin is relative to the quad's local coordinates (0,0 to width,height)
		-- To center the full sprite, origin.x = center of texture, origin.y = distance from quad top to texture center
		local ox = center_x
		local oy = center_y - strip.y
		
		love.graphics.draw(draw_texture, strip.quad, glitch_offset, 0, 0, sx, sy, ox, oy)
	end
	
	if auto_palette then
		graphics.set_shader()
	end
end

Horror.draw_sprite = glitch_draw_sprite
HorrorTentacle.draw_sprite = glitch_draw_sprite

-- Override draw to skip when too far from stage
function Horror:draw()
    if not get_draw_state(self) then
        return
    end
    Horror.super.draw(self)
end

function HorrorTentacle:draw()
    if not get_draw_state(self) then
        return
    end
    HorrorTentacle.super.draw(self)
end

function Horror:new(x, y)
    self.hurt_bubble_radius = 12
    self.wall_bounce_modifier = 0.25
    self.hit_bubble_radius = 7
    self.body_height = 0
    self.irng = rng:new_instance()
    Horror.super.new(self, x, y)
    self.offset_angle = rng:random_angle()
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    -- Start with no bullet push until fully inside stage
    self.bullet_push_modifier = 0
    self.entering_stage = true
    self.drag = 0.01
    self.angle_vel = 0
    self.angle_vel_dir = rng:rand_sign()
    self.rotate_angle = 0
    self:ref_bongle("tentacles")
    self.on_terrain_collision = self.terrain_collision_bounce
    -- Random offset for fade distance to prevent uniform appearance
    self.fade_distance_offset = rng:randf(-HORROR_FADE_RANDOM_RANGE, HORROR_FADE_RANDOM_RANGE)
end

function Horror:is_within_bounds()
    local room = self.world.room
    local half_w = room.room_width / 2
    local half_h = room.room_height / 2
    -- Account for terrain collision radius so entity smoothly slides in
    local margin = self.terrain_collision_radius or 0
    return self.pos.x >= -half_w + margin and self.pos.x <= half_w - margin and
           self.pos.y >= -half_h + margin and self.pos.y <= half_h - margin
end

function Horror:are_all_parts_within_bounds()
    if not self:is_within_bounds() then
        return false
    end
    for _, tentacle in self.tentacles:ipairs() do
        if not tentacle:are_all_parts_within_bounds() then
            return false
        end
    end
    return true
end

function Horror:on_entered_stage()
    self.entering_stage = false
    self.has_entered_stage = true
    self.bullet_push_modifier = 0.2
    -- Propagate to all tentacles recursively
    for _, tentacle in self.tentacles:ipairs() do
        tentacle:on_entered_stage()
    end
end

function Horror:on_left_stage()
    self.entering_stage = true
    self.bullet_push_modifier = 0
    -- Propagate to all tentacles recursively
    for _, tentacle in self.tentacles:ipairs() do
        tentacle:on_left_stage()
    end
end

function Horror:collide_with_terrain()
    -- Collide with terrain as soon as this body is within bounds
    if not self:is_within_bounds() then
        return
    end
    self:constrain_to_room()
end

function Horror:get_tentacle_angle()
    -- if self:is_tick_timer_running("move_time") then
    --     return 0
    -- end
    return self.rotate_angle
end

function Horror:enter()

end

function Horror:life_flash()
    -- No life flash effect for Horror since it spawns outside the stage
end

function Horror:damage(amount)
    -- if amount < 10 then
    amount = min(amount, 5)
    -- end
    Mixins.Behavior.Health.damage(self, amount)
end


function Horror:spawn_tentacle(angle, dist_from_parent, is_respawn)
    local tentacle = self:spawn_object(HorrorTentacle(self.pos.x, self.pos.y, self, angle, 14))
    if is_respawn then
        tentacle.grown_one = true
    end
    self:ref_bongle_push("tentacles", tentacle)
    signal.connect(tentacle, "died", self, "on_tentacle_died", function() 
        local s = self.sequencer
        s:start(function() 
            s:wait(33)
            self:spawn_tentacle(angle, dist_from_parent, true)
        end)
    end)
end

function Horror:update(dt)
    if self.tick == 20 and self.is_new_tick then 
        local num_tentacles = 5
        for i=1, num_tentacles do 
            local angle = self.offset_angle + tau * ((i) / (num_tentacles))
            self:spawn_tentacle(angle, 11)
        end
    end

    -- Check if Horror body has entered the stage
    if self.entering_stage and self.is_new_tick and self.tick > 30 then
        if self:is_within_bounds() then
            self:on_entered_stage()
        end
    end
    
    -- If somehow got pushed back outside, re-enter entering mode
    if not self.entering_stage and not self:is_within_bounds() then
        self:on_left_stage()
    end

    self:play_sfx_if_stopped("enemy_horror_loop", 0.45, 1, true)

    -- When entering stage, move toward center more aggressively
    bx, by = vec2_normalized(self:to_local(self:closest_last_player_body_pos()))
    if self.entering_stage then
        -- Move toward center of stage
        local enter_speed = 0.017
        self:apply_force(bx * enter_speed, by * enter_speed)
        
        -- Dampen velocity if moving away from center
        local to_center_x, to_center_y = vec2_normalized(-self.pos.x, -self.pos.y)
        local vel_dot_center = self.vel.x * to_center_x + self.vel.y * to_center_y
        if vel_dot_center < 0 then
            -- Moving away from center, heavily dampen
            self.vel.x, self.vel.y = vec2_drag(self.vel.x, self.vel.y, 0.5, dt)
        end
    else
        if self.is_new_tick and not self:is_tick_timer_running("move_cooldown") and rng:percent(2) then
            local move_time = rng:randi(28, 150)
            self:play_sfx("enemy_horror_move", 0.5)
            self:start_tick_timer("move_time", move_time)
            self:start_tick_timer("move_cooldown", move_time * (rng:randf(1.25, 2.75)))
        end
        if self:is_tick_timer_running("move_time") then
            local speed = 0.017
            self:apply_force(bx * speed, by * speed)
        end
        local speed = 0.002
        self:apply_force(bx * speed, by * speed)
    end

    self.angle_vel = self.angle_vel + dt * 0.015 * self.angle_vel_dir

    self.angle_vel = clamp(self.angle_vel, -1, 1)

    if self.is_new_tick and rng:percent(0.7) then 
        self.angle_vel_dir = self.angle_vel_dir * -1
    end

    self.rotate_angle = self.rotate_angle + dt * 0.005 * self.angle_vel
    -- print(self.rotate_angle)

    -- local maxdiff = deg2rad(40)
    -- for i, tentacle in self.tentacles:ipairs() do
    --     local angle = vec2_angle(bx, by)
    --     if angle_diff(angle, tentacle.angle) > maxdiff then
    --         angle = clamp(angle, tentacle.angle - maxdiff, tentacle.angle + maxdiff)
    --     end
    --     tentacle.angle = approach_angle(tentacle.angle, self:is_tick_timer_running("move_time") and angle + tentacle.chase_offset - self.rotate_angle or tentacle.initial_angle, dt * 0.025)
    -- end
end

function Horror:exit()
    self:stop_sfx("enemy_horror_loop")
end

function Horror:get_sprite()
    return (iflicker(self.tick + self.random_offset, 7, 11) or iflicker(self.tick + self.random_offset, 2, 40) or iflicker(self.tick + self.random_offset + 5, 2, 40)) and textures.enemy_horror2 or textures.enemy_horror1
end

function Horror:floor_draw()
    if not get_draw_state(self) then
        return
    end
    if self.is_new_tick then 
        for i=1, 30 do 
            local size = rng:randi(2, 15)
            local offx, offy = rng:random_vec2_times(rng:randf(0, size * 2))
            local length = vec2_magnitude_squared(offx, offy)
            local amount = remap(length, 0, size * size * 4, 1, 0)
            graphics.set_color(pow(amount, 2) * 0.25, 0, amount * 0.15)

            graphics.square_centered("fill", offx, offy, rng:randi(1, 5))
        end
    end
end

function HorrorTentacle:floor_draw()
    if not get_draw_state(self) then
        return
    end
    if self.is_new_tick then 
        for i=1, 3 do
            if rng:percent((MAX_TENTACLE_DEPTH - self.depth) * 2) then
            local size = rng:randi(2, 5)
            local offx, offy = rng:random_vec2_times(rng:randf(0, size * 2))
            local length = vec2_magnitude_squared(offx, offy)
            local amount = remap(length, 0, size * size * 4, 1, 0)
            graphics.set_color(pow(amount, 2) * 0.25, 0, amount * 0.15)

            graphics.square_centered("fill", offx, offy, rng:randi(1, 5))
            end
        end
    end
end



function HorrorTentacle:new(x, y, parent, angle, dist_from_parent, depth)
    self.initial_angle = angle
    self.chase_offset = deg2rad(rng:randf(-45, 45))
    self.depth = depth or 1
    self.dist_from_parent = dist_from_parent
    self.big = self.depth < 4
    self.irng = rng:new_instance()
    self.max_hp = self.big and 4 or 2
    self.hit_bubble_radius = self.big and 4 or 2
    self.hurt_bubble_radius = self.big and 5 or 3
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
    self:lazy_mixin(Mixins.Behavior.BulletPushable)
    self.bullet_push_modifier = self.big and 3.545 or 5.0
    self.center_angle = angle
    self.angle = angle + rng:randf(-MAX_TENTACLE_ANGLE/2, MAX_TENTACLE_ANGLE/2)
    HorrorTentacle.super.new(self,  x, y)
    self:ref("parent", parent)
    self:follow_parent()
    -- Inherit entering_stage state from parent
    if parent and parent.entering_stage then
        self.entering_stage = true
    end
    -- Random offset for fade distance to prevent uniform appearance
    self.fade_distance_offset = rng:randf(-HORROR_FADE_RANDOM_RANGE, HORROR_FADE_RANDOM_RANGE)
end


function HorrorTentacle:is_within_bounds()
    local room = self.world.room
    local half_w = room.room_width / 2
    local half_h = room.room_height / 2
    -- Account for terrain collision radius so entity smoothly slides in
    local margin = self.terrain_collision_radius or 0
    return self.pos.x >= -half_w + margin and self.pos.x <= half_w - margin and
           self.pos.y >= -half_h + margin and self.pos.y <= half_h - margin
end

function HorrorTentacle:are_all_parts_within_bounds()
    if not self:is_within_bounds() then
        return false
    end
    if self.child and not self.child:are_all_parts_within_bounds() then
        return false
    end
    return true
end

function HorrorTentacle:on_entered_stage()
    self.entering_stage = false
    self.has_entered_stage = true
    if self.child then
        self.child:on_entered_stage()
    end
end

function HorrorTentacle:on_left_stage()
    self.entering_stage = true
    if self.child then
        self.child:on_left_stage()
    end
end

function HorrorTentacle:collide_with_terrain()
    -- Collide with terrain as soon as this tentacle is within bounds
    if not self:is_within_bounds() then
        return
    end
    self:constrain_to_room()
end

function HorrorTentacle:damage(amount)
    if self.depth < 2 then
        amount = min(amount, 2)
    end
    Mixins.Behavior.Health.damage(self, amount)
end


function HorrorTentacle:follow_parent(dt)
    local parent = self.parent
    if parent then 
        local offsx, offsy = vec2_from_polar(self.dist_from_parent, self:get_tentacle_angle())
        -- local bx, by = self.parent:get_body_center()
        local bx, by = self.parent.pos.x, self.parent.pos.y
        if dt then 
            self:move_to(splerp_vec(self.pos.x, self.pos.y, bx + offsx, by + offsy, 70, dt))
            -- self:move_to(vec2_approach(self.pos.x, self.pos.y, bx + offsx, by + offsy, dt * lerp(2, 0.95, inverse_lerp_clamp(1, MAX_TENTACLE_DEPTH, self.depth))))
        else
            self:move_to(bx + offsx, by + offsy)
        end
    else
        if not self:get_stopwatch("parent_died") then
            self:start_stopwatch("parent_died")
        elseif self:get_stopwatch("parent_died").tick > 2 then
            self:die()
        end
    end
end


function HorrorTentacle:get_sprite()
    local s1, s2
    if self.big then 
        s1 = textures.enemy_horror_bigtentacle1
        s2 = textures.enemy_horror_bigtentacle2
    else
        s1 = textures.enemy_horror_smalltentacle1
        s2 = textures.enemy_horror_smalltentacle2
    end

    if iflicker(self.tick + self.random_offset, 2, 10) then
        return s2
    else
        return s1
    end
end

function HorrorTentacle:get_tentacle_angle()
    local angle = self.angle
    if self.parent and self.parent.get_tentacle_angle then
        self.last_tentacle_angle = self.parent:get_tentacle_angle()
        angle = angle + self.last_tentacle_angle
    elseif self.last_tentacle_angle then
        angle = angle + self.last_tentacle_angle
    end
    return angle
end

function HorrorTentacle:update(dt)
    if self.is_new_tick then
        
        if not self.moving_to_angle then
            if rng:percent(15) then
                self.moving_to_angle = self.center_angle + rng:randf(-MAX_TENTACLE_ANGLE/2, MAX_TENTACLE_ANGLE/2)
            end
        end

        local grow_freq = self.grown_one and SLOW_TENTACLE_GROW_FREQ or TENTACLE_GROW_FREQ
        if self.depth >= SLOW_AFTER_DEPTH then
            grow_freq = SLOW_TENTACLE_GROW_FREQ * 2
        end
        if (self.tick % grow_freq == 0) and self.tick >= grow_freq and not self.child and self.depth <= MAX_TENTACLE_DEPTH and rng:percent(75) then 
            self:spawn_child()
        end
    end

    if self.moving_to_angle then
        local old_angle = self.angle
        self.angle = approach_angle(self.angle, self.moving_to_angle, dt * 0.006)
        if old_angle == self.angle then 
            self.moving_to_angle = false
        end
    end
    
    self:follow_parent(dt)
end

function HorrorTentacle:spawn_child()
    local grown_one = self.grown_one
    self:defer(function()
        self:ref("child", self.world:add_object(HorrorTentacle(self.pos.x, self.pos.y, self, 0, self.big and 10 or 7, self.depth + 1)))
        self.child.grown_one = grown_one
    end)
    self.grown_one = true
end

function HorrorTentacle:die(...)
    HorrorTentacle.super.die(self, ...)
end

-- Tentacle spawn particle effect
local TentacleSpawnParticle = GameObject2D:extend("TentacleSpawnParticle")

local TENTACLE_PARTICLE_COUNT = 10
local TENTACLE_PARTICLE_FLOAT_SPEED = 0.3
local TENTACLE_PARTICLE_WHITE_CHANCE = 15

function TentacleSpawnParticle:new(x, y, texture, use_fade_palette)
    TentacleSpawnParticle.super.new(self, x, y)
    self:add_elapsed_ticks()
    self.z_index = 0.1
    self.particles = batch_remove_list()
    self.use_fade_palette = use_fade_palette
    
    -- Get texture data for pixel sampling
    local data = graphics.texture_data[texture]
    local width = data:getWidth()
    local height = data:getHeight()
    self.width = width
    self.height = height
    -- Collect all non-black pixels
    local valid_pixels = {}
    for py = 0, height - 1 do
        for px = 0, width - 1 do
            local r, g, b, a = data:getPixel(px, py)
            -- Skip transparent and very dark pixels
            if a > 0 and (r > 0.1 or g > 0.1 or b > 0.1) then
                table.insert(valid_pixels, {
                    x = px - width / 2,
                    y = py - height / 2,
                    r = r,
                    g = g,
                    b = b,
                })
            end
        end
    end
    
    -- Spawn random particles from valid pixels
    local count = min(TENTACLE_PARTICLE_COUNT, #valid_pixels)
    for i = 1, count do
        if #valid_pixels == 0 then break end
        local idx = rng:randi(1, #valid_pixels)
        local pixel = valid_pixels[idx]
        table.remove(valid_pixels, idx)
        
        local is_white = rng:percent(TENTACLE_PARTICLE_WHITE_CHANCE)
        
        local particle = {
            x = pixel.x + rng:randf(-0.5, 0.5),
            y = pixel.y + rng:randf(-0.5, 0.5),
            r = is_white and 1 or pixel.r,
            g = is_white and 1 or pixel.g,
            b = is_white and 1 or pixel.b,
            lifetime = rng:randf(5, 15),
            t = 0,
        }
        self.particles:push(particle)
    end
end

function TentacleSpawnParticle:update(dt)
    for _, particle in self.particles:ipairs() do
        particle.t = particle.t + dt
        particle.y = particle.y - TENTACLE_PARTICLE_FLOAT_SPEED * dt
        
        if particle.t >= particle.lifetime then
            self.particles:queue_remove(particle)
        end
    end
    
    self.particles:apply_removals()
    
    if self.particles:is_empty() then
        self:queue_destroy()
    end
end

function TentacleSpawnParticle:draw()
    local t = (self.tick / 4)
    local palette = self.use_fade_palette and Palette.horror_tent_particle_fade_in or Palette.horror_tent_particle
    local color = palette:interpolate_clamped(t)
    if t <= 1 then
        t = ease("outQuad")(t)
        graphics.set_color(color)
        local extra = 0.5 + t * 0.5
        graphics.rectangle_centered("line", 0, 0, self.width * extra, self.height * extra)
    end
    for _, particle in self.particles:ipairs() do
        graphics.set_color(particle.r, particle.g, particle.b)
        graphics.points(particle.x, particle.y)
    end
end

function HorrorTentacle:enter()
    local texture = self:get_sprite()
    local draw_state = get_draw_state(self)
    -- Don't spawn particles if invisible, use fade palette if in transition
    if draw_state then
        local use_fade = draw_state == "fade"
        self:spawn_object(TentacleSpawnParticle(self.pos.x, self.pos.y, texture, use_fade))
    end
    if not self.entering_stage or get_draw_state(self) == "normal" then 
       self:play_sfx("enemy_horror_grow_tentacle", 0.6)
    end
end

return Horror
