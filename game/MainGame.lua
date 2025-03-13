local MainGame = BaseGame:extend("MainGame")
local GlobalState = Object:extend("GlobalState")
local GlobalGameState = Object:extend("GlobalGameState")
local PickupTable = require("obj.pickup_table")
local LevelBonus = require("levelbonus.LevelBonus")

function MainGame:new()
	MainGame.super.new(self)
	-- self.main_screen = Screens.TestPaletteCyclingScreen
	self.main_screen = Screens.MainScreen
end

function MainGame:load()
	MainGame.super.load(self)
    graphics.load_image_font("score_pickup_font", "font_score_pickup", "0123456789")
    graphics.load_image_font("score_pickup_font_white", "font_score_pickup_white", "0123456789")
    graphics.load_image_font("image_font1", "font_font1", " ABCDEFGHIJKLMNOPQRSTUVWXYZ+-")
    fonts.main_font = fonts["PixelOperatorMono8"]
    fonts.hud_font = fonts["PixelOperatorMono8"]
    fonts.main_font_bold = fonts["PixelOperatorMono8-Bold"]
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
GlobalGameState.xp_until_upgrade = 16
GlobalGameState.xp_until_heart = 18
GlobalGameState.xp_until_powerup = 20
GlobalGameState.xp_until_item = 25

function GlobalGameState:new()
    self.level = 1
    self.wave = 1
    self.difficulty = 1
    self.enemies_killed = 0
    self.rescues_saved = 0
    self.score = 0
    self.score_multiplier = 1
    self.xp = 0

    -- self.rescue_chain = 0

    self.level_bonuses = {}
    self.all_bonuses = {}

    self.xp_until_upgrade = GlobalGameState.xp_until_upgrade
    self.xp_until_heart = GlobalGameState.xp_until_heart
    self.xp_until_powerup = GlobalGameState.xp_until_powerup / 2
    self.xp_until_item = GlobalGameState.xp_until_item

    self.num_queued_upgrades = 0
    self.num_queued_powerups = 0
    self.num_queued_items = 0
    self.num_queued_hearts = 0

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

        -- self.num_queued_upgrades = 100
        -- self.num_queued_powerups = 100
        -- self.num_queued_items = 100
        -- self.num_queued_hearts = 100
    end

    signal.register(self, "player_upgraded")
    signal.register(self, "player_heart_gained")
    signal.register(self, "player_downgraded")
    signal.register(self, "xp_threshold_reached")

    if debug.enabled then
        for i = 1, 100 do
            table.pretty_print(self:get_random_available_upgrade())
        end
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
    self.xp_until_powerup = self.xp_until_powerup - amount
    self.xp_until_item = self.xp_until_item - amount
    if self.xp_until_upgrade <= 0 then
        self.xp_until_upgrade = self.xp_until_upgrade + GlobalGameState.xp_until_upgrade + rng.randi(-1, 1)
        self:on_upgrade_xp_threshold_reached()
    end
    if self.xp_until_heart <= 0 then
        self.xp_until_heart = self.xp_until_heart + GlobalGameState.xp_until_heart + rng.randi(-1, 1)
        self:on_heart_xp_threshold_reached()
    end
    if self.xp_until_powerup <= 0 then
        self.xp_until_powerup = self.xp_until_powerup + max(GlobalGameState.xp_until_powerup + rng.randi(-1, 1) - (self.level * 0.35), 8)
        self:on_powerup_xp_threshold_reached()
    end
    if self.xp_until_item <= 0 then
        self.xp_until_item = self.xp_until_item + GlobalGameState.xp_until_item + rng.randi(-1, 1)
        self:on_item_xp_threshold_reached()
    end
end

function GlobalGameState:on_room_clear()
    local xp = 6 + floor(self.level / 7)
	self:gain_xp(xp)
end

function GlobalGameState:on_rescue(rescue_object)
    -- self.score_multiplier = self.score_multiplier + 0.1
    self.rescues_saved = self.rescues_saved + 1
	-- self:gain_xp(0.5)
	-- self.rescue_chain = self.rescue_chain + 1
end

function GlobalGameState:on_rescue_failed()
    -- self.score_multiplier = self.score_multiplier - 0.25
	-- self.rescue_chain = 0
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
		for k, v in pairs(self.upgrades) do
			dbg("upgrade_" .. tostring(k), v)
		end
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

function GlobalGameState:on_powerup_xp_threshold_reached()
    self.num_queued_powerups = self.num_queued_powerups + 1
	signal.emit(self, "xp_threshold_reached", "powerup")
end

function GlobalGameState:on_item_xp_threshold_reached()
    self.num_queued_items = self.num_queued_items + 1
	signal.emit(self, "xp_threshold_reached", "item")
end

function GlobalGameState:get_score_multiplier()
    local multiplier = self.score_multiplier
	-- multiplier = multiplier + (self.rescue_chain * 0.5)
	return stepify_floor(clamp(multiplier, 1, 999.9), 0.025)
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
    return rng.choose(table.values(PickupTable.powerups))
end

function GlobalGameState:get_random_heart()
    local heart = rng.choose(table.values(PickupTable.hearts))
	-- table.pretty_print(heart)
	return heart
end

function GlobalGameState:consume_upgrade()
    self.num_queued_upgrades = self.num_queued_upgrades - 1
end

function GlobalGameState:consume_powerup()
    self.num_queued_powerups = self.num_queued_powerups - 1
end

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
