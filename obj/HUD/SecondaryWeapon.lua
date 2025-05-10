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

function SecondaryWeapon:on_tried_to_use_secondary_weapon_with_no_ammo()
	if game_state.secondary_weapon then
		self:play_sfx("player_not_enough_ammo")
		self:start_timer("not_enough_ammo_flash", 6)
	end
end

function SecondaryWeapon:low_ammo_threshold()
	return ceil(game_state.secondary_weapon.low_ammo_threshold or game_state.secondary_weapon.ammo * LOW_AMMO_THRESHOLD)
end

function SecondaryWeapon:on_secondary_weapon_ammo_used(amount, old, new)
    local low_ammo_threshold = self:low_ammo_threshold()
	if old > low_ammo_threshold and new <= low_ammo_threshold then
		self:play_sfx("player_running_out_of_ammo", 0.7)
	end
	if new == 0 then
		self:play_sfx("player_ran_out_of_ammo", 0.9)
		self:play_sfx("player_not_enough_ammo")
	end
end

function SecondaryWeapon:on_secondary_weapon_ammo_gained(amount, old, new)
    local low_ammo_threshold = self:low_ammo_threshold()
    -- if new > low_ammo_threshold and old <= low_ammo_threshold then
        -- self:play_sfx("player_running_out_of_ammo", 0.6)
    -- end
    self:start_timer("gained_ammo_flash", 10)
	self:play_sfx("player_gained_ammo", 0.7)
end

function SecondaryWeapon:draw()
    graphics.set_color(Color.darkergrey)

	graphics.rectangle("line", 0, 0, self.width, self.height)
	if not game_state.secondary_weapon then
		return
	end

	if self:is_timer_running("gained_weapon_flash") and idivmod_eq_zero(self.tick, 3, 2) then
		return
	end

    local max_ammo = game_state.secondary_weapon.ammo
	local ammo = game_state.secondary_weapon_ammo

	local ammo_start = 1
    local ammo_end = self.width - 2
    local ammo_width = (ammo_end - ammo_start)
	
	local fireable_ammo = stepify_floor(ammo, game_state.secondary_weapon.ammo_needed_per_use)

	graphics.rectangle("fill", ammo_start, self.height - 4, ammo_width, 2)
	
    graphics.set_color(Color.white)


    local hud_icon_color = Color.darkergrey
    local empty_color = Color.darkgrey
    local unfireable_color = Color.grey
    local fireable_color = game_state.secondary_weapon.ammo_color

	if self:is_timer_running("gained_ammo_flash") and idivmod_eq_zero(self.tick, 2, 2) then
        fireable_color = self.tick % 2 == 0 and Color.white or Color.grey
		hud_icon_color = self.tick % 2 == 0 and hud_icon_color or Color.grey
	end

    if self:is_timer_running("not_enough_ammo_flash") and idivmod_eq_zero(self.tick, 2, 2) then
        empty_color = Color.red
		hud_icon_color = Color.darkred
		unfireable_color = Color.orange
    end

	graphics.set_color(hud_icon_color)

    graphics.draw(game_state.secondary_weapon.hud_icon, -1, -1)


	local low_ammo_threshold = self:low_ammo_threshold()

	
	if game_state.secondary_weapon_ammo <= low_ammo_threshold and idivmod_eq_zero(self.tick, 3, 2) then
		fireable_color = self.tick % 2 == 0 and Color.red or Color.orange
	end
	
	if max_ammo <= idiv(ammo_width, 4) then
        for i = 1, max_ammo do
            local x = ammo_start + (i - 1) * (ammo_width / max_ammo)
            local y = self.height - 4
            local w = (ammo_width / max_ammo) - 1
            local h = 2

            -- graphics.set_color(Color.black)

            -- graphics.rectangle("fill", x - 1, y - 1, w + 2, h + 2)

			graphics.set_color(empty_color)

            if i <= fireable_ammo then
                graphics.set_color(fireable_color)
                y = y - 1
                h = h + 1
            elseif i <= ammo then
                graphics.set_color(unfireable_color)
            end

            graphics.rectangle("fill", x, y, w, h)
        end
    else
        graphics.set_color(empty_color)
        graphics.rectangle("fill", ammo_start, self.height - 4, ammo_width, 2)
        graphics.set_color(unfireable_color)
        local unfireable_width = ((ammo_width / max_ammo) * ammo)
		local fireable_width = ((ammo_width / max_ammo) * fireable_ammo)
		graphics.rectangle("fill", ammo_start, self.height - 4, unfireable_width, 2)
        graphics.set_color(fireable_color)
		graphics.rectangle("fill", ammo_start, self.height - 5, fireable_width, 3)
	end
	
	graphics.set_color(Color.white)


end

return SecondaryWeapon
