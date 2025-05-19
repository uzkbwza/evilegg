local MainGame = BaseGame:extend("MainGame")
local GlobalState = Object:extend("GlobalState")
GlobalGameState = Object:extend("GlobalGameState")
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

    -- fonts.main_font = fonts["PixelOperatorMono8"]
    -- fonts.hud_font = fonts["PixelOperatorMono8"]
    -- fonts.main_font_bold = fonts["PixelOperatorMono8-Bold"]
    -- fonts.cn_jp_kr = fonts["quan8"]
    fonts.main_font = fonts.depalettized.image_font2
    fonts.hud_font = fonts.depalettized.image_font2
	fonts.main_font_bold = fonts.depalettized.image_font2
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
	bullets = 1,
    damage = 1,
    -- knockback = 1, -- combined with bullet speed
	bullet_speed = 1,
	-- boost = 1,
}

GlobalGameState.max_artefacts = 8
GlobalGameState.max_hearts = 2
GlobalGameState.xp_until_upgrade = 2600
GlobalGameState.xp_until_heart = 3500
GlobalGameState.xp_until_artefact = 3000

function GlobalGameState:new()
	self.enable_adaptive_difficulty = false
    self.level = 1
    self.wave = 1
    self.difficulty = 1
    self.enemies_killed = 0
	self.rescues_saved = 0
	self.good_ending = false
	self.rescues_saved_this_level = 0
    self.score = 0
    self.score_multiplier = 1
    self.xp = 0
    self.game_time = 0
	self.rescue_chain_bonus = 0

    self.rescue_chain = 0

    self.level_bonuses = {}
	self.all_bonuses = {}
	self.level_scores = {}

    self.xp_until_upgrade = GlobalGameState.xp_until_upgrade
    self.xp_until_heart = 14
    self.xp_until_upgrade = 1020
    -- self.xp_until_powerup = GlobalGameState.xp_until_powerup / 2
    self.xp_until_artefact = 1800

	self.upgrade_xp_target = self.xp + self.xp_until_upgrade
	self.heart_xp_target = self.xp + self.xp_until_heart
	self.artefact_xp_target = self.xp + self.xp_until_artefact

	self.reached_upgrade_xp_at = 0
	self.reached_heart_xp_at = 0
	self.reached_artefact_xp_at = 0

    self.num_queued_upgrades = 0
    self.num_queued_artefacts = 0
    self.num_queued_hearts = 0

	self.egg_rooms_cleared = 0

	self.bullet_powerup = nil
	self.bullet_powerup_time = 0

    self.game_over = false

	self.leaderboard_category = debug.enabled and leaderboard.default_category

	self.used_sacrificial_twin = false

	self.hearts = 1
	
	self.total_damage_taken = 1

	self.rescue_chain_difficulty = 0
	self.highest_rescue_chain = 0

	self.bonus_difficulty_modifier = 0

	self.aggression_bonus = 0

    self.artefacts = {

    }

    self.artefact_slots = {
		
	}

	self.last_spawned_artefacts = {
    }
	
    self.artefacts_destroyed = {

	}

	self.secondary_weapon = nil
	self.secondary_weapon_ammo = 0
	
	self.recently_selected_artefacts = {}
	self.recently_selected_upgrades = {}
	self.selected_artefact_slot = 1

    self.upgrades = {
        fire_rate = 0,
        range = 0,
        bullets = 0,
        damage = 0,
        bullet_speed = 0,
        -- boost = 0,
    }

    signal.register(self, "player_upgraded")
    signal.register(self, "player_heart_gained")
	signal.register(self, "player_heart_lost")
    signal.register(self, "player_powerup_gained")
    signal.register(self, "player_downgraded")
    signal.register(self, "xp_threshold_reached")
	signal.register(self, "player_artefact_gained")
	signal.register(self, "player_artefact_removed")
    signal.register(self, "player_artefact_slot_changed")
	signal.register(self, "player_secondary_weapon_gained")
	signal.register(self, "player_secondary_weapon_lost")
	signal.register(self, "tried_to_use_secondary_weapon_with_no_ammo")
	signal.register(self, "secondary_weapon_ammo_used")
	signal.register(self, "secondary_weapon_ammo_gained")
	signal.register(self, "used_sacrificial_twin")
	signal.register(self, "hatched")
	signal.register(self, "greenoid_harmed")

	self.score_categories = {}

    self.skip_tutorial = usersettings.skip_tutorial or self.level > 1
	
	
    if debug.enabled then
		-- self.score = 999999000
		-- self.hearts = 0
        self.level = 30
		self.hearts = self.max_hearts
        -- self.num_queued_artefacts = 1
		self:gain_artefact(PickupTable.artefacts.SwordSecondaryWeapon)
		self.upgrades.fire_rate = self.max_upgrades.fire_rate
		self.upgrades.range = self.max_upgrades.range
		self.upgrades.bullets = self.max_upgrades.bullets
		self.upgrades.damage = self.max_upgrades.damage
        self.upgrades.bullet_speed = self.max_upgrades.bullet_speed

    end
