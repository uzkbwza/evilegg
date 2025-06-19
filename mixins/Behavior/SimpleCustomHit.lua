local SimpleCustomHit = Object:extend("SimpleCustomHit")

function SimpleCustomHit:__mix_init()
	self.hit_objects = self.hit_objects or {}
end

function SimpleCustomHit:try_hit_team(team)
    local hurt_bubbles = self.world.hurt_bubbles[team]
    local x, y, w, h = self:get_rect()
    hurt_bubbles:each(x, y, w, h, self.try_hit, self)
end

function SimpleCustomHit:get_rect()
	
end

function SimpleCustomHit:before_hit(bubble)
	
end

function SimpleCustomHit.try_hit(bubble, self)
    local parent = bubble.parent
    if parent.intangible then return end

	self:before_hit(bubble)

	self:on_hit_bubble(bubble)

    if self.hit_objects[parent.id] then
        return	
	end

	if not self:check_bubble_collision(bubble) then return end

    parent:hit_by(self)

	self:add_to_hit_objects(parent)
    self:on_hit_something(parent, bubble)
end

function SimpleCustomHit:on_hit_bubble(bubble)
end

function SimpleCustomHit:add_to_hit_objects(parent)
    self.hit_objects[parent.id] = true
end

function SimpleCustomHit:check_bubble_collision(bubble)
	return false
end

function SimpleCustomHit:remove_from_hit_objects(object)
	self.hit_objects[object.id] = nil
end

function SimpleCustomHit:on_hit_something(parent, bubble)
end

return SimpleCustomHit

