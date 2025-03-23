local MainGame = BaseGame:extend("MainGame")
local GlobalState = Object:extend("GlobalState")
local GlobalGameState = Object:extend("GlobalGameState")
local PickupTable = require("obj.pickup_table")
local LevelBonus = require("levelbonus.LevelBonus")

function MainGame:new()
	MainGame.super.new(self)
	-- self.main_screen = Screens.TestPaletteCyclingScreen
    self.main_screen_class = Screens.MainScreen
	graphics.set_pre_canvas_draw_function(function()
		local clear_color = self:get_clear_color()
		if clear_color then
            graphics.set_clear_color(clear_color)
			graphics.clear(clear_color)
		end
	end)
end

function MainGame:load()
    MainGame.super.load(self)

    fonts.main_font = fonts["PixelOperatorMono8"]
    fonts.hud_font = fonts["PixelOperatorMono8"]
    fonts.main_font_bold = fonts["PixelOperatorMono8-Bold"]
	fonts.bonus_font = fonts.image_font1
    fonts.cn_jp_kr = fonts["quan8"]
end

function MainGame:update(dt)
	MainGame.super.update(self, dt)
    if game_state then
        game_state:update(dt)
    end


end

function MainGame:get_clear_color()
	local main_screen = self:get_main_screen()
	if main_screen then
		if main_screen.get_clear_color then
			return main_screen:get_clear_color()
		end
	end
	return Color.transparent
end

function MainGame:initialize_global_state()
	game_state = GlobalGameState()
	return GlobalState()
end

function GlobalState:new()
end

function GlobalState:reset_game_state()
	self:destroy_game_state()
	game_state = GlobalGameState()

end

function GlobalState:destroy_game_state()
	signal.cleanup(game_state)
    game_state = nil
end

GlobalGameState.max_upgrades = {
	fire_rate = 1,
	range = 2,
	bullets = 2,
    damage = 2,
    -- knockback = 1, -- combined with bullet speed
	bullet_speed = 2,
	-- boost = 1,
}

GlobalGameState.max_items = 8
GlobalGameState.max_hearts = 2
GlobalGameState.xp_until_upgrade = 22
GlobalGameState.xp_until_heart = 22
GlobalGameState.xp_until_item = 30

function GlobalGameState:new()
    self.level = 1
    self.wave = 1
    self.difficulty = 1
    self.enemies_killed = 0
    self.rescues_saved = 0
    self.score = 0
    self.score_multiplier = 1
    self.xp = 0

    self.rescue_chain = 0

    self.level_bonuses = {}
    self.all_bonuses = {}

    self.xp_until_upgrade = GlobalGameState.xp_until_upgrade
    self.xp_until_heart = 1
    -- self.xp_until_powerup = GlobalGameState.xp_until_powerup / 2
    self.xp_until_item = GlobalGameState.xp_until_item

    self.num_queued_upgrades = 0
    self.num_queued_items = 0
    self.num_queued_hearts = 0

	self.bullet_powerup = nil
	self.bullet_powerup_time = 0

    self.hearts = 0

    self.items = {

    }

    self.upgrades = {
        fire_rate = 0,
        range = 0,
        bullets = 0,
        damage = 0,
        bullet_speed = 0,
        -- boost = 0,
    }

    if debug.enabled then
        self.level = 1
		self.hearts = 0

        -- self.num_queued_upgrades = 100
        -- self.num_queued_powerups = 100
        self.num_queued_items = 100
        -- self.num_queued_hearts = 100
    end

    signal.register(self, "player_upgraded")
    signal.register(self, "player_heart_gained")
    signal.register(self, "player_powerup_gained")
    signal.register(self, "player_downgraded")
    signal.register(self, "xp_threshold_reached")

    if debug.enabled then
        -- for i = 1, 100 do
            -- table.pretty_print(self:get_random_available_upgrade())
        -- end
    end
end

function GlobalGameState:update(dt)
    if debug.enabled then
		dbg("xp", self.xp)
		dbg("xp_until_upgrade", self.xp_until_upgrade)
		dbg("xp_until_heart", self.xp_until_heart)
		dbg("xp_until_item", self.xp_until_item)
		dbg("num_queued_upgrades", self.num_queued_upgrades)
		dbg("num_queued_hearts", self.num_queued_hearts)
		dbg("num_queued_items", self.num_queued_items)
	end
end

function GlobalGameState:drain_bullet_powerup_time(dt)
	self.bullet_powerup_time = self.bullet_powerup_time - dt
	if self.bullet_powerup_time < 0 then
        self.bullet_powerup_time = 0
		self.bullet_powerup = nil
	end
end

