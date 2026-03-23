local Fungus = BaseEnemy:extend("Fungus")

local BASE_HP = 1
local BASE_HP_BIG = 2
local MAX_HP = 2

local BASE_HP_FRIENDLY = 1.3
local BASE_HP_BIG_FRIENDLY = 2.6
local MAX_HP_FRIENDLY = 2.6
local HP_GAIN_AMOUNT_FRIENDLY = 1.3
local FRIENDLY_DAMAGE = 0.35 / 3

local HP_GAIN_FREQUENCY = 100
local PROPAGATE_FREQUENCY = 1
-- local PROPAGATE_FREQUENCY = 60
local PROPAGATE_VARIANCE_DEVIATION = 20
local HP_GAIN_AMOUNT = 1
local MIN_PLAYER_DISTANCE_FOR_GROWTH = 64

local PROPAGATE_RADIUS = 16
local MAX_FUNGI = 60
local MAX_FUNGI_HAZARDOUS = 90

local _current_propagator
local function _propagation_checker(other)
	_current_propagator:_is_valid_propagation_spot(other)
end

Fungus.spawn_sfx = "hazard_fungus_spawn"
Fungus.spawn_sfx_volume = 0.2
Fungus.cannot_hit_egg = true
Fungus.is_fungus = true
Fungus.max_hp = 1

function Fungus:new(x, y)
    self.team = "neutral"
    local friendly = game_state.artefacts.death_cap
    self.friendly = friendly
	self.hitbox_team = friendly and "player" or "enemy"
    self.max_hp = (friendly and BASE_HP_FRIENDLY or BASE_HP)
	self.highest_hp = (friendly and MAX_HP_FRIENDLY or MAX_HP)
    self.base_hp_big = friendly and BASE_HP_BIG_FRIENDLY or BASE_HP_BIG
	self.hp_gain_amount = friendly and HP_GAIN_AMOUNT_FRIENDLY or HP_GAIN_AMOUNT
	self.hurt_bubble_radius = 3
    self.hurt_bubble_radius_big = 6

	if friendly then
		self.hit_bubble_damage = FRIENDLY_DAMAGE
        self.hit_cooldown = 10
	end
    
	-- self.hit_bubble_radius = 1
	self.body_height = 4
	self.hit_bubble_radius_big = 2
    Fungus.super.new(self, x, y)

    -- self.z_index = 100
    -- self:lazy_mixin(Mixins.Fx.FloorCanvasPush)
	self.declump_radius = 16
    self.declump_mass = 1
	self.bullet_passthrough = true
	self.declump_radius = 6
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self.applying_physics = false
	self.drag = 1.0
    self.self_declump_modifier = 0.0
    self:lazy_mixin(Mixins.Behavior.EntityDeclump)
	self.declump_force = self.declump_force * 0.35
	self.passive_declump = true -- Fungi don't move, so let other objects handle the declump

    self.death_sfx_volume = 0.5
	self.death_sfx = "hazard_fungus_die"
    self.hit_bubble_radius = nil
    self.palette = nil
    if self.friendly then
        self.intangible = true
        self:start_tick_timer("spawn_invulnerability", 7, self.end_spawn_invulnerability, self)
    end
end

function Fungus:end_spawn_invulnerability()
    self.intangible = false
end

function Fungus:max_fungi()
    return self.world.room.curse_hazardous and MAX_FUNGI_HAZARDOUS or MAX_FUNGI
end

function Fungus:enter()
	self:hazard_init()
	self:add_to_spatial_grid("fungus_grid")
	self:add_tag("fungus")
	self:start_hp_gain_timer()
	self:start_propagate_timer()
	-- self:update_bubble_radii()
	self:start_draw_dots_timer()
	if self.friendly then
		signal.connect(self.world, "quick_wave_cleared", self, "on_quick_wave_cleared", function(spare_time, spare_ratio)
			self:on_quick_wave_cleared(spare_time, spare_ratio)
		end)
	end
end

function Fungus:enter_shared()
	Fungus.super.enter_shared(self)
	if self.friendly then
		self:remove_tag("enemy")
	end
end

function Fungus:start_draw_dots_timer()
	local time = 20 - clamp(self.hp * 5, 1, 10)
	self:start_tick_timer("draw_dots", time, function()
        self.draw_dots = true
		self:start_draw_dots_timer()
	end)
