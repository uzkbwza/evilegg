local ArtefactSpawn = require("obj.Spawn.Pickup.BasePickup"):extend("ArtefactSpawn")

local ArtefactSpawner = GameObject2D:extend("ArtefactSpawner")
-- local ArtefactSpawnerFlashEffect = GameObject2D:extend("ArtefactSpawnerFlashEffect")

local Splatter = require("fx.just_the_splatter")

local XpPickup = require("obj.XpPickup")

local ARTEFACT_XP = 1500

function ArtefactSpawn:new(x, y, artefact)
    ArtefactSpawn.super.new(self, x, y)
	game_state.num_spawned_artefacts = game_state.num_spawned_artefacts + 1

	-- self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
    self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)
    -- self:lazy_mixin(Mixins.Behavior.EntityDeclump)
    self:lazy_mixin(Mixins.Behavior.AllyFinder)
    
	self.font = fonts.image_font1
	self.font2 = fonts.depalettized.image_font1
	
	-- self.declump_radius = 32
	-- self.declump_modifier = 0.5
    self.artefact = artefact
	self.is_artefact = true
    self:add_time_stuff()
	self:init_state_machine()
    self.text_amount = 0
    self.text_amount2 = 0
    self.text_amount3 = 0
    self.text_amount4 = 0
    self.z_index = 1.9
	self.hp = 10
	
    self.title_palette_stack = PaletteStack(Color.black)
	self.title_palette_stack:push(Palette.artefact_title_border, 1)
    self.title_palette_stack:push(Palette.artefact_title, 1)
	
	self.desc_palette_stack = PaletteStack(Color.black)
	self.desc_palette_stack:push(Palette.artefact_desc_border, 1)
    self.desc_palette_stack:push(Palette.artefact_desc, 1)

	savedata:add_item_to_codex(self.artefact.name)
end

function ArtefactSpawn:enter()
	self:add_tag("artefact")
end

function ArtefactSpawn:state_Dormant_enter()
	self:hide()
    self.pickupable = false
    local s = self.sequencer
    s:start(function()
        self:ref("spawner", self:spawn_object(ArtefactSpawner(0, 0)))
        s:wait_for_signal(self.spawner, "finished")
		self:change_state("Idle")
        -- self.spawner
    end)
end

function ArtefactSpawn:get_sprite()
	return nil
end

function ArtefactSpawn:update(dt)
    if self.spawner then
        self.spawner:move_to(self.pos.x, self.pos.y)
    end
	self:collide_with_terrain()
end

function ArtefactSpawn:state_Dormant_draw()

end

function ArtefactSpawn:state_Dormant_update(dt)

end

function ArtefactSpawn:state_Idle_enter()
    self:add_hurt_bubble(0, 0, 12, "main")
    self:show()
    local s = self.sequencer
    s:start(function()
        s:start(function()
            self.text_amount = 0
			self.text_amount2 = 0
			self.text_amount3 = 0
            s:tween_property(self, "text_amount", 0, 1, 15, "linear")
            s:tween_property(self, "text_amount2", 0, 1, 15, "linear")
            s:tween_property(self, "text_amount3", 0, 1, 15, "linear")
            s:tween_property(self, "text_amount4", 0, 1, 15, "linear")
        end)
        s:wait(20)
        self.pickupable = not self.artefact.no_pickup
    end)
    local players = self:get_players()
    for _, player in players:ipairs() do
        local bx, by = player:get_body_center()
        local diffx, diffy = bx - self.pos.x, by - self.pos.y
        local dist = vec2_magnitude(diffx, diffy)
        local dx, dy = vec2_normalized(diffx, diffy)
        local speed = 6 * max(0, (1 - dist / 100))
        player:apply_impulse(dx * speed, dy * speed)
    end
end

function ArtefactSpawn:hit_by(other)
    if self:is_tick_timer_running("hit_cooldown") then return end
    self:start_tick_timer("hit_cooldown", 2)
    local was_above_1 = self.hp > 1
    self.hp = self.hp - (other.damage or 1)
    if was_above_1 then self.hp = max(self.hp, 1) end
    local s = self.sequencer

    self:start_timer("damage_flash", 10)

    if self.hp <= 0 then
        self:queue_destroy()

        self.world:add_score_object(self.pos.x, self.pos.y, self:get_destroy_score(), "artefact_destruction")

        self:spawn_object(XpPickup(self.pos.x, self.pos.y, self:get_destroy_xp()))
        self:play_sfx("pickup_artefact_explode", 0.8)
        game_state:on_artefact_destroyed(self.artefact)
    else
        self:play_sfx("pickup_artefact_hurt", 0.6)
    end
