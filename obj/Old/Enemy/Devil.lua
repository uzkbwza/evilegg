local Devil = require("obj.Enemy.Enemy"):extend("Devil")

local Sheet = SpriteSheet(textures.enemy_devil, 16, 16)


function Devil:new(x, y)
    Devil.super.new(self, x, y)
	self.wiggle_amplitude = 64
    self.speed = 3
	self.speed2 = 0.2
    self.wiggle_frequency = 20
	self.targeted_player = false
	self.score = 200
	self.spawn_fx = "enemy_demon_spawn"
end

function Devil:enter()
	self.start_pos = self.pos:clone()
	self.on_right = self.start_pos.x > self.world.middle.x
end

function Devil:update(dt)
    if not self.targeted_player then
        local ydir = -self.world.scroll_direction
        local x = self.start_pos.x + sin(self.elapsed / (self.wiggle_frequency)) * self.wiggle_amplitude * (self.on_right and -1 or 1)
        -- local y = self.start_pos.y + cos(self.elapsed / (self.wiggle_frequency) + pi) * self.wiggle_amplitude
		local y = self.pos.y + self.speed2 * dt * ydir
        self:tp_to(x, y)
        self:set_flip(self.world.middle.x > self.pos.x and 1 or -1)
        local cx, cy = self:get_cell()
        local player = self:get_closest_object_with_tag("player")
        if self.tick > 40 and player then
            local px, py = player.pos.x, player.pos.y
            local pcx, pcy = self:get_cell(px, py)
            if pcx == cx then
                self.targeted_player = sign(pcy - cy)
                self:start_timer("startup", 10)
				self.world:play_sfx("enemy_demon_attack")
            end
        end
    else
        if not self:timer_running("startup") then
			self:start_timer("die", 300, function() self:queue_destroy() end)
			self:tp(0, self.speed * dt * self.targeted_player)
		end
    end

end

function Devil:get_texture() 
    return Sheet:loop(self.tick, 10)
end

return Devil