end

function Fungus:filter_melee_attack(bubble)
	if self.friendly then
		if bubble.parent and bubble.parent.team == "player" then return false end
	end
	
	if bubble.parent and bubble.parent.is_artefact then
		return false
	end
	
	return true
end

function Fungus:modify_received_damage(damage, object)
	if self.friendly and object.is_base_enemy then
		return damage * 0.5
	end
	return damage
end

function Fungus:get_propagate_delay()
    local base = max(rng:randfn(PROPAGATE_FREQUENCY, PROPAGATE_VARIANCE_DEVIATION), 10)
    local scale = self.friendly and self.world.fungi_propagate_speed_scale or 1
    return max(base * scale, 1)
end

function Fungus:start_propagate_timer()
    self:start_tick_timer("propagate", self:get_propagate_delay(),
        function()
            if self.world:get_number_of_objects_with_tag("fungus") < self:max_fungi() and self.big then
                if not self.friendly or self.world:is_fungi_propagation_allowed() then
                    self:propagate()
                end
            end
            self:start_propagate_timer()
        end)
end

function Fungus:on_quick_wave_cleared(spare_time, spare_ratio)
    -- reset timers with rng variance so all fungi don't fire at once
    self:do_heal()

    if self.world:get_number_of_objects_with_tag("fungus") < self:max_fungi() and self.big then
        self:propagate()
    end
    self:start_propagate_timer()
    -- self:start_tick_timer("propagate", self:get_propagate_delay(),
    --     function()
    --         if self.world:get_number_of_objects_with_tag("fungus") < self:max_fungi() and self.big then
    --             if not self.friendly or self.world:is_fungi_propagation_allowed() then
    --                 self:propagate()
    --             end
    --         end
    --         self:start_propagate_timer()
    --     end)
    -- self:start_hp_gain_timer()
end

-- function Fungus:get_damage(other)
--     if self.friendly then
--         local hit_bubble = self:get_hit_bubble("main1")
--         if hit_bubble then
--             local damage = hit_bubble.damage
--             if other.is_enemy_bullet then
--                 return damage * 1.5
--             end
--             return damage
--         end
--     end
--     return Fungus.super.get_damage(self, other)
-- end

-- function Fungus:hit_other(other)
--     if other.is_enemy_bullet then
--         other:start_tick_timer("fungal_slow", 6)
--     end
-- end


function Fungus:update_bubble_radii()
	if self.hp < self.base_hp_big then
        self:set_bubble_radius("hurt", "main", self.hurt_bubble_radius)
		-- self:set_bubble_radius("hit", "main", self.hit_bubble_radius)
	end
end

function Fungus:on_healed()
    if not self.big and not self.reached_max_hp and self.hp >= self.base_hp_big then
        self.reached_max_hp = true
        local s = self.sequencer
        s:start(function()
			local can_grow = false
			while not can_grow do
				can_grow = true
				local closest_player = self:get_closest_player()
                if closest_player then
                    local closest_player_distance = vec2_distance(self.pos.x, self.pos.y, closest_player.pos.x,
                        closest_player.pos.y)
                    if closest_player_distance < MIN_PLAYER_DISTANCE_FOR_GROWTH then
                        can_grow = false
                    end
                end
				s:wait(10)
			end
			self.big = true
			self:set_bubble_radius("hurt", "main", self.hurt_bubble_radius_big)
			local damage = self.friendly and FRIENDLY_DAMAGE or 1
			self:add_hit_bubble(-2.5, 2, self.hit_bubble_radius_big, "main1", damage)
			self:add_hit_bubble(-2.5, -2, self.hit_bubble_radius_big, "main2", damage)
			self:add_hit_bubble(2.5, 2, self.hit_bubble_radius_big, "main3", damage)
			self:add_hit_bubble(2, -2, self.hit_bubble_radius_big, "main4", damage)
			-- self:add_hit_bubble(0, 0, self.hit_bubble_radius_big * 2, "main5", 1)
			-- self:set_bubble_radius("hit", "main", self.hit_bubble_radius_big)
			self.declump_radius = 16
			self.declump_mass = 2
		end)
	end
end

