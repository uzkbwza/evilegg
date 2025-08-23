-- TODO: multiplayer input

local input = {}

input.mapping = nil
input.vectors = nil

input.dummy = {}

input.joysticks = {}

input.generated_action_names = {}

input.mouse = {
    prev_wheel = Vec2(0, 0),
    prev_pos = Vec2(0, 0),
	prev_pos_absolute = Vec2(0, 0),
    pos = Vec2(0, 0),
	pos_absolute = Vec2(0, 0),
    dxy = Vec2(0, 0),
	dxy_absolute = Vec2(0, 0),
	dxy_relative = Vec2(0, 0),
    lmb = false,
    mmb = false,
    rmb = false,
	cached_mouse_data = {
		x = 0,
		y = 0,
		dx = 0,
		dy = 0,
        istouch = false,
		dxy_relative = Vec2(0, 0),
	},

    wheel = Vec2(0, 0),
    dxy_wheel = Vec2(0, 0),
    is_touch = false,
}

input.mouse_pressed = { lmb = false, mmb = false, rmb = false }
input.mouse_released = { lmb = false, mmb = false, rmb = false }

input.last_input_device = "gamepad"

input.signals = {}

function input.load()
    local g = input.generated_action_names

    input.mapping = conf.input_actions
    input.vectors = conf.input_vectors

    input.keyboard_held = {}
    input.keyboard_pressed = {}
    input.keyboard_released = {}

    input.joystick_held = {}
    input.joystick_pressed = {}
    input.joystick_released = {}

    signal.register(input, "joystick_pressed")
    signal.register(input, "joystick_released")
    signal.register(input, "key_pressed")
    signal.register(input, "key_released")
    signal.register(input, "mouse_pressed")
    signal.register(input, "mouse_released")
    signal.register(input, "mouse_moved")
    signal.register(input, "mouse_wheel_moved")
	signal.register(input, "text_input")

    input.dummy.mapping = conf.input_actions
	input.dummy.vectors = conf.input_vectors
	input.dummy.keyboard_held = {}
	input.dummy.keyboard_pressed = {}
	input.dummy.keyboard_released = {}
	input.dummy.joystick_held = {}
	input.dummy.joystick_pressed = {}
    input.dummy.joystick_released = {}
    input.dummy.mouse = table.deepcopy(input.mouse)
    input.mouse_pressed = { lmb = false, mmb = false, rmb = false }
    input.mouse_released = { lmb = false, mmb = false, rmb = false }
    input.dummy.mouse_pressed = table.deepcopy(input.mouse_pressed)
    input.dummy.mouse_released = table.deepcopy(input.mouse_released)
    input.dummy.dummy = input.dummy
	

    for action, _ in pairs(input.mapping) do
        g[action] = {
            pressed = action .. "_pressed",
            released = action .. "_released",
            amount = action .. "_amount",
			held = action .. "_held"
        }

        input[action] = false
        input[action .. "_pressed"] = false
        input[action .. "_released"] = false
		input[action .. "_held"] = false


        input.dummy[action] = false
        input.dummy[action .. "_pressed"] = false
        input.dummy[action .. "_released"] = false
		input.dummy[action .. "_held"] = false

        if input.mapping[action].joystick_axis then
            input[action .. "_amount"] = 0
            input.dummy[action .. "_amount"] = 0
        end
    end

    for vector, _ in pairs(input.vectors) do
        g[vector] = {
            normalized = vector .. "_normalized",
            clamped = vector .. "_clamped",
            digital = vector .. "_digital"
        }
        input[vector] = Vec2(0, 0)
        input.dummy[vector] = Vec2(0, 0)
        input[vector .. "_normalized"] = Vec2(0, 0)
        input.dummy[vector .. "_normalized"] = Vec2(0, 0)
        input[vector .. "_clamped"] = Vec2(0, 0)
        input.dummy[vector .. "_clamped"] = Vec2(0, 0)
        input[vector .. "_digital"] = Vec2(0, 0)
        input.dummy[vector .. "_digital"] = Vec2(0, 0)
		input[vector .. "_pressed"] = false
		input.dummy[vector .. "_pressed"] = false
    end
	
	input.dummy.mouse = table.deepcopy(input.mouse)
    input.dummy.mouse_pressed = table.deepcopy(input.mouse_pressed)
    input.dummy.mouse_released = table.deepcopy(input.mouse_released)


	for k, v in pairs(input) do
		if type(v) == "function" then
			input.dummy[k] = dummy_function
		end
	end
