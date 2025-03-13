local Fungus = require("obj.Spawn.Enemy.BaseEnemy"):extend("Fungus")

local BASE_HP = 1
local BASE_HP_BIG = 2
local MAX_HP = 2

local PROPOGATE_CHILD_FREQUENCY_MODIFIER = 1.0

local HP_GAIN_FREQUENCY = 100
local PROPOGATE_FREQUENCY = 1
-- local PROPOGATE_FREQUENCY = 60
local PROPOGATE_VARIANCE_DEVIATION = 20
local HP_GAIN_AMOUNT = 1
local MIN_PLAYER_DISTANCE_FOR_GROWTH = 32

local PROPOGATE_RADIUS = 16
local MAX_FUNGI = 60

function Fungus:new(x, y, propogate_frequency)
    self.team = "neutral"
	self.hitbox_team = "enemy"
    self.max_hp = BASE_HP
	self.propogate_frequency = propogate_frequency or PROPOGATE_FREQUENCY
	self.hurt_bubble_radius = 3
	self.hurt_bubble_radius_big = 6
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
    self.death_sfx_volume = 0.5
	self.death_sfx = "hazard_fungus_die"
	self.hit_bubble_radius = nil
end

function Fungus:enter()
	self:hazard_init()
	self:add_to_spatial_grid("fungus_grid")
	self:add_tag("fungus")
	self:start_hp_gain_timer()
	self:start_propagate_timer()
    -- self:update_bubble_radii()
    self:start_draw_dots_timer()
end

function Fungus:start_draw_dots_timer()
	local time = 20 - clamp(self.hp * 5, 1, 10)
	self:start_tick_timer("draw_dots", time, function()
        self.draw_dots = true
		self:start_draw_dots_timer()
	end)
end

function Fungus:start_propagate_timer()
	self:start_tick_timer("propagate", max(rng.randfn(self.propogate_frequency, PROPOGATE_VARIANCE_DEVIATION), 10), function()
		if self.world:get_number_of_objects_with_tag("fungus") < MAX_FUNGI and self.big then
			self:propagate()
		end
		self:start_propagate_timer()
	end)
end


function Fungus:update_bubble_radii()
	if self.hp < BASE_HP_BIG then
        self:set_bubble_radius("hurt", "main", self.hurt_bubble_radius)
		-- self:set_bubble_radius("hit", "main", self.hit_bubble_radius)
	end
end

function Fungus:on_healed()
    if not self.big and not self.reached_max_hp and self.hp >= BASE_HP_BIG then
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
			self:add_hit_bubble(-2.5, 2, self.hit_bubble_radius_big, "main1", 1)
			self:add_hit_bubble(-2.5, -2, self.hit_bubble_radius_big, "main2", 1)
			self:add_hit_bubble(2.5, 2, self.hit_bubble_radius_big, "main3", 1)
			self:add_hit_bubble(2, -2, self.hit_bubble_radius_big, "main4", 1)
			-- self:add_hit_bubble(0, 0, self.hit_bubble_radius_big * 2, "main5", 1)
			-- self:set_bubble_radius("hit", "main", self.hit_bubble_radius_big)
			self.declump_radius = 16
			self.declump_mass = 2
		end)
	end
end

function Fungus:propagate()
	local x = self.pos.x
	local y = self.pos.y
    local radius = PROPOGATE_RADIUS
    local rect_x, rect_y, rect_w, rect_h = x - radius, y - radius, radius * 2, radius * 2

	local valid = true

	local test_x, test_y = rng.random_vec2_times(radius)

	local f = function(other)
		local real_x, real_y = self.pos.x + test_x, self.pos.y + test_y
        if real_x < self.world.room.left or real_x > self.world.room.right or real_y < self.world.room.top or real_y > self.world.room.bottom then
			valid = false
			return
		end
        if other == self then return end
        if not Object.is(other, Fungus) then return end
		if vec2_distance(other.pos.x, other.pos.y, real_x, real_y) > radius then return end
        valid = false
		
		local closest_player = self:get_closest_player()
		if closest_player then
			local closest_player_distance = vec2_distance(self.pos.x, self.pos.y, closest_player.pos.x, closest_player.pos.y)
			if closest_player_distance < MIN_PLAYER_DISTANCE_FOR_GROWTH then
				valid = false
				return
			end
		end
	end

    for i = 1, 10 do
		valid = true
        self.world.fungus_grid:each(rect_x, rect_y, rect_w, rect_h, f)
		if valid then break end
		test_x, test_y = rng.random_vec2_times(radius)
	end

	if valid then
		local fungus = self:spawn_object_relative(Fungus(0,0, self.propogate_frequency * PROPOGATE_CHILD_FREQUENCY_MODIFIER * clamp(rng.randfn(1, 0.4), 0.1, 1.9)), test_x, test_y)
		fungus.max_hp = BASE_HP
	end

end

function Fungus:start_hp_gain_timer()
	self:start_tick_timer("gain_hp", HP_GAIN_FREQUENCY * clamp(rng.randfn(1, 0.1), 0.5, 1.5), function()
		if self.world:get_number_of_objects_with_tag("fungus") < MAX_FUNGI and not self.big then
			-- self:propagate()
			self:heal(HP_GAIN_AMOUNT, true)
		end
		if self.hp < MAX_HP then
			self:start_hp_gain_timer()
		end
	end)
end

function Fungus:get_palette()
	return nil, floor(self.random_offset + self.world.tick / (self.big and 5 or 12))
end

function Fungus:get_sprite()
	return self.big and textures.hazard_mushroom2 or textures.hazard_mushroom1
end

local COLOR_MOD = 0.95
function Fungus:floor_draw()
    if self.draw_dots then
        local palette = Palette[self:get_sprite()]
        local color = palette:get_color(1)
        local vec_x, vec_y = rng.random_vec2_times(rng.randf(PROPOGATE_RADIUS * 0.0, PROPOGATE_RADIUS * (0.5 + self.hp / 10)))
		graphics.set_color(color.r * COLOR_MOD, color.g * COLOR_MOD, color.b * COLOR_MOD)
        graphics.circle("fill", vec_x, vec_y, rng.randf(0.5, 2) * (1 + self.hp / 5))
		self.draw_dots = false
	end
end

return Fungus
