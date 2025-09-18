local TwinStickNormalBullet = Object:extend("TwinStickNormalBullet")

function TwinStickNormalBullet:__mix_init()
	self.hit_objects = {}
    self:add_elapsed_time()
	self.lifetime = self.lifetime or 900
    self:add_signal("bullet_hit")
    self:add_signal("bullet_died")
	self.radius = self.radius or 1
    if self.die_on_hit == nil then self.die_on_hit = true end


    self.damage = self.damage or 1
    self:add_update_function(function(self, dt)
		if not self.dead then
			self:collide_with_terrain()

			if self.tick > self.lifetime then
				self:defer(function() self:die() end)
			end
		end
    end)

	self:add_enter_function(function(self)
        self.spawn_position = self.spawn_position or self.pos:clone()
		self:add_to_spatial_grid("bullet_grid", self.get_rect)
    end)
	
	local old_debug_draw = self.debug_draw or self.dummy
    self.debug_draw = function(self)
        old_debug_draw(self)
        self:twin_stick_normal_bullet_debug_draw()
    end


    self.hit = false

	local old_die = self.die

	if old_die then 
        self.die = function(self, ...)
            self:twinstick_bullet_die()
            old_die(self, ...)
        end

    else
		self.die = function(self)
            self:twinstick_bullet_die()
			self:queue_destroy()
			self:emit_signal("bullet_died")
		end
	end
end

function TwinStickNormalBullet:add_to_hit_objects(object)
	self.hit_objects[object.id] = true
end

function TwinStickNormalBullet:remove_from_hit_objects(object)
	self.hit_objects[object.id] = nil
end


function TwinStickNormalBullet:collide_with_terrain()
    local collided = self:constrain_to_room()
end

function TwinStickNormalBullet:get_capsule()
    return self.prev_pos.x, self.prev_pos.y, self.pos.x, self.pos.y, self.radius
end

function TwinStickNormalBullet:constrain_to_room()
    local room = self.world.room
	local collided = false

    if not room then return collided end

	local normal_x, normal_y = 0, 0

    local left = room.left - self.radius / 2
	local right = room.right + self.radius / 2
	local top = room.bullet_bounds.y
	local bottom = room.bottom + self.radius / 2

    if self.pos.x <= left then
        self:move_to(left, self.pos.y)
		normal_x = 1
		collided = true
    end

    if self.pos.x >= right then
        self:move_to(right, self.pos.y)

		normal_x = -1
		collided = true
    end

    if self.pos.y <= top then
        self:move_to(self.pos.x, top)

		normal_y = 1
		collided = true
    end

    if self.pos.y >= bottom then

		self:move_to(self.pos.x, bottom)
		normal_y = -1
		collided = true
    end

    if collided then
            
        local off = (self.radius / 2)
        self:move_to(rect_clamp_point(self.pos.x, self.pos.y, self.world.room.bullet_bounds.x + off, self.world.room.bullet_bounds.y + off, self.world.room.bullet_bounds.width - off * 2, self.world.room.bullet_bounds.height - off * 2))


		self:on_terrain_collision(normal_x, normal_y)
	end
	return collided
end

function TwinStickNormalBullet:on_terrain_collision(normal_x, normal_y)
	
	self:defer(function() self:die() end)
end

function TwinStickNormalBullet:terrain_collision_bounce(normal_x, normal_y)
	-- if self.vel then
	-- 	if normal_x ~= 0 then
	-- 		self.vel.x = self.vel.x * -1
	-- 	end
	-- 	if normal_y ~= 0 then
	-- 		self.vel.y = self.vel.y * -1
	-- 	end
	-- end
end

function TwinStickNormalBullet.try_hit(bubble, self)
    local parent = bubble.parent
	
    if self.hit_objects[parent.id] then return end

	if parent.intangible then return end

    if parent.started_death_sequence then return end

	-- local bubble_x, bubble_y = bubble:get_position()
	if bubble:collides_with_capsule(self.prev_pos.x, self.prev_pos.y, self.pos.x, self.pos.y, self.radius) then
		parent:hit_by(self)
		self:on_hit_something(parent, bubble)
		self:add_to_hit_objects(parent)
        self.hit = true
		if not parent.bullet_passthrough then 
			self.hit_blocking = true
		end
		self:emit_signal("bullet_hit")
	end
end

function TwinStickNormalBullet:try_push(object, speed, dir_x, dir_y)
	if not object.bullet_pushable then return end
	if dir_x == nil or dir_y == nil then
		dir_x, dir_y = self.direction.x, self.direction.y
	end

	local direction_x, direction_y = vec2_normalized(dir_x, dir_y)
	object:get_pushed_by_bullet(direction_x * speed, direction_y * speed)

end

function TwinStickNormalBullet:get_rect()
	return get_capsule_rect(self.prev_pos.x, self.prev_pos.y, self.pos.x, self.pos.y, self.radius)
end

function TwinStickNormalBullet:twinstick_bullet_die()
	self.dead = true
end

function TwinStickNormalBullet:try_hit_nearby_objects(team)
	local hurt_bubbles = self.world.hurt_bubbles[team]
	local x, y, w, h = self:get_rect()
	hurt_bubbles:each(x, y, w, h, self.try_hit, self)
	if self.hit_blocking and self.die_on_hit then
		self:on_hit_blocking_objects_this_frame()
		self.hit_blocking = false
	end
end

function TwinStickNormalBullet:on_hit_blocking_objects_this_frame()
	-- self:die()
end

function TwinStickNormalBullet:try_hit_nearby_anyone()
	self:try_hit_nearby_objects("enemy")
	self:try_hit_nearby_objects("player")
	self:try_hit_nearby_objects("neutral")
end

function TwinStickNormalBullet:try_hit_nearby_enemies()
    self:try_hit_nearby_objects("enemy")
    self:try_hit_nearby_objects("neutral")
end

function TwinStickNormalBullet:try_hit_nearby_players()
	self:try_hit_nearby_objects("player")
	self:try_hit_nearby_objects("neutral")
end

function TwinStickNormalBullet:on_hit_something(parent, bubble)
end

function TwinStickNormalBullet:draw()
    graphics.circle("fill", 0, 0, self.radius)
end

function TwinStickNormalBullet:twin_stick_normal_bullet_debug_draw()
	if not debug.can_draw_bounds() then return end
    graphics.set_color(Color.blue)

    local prev_x, prev_y = 0, 0
	if self.prev_pos then
		prev_x, prev_y = self:to_local(self.prev_pos.x, self.prev_pos.y)
	end
	graphics.debug_capsule(prev_x, prev_y, 0, 0, self.radius, gametime.tick % 2 == 0)
end

return TwinStickNormalBullet
