local MainMenuWorld = World:extend("MainMenuWorld")
local TitleTextObject = GameObject2D:extend("TitleTextObject")
local O = (require "obj")
local GamerHealthTimer = require("obj.Menu.GamerHealthTimer")

local MENU_ITEM_H_PADDING = 12
local MENU_ITEM_V_PADDING = 12
local MENU_ITEM_SKEW = 0

local QUAD_SIZE_X = 3
local QUAD_SIZE_Y = 1

local EGG_FRAGMENT_OFFSET_X = -15
local EGG_FRAGMENT_OFFSET_Y = 6

local EGG_FRAGMENT_OFFSET_X_TARGET = 0
local EGG_FRAGMENT_OFFSET_Y_TARGET = 15

function MainMenuWorld:new(started_from_title_screen)
    MainMenuWorld.super.new(self)
	self:add_signal("menu_item_selected")
    self:add_signal("start_game_requested")
    self:add_signal("options_menu_requested")
	self:add_signal("codex_menu_requested")
	self:add_signal("leaderboard_menu_requested")

	self.draw_sort = self.y_sort
	self.started_from_title_screen = started_from_title_screen

    self:generate_fragments()

    self.egg_fragments_offset_amount = 0
    self.random_offset = rng:randi()
end

function MainMenuWorld:generate_fragments()
    local texture = textures.title_egg4
    local image_data = graphics.texture_data[texture]
    local width, height = image_data:getWidth(), image_data:getHeight()
    self.num_shell_fragments = 0

    local x_fragments = floor(width - 1 / QUAD_SIZE_X)
    local y_fragments = floor(height - 1 / QUAD_SIZE_Y)

    self.shell_fragment_locations = {}

    local c = 0

    for qx = 0, x_fragments do
        for qy = 0, y_fragments do
            c = c + 1
            if rng:percent(87) then
                goto continue
            end

            local x = qx * QUAD_SIZE_X - width * 0.5 + QUAD_SIZE_X * 0.5
            local y = qy * QUAD_SIZE_Y - height * 0.5 + QUAD_SIZE_Y * 0.5

            if vec2_distance(x, y * 0.85, 0, 0) < 40 then
                goto continue
            end

            -- Check if coordinates are within image bounds before getting pixel
            local a1 = 0
            if qx * QUAD_SIZE_X < width and qy * QUAD_SIZE_Y < height then
                local _, _, _, alpha = image_data:getPixel(qx * QUAD_SIZE_X, qy * QUAD_SIZE_Y)
                a1 = alpha
            end

            -- Check if all four corners of the quad are transparent
            local x1, y1 = qx * QUAD_SIZE_X, qy * QUAD_SIZE_Y
            local x2, y2 = qx * QUAD_SIZE_X + QUAD_SIZE_X, qy * QUAD_SIZE_Y + QUAD_SIZE_Y

            -- Check if coordinates are within image bounds
            local in_bounds1 = x1 >= 0 and x1 < width and y1 >= 0 and y1 < height
            local in_bounds2 = x2 >= 0 and x2 < width and y1 >= 0 and y1 < height
            local in_bounds3 = x1 >= 0 and x1 < width and y2 >= 0 and y2 < height
            local in_bounds4 = x2 >= 0 and x2 < width and y2 >= 0 and y2 < height

            local a1 = in_bounds1 and select(4, image_data:getPixel(x1, y1)) or 0
            local a2 = in_bounds2 and select(4, image_data:getPixel(x2, y1)) or 0
            local a3 = in_bounds3 and select(4, image_data:getPixel(x1, y2)) or 0
            local a4 = in_bounds4 and select(4, image_data:getPixel(x2, y2)) or 0

            if a1 == 0 and a2 == 0 and a3 == 0 and a4 == 0 then
                goto continue
            end

            local id = xy_to_id(qx, qy, x_fragments)

            local fragment = {
                x = x,
                y = y,
                width = QUAD_SIZE_X,
                height = QUAD_SIZE_Y,
                id = xy_to_id(qx, qy, x_fragments),
                cycle_speed = rng:randf(0.9, 1.0),
                -- splerp_decay = rng:randf(200, 2000),
                swell_mod = max(rng:randfn_abs(1, 1.5), 0.5),
                explosion_offset_x = rng:randf(-10, 10),
                explosion_offset_y = rng:randf(-10, 10),
                in_explosion = rng:percent(20),
                -- swell_mod = 1,
                -- offset_x = self.started_from_title_screen and EGG_FRAGMENT_OFFSET_X or EGG_FRAGMENT_OFFSET_X_TARGET,
                -- offset_y = self.started_from_title_screen and EGG_FRAGMENT_OFFSET_Y or EGG_FRAGMENT_OFFSET_Y_TARGET,
                explode_scale = rng:randi(1, 8),
                rect_h_scale = rng:randf_pow(1, 4, 3)
            }

            if rng:percent(35) then
                fragment.swell_mod = fragment.swell_mod * rng:randf_pow(1, 4, 3)
            end
            -- local quad = graphics.new_quad(qx * QUAD_SIZE_X, qy * QUAD_SIZE_Y, QUAD_SIZE_X, QUAD_SIZE_Y, width, height)
            -- local quad_table = graphics.get_quad_table(texture, quad, QUAD_SIZE_X, QUAD_SIZE_Y)

            -- fragment.quad = quad
            -- fragment.quad_table = quad_table
            if self.shell_fragment_locations[id] == nil then
                self.shell_fragment_locations[id] = fragment
                self.num_shell_fragments = self.num_shell_fragments + 1
            else
                -- print("duplicate fragment")
            end
            ::continue::
        end
    end

    print("num shell fragments", self.num_shell_fragments)