end

function input.get_mouse_position()
	return input.mouse.cached_mouse_data.x, input.mouse.cached_mouse_data.y, input.mouse.cached_mouse_data.dx, input.mouse.cached_mouse_data.dy
end

function input.joystick_added(joystick)
    input.joysticks[joystick] = true

	input.joystick_held[joystick] = input.joystick_held[joystick] or {}
    input.joystick_pressed[joystick] = input.joystick_pressed[joystick] or {}
	
end

function input.joystick_removed(joystick)
    input.joysticks[joystick] = nil
	input.joystick_held[joystick] = {}
    input.joystick_pressed[joystick] = {}
end

function input.check_input_combo(mapping_table, mapping_type, joystick, input_table)
    local pressed = false

    for _, keycombo in ipairs(mapping_table) do
        if type(keycombo) == "string" then
            if mapping_type == "keyboard" then
                local key = love.keyboard.get_key_from_scancode(keycombo)
                if input_table.keyboard_held[key] or input_table.keyboard_pressed[key] then
                    pressed = true
                end
            elseif mapping_type == "joystick" then
                if input_table.joystick_held[joystick][keycombo] or input_table.joystick_pressed[joystick][keycombo] then
                    pressed = true
                end
			elseif mapping_type == "mouse" then
				if input_table.mouse[keycombo] then
					pressed = true
				end
            end
        else
            pressed = true

            for _, key in ipairs(keycombo) do
                if mapping_type == "keyboard" then
                    key = love.keyboard.get_key_from_scancode(key)
                    if not input_table.keyboard_held[key] and not input_table.keyboard_pressed[key] then
                        pressed = false
                        break
                    end
                elseif mapping_type == "joystick" then
                    if not input_table.joystick_held[joystick][key] and not input_table.joystick_pressed[joystick][key] then
                        pressed = false
                        break
                    end
                elseif mapping_type == "mouse" then
                    if not input_table.mouse[key] then
                        pressed = false
                        break
                    end
                end
            end
        end



        if pressed then
            break
        end
    end
    return pressed
end

function input.post_update()
	input.post_process(input)
end

function input.resolve_remapping_table_internal(action, mapping, input_type, use_default)
    use_default = truthy_nil(use_default)
    if usersettings.input_remapping[action] and usersettings.input_remapping[action][input_type] then
        if usersettings.input_remapping[action][input_type].skip_input then return nil end
        return usersettings.input_remapping[action][input_type]
    end
    if use_default then
        return mapping[input_type]
    end
end

function input:resolve_remapping_table(action, input_type, use_default)
    local mapping = self.mapping[action]
    return input.resolve_remapping_table_internal(action, mapping, input_type, use_default)
end

