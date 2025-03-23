local TwinStickEntity = Object:extend("TwinStickEntity")
local CollisionBubble = require "obj.collision_bubble" -- the generic bubble class
local HitBubble = require "obj.hit_bubble"

function TwinStickEntity:__mix_init()
    self.terrain_collision_radius = self.terrain_collision_radius or 4
    self.body_height = self.body_height or 0
    self.aim_direction = Vec2(1, 0)
    self.aim_radius = self.aim_radius or 10
    self.team = self.team or "enemy"
	self.hitbox_team = self.hitbox_team or self.team
    self.shadow_radius = self.shadow_radius or 1
    self:add_elapsed_time()
	self:add_elapsed_ticks()
	self:add_sequencer()

    -- Set up main bubble-tables (both 'hurt' and 'hit')
    self.bubbles = {
        hurt = {},
        hit  = {}
    }

    -- We’ll store a parallel set of bubble grids as well
    -- (assuming your world has separate grids for hurt vs hit).
    self.bubbles_grid = {
        hurt = nil,  -- we'll assign these when we enter the world
        hit  = nil
    }

    -- When destroyed, clear all bubbles.
    self:add_exit_function(self.clear_all_bubbles)

    -- When we move, update both sets of bubbles.
    self:add_move_function(self.update_all_bubbles_on_move)

	self:add_update_function(self.check_melee_attack)

    -- Overwrite enter_shared to also set up grids.
	
    self:add_enter_function(self.twinstick_enter)

    -- Overwrite debug_draw to also show bubble debug
    local old_debug_draw = self.debug_draw or self.dummy
    self.debug_draw = function(self)
        old_debug_draw(self)
        self:twin_stick_debug_draw()
    end

    if self.melee_attacking == nil then
        self.melee_attacking = true
    end
    if self.intangible == nil then
        self.intangible = false
    end
	if self:has_signal("flipped") then
		signal.connect(self, "flipped", self, "on_flipped")
	end
end

-----------------------------------------------------------------------------
--  Shared CollisionBubble Helpers
-----------------------------------------------------------------------------
-- Each helper below takes a 'bubble_type' which is either "hurt" or "hit".

-- Adds a bubble of type 'bubble_type'.
-- Example usage: self:add_bubble("hurt", 0, 0, 8, "head")
--               self:add_bubble("hit", 10, 10, 5, "punch_zone")

function TwinStickEntity:get_bubble(bubble_type, name)
	local bubble_list = self.bubbles[bubble_type]
	if not bubble_list then
		error("Unknown bubble type: " .. tostring(bubble_type))
	end
	return bubble_list[name]
end

function TwinStickEntity:add_bubble(bubble_type, x, y, radius, name, x2, y2, ...)
    local bubble_list = self.bubbles[bubble_type]
    if not bubble_list then
        error("Unknown bubble type: " .. tostring(bubble_type))
    end

    if name == nil then
        -- auto-generate a numeric name if not provided
        name = #bubble_list + 1
    end

    if bubble_list[name] then
        error(bubble_type .. " bubble already exists: " .. tostring(name))
    end

    radius = radius or 8

    local px, py = self:get_body_center()

    local b

    if bubble_type == "hit" then
        b = HitBubble(self, x, y, px, py, radius, x2, y2, ...)
    else
        b = CollisionBubble(self, x, y, px, py, radius, x2, y2)
    end

    bubble_list[name] = b

    -- Add to the correct grid
    local grid = self.bubbles_grid[bubble_type]
    if grid then
        local bx, by, w, h = b:get_rect()
        grid:add(b, bx, by, w, h)
    end
end

function TwinStickEntity:remove_bubble(bubble_type, name)
    local bubble_list = self.bubbles[bubble_type]
    local bubble = bubble_list and bubble_list[name]
    if bubble then
        bubble_list[name] = nil
        local grid = self.bubbles_grid[bubble_type]
        if grid then
            grid:remove(bubble)
        end
    end
