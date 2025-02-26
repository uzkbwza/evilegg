local TwinStickNormalBullet = Object:extend("TwinStickNormalBullet")

function TwinStickNormalBullet:__mix_init()
	self.hit_objects = {}
	self:lazy_mixin(Mixins.Behavior.TrackPreviousPosition2D)
    self:add_elapsed_time()
	self.lifetime = self.lifetime or 900
    self:add_signal("bullet_hit")
    self:add_signal("bullet_died")
	self.radius = self.radius or 1
    if self.die_on_hit == nil then self.die_on_hit = true end


    self.damage = self.damage or 1
    self:add_update_function(function(self, dt)
		if not self.dead then
			if self.elapsed > self.lifetime then
				self:die()
			end
		end
    end)

    self:add_move_function(function(self)
		if not self.dead then
			if not self.world.room.bullet_bounds:contains_circle(self.pos.x, self.pos.y, self.radius) then
				self:move_to(self.world.room.bullet_bounds:clamp_circle(self.pos.x, self.pos.y, self.radius))
				self:die()
			end
		end
	end)

	self:add_enter_function(function(self)
        self.spawn_position = self.spawn_position or self.pos:clone()
		self:add_to_spatial_grid("bullet_grid", self.get_rect)
	end)


    self.hit = false

	local old_die = self.die

	if old_die then 
        self.die = function(self, ...)
            self:twinstick_die()
            old_die(self, ...)
        end

    else
		self.die = function(self)
            self:twinstick_die()
			self:queue_destroy()
			self:emit_signal("bullet_died")
		end
	end
end

function TwinStickNormalBullet.try_hit(bubble, self)
    local parent = bubble.parent
	
    if self.hit_objects[parent] then return end

	local bubble_x, bubble_y = bubble:get_position()
	if circle_capsule_collision(bubble_x, bubble_y, bubble.radius, self.prev_pos.x, self.prev_pos.y, self.pos.x, self.pos.y, self.radius) then
		parent:hit_by(self)
		self:on_hit_something(parent, bubble)
		self.hit_objects[parent] = true
		signal.connect(parent, "destroyed", self, "on_parent_destroyed", function()
			self.hit_objects[parent] = nil
		end)
		self.hit = true
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
    local prev_x, prev_y = self.prev_pos.x, self.prev_pos.y
    local dx = abs(self.pos.x - prev_x)
    local dy = abs(self.pos.y - prev_y)
    local start_x = min(prev_x, self.pos.x) - self.radius
    local start_y = min(prev_y, self.pos.y) - self.radius
    return
        start_x,
        start_y,
        self.radius * 2 + dx,
        self.radius * 2 + dy
end

function TwinStickNormalBullet:twinstick_die()
	self.dead = true
end

function TwinStickNormalBullet:try_hit_nearby_objects(team)
	local hurt_bubbles = self.world.hurt_bubbles[team]
	local x, y, w, h = self:get_rect()
	hurt_bubbles:each(x, y, w, h, self.try_hit, self)
	if self.hit and self.die_on_hit then
		self:on_hit_objects_this_frame()
		self.hit = false
	end
end

function TwinStickNormalBullet:on_hit_objects_this_frame()
	-- self:die()
end

function TwinStickNormalBullet:try_hit_nearby_anyone()
	self:try_hit_nearby_objects("enemy")

	self:try_hit_nearby_objects("player")
end

function TwinStickNormalBullet:try_hit_nearby_enemies()
    self:try_hit_nearby_objects("enemy")
end

function TwinStickNormalBullet:try_hit_nearby_players()
	self:try_hit_nearby_objects("player")
end

function TwinStickNormalBullet:on_hit_something(parent, bubble)
end

function TwinStickNormalBullet:draw()
    graphics.circle("fill", 0, 0, self.radius)

end


return TwinStickNormalBullet