end

function GlobalGameState:update(dt)

	if debug.enabled then
		-- dbg("xp", self.xp)
		-- dbg("xp_until_upgrade", self.xp_until_upgrade)
		-- dbg("xp_until_heart", self.xp_until_heart)
		-- dbg("xp_until_artefact", self.xp_until_artefact)
		-- dbg("num_queued_upgrades", self.num_queued_upgrades)
		-- dbg("num_queued_hearts", self.num_queued_hearts)
		-- dbg("num_queued_artefacts", self.num_queued_artefacts)
		dbg("difficulty_modifier", self:get_difficulty_modifier())
		dbg("bonus_difficulty_modifier", self.bonus_difficulty_modifier)
		dbg("aggression_bonus", self.aggression_bonus)
	end
	
	if not self.game_over then
		self.game_time = self.game_time + dt
	end
end

function GlobalGameState:on_hatched()
    self.hatched = true
	signal.emit(self, "hatched")
end

function GlobalGameState:get_upgrade_ratio()
	local total = 0
	local max_total = 0
	for upgrade_type, max_upgrade in pairs(GlobalGameState.max_upgrades) do
		total = total + self.upgrades[upgrade_type]
		max_total = max_total + max_upgrade
	end
	return total / max_total
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

function GlobalGameState:set_selected_artefact_slot(slot)
    local old = self.selected_artefact_slot
    self.selected_artefact_slot = slot
    if old ~= slot then
        signal.emit(self, "player_artefact_slot_changed", slot, old)
    end
end


function GlobalGameState:gain_artefact(artefact)
    if self.artefacts[artefact.key] then
        return
    end
	
    if artefact.is_secondary_weapon then
		self:gain_secondary_weapon(artefact)
		return
	end

	-- if self.artefact_slots[self.selected_artefact_slot] then
	self:remove_artefact(self.selected_artefact_slot)
	-- end

    self.artefact_slots[self.selected_artefact_slot] = artefact

	local slot = self.selected_artefact_slot
	
    self.artefacts[artefact.key] = { slot = self.selected_artefact_slot, artefact = artefact }

	
	local found_free_space = false
	for i = 1, GlobalGameState.max_artefacts do
		if not self.artefact_slots[i] then
			self:set_selected_artefact_slot(i)
			found_free_space = true
			break
		end
	end
	if not found_free_space then
		self:set_selected_artefact_slot(self.selected_artefact_slot + 1)
		if self.selected_artefact_slot > GlobalGameState.max_artefacts then
			self:set_selected_artefact_slot(1)
		end
	end

	signal.emit(self, "player_artefact_gained", artefact, slot)
end

function GlobalGameState:gain_secondary_weapon(artefact)
    local new_ammo = artefact.starting_ammo
    if self.secondary_weapon then
        if self.secondary_weapon == artefact then
            new_ammo = self.secondary_weapon_ammo + artefact.starting_ammo
            if new_ammo > artefact.ammo then
                new_ammo = artefact.ammo
            end
        else
            self:lose_secondary_weapon()
        end
    end

    self.secondary_weapon = artefact
    self.secondary_weapon_ammo = new_ammo

    signal.emit(self, "player_secondary_weapon_gained", artefact)
end

function GlobalGameState:on_tried_to_use_secondary_weapon_with_no_ammo()
	signal.emit(self, "tried_to_use_secondary_weapon_with_no_ammo")
end


function GlobalGameState:lose_secondary_weapon()
    self.secondary_weapon = nil
    self.secondary_weapon_ammo = 0
    signal.emit(self, "player_secondary_weapon_lost")
end

function GlobalGameState:can_use_secondary_weapon()
	return self.secondary_weapon and self.secondary_weapon_ammo >= self.secondary_weapon.ammo_needed_per_use
end