end

function ArtefactSpawn:get_destroy_xp()
    return self.artefact.destroy_xp or (self.artefact.is_secondary_weapon and 1800 or ARTEFACT_XP)
end

function ArtefactSpawn:get_destroy_score()
    return self.artefact.destroy_score or (self.artefact.is_secondary_weapon and 750 or 500)
end

function ArtefactSpawn:get_palette()
	local palette = nil
	local offset = 0
	if self:is_timer_running("damage_flash") then
		palette = Palette.cmy
		offset = idiv(self.tick, 3)
	end
	return palette, offset
end

function ArtefactSpawn:state_Idle_draw()
    local tick = self.state_tick
	local elapsed = self.state_elapsed
	
	
    -- graphics.rectangle_centered("line", self.pos.x, self.pos.y, 20 + sin(elapsed / 17) * 4, 16 + sin(elapsed / 19) * 2)
	
	local num_rects = 12
    local r = ease("outCubic")(clamp(elapsed / 40, 0, 1)) * 16 + sin(elapsed / 21) * 2
	
	local pickup_stopwatch = self:get_stopwatch("pickup_time")
	
    if pickup_stopwatch then
		-- local old_r = r
        r = r + pickup_stopwatch.elapsed * 10.0
		-- num_rects = round(lerp(num_rects, ceil(num_rects * (r / old_r)), 0.1))
	end

	if r < 2000 then

		for i = 1, num_rects do
			local x, y = vec2_from_polar(r, tau * (i / num_rects) + elapsed / 100)
			graphics.set_color(Palette.artefact_title_border:tick_color(tick / 5))
			graphics.rectangle_centered("line", x, y + 1, 5, 5)
			graphics.set_color(Palette.cmy:tick_color(tick / 7))
			graphics.rectangle_centered("line", x, y, 5, 5)
		end

	end

    graphics.set_color(Color.white)
    local palette, offset = self:get_palette()
	
	if not self.picked_up then
		graphics.drawp_centered(self.artefact.sprite or self.artefact.icon, palette, offset, 0, sin(elapsed / 20) * 1)
	end
	graphics.set_color(Color.black)
	
	local name = tr[self.artefact.name]
    local desc = tr[self.artefact.description]:upper()
	name = name:sub(1, name:len() * self.text_amount)
	desc = desc:sub(1, desc:len() * self.text_amount)
	
	graphics.set_font(self.font2)
	graphics.print_outline_centered(Color.black, name, self.font2, 0, -16)
	graphics.print_outline_centered(Color.black, desc, self.font2, 0, 16)
	graphics.set_font(self.font)
    graphics.set_color(Color.white)
	self.title_palette_stack:set_palette_offset(2, tick / 5)
	self.title_palette_stack:set_palette_offset(3, tick / 3)
	graphics.printp_centered(name, self.font, self.title_palette_stack, 0, 0, -16)
	self.desc_palette_stack:set_palette_offset(2, tick / 5)
	self.desc_palette_stack:set_palette_offset(3, tick / 3)
    graphics.printp_centered(desc, self.font, self.desc_palette_stack, 0, 0, 16)
	
	
	if self.artefact.is_secondary_weapon then
        local tip1 = tr.artefact_guide_use:format(input.last_input_device == "gamepad" and control_glyphs.rt or
        control_glyphs.rmb)
		local ammo_count1 = string.fraction(self.artefact.minimum_ammo_needed_to_use_normalized or self.artefact.ammo_needed_per_use_normalized)
		local ammo_count1_text = self.artefact.minimum_ammo_needed_to_use and tr.artefact_guide_min_ammo_requirement or tr.artefact_guide_ammo_requirement
		local tip3 = ammo_count1_text:format(ammo_count1)
		local tip2 = tr.artefact_guide_ammo_gain:format(string.fraction(self.artefact.ammo_gain_per_level_normalized))
		
		tip1 = string.interpolate(tip1, self.text_amount2)
		tip2 = string.interpolate(tip2, self.text_amount3)
		tip3 = string.interpolate(tip3, self.text_amount4)
		graphics.set_font(fonts.depalettized.image_font2)
		
		graphics.set_color(Color.white)
		graphics.print_centered(tip1, fonts.depalettized.image_font2, 0, 25)
		graphics.set_color(Color.green)
		graphics.print_centered(tip2, fonts.depalettized.image_font2, 0, 34)
		-- graphics.set_color(Color.red)
		-- graphics.print_centered(tip3, fonts.depalettized.image_font2, 0, 43)
	end