end

function MainMenuWorld:enter()
	
	-- self.camera:move(conf.viewport_size.x / 2, conf.viewport_size.y / 2)

    self:start_timer("create_buttons", 10, function() self:create_buttons() end)
    self:ref("title_text", self:spawn_object(TitleTextObject(2, 38)))
	local title_y = self.title_text.pos.y
	local s = self.sequencer
    self.egg_fragments_offset_amount = 0
    s:start(function()
        s:tween(
        function(t) self.title_text:move_to(self.title_text.pos.x, lerp(title_y, -conf.viewport_size.y / 2 + 55, t)) end,
            0, 1, 10, "linear")
		self.drawing_version = true
    end)
	

	if not self.started_from_title_screen then
        self.sequencer:end_all()
        self:end_timer("create_buttons")
        self.egg_fragments_offset_amount = 1
    else
        self.egg_fragments_offset_amount = 0
        self:interpolate_property_eased("egg_fragments_offset_amount", 0, 1, 3, "linear")
		self:play_sfx("ui_title_screen_clicked", 0.7)
		-- self:play_sfx("ui_title_screen_clicked", 0.7)
	end


	self.clear_color = Color.transparent

end

function MainMenuWorld:create_buttons()
	local menu_root = self:spawn_object(O.MainMenu.MainMenuRoot(1, 1, 1, 1))

    local menu_items = {
		{name = tr.main_menu_start_button, func = function() 
            global_state.restarting = false
            self:emit_signal("start_game_requested")
            end},
        -- {name = tr.menu_codex_button, func = function() end},
        -- {name = tr.main_menu_tutorial_buttom, func = function() end},
		{
			name = tr.main_menu_leaderboard_button,
			func = function()
				self:emit_signal("leaderboard_menu_requested")
		end},
        {
            name = tr.menu_codex_button,
            func = function()
                self:emit_signal("codex_menu_requested")
				
			end },
		
        {name = tr.menu_options_button, func = function() self:emit_signal("options_menu_requested") end},
        -- {name = tr.main_menu_credits_button, func = function() end},

		{name = tr.main_menu_quit_button, func = function() love.event.quit() end},
	}

	self:ref_array("menu_items")

    local prev = nil
	local distance_between_items = 19
	-- local base = MENU_ITEM_V_PADDING
	-- local base = conf.viewport_size.y - (#menu_items * distance_between_items) - MENU_ITEM_V_PADDING
    -- local base_x = EGG_FRAGMENT_OFFSET_X
    -- local base_y = EGG_FRAGMENT_OFFSET_Y - 40
    local base_x = 0
    local base_y = -28
    for i, menu_table in ipairs(menu_items) do
        local v_offset = (i - 1) * distance_between_items
		local h_offset = (i - 1) * MENU_ITEM_SKEW
		local menu_item = self:spawn_object(O.MainMenu.MainMenuButton(base_x + h_offset, base_y + v_offset, menu_table.name:upper()))
        signal.connect(menu_item, "selected", self, "on_menu_item_selected", function()
			self:on_menu_item_selected(menu_item, menu_table.func)
		end)
        menu_root:add_child(menu_item)
		if prev then
            menu_item:add_neighbor(prev, "up")
			prev:add_neighbor(menu_item, "down")
		end
		prev = menu_item
        if i == 1 then
            menu_item:focus()
        end
		self:ref_array_push("menu_items", menu_item)
	end

	if #self.menu_items > 1 then
		self.menu_items[1]:add_neighbor(self.menu_items[#self.menu_items], "up")
		self.menu_items[#self.menu_items]:add_neighbor(self.menu_items[1], "down")
	end
end

function MainMenuWorld:update(dt)
    local cooldown = usersettings.retry_cooldown and savedata:get_seconds_until_retry_cooldown_is_over() > 0
    if self.menu_items and self.menu_items[1] then
        self.menu_items[1]:set_enabled(not cooldown)
        if cooldown and not self.gamer_health_timer and self.tick > 2 then
            self:ref("gamer_health_timer",
            self:spawn_object(GamerHealthTimer(self.menu_items[1].pos.x, self.menu_items[1].pos.y, 150, 18)))
        end
        if self.gamer_health_timer then
            self.gamer_health_timer:move_to(self.menu_items[1].pos.x, self.menu_items[1].pos.y)
        end
    end
    

    -- if self.tick > 5 then
    -- for _, fragment in pairs(self.shell_fragment_locations) do
    --     local target_x, target_y = vec2_lerp(EGG_FRAGMENT_OFFSET_X, EGG_FRAGMENT_OFFSET_X_TARGET, EGG_FRAGMENT_OFFSET_Y, EGG_FRAGMENT_OFFSET_Y_TARGET, ease("inOutCubic")(self.egg_fragments_offset_amount))
    --     fragment.offset_x, fragment.offset_y = splerp_vec(fragment.offset_x, fragment.offset_y, target_x, target_y, fragment.splerp_decay, dt)
    -- end
    -- end
end

function MainMenuWorld:on_menu_item_selected(menu_item, func)
    self:emit_signal("menu_item_selected")
    menu_item:focus()
    local s = self.sequencer
    s:start(function()
        for _, item in ipairs(self.menu_items) do
            if item ~= menu_item then
                item:disappear_animation()
            end
        end
        s:wait(2)
        func()
    end)
end


function MainMenuWorld:draw_background()

    
    graphics.set_color(Color.white)
    -- graphics.dashrect_centered(0, 0, conf.room_size.x, conf.room_size.y, 2, 2, -self.elapsed * 0.05)
    
    if self.tick < 3 and self.started_from_title_screen then
        graphics.set_color(Color.darkpurple)
        local res = 10
        for i = 1, res do
            graphics.draw_centered(textures.title_egg4, vec2_lerp(EGG_FRAGMENT_OFFSET_X, EGG_FRAGMENT_OFFSET_Y, EGG_FRAGMENT_OFFSET_X_TARGET, EGG_FRAGMENT_OFFSET_Y_TARGET, i / res))
        end
    end
    graphics.set_color(Color.white)

    if not (self.started_from_title_screen and self.tick < 3) then
        self:draw_fragments()
    end
end

function MainMenuWorld:draw_fragments()
    graphics.push("all")

    local e = self.elapsed - 3
    
    if not self.started_from_title_screen then
        e = e + 60
    end

    local e60outcubic = ease("outCubic")(clamp01(e / 60))
    local e120outcubic = ease("outCubic")(clamp01(e / 120))

    -- graphics.translate(vec2_lerp(EGG_FRAGMENT_OFFSET_X, EGG_FRAGMENT_OFFSET_Y, EGG_FRAGMENT_OFFSET_X_TARGET, EGG_FRAGMENT_OFFSET_Y_TARGET, ease("inOutCubic")(self.egg_fragments_offset_amount)))
    graphics.translate(vec2_lerp(EGG_FRAGMENT_OFFSET_X, EGG_FRAGMENT_OFFSET_Y, EGG_FRAGMENT_OFFSET_X_TARGET, EGG_FRAGMENT_OFFSET_Y_TARGET, 1))
    -- graphics.translate(vec2_lerp(-15, 10, 0, 25, 0))
    local MAX_SWELL = 0.9
    local swell = MAX_SWELL
    swell = min(swell, 1 + (swell - 1) * e60outcubic)

    local exploding = false

    if e < 60 then
        exploding = true
    end

    -- graphics.translate(EGG_FRAGMENT_OFFSET_X, EGG_FRAGMENT_OFFSET_Y)



    -- swell = swell * lerp(1, 2, e60outcubic)

    local quad_size_x = QUAD_SIZE_X
    local quad_size_y = QUAD_SIZE_Y
    if exploding then
        -- quad_size_x = 1
        -- quad_size_y = 1
    end


    local palette1 = Palette.main_menu_egg_fragment
    local palette2 = Palette.main_menu_egg_fragment2

    -- graphics.translate(EGG_FRAGMENT_OFFSET_X_TARGET, EGG_FRAGMENT_OFFSET_Y_TARGET)
    if e < 15 then
        palette1 = Palette.main_menu_egg_fragment_dark
    end
    if e < 10 then
        palette1 = Palette.main_menu_egg_fragment_darker
    end
    if e < 5 then
        palette1 = Palette.black
    end

    if e > 45 then
        palette2 = Palette.main_menu_egg_fragment2_dark
    end
    if e > 50 then
        palette2 = Palette.main_menu_egg_fragment2_darker
    end
    if e > 55 then
        palette2 = Palette.black
    end




    -- for j = 1, 1 do
    -- for j = 1, 2 do
    for i, fragment in pairs(self.shell_fragment_locations) do
        -- local swell_amount = max(0, (1 - pow(abs(fragment.y) / 75, 1.5)))
        -- if color ~= Color.black then
        

        do


            local palette = palette1

            local color = palette:tick_color(e + i * self.random_offset * fragment.cycle_speed, 0, 3)

            if color ~= Color.black then

            local yswell = 1.0


                local swell_amount = fragment.swell_mod * max(0, (1 - pow(abs(fragment.y) / 75, 1.5)))
                local fragment_x = fragment.x * lerp(1, swell, swell_amount)
                local fragment_y = fragment.y * lerp(1, yswell, swell_amount)
                local wiggle = 3 * ease("outCubic")(clamp01(e / 50)) * sin(e * 0.026 + i * 10 + self.random_offset)
                -- wiggle = wiggle * swell_amount
                fragment_x = fragment_x + wiggle


                -- if j == 1 then
                -- local quad_width = (sin01(e * 0.1 + i * 10 + self.random_offset))
                -- quad_width = remap01(quad_width, 0.15, 2.0)
                local quad_width = 1
                local quad_height = 1


                fragment_x = fragment_x * lerp(1.1, 1.2, e120outcubic)
                fragment_y = fragment_y * lerp(1, 1.02, e120outcubic)

                graphics.set_color(color)
                --     graphics.draw_quad_table_centered(
                --         fragment.quad_table,
                --         fragment_x,
                --         fragment_y
                --     )
                graphics.rectangle_centered("fill", fragment_x + fragment.explosion_offset_x,
                fragment_y + fragment.explosion_offset_y, max(1, quad_size_x * quad_width) * fragment.rect_h_scale,
                max(1, quad_size_y * quad_height))
            end
        end
            



        if exploding and fragment.in_explosion then

            local palette = palette2

            local color = palette:tick_color(e + i * self.random_offset * fragment.cycle_speed, 0, 3)

            if color ~= Color.black then

                local quad_size_x = 1
                local quad_size_y = 1

                local yswell = 1.0

                local swell_amount = 1
                local fragment_x = fragment.x * lerp(1, swell * (1.2 + (clamp01(e / 60) * 0.25)), swell_amount)
                local fragment_y = fragment.y * lerp(1, yswell * (1.0 + (clamp01(e / 60) * 0.15)), swell_amount)
                local wiggle = 3 * ease("outCubic")(clamp01(e / 50)) * sin(e * 0.016 + i * 10 + self.random_offset)
                -- wiggle = wiggle * swell_amount
                fragment_x = fragment_x + wiggle
        
        
                -- if j == 1 then
                local quad_width = (sin01(e * 0.1 + i * 10 + self.random_offset))
                quad_width = remap01(quad_width, 0.15, 2.0)
                -- local quad_width = 1
                local quad_height = 1
        
        
                fragment_x = fragment_x * lerp(1.1, 1.2, e120outcubic)
                fragment_y = fragment_y * lerp(1, 1.02, e120outcubic)

                graphics.set_color(color)
                yswell = swell
                local scale = fragment.explode_scale * (1 - (clamp01(e / 60)))
                graphics.rectangle_centered("fill", fragment_x + fragment.explosion_offset_x,
                    fragment_y + fragment.explosion_offset_y, max(1, quad_size_x * quad_width) * scale,
                    max(1, quad_size_y * quad_height) * scale)
            end
        end

        -- end
        -- else
        --     -- graphics.set_color(Color.darkblue)
        --     graphics.set_color(Color.black)
        --     -- graphics.draw_quad_table_centered(fragment.quad_table, fragment_x * 0.7, fragment_y * 0.7)
        --     local scale = 1.5
        --     if exploding then
        --         scale = 10
        --     end
        --     graphics.rectangle_centered("fill", fragment_x * 0.7, fragment_y * 0.7, quad_size_x * scale,
        --     quad_size_y * scale)
        -- end
    end
    -- end
    
    graphics.pop()
end


local VERSION_PALETTE = Palette{Color.black, Color.black, Color.black, Color.black, Color.black, Color.darkgrey}

function MainMenuWorld:draw()


    self:draw_background()

    if self.drawing_version then
        local font = fonts.greenoid
		graphics.set_font(font)
        graphics.printp_right_aligned(GAME_VERSION, font, VERSION_PALETTE, 0, 114, -41)
        -- graphics.print(GAME_VERSION, font, -conf.viewport_size.x / 2, conf.viewport_size.y / 2 - 7)
    end
	MainMenuWorld.super.draw(self)
end

function TitleTextObject:new(x, y)
    TitleTextObject.super.new(self, x, y)
	self.z_index = 1
end

function TitleTextObject:draw()
    -- TitleTextObject.super.draw(self)
	graphics.draw_centered(textures.title_title_text, 0, 0)
end




return MainMenuWorld