function input.process(t)

    local g = input.generated_action_names

    for action, mapping in pairs(t.mapping) do
		
        local pressed = false

        if mapping.debug and not debug.enabled then
            goto skip
        end

        local keyboard = input.resolve_remapping_table_internal(action, mapping, "keyboard")
        local mouse = input.resolve_remapping_table_internal(action, mapping, "mouse")
        local joystick_button = input.resolve_remapping_table_internal(action, mapping, "joystick")
        local joystick_axis = input.resolve_remapping_table_internal(action, mapping, "joystick_axis")

        if keyboard and input.check_input_combo(keyboard, "keyboard", nil, t) then
            pressed = true
        end

        if mouse and input.check_input_combo(mouse, "mouse", nil, t) then
            pressed = true
        end


        if mapping.joystick_axis then
            t[g[action].amount] = 0
        end

        -- todo: local multiplayer with joysticks

        for joystick, _ in pairs(input.joysticks) do
            if joystick_button and input.check_input_combo(joystick_button, "joystick", joystick, t) then
                pressed = true
            end


            if pressed then break end

            if joystick_axis and joystick_axis.axis then
                local axis = joystick_axis.axis
                local dir = joystick_axis.dir
                local value = joystick:getGamepadAxis(axis)
                local deadzone = joystick_axis.deadzone or 0.33
                if dir == 1 then
                    if value > deadzone then
                        pressed = true
                        t[g[action].amount] = abs(value)
                    end
                else
                    if value < -deadzone then
                        pressed = true
                        t[g[action].amount] = abs(value)
                    end
                end
                if not pressed then
                    t[g[action].amount] = 0
                end
            end
            if pressed then break end
        end

        if pressed then
            t[g[action].held] = true
            if not t[action] then
                t[g[action].pressed] = true
            end
            if not t[g[action].amount] or t[g[action].amount] == 0 then
                t[g[action].amount] = 1
            end
        else
            if t[action] then
                t[g[action].released] = true
            end
            t[g[action].amount] = 0
        end

        t[action] = pressed
        ::skip::
    end
	


    for k, dirs in pairs(t.vectors) do

		
		
        local v = t[k]
        v.x = 0
        v.y = 0

        if t[g[dirs.left].amount] and t[dirs.left] then
            v.x = v.x - t[g[dirs.left].amount]
        elseif t[dirs.left] then
            v.x = v.x - 1
        end
        if t[g[dirs.right].amount] and t[dirs.right] then
            v.x = v.x + t[g[dirs.right].amount]
        elseif t[dirs.right] then
            v.x = v.x + 1
        end
        if t[g[dirs.up].amount] and t[dirs.up] then
            v.y = v.y - t[g[dirs.up].amount]
        elseif t[dirs.up] then
            v.y = v.y - 1
        end
        if t[g[dirs.down].amount] and t[dirs.down] then
            v.y = v.y + t[g[dirs.down].amount]
        elseif t[dirs.down] then
            v.y = v.y + 1
        end

        t[k] = v

        local nv = t[g[k].normalized]
        local nx, ny = vec2_normalized(v.x, v.y)
        nv.x = nx
        nv.y = ny

        local cv = t[g[k].clamped]
        local cx, cy = v.x, v.y
        if vec2_magnitude(v.x, v.y) > 1 then
            cx, cy = vec2_normalized(v.x, v.y)
        end
        cv.x = cx
        cv.y = cy

		local dv = t[g[k].digital]
		local dx, dy = v.x == 0 and 0 or sign(v.x), v.y == 0 and 0 or sign(v.y)
		dv.x = dx
        dv.y = dy

    end

end

---@param name string 
---@param check_type "pressed" | "held" | "released"
function input:vector_boolean(name, check_type)
	local g = input.generated_action_names
    local direction_names = { "left", "right", "up", "down" }
    for _, dir in ipairs(direction_names) do
        if self[g[self.vectors[name][dir]][check_type]] then
            return true
        end
    end
end

function input:any_joystick_pressed(button)
	for joystick, _ in pairs(input.joysticks) do
		if input.joystick_pressed[joystick][button] then
			return true
		end
	end
	return false
end

function input:any_joystick_held(button)
	for joystick, _ in pairs(input.joysticks) do
		if input.joystick_held[joystick][button] then
			return true
		end
	end
	return false
end

function input:any_joystick_released(button)
	for joystick, _ in pairs(input.joysticks) do
		if input.joystick_released[joystick][button] then
			return true
		end
	end
	return false
end


local name_by_id = { [1] = "lmb", [2] = "rmb", [3] = "mmb" }