function Fungus:_is_valid_propagation_spot(other)
	if not self._propagate_valid then return end

	local real_x, real_y = self.pos.x + self._propagate_test_x, self.pos.y + self._propagate_test_y
	if real_x < self.world.room.left or real_x > self.world.room.right or real_y < self.world.room.top or real_y > self.world.room.bottom then
		self._propagate_valid = false
		return
	end

	if other == self then return end
	if not Object.is(other, Fungus) then return end
	if vec2_distance(other.pos.x, other.pos.y, real_x, real_y) > PROPAGATE_RADIUS then return end

	self._propagate_valid = false
end

function Fungus:propagate()
    if self.world.room.nofungus then return end

	local closest_player = self:get_closest_player()
	if closest_player then
		local closest_player_distance = vec2_distance(self.pos.x, self.pos.y, closest_player.pos.x, closest_player.pos.y)
		if closest_player_distance < MIN_PLAYER_DISTANCE_FOR_GROWTH then
			return
		end
	end
	
	local x = self.pos.x
	local y = self.pos.y
    local radius = PROPAGATE_RADIUS
    local rect_x, rect_y, rect_w, rect_h = x - radius, y - radius, radius * 2, radius * 2

    for i = 1, 10 do
		self._propagate_valid = true
		self._propagate_test_x, self._propagate_test_y = rng:random_vec2_times(radius)

		_current_propagator = self
        self.world.fungus_grid:each(rect_x, rect_y, rect_w, rect_h, _propagation_checker)
		_current_propagator = nil
		
		if self._propagate_valid then break end
	end

	if self._propagate_valid then
		local fungus = self:spawn_object_relative(Fungus(0,0), self._propagate_test_x, self._propagate_test_y)
	end

	self._propagate_valid = nil
	self._propagate_test_x = nil
	self._propagate_test_y = nil
end

function Fungus:get_hp_gain_delay()
	local base = HP_GAIN_FREQUENCY * clamp(rng:randfn(1, 0.1), 0.5, 1.5)
	local scale = self.friendly and self.world.fungi_propagate_speed_scale or 1
	return max(base * scale, 1)
end

function Fungus:start_hp_gain_timer()
    self:start_tick_timer("gain_hp", self:get_hp_gain_delay(), function()
        self:do_heal()
    end)
end

function Fungus:get_time_scale()
    if self.friendly then
        return 1
    end
    return Fungus.super.get_time_scale(self)
end

function Fungus:do_heal()
    if self.hp < self.highest_hp then
        if self.world:get_number_of_objects_with_tag("fungus") < self:max_fungi() and not self.big then
            -- local scale = self.friendly and self.world.fungi_propagate_speed_scale or 1
            local scale = 1
            self:heal(min(self.hp_gain_amount / max(scale, 0.01), self.highest_hp - self.hp), true)
        end
    end
    self:start_hp_gain_timer()
    -- end
end

function Fungus:get_palette()
	return nil, floor(self.random_offset + gametime.tick / (self.big and 5 or 12))
end

function Fungus:draw()
    -- if (self.friendly and iflicker(gametime.tick + self.random_offset, 1, 5)) then
		-- return
	-- end
	Fungus.super.draw(self)
end

function Fungus:get_sprite()	
    if not (self.friendly) then
        return self.big and textures.hazard_mushroom2 or textures.hazard_mushroom1
    end
	if iflicker(gametime.tick + self.random_offset, 1, 2) then
		return self.big and textures.hazard_friendly_mushroom_alt2 or textures.hazard_friendly_mushroom_alt1
	end
	return self.big and textures.hazard_friendly_mushroom2 or textures.hazard_friendly_mushroom1
end

local COLOR_MOD = 0.95
function Fungus:floor_draw()
    if self.draw_dots then
        local palette = Palette[self:get_sprite()]
        local color = palette:get_color(1)
        local vec_x, vec_y = rng:random_vec2_times(rng:randf(PROPAGATE_RADIUS * 0.0, PROPAGATE_RADIUS * (0.5 + self.hp / 10)))
		graphics.set_color(color.r * COLOR_MOD, color.g * COLOR_MOD, color.b * COLOR_MOD)
        graphics.circle("fill", vec_x, vec_y, rng:randf(0.5, 2) * (1 + self.hp / 5))
		self.draw_dots = false
	end
end

return Fungus
