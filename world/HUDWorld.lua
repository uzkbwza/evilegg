local HUDWorld = require("world.BaseWorld"):extend("HUDWorld")
local O = filesystem.get_modules("obj").HUD

function HUDWorld:new()
    HUDWorld.super.new(self)
	self.draw_sort = function(a, b)
		local az = a.z_index or 0
		local bz = b.z_index or 0

		if az < bz then
			return true
		elseif az > bz then
			return false
		end

		local avalue = a.pos.y + az
		local bvalue = b.pos.y + bz
		if avalue == bvalue then
			return a.pos.x < b.pos.x
		end
		return avalue < bvalue
	end
end

function HUDWorld:enter()
	local game_area_width = conf.viewport_size.x - conf.room_padding.x * 2
    local game_area_height = conf.viewport_size.y - conf.room_padding.y * 2
    local x_start = - conf.viewport_size.x / 2
    local y_start = - conf.viewport_size.y / 2 - 2
    local h_padding = conf.room_padding.x - 2
    local v_padding = conf.room_padding.y - 9
    local left = x_start + h_padding
    local top = y_start + v_padding
    local bottom = y_start + v_padding + game_area_height + 11
	-- self.center_camera = false
 
    self:ref_array("heart_objects")
	self:ref_array("artefact_objects")
	
	for i = 1, game_state.max_hearts do
		self:ref_array_push("heart_objects", self:spawn_object(O.Heart(left + (i - 1) * 14 + 7, bottom + 6, i)))
	end

	local base = 231 - (game_state.max_artefacts) * 14

	for i = 1, game_state.max_artefacts do
		self:ref_array_push("artefact_objects", self:spawn_object(O.Artefact(left + base + (i - 1) * 14, bottom + 6, i)))
	end
    -- local s = self:spawn_object(GameObject2D())
    -- s.draw = function(self)
	-- 	graphics.set_color(Color.white)
	-- 	graphics.rectangle_centered("fill", 0, 0, 50, 50)
	-- end
end

function HUDWorld:on_artefact_gained(artefact, slot)
	if slot > #self.artefact_objects then
		return
	end
	self.artefact_objects[slot]:gain_artefact(artefact)
end

function HUDWorld:on_artefact_removed(artefact, slot)
	if slot > #self.artefact_objects then
		return
	end
	self.artefact_objects[slot]:remove_artefact()
end

function HUDWorld:on_heart_gained()
    for i, heart in ipairs(self.heart_objects) do
		if game_state.hearts >= i then
			heart:flash()
		end
		heart:update_fill(game_state.hearts)
	end
end

function HUDWorld:on_heart_lost()
	for i, heart in ipairs(self.heart_objects) do
        if heart.filled and game_state.hearts < i then
			heart:empty_animation()
		end
        heart:update_fill(game_state.hearts)
		heart:flash()
	end
end

return HUDWorld
