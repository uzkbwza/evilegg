local SecondaryWeapon = GameObject2D:extend("SecondaryWeapon")

local LOW_AMMO_THRESHOLD = 0.30

function SecondaryWeapon:new(x, y, width, height)
    SecondaryWeapon.super.new(self, x, y)
    self.width = width
	self:add_time_stuff()
	self.height = height
	signal.connect(game_state, "player_secondary_weapon_gained", self, "on_secondary_weapon_gained")
	signal.connect(game_state, "tried_to_use_secondary_weapon_with_no_ammo", self, "on_tried_to_use_secondary_weapon_with_no_ammo")
	signal.connect(game_state, "secondary_weapon_ammo_used", self, "on_secondary_weapon_ammo_used")
	signal.connect(game_state, "secondary_weapon_ammo_gained", self, "on_secondary_weapon_ammo_gained")
end

function SecondaryWeapon:enter()
    self:add_tag("secondary_weapon")
end

function SecondaryWeapon:on_secondary_weapon_gained(artefact)
    self:play_sfx("pickup_secondary_weapon_gained", 0.8)
	self:start_timer("gained_weapon_flash", 20)
end

local not_enough_ammo_rumble_func = function(t)
    return 0.4
end

local gained_ammo_rumble_func = function(t)
    t = round(t * 20)
    if t >= 10 and t < 15 then
        return 0.4
    end
    if t >= 0 and t < 5 then
        return 0.2
    end
    return 0.0
end

function SecondaryWeapon:on_tried_to_use_secondary_weapon_with_no_ammo()
	if game_state.secondary_weapon then
		self:play_sfx("player_not_enough_ammo")
        self:start_timer("not_enough_ammo_flash", 6)
        input.start_rumble(not_enough_ammo_rumble_func, 3)
	end
end

function SecondaryWeapon:low_ammo_threshold()
	return ceil(game_state.secondary_weapon.low_ammo_threshold or game_state.secondary_weapon.ammo * LOW_AMMO_THRESHOLD)
end

function SecondaryWeapon:on_secondary_weapon_ammo_used(amount, old, new)
    local low_ammo_threshold = self:low_ammo_threshold()

	if game_state.secondary_weapon.minimum_ammo_needed_to_use then
        if old < game_state.secondary_weapon.minimum_ammo_needed_to_use then old = 0 end
		if new < game_state.secondary_weapon.minimum_ammo_needed_to_use then new = 0 end
	else
		old = stepify_floor(old, game_state.secondary_weapon.ammo_needed_per_use)
		new = stepify_floor(new, game_state.secondary_weapon.ammo_needed_per_use)	
	end

	if old > low_ammo_threshold and new <= low_ammo_threshold then
		self:play_sfx("player_running_out_of_ammo", 0.7)
        game_state:on_player_running_out_of_ammo()
	end
	if new == 0 and old > 0 then
        self:play_sfx("player_ran_out_of_ammo", 0.9)
        game_state:on_ran_out_of_ammo()
	end
end

function SecondaryWeapon:on_secondary_weapon_ammo_gained(amount, old, new)
    local low_ammo_threshold = self:low_ammo_threshold()
    -- if new > low_ammo_threshold and old <= low_ammo_threshold then
        -- self:play_sfx("player_running_out_of_ammo", 0.6)
    -- end


	
	if game_state.secondary_weapon.minimum_ammo_needed_to_use then
        if old < game_state.secondary_weapon.minimum_ammo_needed_to_use then old = 0 end
		if new < game_state.secondary_weapon.minimum_ammo_needed_to_use then new = 0 end
	else
		old = stepify_floor(old, game_state.secondary_weapon.ammo_needed_per_use)
		new = stepify_floor(new, game_state.secondary_weapon.ammo_needed_per_use)
	end

	

	if new == game_state.secondary_weapon.ammo or (old <= new and not (game_state.secondary_weapon.minimum_ammo_needed_to_use and new < game_state.secondary_weapon.minimum_ammo_needed_to_use)	) then
		self:play_sfx("player_gained_ammo", 0.7)
        self:start_timer("gained_ammo_flash", 10)
        input.start_rumble(gained_ammo_rumble_func, 12)
    else
		self:play_sfx("player_gained_ammo_partial", 0.7)
		
	end

end