function GlobalGameState:use_secondary_weapon_ammo(amount)
    if not self.secondary_weapon then
        return
    end
	local old = self.secondary_weapon_ammo
	amount = amount or self.secondary_weapon.ammo_needed_per_use
	self.secondary_weapon_ammo = self.secondary_weapon_ammo - amount
	if self.secondary_weapon_ammo <= 0 then
		self.secondary_weapon_ammo = 0
	end
	self.used_secondary_weapon_this_level = true
	
	signal.emit(self, "secondary_weapon_ammo_used", amount, old, self.secondary_weapon_ammo)
end

function GlobalGameState:gain_secondary_weapon_ammo(amount)
    local old = self.secondary_weapon_ammo
	self.secondary_weapon_ammo = self.secondary_weapon_ammo + amount
	if self.secondary_weapon_ammo > self.secondary_weapon.ammo then
		self.secondary_weapon_ammo = self.secondary_weapon.ammo
	end
	signal.emit(self, "secondary_weapon_ammo_gained", amount, old, self.secondary_weapon_ammo)
end

function GlobalGameState:remove_artefact(slot)
    if not self.artefact_slots[slot] then
        return
    end
    local artefact = self.artefact_slots[slot]
	
	self.artefacts[artefact.key] = nil
    self.artefact_slots[slot] = nil

    if artefact.remove_function then
		artefact.remove_function(self, slot)
	end

	signal.emit(self, "player_artefact_removed", artefact, slot)
end

function GlobalGameState:on_game_over()
	self.game_over = true
    savedata:add_category_death(self.leaderboard_category)
    savedata:set_save_data("death_count", savedata.death_count + 1)
	leaderboard.add_death()
end

function GlobalGameState:on_egg_room_cleared()
    self.egg_rooms_cleared = self.egg_rooms_cleared + 1
	self:level_bonus("elevator_killed")
end

function GlobalGameState:gain_xp(amount)
	if self.game_over then return end
    self.xp = self.xp + amount

	if not self:is_fully_upgraded() then
		local ratio = remap_clamp(self:get_upgrade_ratio(), 0.0, 5/7, 2.0, 0.4)
		local amount = (amount) * ratio
		-- print(self:get_upgrade_ratio(), ratio)
		self.xp_until_upgrade = self.xp_until_upgrade - amount
	end
	self.xp_until_heart = self.xp_until_heart - amount
    -- self.xp_until_powerup = self.xp_until_powerup - amount
	self.xp_until_artefact = self.xp_until_artefact - amount
    if self.xp_until_upgrade <= 0 then
		self.xp_until_upgrade = self.xp_until_upgrade + (GlobalGameState.xp_until_upgrade + rng.randi(-100, 100))
        self:on_upgrade_xp_threshold_reached()
    end
	if self.xp_until_heart <= 0 then
        self.xp_until_heart = self.xp_until_heart + GlobalGameState.xp_until_heart + rng.randi(-100, 100)
        self:on_heart_xp_threshold_reached()
    end
    -- if self.xp_until_powerup <= 0 then
    --     self.xp_until_powerup = self.xp_until_powerup + max(GlobalGameState.xp_until_powerup + rng.randi(-1, 1) - (self.level * 0.45), 8)
    --     self:on_powerup_xp_threshold_reached()
    -- end
    if self.xp_until_artefact <= 0 then
        self.xp_until_artefact = self.xp_until_artefact + GlobalGameState.xp_until_artefact + rng.randi(-100, 100)
        self:on_artefact_xp_threshold_reached()
    end
end

function GlobalGameState:on_damage_taken()
	self.any_damage_taken = true
	self.total_damage_taken = self.total_damage_taken + 1
end

function GlobalGameState:apply_level_bonus_difficulty(bonus)
	self.bonus_difficulty_modifier = self.bonus_difficulty_modifier + (bonus or 0)
end

function GlobalGameState:on_level_start()
	table.insert(self.level_scores, self.score)
	self.level = self.level + 1
	self.boss_level = false
    self.any_room_failures = false
	self.any_damage_taken = false
    self.aggression_bonus = 0
	
	self.harmed_noid = false
    self.level_bonuses = {}
	self.rescues_saved_this_level = 0
	self.used_secondary_weapon_this_level = false
    if debug.enabled then
        print("--- Score Categories ---")
        local sum = 0
        for k, v in pairs(self.score_categories) do
            sum = sum + v
        end
        for k, v in pairs(self.score_categories) do
            local percent = (v / sum) * 100
            print(string.format("%s: %d (%.2f%%)", k, v, percent))
        end
        print("------------------------")
    end
    self.bonus_difficulty_modifier = approach(self.bonus_difficulty_modifier, 0,
    stepify(self.bonus_difficulty_modifier * 0.2, 0.05))
	if self.secondary_weapon then
        self:gain_secondary_weapon_ammo(self.secondary_weapon.ammo_gain_per_level)
	end
