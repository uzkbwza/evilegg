local RoomObject = GameObject2D:extend("RoomObject")

local PLAYER_DISTANCE = 8

local ICON_SIZE = 14
local ICON_BORDER = 2
local ICONS_PER_ROW = 4

local RECT_WIDTH = ICONS_PER_ROW * ICON_SIZE

function RoomObject:new(x, y, room)
	self.direction = Vec2(0, 0)
	RoomObject.super.new(self, x, y)
	self:lazy_mixin(Mixins.Behavior.PlayerFinder)
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
	self.stored_room = room
    self:add_signal("room_chosen")
    self:add_elapsed_ticks()
    self.icons = {
		enemy = {},
		hazard = {},
	}
    for data in pairs(room.all_spawn_types) do
        local icon = data.icon
		if data.type == "enemy" then
			table.insert(self.icons.enemy, icon)
		elseif data.type == "hazard" then
			table.insert(self.icons.hazard, icon)
		end
	end
    self.z_index = 100
	self.icon_stencil_function = function()
		graphics.circle("fill", 0, 0, PLAYER_DISTANCE)
	end
end

function RoomObject:enter()
    self:add_tag("room_object")
end

function RoomObject:update(dt)
    RoomObject.super.update(self, dt)
	local player = self:get_closest_player()
	if player and self.tick > 10 then
        local bx, by = self.pos.x, self.pos.y
		local pbx, pby = player:get_body_center()
		local distance = vec2_distance(bx, by, pbx, pby)
		if distance < PLAYER_DISTANCE then
			self:emit_signal("room_chosen")
		end
	end
end

function RoomObject:draw_icon(icon, x, y)
    graphics.push("all")
	graphics.translate(x, y)
	graphics.set_stencil_mode("draw", 1)
	graphics.set_color(0, 0, 0, 1.0)
	graphics.rectangle("fill", ICON_BORDER, ICON_BORDER, ICON_SIZE - ICON_BORDER * 2, ICON_SIZE - ICON_BORDER * 2)
    graphics.set_stencil_mode("test", 1)
	graphics.set_color(1, 1, 1, 1.0)
    graphics.draw_centered(icon, ICON_SIZE / 2, ICON_SIZE / 2)
	graphics.pop()
end
function RoomObject:draw()
	-- self:body_translate()
	graphics.set_color(1, 1, 1, 1)
    graphics.circle("line", 0, 0, PLAYER_DISTANCE)


	local rect_height
    local enemy_rows = ceil(#self.icons.enemy / ICONS_PER_ROW)
	local hazard_rows = ceil(#self.icons.hazard / ICONS_PER_ROW)

    rect_height = enemy_rows * ICON_SIZE + hazard_rows * ICON_SIZE

	graphics.translate(-RECT_WIDTH / 2, -rect_height / 2)
	graphics.translate(-self.direction.x * RECT_WIDTH/2, -self.direction.y * rect_height/2)

	graphics.set_color(0, 0, 0, 1)
    graphics.rectangle("fill", 0, 0, RECT_WIDTH, rect_height)
    graphics.set_color(1, 1, 1, 1)
	graphics.rectangle("line", 0, 0, RECT_WIDTH, rect_height)

    for i, icon in ipairs(self.icons.hazard) do
		self:draw_icon(icon, (i-1) % ICONS_PER_ROW * ICON_SIZE, floor((i-1) / ICONS_PER_ROW) * ICON_SIZE)
    end
	for i, icon in ipairs(self.icons.enemy) do
		self:draw_icon(icon, (i-1) % ICONS_PER_ROW * ICON_SIZE, floor((i-1) / ICONS_PER_ROW) * ICON_SIZE + hazard_rows * ICON_SIZE)
	end
end

return RoomObject