function SecondaryWeapon:draw()
    graphics.set_color(Color.darkergrey)

	graphics.rectangle("line", 0, 0, self.width, self.height)
	if not game_state.secondary_weapon then
		return
	end

	if self:is_timer_running("gained_weapon_flash") and iflicker(self.tick, 3, 2) then
		return
	end

    local max_ammo = game_state.secondary_weapon.ammo
	local ammo = game_state.secondary_weapon_ammo

	local ammo_start = 1
    local ammo_end = self.width - 2
    local ammo_width = (ammo_end - ammo_start)
	
	local ammo_needed_per_use = game_state.secondary_weapon.ammo_needed_per_use

	local fireable_ammo = stepify_floor(ammo, ammo_needed_per_use)

	local min_ammo_needed_to_use = game_state.secondary_weapon.minimum_ammo_needed_to_use

    if min_ammo_needed_to_use then
		if fireable_ammo < min_ammo_needed_to_use then
			fireable_ammo = 0
        else
			fireable_ammo = ammo
		end
	end

	graphics.rectangle("fill", ammo_start, self.height - 4, ammo_width, 2)
	
    graphics.set_color(Color.white)


    local hud_icon_color = Color.darkergrey
    local empty_color = Color.darkgrey
    local unfireable_color = Color.grey
    local fireable_color = game_state.secondary_weapon.ammo_color

    -- if self.world.room.curse_famine then
    --     fireable_color = Color.red
    -- end

	if self:is_timer_running("gained_ammo_flash") and iflicker(self.tick, 2, 2) then
        fireable_color = self.tick % 2 == 0 and Color.white or Color.grey
		hud_icon_color = self.tick % 2 == 0 and hud_icon_color or Color.grey
	end

    if self:is_timer_running("not_enough_ammo_flash") and iflicker(self.tick, 2, 2) then
        empty_color = Color.red
		hud_icon_color = Color.darkred
		unfireable_color = Color.orange
    end

	graphics.set_color(hud_icon_color)

    graphics.draw(game_state.secondary_weapon.hud_icon, -1, -1)


	local low_ammo_threshold = self:low_ammo_threshold()

	
	if game_state.secondary_weapon_ammo <= low_ammo_threshold and iflicker(self.tick, 3, 2) then
		fireable_color = self.tick % 2 == 0 and Color.red or Color.orange
	end
    
    local unfireable_height = 2
    local fireable_height = 3
    
    local unfireable_y_start = self.height - unfireable_height - 2
    local fireable_y_start = self.height - fireable_height - 2
	
	if game_state.secondary_weapon.show_individual_ammo then
        for i = 1, max_ammo do
            local x = floor(ammo_start + (i - 1) * (ammo_width / max_ammo))
            local y = unfireable_y_start
            local w = floor((ammo_width / max_ammo) - 1)
            local h = unfireable_height

            -- graphics.set_color(Color.black)

            -- graphics.rectangle("fill", x - 1, y - 1, w + 2, h + 2)

			graphics.set_color(empty_color)

            if i <= fireable_ammo then
                graphics.set_color(fireable_color)
                y = y - 1
                h = fireable_height
            elseif i <= ammo then
                graphics.set_color(unfireable_color)
            end

            graphics.rectangle("fill", x, y, w, h)
        end
    else
        if min_ammo_needed_to_use then
			local chunk1_width = ((ammo_width / max_ammo) * min_ammo_needed_to_use)
            local chunk2_width = ammo_width - chunk1_width
			
            local unfireable_chunk1_ratio = inverse_lerp_safe_clamp(0, min_ammo_needed_to_use, ammo)
            local unfireable_chunk2_ratio = inverse_lerp_safe_clamp(min_ammo_needed_to_use, max_ammo, ammo)

			local fireable_chunk1_ratio = ammo >= min_ammo_needed_to_use and 1 or 0
			local fireable_chunk2_ratio = unfireable_chunk2_ratio

            if ammo < min_ammo_needed_to_use then
                unfireable_chunk2_ratio = 0
				fireable_chunk2_ratio = 0
			end
            if ammo >= min_ammo_needed_to_use then
                unfireable_chunk1_ratio = 1
                fireable_chunk1_ratio = 1
            end
			
			-- print(fireable_chunk1_ratio, fireable_chunk2_ratio)
			
			graphics.set_color(empty_color)
			graphics.rectangle("fill", ammo_start, unfireable_y_start, chunk1_width - 1, unfireable_height)
            graphics.rectangle("fill", ammo_start + chunk1_width, unfireable_y_start, chunk2_width, unfireable_height)
			
			graphics.set_color(unfireable_color)
            graphics.rectangle("fill", ammo_start, unfireable_y_start, unfireable_chunk1_ratio * (chunk1_width - 1), unfireable_height)
            graphics.rectangle("fill", ammo_start + chunk1_width, unfireable_y_start, unfireable_chunk2_ratio * (chunk2_width), unfireable_height)

			graphics.set_color(fireable_color)
			graphics.rectangle("fill", ammo_start, fireable_y_start, fireable_chunk1_ratio * (chunk1_width - 1), fireable_height)
            graphics.rectangle("fill", ammo_start + chunk1_width, fireable_y_start, fireable_chunk2_ratio * (chunk2_width), fireable_height)
			
		else

        -- elseif ammo_needed_per_use > 1 and ceil(max_ammo / ammo_needed_per_use) <= idiv(ammo_width, 4) then
			local num_chunks = ceil(max_ammo / ammo_needed_per_use)
			local chunk_width = (ammo_width / num_chunks)
			
			local w = (chunk_width - 1)
            local y = unfireable_y_start
			local h = unfireable_height
			
			for i=1, num_chunks do
				graphics.set_color(empty_color)
				local x = (ammo_start + (i - 1) * chunk_width)
				
                local unfireable_ratio = inverse_lerp_safe_clamp(ammo_needed_per_use * (i - 1), ammo_needed_per_use * (i),
                ammo)
				local fireable_ratio = fireable_ammo >= ammo_needed_per_use * (i) and 1 or 0

				graphics.rectangle("fill", x, unfireable_y_start, w, h)
				graphics.set_color(unfireable_color)
				graphics.rectangle("fill", x, unfireable_y_start, w * unfireable_ratio, h)
				graphics.set_color(fireable_color)
				graphics.rectangle("fill", x, fireable_y_start, w * fireable_ratio, fireable_height)
			end
        -- else
			-- graphics.set_color(empty_color)
			-- graphics.rectangle("fill", ammo_start, self.height - 4, ammo_width, 2)
			-- graphics.set_color(unfireable_color)
			-- local unfireable_width = ((ammo_width / max_ammo) * ammo)
			-- local fireable_width = ((ammo_width / max_ammo) * fireable_ammo)
			-- graphics.rectangle("fill", ammo_start, self.height - 4, unfireable_width, 2)
			-- graphics.set_color(fireable_color)
			-- graphics.rectangle("fill", ammo_start, self.height - 5, fireable_width, 3)
		end
	end
	
	graphics.set_color(Color.white)


end

return SecondaryWeapon
