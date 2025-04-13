local FungalDeathSplatter = require("fx.enemy_death_pixel_splatter"):extend("FungalDeathSplatter")
function FungalDeathSplatter:exit()
    for _, pixel in ipairs(self.pixels) do
		if rng.percent(1) then
            self:spawn_object(require("obj.Spawn.Enemy.Hazard.Fungus")(self:to_global(pixel.start_x + pixel.x, pixel.start_y + pixel.y))).palette =
            self.texture_palette
			break
		end
	end
end

return FungalDeathSplatter