end

function GlobalGameState:on_room_clear()
	if self.aggression_bonus > 0 and not self.boss_level then
		self:level_bonus("aggression_bonus")
	end

	if not self.final_room_cleared then
		self:level_bonus("room_clear")
	else
		self:level_bonus("final_room_clear")
	end

	local perfect = true
	if not self.any_room_failures and self.rescues_saved_this_level > 0 then
		self:level_bonus("all_rescues")
	else
		perfect = false
	end
	if not self.any_damage_taken then
		self:level_bonus("no_damage")
	else
		perfect = false
	end

	if self.harmed_noid then
		perfect = false
	end

	if perfect then
		self:level_bonus("perfect")
	end
	if not self.used_secondary_weapon_this_level then
		self:level_bonus("ammo_saver")
	end
end

function GlobalGameState:on_final_room_entered()
    self.final_room_entered = true
end

function GlobalGameState:on_final_room_cleared()
	self.final_room_cleared = true
	self.good_ending = true
end

local RESCUE_CHAIN_MULTIPLIER_CAP = 20

function GlobalGameState:on_rescue(rescue_object)
    -- self.score_multiplier = self.score_multiplier + 0.1
    self.rescues_saved = self.rescues_saved + 1
	self.rescues_saved_this_level = self.rescues_saved_this_level + 1
	-- self:gain_xp(0.5)
    self.rescue_chain = self.rescue_chain + 1
    self.rescue_chain_bonus = self.rescue_chain_bonus + 1
	self.rescue_chain_bonus = min(self.rescue_chain_bonus, RESCUE_CHAIN_MULTIPLIER_CAP)
	self.rescue_chain_difficulty = min(self.rescue_chain_difficulty + 1, 30)
	self.highest_rescue_chain = max(self.highest_rescue_chain, self.rescue_chain)

	self:level_bonus("rescue")
end

function GlobalGameState:on_rescue_failed()
    -- self.score_multiplier = self.score_multiplier - 0.25
	self.rescue_chain_difficulty = max(self.rescue_chain_difficulty - 12, 0)
    self.rescue_chain = 0
    self.any_room_failures = true
end

function GlobalGameState:greenoid_harm_penalty()
	self:level_bonus("harmed_noid")
end

function GlobalGameState:on_greenoid_harmed()
	self.harmed_noid = true
    self.rescue_chain_bonus = self.rescue_chain_bonus - 3
    if self.rescue_chain_bonus < 0 then
        self.rescue_chain_bonus = 0
    end
	signal.emit(self, "greenoid_harmed")
end

function GlobalGameState:get_max_upgrade(upgrade_type)
	local offset = 0
    if self.artefacts.more_bullets and upgrade_type == "bullets" then
		offset = offset + 1
	end
    return self.max_upgrades[upgrade_type] + offset
end

function GlobalGameState:is_fully_upgraded()
    for k, v in pairs(self.upgrades) do
        if not self:get_max_upgrade(k) then
            return false
        end
        if v < self:get_max_upgrade(k) then
            return false
        end
    end
    return true
end

function GlobalGameState:add_kill()
	if self.game_over then return end
    self.enemies_killed = self.enemies_killed + 1
end

function GlobalGameState:add_score_multiplier(multiplier)
	if self.game_over then return end
    self.score_multiplier = self.score_multiplier + multiplier
	if self.score_multiplier < 1 then
		self.score_multiplier = 1
	end
end

function GlobalGameState:get_run_data_table()

	local artefacts = {}

	for i=1, GlobalGameState.max_artefacts do
		artefacts[i] = self.artefact_slots[i] and self.artefact_slots[i].key or "none"
	end

	return {
		name = savedata.name,
        uid = savedata.uid,
		score = self.score,
		--- extra stuff
		timestamp = os.time(),
		kills = self.enemies_killed,
		level = self.level,
		category = self.leaderboard_category,
		rescues = self.rescues_saved,
		artefacts = artefacts,
		game_time = self.game_time,
		secondary_weapon = self.secondary_weapon and self.secondary_weapon.key,
		good_ending = self.good_ending,
		damage_taken = self.total_damage_taken,
		highest_rescue_chain = self.highest_rescue_chain
	}
end