function input.post_process(t)

	t.mouse.dxy.x = t.mouse.pos.x - t.mouse.prev_pos.x
	t.mouse.dxy.y = t.mouse.pos.y - t.mouse.prev_pos.y


	t.mouse.dxy_absolute.x = 0
	t.mouse.dxy_absolute.y = 0

	t.mouse.dxy_relative.x = 0
	t.mouse.dxy_relative.y = 0

    t.mouse.prev_pos.x = t.mouse.pos.x
    t.mouse.prev_pos.y = t.mouse.pos.y

	t.mouse.prev_pos_absolute.x = t.mouse.pos_absolute.x
	t.mouse.prev_pos_absolute.y = t.mouse.pos_absolute.y

    t.mouse.prev_wheel.x = t.mouse.wheel.x
    t.mouse.prev_wheel.y = t.mouse.wheel.y

	local mposx, mposy, mdx, mdy = input.get_mouse_position()
	t.mouse.dxy_absolute.x = mdx
    t.mouse.dxy_absolute.y = mdy
	t.mouse.dxy_relative.x = input.mouse.cached_mouse_data.dxy_relative.x
    t.mouse.dxy_relative.y = input.mouse.cached_mouse_data.dxy_relative.y
    t.on_mouse_moved(mposx, mposy)
	
	t.mouse.cached_mouse_data.dxy_relative.x = 0
    t.mouse.cached_mouse_data.dxy_relative.y = 0
	t.mouse.cached_mouse_data.dx = 0
	t.mouse.cached_mouse_data.dy = 0


    for k, v in pairs(t.keyboard_pressed) do
		t.keyboard_pressed[k] = false
	end

	for k, v in pairs(t.mouse_pressed) do
		t.mouse_pressed[k] = false
	end

    for joystick, t2 in pairs(t.joystick_pressed) do
        for k, v in pairs(t2) do
            t.joystick_pressed[joystick][k] = false
        end
    end

	if t.mouse.dxy.x ~= 0 or t.mouse.dxy.y ~= 0 then
		signal.emit(input, "mouse_moved", t.mouse.dxy.x, t.mouse.dxy.y)
	end

    for k, v in pairs(t.keyboard_released) do
		t.keyboard_released[k] = false

	end

	for k, v in pairs(t.mouse_released) do
		t.mouse_released[k] = false
	end

    for joystick, tab in pairs(t.joystick_released) do
        for k, v in pairs(tab) do
            t.joystick_released[joystick][k] = false
        end
    end
	
	for k, v in pairs(t.keyboard_held) do
		if not love.keyboard.isDown(k) then 
            t.keyboard_held[k] = false
			if v then
				t.keyboard_released[k] = true
				signal.emit(input, "key_released", k)
			end
		end
	end

    for joystick, tab in pairs(t.joystick_held) do
		t.joystick_released[joystick] = t.joystick_released[joystick] or {}
        for k, v in pairs(tab) do
			local down = false
			if type(k) == "string" then
				if joystick:isGamepadDown(k) then down = true end
			elseif joystick:isDown(k) then
				down = true
			end
			if not (down) then
                t.joystick_held[joystick][k] = false
				if v then
					input.joystick_released[joystick][k] = true
					signal.emit(input, "joystick_released", joystick, v)
				end
			end
		end
	end

	-- reconcile mouse held state in case events were missed
	do
		
		for id, name in pairs(name_by_id) do
			local down = love.mouse.isDown(id)
			if not down and t.mouse[name] then
				t.mouse[name] = false
				t.mouse_released[name] = true
				signal.emit(input, "mouse_released", t.mouse.pos.x, t.mouse.pos.y, id)
			end
		end
	end

    local g = input.generated_action_names

    for action, _ in pairs(t.mapping) do
        t[g[action].pressed] = false
        t[g[action].released] = false
		t[g[action].held] = false
    end
end


function input.update(dt)
    input.process(input)

end

function input.on_key_pressed(key)
    -- if not input.keyboard_held[key] then
        input.keyboard_held[key] = true
        input.keyboard_pressed[key] = true
		signal.emit(input, "key_pressed", key)
    -- end
end

function input.on_joystick_pressed(joystick, button)
	-- if not input.joystick_held[joystick][button] then
        input.joystick_held[joystick][button] = true
        input.joystick_pressed[joystick][button] = true

		signal.emit(input, "joystick_pressed", joystick, button)
    -- end
end

function input.on_mouse_pressed(x, y, button)
    if button == 1 then
        -- if not input.mouse.lmb then
            input.mouse.lmb = true
            input.mouse_pressed.lmb = true
            signal.emit(input, "mouse_pressed", x, y, button)
        -- end
    end
    if button == 2 then
        -- if not input.mouse.rmb then
            input.mouse.rmb = true
            input.mouse_pressed.rmb = true
            signal.emit(input, "mouse_pressed", x, y, button)
        -- end
    end
    if button == 3 then
        -- if not input.mouse.mmb then
            input.mouse.mmb = true
            input.mouse_pressed.mmb = true
            signal.emit(input, "mouse_pressed", x, y, button)
        -- end
    end
end

function input.on_mouse_released(x, y, button)
    if button == 1 then
        if input.mouse.lmb then
            input.mouse.lmb = false
            input.mouse_released.lmb = true
        end
    end
    if button == 2 then
        if input.mouse.rmb then
            input.mouse.rmb = false
            input.mouse_released.rmb = true
        end
    end
    if button == 3 then
        if input.mouse.mmb then
            input.mouse.mmb = false
            input.mouse_released.mmb = true
        end
    end
    signal.emit(input, "mouse_released", x, y, button)
