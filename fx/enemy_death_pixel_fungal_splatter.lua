local FungalDeathSplatter = require("fx.enemy_death_pixel_splatter"):extend("FungalDeathSplatter")
function FungalDeathSplatter:exit()
    local class = require("obj.Spawn.Enemy.Hazard.Fungus")
	local spawned_positions = {}
    for _, pixel in ipairs(self.pixels) do
		if rng.percent(1) then
			local pos = Vec2(self:to_global(pixel.start_x + pixel.x, pixel.start_y + pixel.y))
			local valid = true
			for i=1, #spawned_positions do 
				if spawned_positions[i]:distance_to(pos) < 16 then
					valid = false
					break
				end
			end
            if valid then
                self:spawn_object(class(pos))
				table.insert(spawned_positions, pos)
			end
		end
	end
end

return FungalDeathSplatter