function GlobalGameState:gain_heart(heart)
    self.hearts = self.hearts + 1
	if self.hearts > GlobalGameState.max_hearts then
        self.hearts = GlobalGameState.max_hearts
		if self.artefacts.stone_trinket and not self:is_fully_upgraded() then
			local upgrade = self:get_random_available_upgrade(false)
			if upgrade then
				self:upgrade(upgrade)
			end
		end
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

function GlobalGameState:get_score_breakdown()

end

function GlobalGameState:lose_heart()
    if self.hearts > 0 then
        self.hearts = self.hearts - 1
		signal.emit(self, "player_heart_lost")
    end
end

function GlobalGameState:upgrade(upgrade)
	local type = upgrade.upgrade_type
    self.upgrades[type] = self.upgrades[type] + 1
    if self.upgrades[type] > self:get_max_upgrade(type) then
        self.upgrades[type] = self:get_max_upgrade(type)
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
	self.upgrade_xp_target = self.xp + self.xp_until_upgrade
	self.reached_upgrade_xp_at = self.xp

	if not self:is_fully_upgraded() then
		signal.emit(self, "xp_threshold_reached", "upgrade")
	end
end

function GlobalGameState:on_heart_xp_threshold_reached()
    self.num_queued_hearts = self.num_queued_hearts + 1
	self.heart_xp_target = self.xp + self.xp_until_heart
	self.reached_heart_xp_at = self.xp
	signal.emit(self, "xp_threshold_reached", "heart")
end

-- function GlobalGameState:on_powerup_xp_threshold_reached()
    -- self.num_queued_powerups = self.num_queued_powerups + 1
	-- signal.emit(self, "xp_threshold_reached", "powerup")
-- end

function GlobalGameState:on_artefact_xp_threshold_reached()
    self.num_queued_artefacts = self.num_queued_artefacts + 1
	self.artefact_xp_target = self.xp + self.xp_until_artefact
	self.reached_artefact_xp_at = self.xp
	signal.emit(self, "xp_threshold_reached", "artefact")
end

local MIN_SCORE_MULTIPLIER = 0.01
local MAX_CHAIN = 20
local EXTRA_CHAIN_MULTIPLIER = 0.685
local EXTRA_CHAIN_BASE = 1.4
local MAX_SCORE_MULTIPLIER = 30

function GlobalGameState:get_score_multiplier(include_rescue_chain)
    local multiplier = self.score_multiplier

    if include_rescue_chain == nil then
        include_rescue_chain = true
    end


    if include_rescue_chain then
        multiplier = multiplier + self:get_rescue_chain_multiplier()
    end

    multiplier = multiplier * (1 + self:get_difficulty_modifier(false))
    multiplier = stepify_floor(multiplier, MIN_SCORE_MULTIPLIER)
    multiplier = min(multiplier, MAX_SCORE_MULTIPLIER)

    return multiplier
end

function GlobalGameState:get_rescue_chain_multiplier()
    -- local rescue_chain_multiplier = self.rescue_chain
    -- local max_chain = MAX_CHAIN - 4

    -- if rescue_chain_multiplier > max_chain then
    --     local extra = rescue_chain_multiplier - max_chain

    --     local scaled_extra = (logb(extra + 1.50, EXTRA_CHAIN_BASE) * EXTRA_CHAIN_MULTIPLIER) +
    --         (extra * MIN_SCORE_MULTIPLIER - MIN_SCORE_MULTIPLIER)
    --     scaled_extra = min(scaled_extra, extra)

    --     rescue_chain_multiplier = max_chain + scaled_extra
    -- else
    --     rescue_chain_multiplier = self.rescue_chain
    -- end

    -- return clamp(rescue_chain_multiplier, 0, RESCUE_CHAIN_MULTIPLIER_CAP)

	return self.rescue_chain_bonus
end


local DIFFICULTY_MULTIPLIER = 0.4

function GlobalGameState:get_difficulty_modifier(include_rescue_chain)

	if not self.enable_adaptive_difficulty then
		return 0
	end

    if include_rescue_chain == nil then
		include_rescue_chain = true
	end

    local upgrade_sum = 0
    for upgrade, count in pairs(self.upgrades) do
        upgrade_sum = upgrade_sum + count
    end

    local upgrade_modifier = upgrade_sum / 12
	local heart_modifier = self.hearts / 6

	local rescue_modifier = include_rescue_chain and (min(self.rescue_chain_difficulty / 30, 1) * 0.35) or 0
	local bonus_difficulty_modifier = self.bonus_difficulty_modifier

	local modifier = upgrade_modifier + heart_modifier + rescue_modifier + bonus_difficulty_modifier

	local level_multiplier = min(self.level - 1, 4) / 4


	return modifier * level_multiplier * DIFFICULTY_MULTIPLIER
