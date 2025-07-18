local MenuItem = GameObject2D:extend("MenuItem")

function MenuItem:new(x, y, width, height)
	MenuItem.super.new(self, x, y)
    self.focused = false
	self.width = width or 1
	self.height = height or 1
	self:add_signal("mouse_entered")
	self:add_signal("mouse_exited")
	self:add_signal("focused")
    self:add_signal("unfocused")
    self:add_signal("mouse_pressed")
    self:add_signal("mouse_released")

	self:add_time_stuff()

    -- Child management
    self:ref_array("menu_children")
	self.focused_child = nil
    self:ref("default_child", nil)
    self:ref("menu_parent", nil)
    
	self.neighbors = {
		up = nil,
		down = nil,
		left = nil,
		right = nil,
    }

	self.mouse_hovered = false
    self.mouse_held = {
		lmb = false,
		rmb = false,
		mmb = false,
    }

	self.mouse_just_entered = false
	self.mouse_just_exited = false
    self.mouse_can_click = {
		lmb = false,
		rmb = false,
		mmb = false,
    }
	
    if self.focusable == nil then
        self.focusable = true
    end
	
	if self.mouse_enabled == nil then
		self.mouse_enabled = true
	end

    if self.menu_visible == nil then
        self.menu_visible = true
    end
	
	if self.centered == nil then
		self.centered = false
	end

	if self.focus_on_hover == nil then
		self.focus_on_hover = true
	end
end

local _OPPOSITE_DIRECTION = {
	up = "down",
	down = "up",
	left = "right",
	right = "left",
}

function MenuItem:add_neighbor(neighbor, direction, bidirectional)
	if self.neighbors[direction] then
		self:remove_neighbor(direction)
	end
    self.neighbors[direction] = neighbor
	signal.connect(neighbor, "destroyed", self, "on_neighbor_destroyed_" .. direction, function()
		self.neighbors[direction] = nil
    end, true)

    if bidirectional then
        neighbor:add_neighbor(self, _OPPOSITE_DIRECTION[direction], false)
    end

	return neighbor
end

function MenuItem:remove_neighbor(direction)
	local neighbor = self.neighbors[direction]
	if not neighbor then return end
	self.neighbors[direction] = nil
    signal.disconnect(neighbor, "destroyed", self, "on_neighbor_destroyed_" .. direction)
	return neighbor
end


function MenuItem:get_rect()
	local x, y, w, h = self:get_rect_local()
	x = x + self.pos.x
	y = y + self.pos.y
	return x, y, w, h
end

function MenuItem:get_rect_local()
	local x, y = 0, 0
	if self.centered then
		x = x - self.width / 2
		y = y - self.height / 2
	end
	return x, y, self.width, self.height
end

function MenuItem:enter_shared()
	self:add_tag("menu_item")
	MenuItem.super.enter_shared(self)
end

function MenuItem:focus()
	if not self.focusable then return end
	if self.focused then return end
    self.focused = true
	for _, child in ipairs(self.menu_children) do
		child:unfocus()
	end
	self:on_focused()
    self:emit_signal("focused", self)
end

function MenuItem:unfocus()
	if not self.focusable then return end
    if not self.focused then return end
    self.focused = false
	self:on_unfocused()
	self:emit_signal("unfocused", self)
end

function MenuItem:update_shared(dt)
    if self.mouse_enabled then
        self:mouse_poll(dt)
    end

    if self.focused then
        self:focused_poll(dt)
    else
        self:unfocused_poll(dt)
    end

	MenuItem.super.update_shared(self, dt)
end

function MenuItem:update(dt)
end
function MenuItem:mouse_poll(dt)
	local input = self:get_input_table()

    if self.mouse_hovered then
        self:mouse_hovered_poll(dt, input)
    else
        self:mouse_unhovered_poll(dt, input)
    end
	
	for mouse_button, _ in pairs(self.mouse_held) do
		if self.mouse_held[mouse_button] and not input.mouse[mouse_button] then
			self.mouse_held[mouse_button] = false
			self:on_mouse_released(mouse_button)
			self:emit_signal("mouse_released", mouse_button)
		end
	end
end

function MenuItem:child_is_hovered()
	for _, child in ipairs(self.menu_children) do
		if child.mouse_hovered then
			return true
		end
	end
end

function MenuItem:mouse_hovered_poll(dt, input)

    if (self.mouse_hovered and not self:mouse_is_in_rect()) or self:child_is_hovered() then
        self.mouse_hovered = false
        self.mouse_just_exited = true
        self.mouse_can_click.lmb = false
        self.mouse_can_click.rmb = false
        self.mouse_can_click.mmb = false
        self:on_mouse_exited()
        self:emit_signal("mouse_exited")
        return self:mouse_unhovered_poll(dt, input)
    end

    for mouse_button, _ in pairs(self.mouse_held) do
        if not input.mouse[mouse_button] then
            self.mouse_can_click[mouse_button] = true
        elseif self.mouse_can_click[mouse_button] and (not self.mouse_held[mouse_button] and input.mouse[mouse_button]) then
            self.mouse_held[mouse_button] = true
            if mouse_button == "lmb" then
                self:focus()
            end
            self:on_mouse_pressed(mouse_button)
            self:emit_signal("mouse_pressed", mouse_button)
        end
    end

	if not self.focused and self.focus_on_hover then
		if input.mouse.dxy.x ~= 0 or input.mouse.dxy.y ~= 0 then
			self:focus()
		end
	end
	
	self.mouse_just_entered = false
end