end

function input.on_mouse_moved(x, y)
    local mposx, mposy = graphics.screen_pos_to_canvas_pos(x, y)
    input.mouse.pos.x = (mposx)
    input.mouse.pos.y = (mposy)

    if debug.enabled then
        dbg("mouse_pos", "(" .. tostring(floor(input.mouse.pos.x)) .. ", " .. tostring(floor(input.mouse.pos.y)) .. ")")
    end
end

function input.read_mouse_input(x, y, dx, dy, istouch)
	input.mouse.cached_mouse_data.x = x
    input.mouse.cached_mouse_data.y = y
	if dx ~= 0 or dy ~= 0 then
		input.mouse.cached_mouse_data.dx = dx
		input.mouse.cached_mouse_data.dy = dy
        local d_relative_x, d_relative_y = graphics.screen_pos_to_canvas_pos(dx, dy)
		input.mouse.cached_mouse_data.dxy_relative.y = d_relative_y
		input.mouse.cached_mouse_data.dxy_relative.x = d_relative_x
	end
    input.mouse.cached_mouse_data.istouch = istouch
end

function input.on_text_input(text)
	signal.emit(input, "text_input", text)
end

function input.on_mouse_wheel_moved(dx, dy)
    input.mouse.wheel.x = dx
    input.mouse.wheel.y = dy
    signal.emit(input, "mouse_wheel_moved", dx, dy)
end


local function get_wasd_string()
    local left_mapping = input:resolve_remapping_table("move_left", "keyboard")
    local right_mapping = input:resolve_remapping_table("move_right", "keyboard")
    local up_mapping = input:resolve_remapping_table("move_up", "keyboard")
    local down_mapping = input:resolve_remapping_table("move_down", "keyboard")
    local text = ""
    if up_mapping and up_mapping[1] then
        text = text .. up_mapping[1]
    end
    if left_mapping and left_mapping[1] then
        text = text .. left_mapping[1]
    end
    if down_mapping and down_mapping[1] then
        text = text .. down_mapping[1]
    end
    if right_mapping and right_mapping[1] then
        text = text .. right_mapping[1]
    end
    if text == "" then
        return tr.control_wasd
    end
    return text:upper()
end

function input:get_move_prompt()
    return self.last_input_device == "gamepad" and (usersettings.southpaw_mode and control_glyphs.r or control_glyphs.l) or get_wasd_string()
end

function input:get_control_glyph(button)
    if remap_keys[button] then
        button = remap_keys[button]
    end
    if control_glyphs[button] then
        return control_glyphs[button]
    end
    return button
end


function input:get_prompt(action, mkb_default, gamepad_default)
    local kbd_mapping = self:resolve_remapping_table(action, "keyboard", false)
    local mouse_mapping = self:resolve_remapping_table(action, "mouse", false)
    local joystick_mapping = self:resolve_remapping_table(action, "joystick", false)
    local joystick_axis_mapping = self:resolve_remapping_table(action, "joystick_axis", false)

    if self.last_input_device == "gamepad" then
        if joystick_mapping and joystick_mapping[1] then
            return self:get_control_glyph(joystick_mapping[1])
        end

        if joystick_axis_mapping and joystick_axis_mapping.axis then
            return self:get_control_glyph(joystick_axis_mapping.axis)
        end

        return self:get_control_glyph(gamepad_default)
    else
        if mouse_mapping and mouse_mapping[1] then
            return self:get_control_glyph(mouse_mapping[1])
        end

        if kbd_mapping and kbd_mapping[1] then
            return self:get_control_glyph(kbd_mapping[1])
        end

        return self:get_control_glyph(mkb_default)
    end 
end

function input:get_shoot_prompt()
    return self:get_prompt("shoot", "lmb", usersettings.southpaw_mode and "l" or "r")
end

function input:get_boost_prompt()
    return self:get_prompt("hover", "space", "lt")
end

function input:get_secondary_weapon_prompt()
    return self:get_prompt("secondary_weapon", "rmb", "rt")
end

function input:get_skip_bonus_screen_prompt()
    return self:get_prompt("skip_bonus_screen", "tab", "start")
end





return input
