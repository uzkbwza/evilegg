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
	signal.connect(game_state, "hatched", self, "initialize")
end

function HUDWorld:initialize()
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
        self:ref_array_push("artefact_objects",
            self:spawn_object(O.Artefact(left + base + (i - 1) * 14, bottom + 6, game_state.max_artefacts - i + 1)))
    end

	local heart_end = left + (game_state.max_hearts - 1) * 14
	local artefact_start = left + base
	
    self:ref("secondary_weapon", self:spawn_object(O.SecondaryWeapon(heart_end + 15, bottom + 1, artefact_start - heart_end - 22, 10)))
end

function HUDWorld:on_artefact_gained(artefact, slot)
	if slot > #self.artefact_objects then
		return
	end
	self.artefact_objects[#self.artefact_objects - slot + 1]:gain_artefact(artefact)
end

function HUDWorld:on_artefact_removed(artefact, slot)
	if slot > #self.artefact_objects then
		return
	end
	self.artefact_objects[#self.artefact_objects - slot + 1]:remove_artefact()
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

function HUDWorld:draw()
	if not self.showing then return end
	HUDWorld.super.draw(self)

	

	local room_elapsed = self.canvas_layer.game_layer.world.room.elapsed
	local world = self.canvas_layer.game_layer.world
	local show_time_on_room_clear = world.state == "RoomClear" or world.state == "LevelTransition"
	local show_time_on_room_start = room_elapsed < 60 or room_elapsed < 90 and iflicker(gametime.tick, 3, 2)
	
	if show_time_on_room_clear or show_time_on_room_start or self.canvas_layer.parent.ui_layer.state == "Paused" or self.force_show_time then
		local font = fonts.depalettized.image_font2
		graphics.set_font(font)
		graphics.set_color(Color.white)
		local text = format_hhmmssms1(frames_to_seconds(game_state.game_time) * 1000)
		graphics.print(text, conf.room_size.x / 2 - 1 - font:getWidth(text), 96)
	end
end

return HUDWorld