end

-- Clears all bubbles of the given type
function TwinStickEntity:clear_bubbles(bubble_type)
    local bubble_list = self.bubbles[bubble_type]
    if not bubble_list then return end

    local names = {}
    for name, _ in pairs(bubble_list) do
        names[#names + 1] = name
    end
    for _, name in ipairs(names) do
        self:remove_bubble(bubble_type, name)
    end
end

-- Clears *all* bubbles (both hurt and hit).
function TwinStickEntity:clear_all_bubbles()
    self:clear_bubbles("hurt")
    self:clear_bubbles("hit")
end

-- Called whenever we move; it updates positions in the grid.
function TwinStickEntity:update_all_bubbles_on_move()
    self:update_bubbles_on_move("hurt")
    self:update_bubbles_on_move("hit")
end

function TwinStickEntity:update_bubbles_on_move(bubble_type)
    local bubble_list = self.bubbles[bubble_type]
    if not bubble_list then return end

    for _, bubble in pairs(bubble_list) do
        local px, py = self:get_body_center()
        bubble:set_parent_position(px, py)
        self:on_bubble_updated(bubble_type, bubble)
    end
end

-- Called after bubble changes, re-inserts in the grid
function TwinStickEntity:on_bubble_updated(bubble_type, bubble)
    local grid = self.bubbles_grid[bubble_type]
    if grid then
        grid:update(bubble, bubble:get_rect())
    end
end

-- Sets bubble radius
function TwinStickEntity:set_bubble_radius(bubble_type, name, radius)
    -- if not self.bubbles[bubble_type] or not self.bubbles[bubble_type][name] then
	-- 	error("Unknown bubble: " .. tostring(bubble_type) .. " " .. tostring(name))
	-- 	return
	-- end
    local bubble = self.bubbles[bubble_type] and self.bubbles[bubble_type][name]
    if not bubble then return end
    bubble:set_radius(radius)
    self:on_bubble_updated(bubble_type, bubble)
end

-- Sets bubble offset position
function TwinStickEntity:set_bubble_position(bubble_type, name, x, y)
    local bubble = self.bubbles[bubble_type] and self.bubbles[bubble_type][name]
    if not bubble then return end
    bubble:set_position(x, y)
    self:on_bubble_updated(bubble_type, bubble)
end

function TwinStickEntity:set_bubble_capsule_end_points(bubble_type, name, x2, y2)
    local bubble = self.bubbles[bubble_type] and self.bubbles[bubble_type][name]
    if not bubble then return end
    bubble:set_capsule_end_points(x2, y2)
    self:on_bubble_updated(bubble_type, bubble)
end

function TwinStickEntity:each_nearby_bubble(bubble_type, bubble_team, radius, fn)
    local bx, by = self:get_body_center()
    local x, y, w, h = bx - radius, by - radius, radius * 2, radius * 2
    local target_bubble_grid
    if bubble_type == "hurt" then
        target_bubble_grid = self.world.hurt_bubbles[bubble_team]
    elseif bubble_type == "hit" then
        target_bubble_grid = self.world.hit_bubbles[bubble_team]
    end
    target_bubble_grid:each(x, y, w, h, fn)
end


function TwinStickEntity:each_nearby_bubble_self(bubble_type, bubble_team, radius, fn)
	local bx, by = self:get_body_center()
    local x, y, w, h = bx - radius, by - radius, radius * 2, radius * 2
	local target_bubble_grid
	if bubble_type == "hurt" then
		target_bubble_grid = self.world.hurt_bubbles[bubble_team]
	elseif bubble_type == "hit" then
		target_bubble_grid = self.world.hit_bubbles[bubble_team]
	end
	target_bubble_grid:each_self(x, y, w, h, fn, self)
end

function TwinStickEntity:circle_collides_with_any_bubble(bubble_type, x, y, radius)
    for _, bubble in pairs(self.bubbles[bubble_type]) do
        if bubble:collides_with_circle(x, y, radius) then
            return true
        end
    end
    return false
end

function TwinStickEntity:on_flipped(flip)
	self:update_all_bubbles_on_move()
end

-----------------------------------------------------------------------------
--  "Shortcut" methods specifically for HURT / HIT if you prefer
-----------------------------------------------------------------------------

function TwinStickEntity:add_hurt_bubble(x, y, radius, name, x2, y2)
    return self:add_bubble("hurt", x, y, radius, name, x2, y2)
end
function TwinStickEntity:remove_hurt_bubble(name)
    return self:remove_bubble("hurt", name)
end
function TwinStickEntity:clear_hurt_bubbles()
    return self:clear_bubbles("hurt")
end
function TwinStickEntity:set_hurt_bubble_radius(name, radius)
    return self:set_bubble_radius("hurt", name, radius)
end
function TwinStickEntity:set_hurt_bubble_position(name, x, y)
    return self:set_bubble_position("hurt", name, x, y)
end

function TwinStickEntity:set_hurt_bubble_capsule_end_points(name, x2, y2)
    return self:set_bubble_capsule_end_points("hurt", name, x2, y2)
end

function TwinStickEntity:set_hit_bubble_capsule_end_points(name, x2, y2)
    return self:set_bubble_capsule_end_points("hit", name, x2, y2)
end

function TwinStickEntity:add_hit_bubble(x, y, radius, name, damage, x2, y2)
    return self:add_bubble("hit", x, y, radius, name, x2, y2, damage)
end
function TwinStickEntity:remove_hit_bubble(name)
    return self:remove_bubble("hit", name)
end
function TwinStickEntity:clear_hit_bubbles()
    return self:clear_bubbles("hit")
end
function TwinStickEntity:set_hit_bubble_radius(name, radius)
    return self:set_bubble_radius("hit", name, radius)
end
function TwinStickEntity:set_hit_bubble_position(name, x, y)
    return self:set_bubble_position("hit", name, x, y)
end

function TwinStickEntity:collide_with_terrain()
    self:constrain_to_room()
end

function TwinStickEntity:constrain_to_room()
    local room = self.world.room
	local collided = false

    if not room then return collided end

	local normal_x, normal_y = 0, 0

    if self.pos.x - self.terrain_collision_radius <= room.left then
        self:move_to(room.left + self.terrain_collision_radius, self.pos.y)
        -- if self.vel and self.vel.x < 0 then
        --     self.vel.x = 0
        -- end
		normal_x = 1
		collided = true
    end

    if self.pos.x + self.terrain_collision_radius >= room.right then
        self:move_to(room.right - self.terrain_collision_radius, self.pos.y)

		normal_x = -1
		collided = true
    end

    if self.pos.y - self.terrain_collision_radius <= room.top then
        self:move_to(self.pos.x, room.top + self.terrain_collision_radius)

		normal_y = 1
		collided = true
    end

    if self.pos.y + self.terrain_collision_radius >= room.bottom then

		self:move_to(self.pos.x, room.bottom - self.terrain_collision_radius)
		normal_y = -1
		collided = true
    end

	if collided then
		self:on_terrain_collision(normal_x, normal_y)
	end
	return collided
end

function TwinStickEntity:on_terrain_collision(normal_x, normal_y)
	if self.vel then
		if normal_x ~= 0 then
			self.vel.x = 0
		end
		if normal_y ~= 0 then
			self.vel.y = 0
		end
	end
end

function TwinStickEntity:terrain_collision_bounce(normal_x, normal_y)
	if self.vel then
		if normal_x ~= 0 then
			self.vel.x = self.vel.x * -1
		end
		if normal_y ~= 0 then
			self.vel.y = self.vel.y * -1
		end
	end
end

function TwinStickEntity:get_body_center()
    return self.pos.x, self.pos.y - self.body_height
end

function TwinStickEntity:get_body_center_rect(size_x, size_y)
	size_y = size_y or size_x
	local bx, by = self:get_body_center()
	return bx - size_x * 0.5, by - size_y * 0.5, size_x, size_y
end

function TwinStickEntity:body_direction_to(other)
	local bx, by = self:get_body_center()
	local ox, oy = other:get_body_center()
	return vec2_direction_to(bx, by, ox, oy)
end

function TwinStickEntity:body_distance_to(other)
	local bx, by = self:get_body_center()
	local ox, oy = other:get_body_center()
	return vec2_distance(bx, by, ox, oy)
end

function TwinStickEntity:body_position_difference(other)
	local bx, by = self:get_body_center()
	local ox, oy = other:get_body_center()
	return bx - ox, by - oy
end
	
function TwinStickEntity:get_body_center_local()
    return 0, -self.body_height
end

function TwinStickEntity:set_body_height(height)
    self.body_height = height
	self:update_all_bubbles_on_move()
end

function TwinStickEntity:get_aim_position(radius)
    radius = radius or self.aim_radius
    return self.pos.x + self.aim_direction.x * radius,
           self.pos.y + self.aim_direction.y * radius - self.body_height
end

function TwinStickEntity:get_aim_position_local(radius)
    radius = radius or self.aim_radius
    return self.aim_direction.x * radius,
           self.aim_direction.y * radius - self.body_height
end

function TwinStickEntity:terrain_collision_rect()
    return self.pos.x - self.terrain_collision_radius, self.pos.y - self.terrain_collision_radius,
           self.terrain_collision_radius * 2, self.terrain_collision_radius * 2
end

function TwinStickEntity:collide_with_shape(shape)
    -- same as your existing code ...
end

function TwinStickEntity:get_shoot_position()
    return self:get_aim_position(self.aim_radius)
end

function TwinStickEntity:body_translate()
    graphics.translate(0, -self.body_height)
end

function TwinStickEntity:collision_bubble_draw(bubble)
	local gx, gy = bubble:get_position()
	local lx, ly = self:to_local(gx, gy)
	graphics.circle("line", lx, ly, bubble.radius)

    if bubble.capsule then
		local lx2, ly2 = self:to_local(bubble:get_end_position())
        graphics.circle("line", lx2, ly2, bubble.radius)
		local angle = vec2_angle_to(lx, ly, lx2, ly2)
		local length = vec2_distance(lx, ly, lx2, ly2)
        graphics.line(lx, ly, lx + cos(angle) * length, ly + sin(angle) * length)

		if gametime.tick % 2 == 0 then
			local rx, ry, rw, rh = bubble:get_rect()
			rx, ry = self:to_local(rx, ry)

			graphics.rectangle("line", rx, ry, rw, rh)
		end
	end
end

function TwinStickEntity:twin_stick_debug_draw()
	if debug.can_draw_bounds() then
		-- Draw the collision circle
		graphics.set_color(Color.cyan)
		graphics.circle("line", 0, 0, self.terrain_collision_radius)

		-- Optionally draw all hurt & hit bubbles
		graphics.set_color(Color.yellow)
		-- Draw HURT
		for _, bubble in pairs(self.bubbles.hurt) do
			self:collision_bubble_draw(bubble)
		end

		-- Draw HIT in a different color to distinguish
		graphics.set_color(Color.magenta)
		for _, bubble in pairs(self.bubbles.hit) do
			self:collision_bubble_draw(bubble)
		end
    end
end

function TwinStickEntity:fire_bullet(bullet, direction, offset_x, offset_y, ...)
    local x, y = self:get_shoot_position()
	offset_x = offset_x or 0
    offset_y = offset_y or 0
	direction = (direction or self.aim_direction:clone()):normalize_in_place()
	offset_x, offset_y = vec2_rotated(offset_x, offset_y, vec2_angle(direction.x, direction.y))
	local b = bullet(x + offset_x, y + offset_y, ...)
	b.direction = direction
	return self:spawn_object(b)
end

function TwinStickEntity:twinstick_enter()
    -- Suppose the world has "hurt_bubbles" and "hit_bubbles" by team:
    self.bubbles_grid.hurt = self.world.hurt_bubbles[self.team]
    self.bubbles_grid.hit  = self.world.hit_bubbles[self.hitbox_team]
    self.spawn_position    = self.spawn_position or self.pos:clone()

    self:add_tag("twinstick_entity")
    self:add_to_spatial_grid("game_object_grid", self.hurt_bubble_rect)
    -- self.world:track_object_class_count(self)
end

function TwinStickEntity:hurt_bubble_rect()
	local bx, by = self:get_body_center()
	local x, y, w, h = bx, by, 1, 1
	for _, bubble in pairs(self.bubbles.hurt) do
		local brx, bry, br = bubble:get_rect()
		x = min(x, brx)
		y = min(y, bry)
		w = max(w, brx + br)
		h = max(h, bry + br)
	end
	return x, y, w, h
end

function TwinStickEntity:filter_melee_attack(bubble)
	return true
end

local HIT_COOLDOWN = 30

function TwinStickEntity.try_melee_attack(other, self, bubble)
	self.twinstick_entity_hit_objects = self.twinstick_entity_hit_objects or {}
    if (not self:filter_melee_attack(other)) then
        return false
    end
    if self.twinstick_entity_hit_objects[other.parent.id] then
        return false
    end
	if other.parent.intangible then
		return false
	end
	if bubble:collides_with_bubble(other) then
		if other.parent ~= self then
			other.parent:hit_by(bubble)
            self.twinstick_entity_landed_melee_attack = true
            self.twinstick_entity_hit_objects[other.parent.id] = true
			local s = self.sequencer
			s:start(function()
                s:wait(HIT_COOLDOWN)
                self.twinstick_entity_hit_objects[other.parent.id] = nil
            end)

			return true
		end
	end
	return false
end

function TwinStickEntity:get_sprite()
	return nil
end
function TwinStickEntity:get_default_palette()
    return Palette[self:get_sprite()]
end

function TwinStickEntity:get_palette()
	return nil, nil
end

function TwinStickEntity:get_palette_shared()
	local offset = 0
	
	local palette, offs = self:get_palette()

	palette = palette or self:get_default_palette()
	offset = offs or 0

	return palette, offset
end


function TwinStickEntity:check_melee_attack_against_team(target_team)
	local hit = false
    for _, bubble in pairs(self.bubbles.hit) do
        local target_bubble_grid = self.world.hurt_bubbles[target_team]
        local x, y, w, h = bubble:get_rect()
		target_bubble_grid:each(x, y, w, h, self.try_melee_attack, self, bubble)
		hit = hit or self.twinstick_entity_landed_melee_attack
	end
	return hit
end

function TwinStickEntity:on_landed_melee_attack()
end

function TwinStickEntity:check_melee_attack()
    if not self.melee_attacking then
        return
	end
	self.twinstick_entity_landed_melee_attack = false
	if self.melee_both_teams then
		local player = self:check_melee_attack_against_team("player")
		local enemy = self:check_melee_attack_against_team("enemy")
		local neutral = self:check_melee_attack_against_team("neutral")
		if player or enemy or neutral then
			self.twinstick_entity_landed_melee_attack = false
			self:on_landed_melee_attack()
			return true
		end
	else
		local hit_other_team = self:check_melee_attack_against_team(self.hitbox_team == "enemy" and "player" or "enemy")
		local hit_neutral = self:check_melee_attack_against_team("neutral")
		if hit_other_team or hit_neutral then
			self.twinstick_entity_landed_melee_attack = false
			self:on_landed_melee_attack()
			return true
		end
	end
	return false
end

return TwinStickEntity