end

function GlobalGameState:on_artefact_destroyed(artefact)
    self.artefacts_destroyed[artefact.key] = true
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
				if self:get_max_upgrade(v.upgrade_type) then
					if self.upgrades[v.upgrade_type] < self:get_max_upgrade(v.upgrade_type) then
						table.insert(tab, v)
					end
				end
			else
				table.insert(tab, v)
			end
		end
    end

    local v = rng.weighted_choice(tab, function(upgrade)
		local weight = upgrade.spawn_weight
		if table.list_has(self.recently_selected_upgrades, upgrade.upgrade_type) then
			weight = weight / 100
		end
		return weight
	end)
	
	if allow_nil and v and self:get_max_upgrade(v.upgrade_type) then
		if self.upgrades[v.upgrade_type] < self:get_max_upgrade(v.upgrade_type) then
            return v
        else
			return nil
		end
	end

	return v
end

function GlobalGameState:use_sacrificial_twin()
	self:remove_artefact(self.artefacts.sacrificial_twin.slot)
	self.used_sacrificial_twin = true
	signal.emit(self, "used_sacrificial_twin")
end

function GlobalGameState:prune_artefact(artefact)
    table.insert(self.recently_selected_artefacts, artefact.key)
	if #self.recently_selected_artefacts > 3 then
		table.remove(self.recently_selected_artefacts, 1)
	end
end

function GlobalGameState:prune_upgrade(upgrade)
    table.insert(self.recently_selected_upgrades, upgrade.upgrade_type)
	if #self.recently_selected_upgrades > 3 then
		table.remove(self.recently_selected_upgrades, 1)
	end
end

function GlobalGameState:get_random_available_artefact()

    local tab = {}
    for k, v in pairs(PickupTable.artefacts) do
        if not v.base then

			-- if not self.secondary_weapon then
			-- 	if not v.is_secondary_weapon then
			-- 		goto continue
			-- 	end
			-- end

			if self.artefacts[v.key] then
				goto continue
			end
			
			if self.last_spawned_artefacts[v.key] then
				goto continue
			end
            
			if table.list_has(self.recently_selected_artefacts, v.key) then
                goto continue
            end
            
			if self.used_sacrificial_twin and v.key == "sacrificial_twin" then
                goto continue
            end

			if self.artefacts_destroyed[v.key] then
				goto continue
			end
			
			if v.requires_artefacts then
				for _, artefact in pairs(v.requires_artefacts) do
					if not self.artefacts[artefact] then
						goto continue
					end
				end
			end

			if self.secondary_weapon == v then
				goto continue
			end

			if v.must_not_have_artefacts then
				for _, artefact in pairs(v.must_not_have_artefacts) do
					if self.artefacts[artefact] then
						goto continue
					end
				end
			end
			table.insert(tab, v)
			::continue::
		end
    end

    local v = rng.weighted_choice(tab, function(artefact)
		local weight = artefact.spawn_weight
        
		if debug.enabled and artefact.debug_spawn_weight then
            weight = artefact.debug_spawn_weight
        end
	
		if artefact.is_secondary_weapon then
			if self.secondary_weapon then
                weight = weight * 0.01
			end
		end

		return weight
	end)


	return v
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
    local heart = rng.choose(table.filtered(table.values(PickupTable.hearts), function(heart)
        return not heart.base
    end))
	-- table.pretty_print(heart)
	return heart
end

function GlobalGameState:consume_upgrade()
    self.num_queued_upgrades = max(0, self.num_queued_upgrades - 1)
end

-- function GlobalGameState:consume_powerup()
--     self.num_queued_powerups = self.num_queued_powerups - 1
-- end

function GlobalGameState:consume_heart()
    self.num_queued_hearts = max(0, self.num_queued_hearts - 1)
end

function GlobalGameState:consume_artefact()
    self.num_queued_artefacts = max(0, self.num_queued_artefacts - 1)
end

function GlobalGameState:add_score(score, score_category)
	if self.game_over then return end
	if score <= 0 then return end
    self.score = self.score + score
	assert(type(score_category) == "string", "score_category must be a string")
	self.score_categories[score_category] = self.score_categories[score_category] or 0
	self.score_categories[score_category] = self.score_categories[score_category] + score
end

return MainGame