function GlobalGameState:level_bonus(bonus_name)
    self.level_bonuses[bonus_name] = self.level_bonuses[bonus_name] or 0
    self.level_bonuses[bonus_name] = self.level_bonuses[bonus_name] + 1
	self.all_bonuses[bonus_name] = self.all_bonuses[bonus_name] or 0
	self.all_bonuses[bonus_name] = self.all_bonuses[bonus_name] + 1
end

function GlobalGameState:gain_xp(amount)
    self.xp = self.xp + amount
    self.xp_until_upgrade = self.xp_until_upgrade - amount
    self.xp_until_heart = self.xp_until_heart - amount
    -- self.xp_until_powerup = self.xp_until_powerup - amount
    self.xp_until_item = self.xp_until_item - amount
    if self.xp_until_upgrade <= 0 then
        self.xp_until_upgrade = self.xp_until_upgrade + GlobalGameState.xp_until_upgrade + rng.randi(-1, 1)
        self:on_upgrade_xp_threshold_reached()
    end
    if self.xp_until_heart <= 0 then
        self.xp_until_heart = self.xp_until_heart + GlobalGameState.xp_until_heart + rng.randi(-1, 1)
        self:on_heart_xp_threshold_reached()
    end
    -- if self.xp_until_powerup <= 0 then
    --     self.xp_until_powerup = self.xp_until_powerup + max(GlobalGameState.xp_until_powerup + rng.randi(-1, 1) - (self.level * 0.45), 8)
    --     self:on_powerup_xp_threshold_reached()
    -- end
    if self.xp_until_item <= 0 then
        self.xp_until_item = self.xp_until_item + GlobalGameState.xp_until_item + rng.randi(-1, 1)
        self:on_item_xp_threshold_reached()
    end
end

function GlobalGameState:on_level_start()
	self.level = self.level + 1
    self.any_room_failures = false
	self.level_bonuses = {}
end

function GlobalGameState:on_room_clear()
    self:level_bonus("room_clear")
	if not self.any_room_failures then
		self:level_bonus("all_rescues")
	end
end

function GlobalGameState:on_rescue(rescue_object)
    -- self.score_multiplier = self.score_multiplier + 0.1
    self.rescues_saved = self.rescues_saved + 1
	-- self:gain_xp(0.5)
    self.rescue_chain = self.rescue_chain + 1
	self:level_bonus("rescue")
end

function GlobalGameState:on_rescue_failed()
    -- self.score_multiplier = self.score_multiplier - 0.25
	self.rescue_chain = 0
	self.any_room_failures = true
end

function GlobalGameState:is_fully_upgraded()
    for k, v in pairs(self.upgrades) do
		if not GlobalGameState.max_upgrades[k] then
			return false
		end
        if v < GlobalGameState.max_upgrades[k] then
            return false
        end
    end
    return true
end

function GlobalGameState:gain_heart(heart)
    self.hearts = self.hearts + 1
	if self.hearts > GlobalGameState.max_hearts then
        self.hearts = GlobalGameState.max_hearts
		game_state:level_bonus("overheal")
    else
		signal.emit(self, "player_heart_gained", heart)
	end
end


function GlobalGameState:gain_powerup(powerup)
    if powerup.bullet_powerup then
		if powerup == self.bullet_powerup then
			self.bullet_powerup_time = self.bullet_powerup_time + seconds_to_frames(powerup.bullet_powerup_time - 1)
		else
			self.bullet_powerup = powerup
			self.bullet_powerup_time = seconds_to_frames(powerup.bullet_powerup_time - 1)
		end
	end
	signal.emit(self, "player_powerup_gained", powerup)
end

function GlobalGameState:get_bullet_powerup()
	return self.bullet_powerup
end

function GlobalGameState:lose_heart()
    self.hearts = self.hearts - 1
	if self.hearts < 0 then
		self.hearts = 0
	end
end

function GlobalGameState:on_enemy_killed()
	
end

function GlobalGameState:upgrade(upgrade)
	local type = upgrade.upgrade_type
    self.upgrades[type] = self.upgrades[type] + 1
    if self.upgrades[type] > GlobalGameState.max_upgrades[type] then
        self.upgrades[type] = GlobalGameState.max_upgrades[type]
    else
		signal.emit(self, "player_upgraded", upgrade)
	end

    if debug.enabled then
		-- for k, v in pairs(self.upgrades) do
		-- 	dbg("upgrade_" .. tostring(k), v)
		-- end
	end
end

function GlobalGameState:downgrade(upgrade)
    local type = upgrade.upgrade_type
	if self.upgrades[type] > 0 then
		self.upgrades[type] = self.upgrades[type] - 1
		if self.upgrades[type] < 0 then
			self.upgrades[type] = 0
		end
		signal.emit(self, "player_downgraded", upgrade)
	end
end