end

function ArtefactSpawn:state_Idle_update(dt)

end

function ArtefactSpawn:on_pickup(player)
    if self.picked_up then return end
	self:start_stopwatch("pickup_time")
    game_state:gain_artefact(self.artefact)
    self.picked_up = true
    self.intangible = true
	self.z_index = -2
	self:remove_tag("artefact")
	-- self:queue_destroy()
end

function ArtefactSpawner:new(x, y)
    ArtefactSpawner.super.new(self, x, y)
    self:add_signal("finished")
	self.z_index = 1
    self:add_time_stuff()
    self.sky_laser_bottom = 0
    self.sky_laser_top = 0
    self.flash_rect_size = 0
	self.start_e = 0
    -- self.flash_rect_filled = true
	self.flash_rect_line_size = 0.0
	self.flash_rect_size2 = 0
	-- self.sky_laser_width = 1
	

    local s = self.sequencer
    s:start(function()
		self:play_sfx("pickup_artefact_spawn", 0.6)
		s:start(function()
			s:wait(18)
			self:play_sfx("pickup_artefact_pre_boom", 1.0)
		end)
		s:wait(25)
        self.start_e = self.elapsed

		s:tween_property(self, "sky_laser_bottom", 0, 1, 7, "linear")
		self:stop_sfx("pickup_artefact_pre_boom")
		self:stop_sfx("pickup_artefact_spawn")
		self:play_sfx("pickup_artefact_boom")
        self:spawn_object(Splatter(self.pos.x, self.pos.y, 40, 40, 2)).z_index = -1
		local flash_size = 100
		-- self:spawn_object(ArtefactSpawnerFlashEffect(self.pos.x, self.pos.y))
        s:start(function()s:tween_property(self, "flash_rect_size", flash_size, 0, 10, "inQuad")end)
        s:start(function()
            s:tween_property(self, "flash_rect_size2", flash_size, flash_size + 10, 10, "outQuad")
			self.flash_rect_size2 = 0
		end)
        s:start(function()
            s:tween_property(self, "flash_rect_line_size", flash_size, flash_size + 55, 12, "outQuad")
			self.flash_rect_line_size = 0
		end)
        -- s:start(function()s:wait(8) self.flash_rect_filled = false end)
        s:wait(3)
        self:emit_signal("finished")
        -- s:start(function()
			-- s:tween_property(self, "sky_laser_width", 1, 0.8, 10, "inCubic")
		-- end)
		s:tween_property(self, "sky_laser_top", 0, 1, 8, "outCubic")
    end)
end

function ArtefactSpawner:draw()
	local laser_width = 12
	local laser_height = 200
	local laser_rect_x = self.pos.x - laser_width / 2
	local laser_y_start = (self.sky_laser_top * laser_height) - laser_height
    local laser_vert_amount = (self.sky_laser_bottom - self.sky_laser_top) * laser_height
    local color = Color.white

	local e = self.elapsed - self.start_e
	
	if e > 8 then 
		color = Color.yellow
	end

    if e > 12 then
		color = Color.green
	end

    if e > 16 then
        color = Color.cyan
    end
	
	if e > 20 then
		color = Color.blue
	end

    graphics.set_color(color)

    -- flash rect
    local flash_rect_size = floor(self.flash_rect_size)
    if flash_rect_size > 0 then
        graphics.rectangle_centered("fill", self.pos.x, self.pos.y, max(flash_rect_size, laser_width), flash_rect_size)
        graphics.rectangle_centered("line", self.pos.x, self.pos.y, self.flash_rect_size2, (self.flash_rect_size2))
    end
	if self.flash_rect_line_size > 0 then
		graphics.rectangle_centered("line", self.pos.x, self.pos.y,
            self.flash_rect_line_size, self.flash_rect_line_size)
	end


	-- laser

	-- print(self.sky_laser_top, self.sky_laser_bottom)
    graphics.rectangle("fill", laser_rect_x, laser_y_start, laser_width, laser_vert_amount)
end

function ArtefactSpawner:enter()
	-- self:add_tag("artefact")
end

AutoStateMachine(ArtefactSpawn, "Dormant")

return ArtefactSpawn


