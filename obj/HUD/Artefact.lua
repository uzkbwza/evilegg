local Artefact = GameObject2D:extend("Artefact")
local DeathFlash = require("fx.enemy_death_flash")
local DeathSplatter = require("fx.enemy_death_pixel_splatter")

local TwinDeathEffect = Effect:extend("TwinDeathEffect")

function Artefact:new(x, y, index)
    Artefact.super.new(self, x, y)
	self.filled = false
    self.index = index
	self:add_time_stuff()
	self.waiting_for_animation = false
    self.flashing = false
    self.selected = false
	self.rumble = 0
    signal.connect(game_state, "player_artefact_slot_changed", self, "on_game_state_artefact_slot_changed")
	signal.connect(game_state, "used_sacrificial_twin", self, "on_used_sacrificial_twin")
    self:on_game_state_artefact_slot_changed(game_state.selected_artefact_slot, game_state.selected_artefact_slot)
	if game_state.artefact_slots[self.index] then
		self:gain_artefact(game_state.artefact_slots[self.index])
	end
end

function Artefact:enter()
	self:add_tag("artefact")
end

function Artefact:on_game_state_artefact_slot_changed(new, old)
    self.selected = new == self.index
	if self.selected then
		self:selection_flash(30)
	end
end

function Artefact:on_used_sacrificial_twin()
	if not (self.artefact and self.artefact.key == "sacrificial_twin") then return end
    self.waiting_for_animation = true
	local s = self.sequencer
    s:start(function()
		-- self:selection_flash(10)
		for _, artefact in self.world:get_objects_with_tag("artefact"):ipairs() do
			-- artefact:flash(30)
			-- artefact:flash(30)
			artefact:selection_flash(30)
		end
        s:tween(function(t)
			self.rumble = t
		end, 0, 1, 15, "linear")
		self:play_sfx("pickup_artefact_twin_death", 0.8)
        self.waiting_for_animation = false
		self:spawn_object(DeathFlash(self.pos.x, self.pos.y, self.artefact.icon, 1.5, nil, nil, false)).duration = 60
		self:spawn_object(DeathSplatter(self.pos.x + 1, self.pos.y + 2, 1, self.artefact.icon, Palette[self.artefact.icon], 2, 0, 0, self.pos.x + 6, self.pos.y + 10, 10)).duration = 40
		self:spawn_object(TwinDeathEffect(self.pos.x, self.pos.y))
		self:selection_flash(30)
		for _, artefact in self.world:get_objects_with_tag("artefact"):ipairs() do
            -- artefact:flash(30)
            artefact:flash(30)
            artefact:selection_flash(30)
        end
        self.artefact = nil
		self.rumble = 0
	end)
end

function Artefact:flash(time)
	local s = self.sequencer
	if self.flashing_coroutine then
		s:stop(self.flashing_coroutine)
	end
	self.flashing_coroutine = s:start(function()
        self.flashing = true
        s:wait(time or 20)
        self.flashing = false
        if self.flashing_coroutine then
            s:stop(self.flashing_coroutine)
        end
		self.flashing_coroutine = nil
    end)
end

function Artefact:selection_flash(time)
    local s = self.sequencer
	if self.selection_flash_coroutine then
		s:stop(self.selection_flash_coroutine)
	end
    self.selection_flash_coroutine = s:start(function()
        self.selection_flashing = true
        s:wait(time or 20)
        self.selection_flashing = false
        if self.selection_flash_coroutine then
            s:stop(self.selection_flash_coroutine)
        end
		self.selection_flash_coroutine = nil
    end)
end

function Artefact:gain_artefact(artefact)
	local s = self.sequencer
	self.gaining_artefact = true
    s:start(function()
		while self.waiting_for_animation do s:wait(1) end
        self.artefact = artefact
		self:play_sfx("pickup_artefact_gained", 0.8)
		self.gaining_artefact = false
		self:flash(10)
	end)
end

function Artefact:remove_artefact()
	local s = self.sequencer
	s:start(function()
        while self.waiting_for_animation do s:wait(1) end
		if self.gaining_artefact then return end
		self.artefact = nil
	end)
end

function Artefact:draw()
    local selection_flash = iflicker(self.tick, 3, 2) and self.selection_flashing
	
	if not selection_flash then
	local texture1 = (self.selected) and (textures.hud_artefact_slot2) or textures.hud_artefact_slot1
		graphics.drawp_centered(texture1, nil, 0, 0, 0)
	end

	if self.flashing and iflicker(self.tick, 3, 2) then
		return
	end

	if not self.artefact then
		return
	end

    local texture = self.artefact.icon
    local rumble_x, rumble_y = 0, 0
    if self.rumble > 0 then
		local size = self.rumble * 8
		rumble_x, rumble_y = rng:rand_sign() * size, rng:rand_sign() * size
	end
    graphics.drawp_centered(texture, nil, 0, rumble_x, rumble_y)
end

function Artefact:update_artefact(artefact)

end

function TwinDeathEffect:new(x, y)
    TwinDeathEffect.super.new(self, x, y)
	self.duration = 60
end

function TwinDeathEffect:draw(elapsed, tick, t)
    local size = 30 + elapsed * 16
	graphics.set_color(Color.red)
    graphics.rectangle_centered("line", 0, 0, size, size)
end

return Artefact