function MenuItem:mouse_unhovered_poll(dt, input)
    if not self.mouse_hovered and self:mouse_is_in_rect() and not self:child_is_hovered() then
        self.mouse_hovered = true
		self.mouse_just_entered = true
        self:on_mouse_entered()
        self:emit_signal("mouse_entered")
		return self:mouse_hovered_poll(dt, input)
    end



	self.mouse_just_exited = false
end


function MenuItem:mouse_is_in_rect()
    local mouse_pos_x, mouse_pos_y = self:get_mouse_position()
    local rect_x, rect_y, rect_w, rect_h = self:get_rect()
    return mouse_pos_x >= rect_x and mouse_pos_x <= rect_x + rect_w and
        mouse_pos_y >= rect_y and mouse_pos_y <= rect_y + rect_h
end

function MenuItem:unfocused_poll(dt)
end

function MenuItem:focused_poll(dt)
	local input = self:get_input_table()
	
	if self.world.gamepad_nav_only then
		if input.last_input_device ~= "gamepad" then
			return
		end
	end

    if input.ui_nav_up_pressed and self.neighbors.up and self.neighbors.up.focusable then
        self:defer(function()
			if input.ui_nav_left_pressed and self.neighbors.up.neighbors.left and self.neighbors.up.neighbors.left.focusable then
				self.neighbors.up.neighbors.left:focus()
			elseif input.ui_nav_right_pressed and self.neighbors.up.neighbors.right and self.neighbors.up.neighbors.right.focusable then
				self.neighbors.up.neighbors.right:focus()
			else
				self.neighbors.up:focus()
			end
        end)
    end

    if input.ui_nav_down_pressed and self.neighbors.down and self.neighbors.down.focusable then
        self:defer(function()
			if input.ui_nav_left_pressed and self.neighbors.down.neighbors.left and self.neighbors.down.neighbors.left.focusable then
				self.neighbors.down.neighbors.left:focus()
			elseif input.ui_nav_right_pressed and self.neighbors.down.neighbors.right and self.neighbors.down.neighbors.right.focusable then
				self.neighbors.down.neighbors.right:focus()
			else
				self.neighbors.down:focus()
			end
        end)
    end

    if input.ui_nav_left_pressed and self.neighbors.left and self.neighbors.left.focusable then
        self:defer(function()
			if input.ui_nav_up_pressed and self.neighbors.left.neighbors.up and self.neighbors.left.neighbors.up.focusable then
				self.neighbors.left.neighbors.up:focus()
			elseif input.ui_nav_down_pressed and self.neighbors.left.neighbors.down and self.neighbors.left.neighbors.down.focusable then
				self.neighbors.left.neighbors.down:focus()
			else
				self.neighbors.left:focus()
			end
        end)
    end

    if input.ui_nav_right_pressed and self.neighbors.right and self.neighbors.right.focusable then
        self:defer(function()
			if input.ui_nav_up_pressed and self.neighbors.right.neighbors.up and self.neighbors.right.neighbors.up.focusable then
				self.neighbors.right.neighbors.up:focus()
			elseif input.ui_nav_down_pressed and self.neighbors.right.neighbors.down and self.neighbors.right.neighbors.down.focusable then
				self.neighbors.right.neighbors.down:focus()
			else
				self.neighbors.right:focus()
			end
        end)
    end
end

-- function MenuItem:draw_shared()
--     MenuItem.super.draw_shared(self)
-- 	for _, child in ipairs(self.menu_children) do
-- 		self.world:draw_object(child)
-- 	end
-- end

-- function MenuItem:set_visibility(visible)
--     if self.parent then
--         self.menu_visible = visible
-- 		MenuItem.super.set_visibility(self, false)
-- 	else
-- 		MenuItem.super.set_visibility(self, visible)
-- 	end
-- end

function MenuItem:draw()
end

function MenuItem:debug_draw()
    graphics.set_color(self.focused and Color.red or Color.white)
    if self.mouse_hovered then
        graphics.set_color(Color.blue)
    end
    if self.mouse_held.lmb then
		graphics.set_color(Color.green)
	end
	graphics.rectangle("line", self:get_rect_local())
end


function MenuItem:on_mouse_entered()
end

function MenuItem:on_mouse_exited()
end

function MenuItem:on_mouse_pressed(button)
end

function MenuItem:on_mouse_released(button)
end

function MenuItem:on_focused()
end

function MenuItem:on_unfocused()
end

-- child management methods
function MenuItem:add_child(child)
	-- child:hide()
    
	self:ref_array_push("menu_children", child)
    child:ref("menu_parent", self)
    signal.connect(child, "focused", self, "on_child_focused")
    signal.connect(child, "unfocused", self, "on_child_unfocused")
    
    if self.default_child == nil then
        self:set_default_child(child)
    end

    child.z_index = child.z_index + self.z_index + 1
	return child
end

function MenuItem:remove_child(child)
    self:ref_array_remove("menu_children", child)
    child:ref("menu_parent", nil)
    signal.disconnect(child, "focused", self, "on_child_focused")
    signal.disconnect(child, "unfocused", self, "on_child_unfocused")
end

function MenuItem:set_default_child(child)
    self:ref("default_child", child)
end

function MenuItem:on_child_focused(child)
    if self.focused_child and self.focused_child ~= child then
        self.focused_child:unfocus()
    end
	
    self:unfocus()
	
    self:ref("focused_child", child)
end

function MenuItem:on_child_unfocused(child)
	if self.focused_child == child then
		self:unref("focused_child")
		-- self:focus()
	end

end

return MenuItem