function GlobalGameState:random_downgrade()
    local tab = {}
	local any_upgrades = false
	for k, v in pairs(PickupTable.upgrades) do
		if game_state.upgrades[v.upgrade_type] and game_state.upgrades[v.upgrade_type] > 0 then
			table.insert(tab, v)
			any_upgrades = true
		end
	end
	if any_upgrades then
		local type = rng.choose(tab)
		self:downgrade(type)
	end
end

function GlobalGameState:on_upgrade_xp_threshold_reached()
    self.num_queued_upgrades = self.num_queued_upgrades + 1
	if not self:is_fully_upgraded() then
		signal.emit(self, "xp_threshold_reached", "upgrade")
	end
end

function GlobalGameState:on_heart_xp_threshold_reached()
    self.num_queued_hearts = self.num_queued_hearts + 1
	signal.emit(self, "xp_threshold_reached", "heart")
end

-- function GlobalGameState:on_powerup_xp_threshold_reached()
    -- self.num_queued_powerups = self.num_queued_powerups + 1
	-- signal.emit(self, "xp_threshold_reached", "powerup")
-- end

function GlobalGameState:on_item_xp_threshold_reached()
    self.num_queued_items = self.num_queued_items + 1
	signal.emit(self, "xp_threshold_reached", "item")
end

local MIN_SCORE_MULTIPLIER = 0.01
local MAX_CHAIN = 20
local EXTRA_CHAIN_MULTIPLIER = 0.685
local EXTRA_CHAIN_BASE = 1.4
local RESCUE_CHAIN_MULTIPLIER_CAP = 50

function GlobalGameState:get_score_multiplier()
    local multiplier = self.score_multiplier

    local rescue_chain_multiplier = self.rescue_chain
	local max_chain = MAX_CHAIN - 4

    if rescue_chain_multiplier > max_chain then
        local extra = rescue_chain_multiplier - max_chain
		
		local scaled_extra = (logb(extra + 1.50, EXTRA_CHAIN_BASE) * EXTRA_CHAIN_MULTIPLIER) + (extra * MIN_SCORE_MULTIPLIER - MIN_SCORE_MULTIPLIER)
        scaled_extra = min(scaled_extra, extra)

		rescue_chain_multiplier = max_chain + scaled_extra
	else
		rescue_chain_multiplier = self.rescue_chain
	end

	multiplier = multiplier + (rescue_chain_multiplier)
    multiplier = stepify_floor(clamp(multiplier, 1, RESCUE_CHAIN_MULTIPLIER_CAP), MIN_SCORE_MULTIPLIER)
	-- multiplier = multiplier + (self.rescue_chain * 0.5)
	return multiplier
end

function GlobalGameState:determine_score(score)
    return stepify_floor(score * self:get_score_multiplier(), 10)
end

function GlobalGameState:get_random_available_upgrade(allow_nil)
    if allow_nil == nil then
		allow_nil = true
	end
    local tab = {}
    for k, v in pairs(PickupTable.upgrades) do
        if not v.base then
			if not allow_nil then
				if GlobalGameState.max_upgrades[v.upgrade_type] then
					if self.upgrades[v.upgrade_type] < GlobalGameState.max_upgrades[v.upgrade_type] then
						table.insert(tab, v)
					end
				end
			else
				table.insert(tab, v)
			end
		end
    end

	local v = rng.weighted_choice(tab, "spawn_weight")
	if allow_nil and GlobalGameState.max_upgrades[v.upgrade_type] then
		if self.upgrades[v.upgrade_type] < GlobalGameState.max_upgrades[v.upgrade_type] then
            return v
        else
			return nil
		end
	end

	return v
end

function GlobalGameState:get_random_available_item()
    return rng.choose(table.values(PickupTable.items))
end

function GlobalGameState:get_random_powerup()
	local tab = {}
    for k, v in pairs(PickupTable.powerups) do
        if v.base then
            goto continue
        end
        if v.subtype ~= "powerup" then
            goto continue
        end
        table.insert(tab, v)
        ::continue::
    end
	local v = rng.weighted_choice(tab, "spawn_weight")

    return v
end

function GlobalGameState:get_random_heart()
    local heart = rng.choose(table.values(PickupTable.hearts))
	-- table.pretty_print(heart)
	return heart
end

function GlobalGameState:consume_upgrade()
    self.num_queued_upgrades = self.num_queued_upgrades - 1
end

-- function GlobalGameState:consume_powerup()
--     self.num_queued_powerups = self.num_queued_powerups - 1
-- end

function GlobalGameState:consume_heart()
    self.num_queued_hearts = self.num_queued_hearts - 1
end

function GlobalGameState:consume_item()
    self.num_queued_items = self.num_queued_items - 1
end

function GlobalGameState:add_score(score)
    self.score = self.score + score
end

return MainGame
