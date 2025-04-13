
local SkullBird = require("obj.Spawn.Enemy.Enemy"):extend("SkullBird")
local Wall = require("obj.Spawn.Enemy.Wall")

function SkullBird:new(x, y)
    -- self.state = "Idle"
    SkullBird.super.new(self, x, y + 1)
	-- self.solid = true
	self:init_health(1)
    -- self:enable_bump_mask(PHYSICS_ENEMY)
	self:clear_bump_masks()
	self:implement(Mixins.Behavior.GridMovement)
    self.speed = 8
    self.target_cell = Vec2(0, 0)
    self.last_move_direction = Vec2(0, 1)
	self.reversed = false
	self.is_skullbird = true
end

function SkullBird:enter()
	local x, y = self:get_cell()
    self.target_cell = Vec2(x, y - self.world.scroll_direction * (self.reversed and -1 or 1) * 120)
	self.last_move_direction = Vec2(0, -self.world.scroll_direction)
	self:move_around()
end

function SkullBird:get_texture()
    return floor(self.tick / 5) % 2 == 0 and textures.enemy_skullbird1 or textures.enemy_skullbird2
end

function SkullBird:is_solid_object_at_cell(x, y)
	local enemies = self:get_enemies_at_cell(x, y)
    for _, enemy in ipairs(enemies) do
		if enemy == self then goto continue end
		if enemy.is and (enemy:is(SkullBird) or enemy:is(Wall)) then
			return true
		end
		::continue::
	end
	return false
end

function SkullBird:draw()
    -- if self.at_cell then
	-- local cx, cy = self:get_cell()
    -- for _, neighbor in ipairs(neighbors(cx, cy)) do
	-- 	if not self:is_cell_solid(neighbor.x, neighbor.y, 0) then	
	-- 		local wx, wy = self.world.map.cell_to_world(neighbor.x, neighbor.y, 0)
	-- 		wx, wy = self:to_local(wx, wy)
	-- 		graphics.draw_centered(self:get_texture(), wx, wy, 0, self.flip, 1, 0, 1)
	-- 	end
	-- end	
    SkullBird.super.draw(self)
    graphics.set_color(Color.red)
	if debug.can_draw() then
		local cx, cy = self:get_cell()
        local wx, wy = self:to_local(self.world.map.cell_to_world(cx, cy, 0))
		local wx2, wy2 = self:to_local(self.world.map.cell_to_world(self.target_cell.x, self.target_cell.y, 0))
		graphics.line(wx, wy, wx2 * 1, wy2 * 1)
	end
end


function SkullBird:update_next_cell(current_cell_x, current_cell_y)
	local diff = self.target_cell - Vec2(current_cell_x, current_cell_y)
    local next_cell_x, next_cell_y = current_cell_x, current_cell_y	
	next_cell_x = next_cell_x + (diff.x ~= 0 and sign(diff.x) or 0)
	next_cell_y = next_cell_y + (diff.y ~= 0 and sign(diff.y) or 0)
	return next_cell_x, next_cell_y
end

function SkullBird:move_around()
    if not self.moving then
		self.world:play_sfx("enemy_bonerattle2")

		-- self.target_cell = Vec2(self.target_cell.x, self.target_cell.y + self.world.scroll_direction)
        local player = self:get_closest_object_with_tag("player")
        local current_cell_x, current_cell_y = self:get_cell()

        local next_cell_x, next_cell_y = self:update_next_cell(current_cell_x, current_cell_y)

        if player and not self:is_timer_running("player_check") then
            local px, py = player:get_cell()
            if current_cell_x == px then
                self.target_cell = Vec2(current_cell_x, py)
            elseif abs(current_cell_y - py) < 4 then
                self.target_cell = Vec2(px, current_cell_y)
            end
			self:start_timer("player_check", 10)
        end
        
		next_cell_x, next_cell_y = self:update_next_cell(current_cell_x, current_cell_y)

		
		local c = 0
        while self:is_cell_solid(next_cell_x, next_cell_y, 0) or self:is_solid_object_at_cell(next_cell_x, next_cell_y) do
            self.target_cell = self.target_cell * 0
            if rng.coin_flip() then
                self.target_cell = Vec2(current_cell_x + rng.rand_sign(), current_cell_y)
            else
                self.target_cell = Vec2(current_cell_x, current_cell_y - self.world.scroll_direction * (self.reversed and -1 or 1))
            end
            next_cell_x, next_cell_y = self:update_next_cell(current_cell_x, current_cell_y)
            c = c + 1
			if c > 10 then
				break
			end
        end
        if self.target_cell == Vec2(current_cell_x, current_cell_y) then
            self.target_cell = self.target_cell + self.last_move_direction
        end
		
		local enemies_at_own_cell = self:is_solid_object_at_cell(current_cell_x, current_cell_y)
		if enemies_at_own_cell then
			self.target_cell = Vec2(current_cell_x, current_cell_y) - self.last_move_direction
		end

		if self.target_cell.x ~= current_cell_x and self.target_cell.y ~= current_cell_y then
            if rng.coin_flip() then
                self.target_cell = Vec2(self.target_cell.x, current_cell_y)
            else
                self.target_cell = Vec2(current_cell_x, self.target_cell.y)
            end
        end

        next_cell_x, next_cell_y = self:update_next_cell(current_cell_x, current_cell_y)


		local immediate = enemies_at_own_cell
		-- print(#objects)
        if self:is_solid_object_at_cell(next_cell_x, next_cell_y) then
        	self:move_toward_cell(current_cell_x, current_cell_y, self.speed, immediate)
		else
			self:move_toward_cell(self.target_cell.x, self.target_cell.y, self.speed, immediate)
        end
        self.last_move_direction = self.target_cell - Vec2(current_cell_x, current_cell_y)
	end
end

function SkullBird:update()
    self:move_around()
    if self.tick % 30 == 0 then
	end
end

return SkullBird

