local CodexWorld = World:extend("CodexWorld")
local O = require("obj")
local SpawnDataTable = require("obj.spawn_data")
local PickupDataTable = require("obj.pickup_table")
local LevelBonus = require("levelbonus.LevelBonus")
local Room = require("room.Room")


local MENU_ITEM_H_PADDING = 12
local MENU_ITEM_V_PADDING = 6

local NUM_OBJECT_COLUMNS = 5
local NUM_OBJECT_ROWS = 8

local ICON_SIZE = 25
local GLOSSARY_ICON_SIZE = 15
local GLOSSARY_PAGE_LENGTH = 13

local OBJECTS_PER_PAGE = NUM_OBJECT_ROWS * NUM_OBJECT_COLUMNS

local SPAWN_CATEGORY_ORDER = {
	"enemy",
	"hazard",
	"rescue",
	"pickups",
	"artefact",
    "secondary_weapon",
}

-- local PAGE_CATEGORY_ORDER = table.extend({"all"}, SPAWN_CATEGORY_ORDER)
-- local START_PAGE = 1
local PAGE_CATEGORY_ORDER = table.extend({"all", "glossary", "levelbonus"}, SPAWN_CATEGORY_ORDER)
local START_PAGE = 3

function CodexWorld:new(x, y)
    CodexWorld.super.new(self, x, y)
    self:add_signal("exit_menu_requested")
    self.object_buttons = {}
    self.page_number = 1
    self.category_index_selected = 1
    self.category_selected = PAGE_CATEGORY_ORDER[self.category_index_selected]
    self.spawn_tables = {}
    for _, page_category in ipairs(PAGE_CATEGORY_ORDER) do
        self.spawn_tables[page_category] = {}
        for _, spawn in ipairs(self:get_spawns(page_category)) do
            table.insert(self.spawn_tables[page_category], spawn)
        end
        self.spawn_tables[page_category].count = #self.spawn_tables[page_category]
    end
	self.draw_sort = self.y_sort

		
	local tab = {}
	for _, enemy in pairs(SpawnDataTable.data_by_type["enemy"]) do
		table.insert(tab, {name = enemy.name, score = enemy.score})
	end
	table.sort(tab, function(a, b) return a.score > b.score end)
	print("---SCORE VALUES---")
	for _, enemy in pairs(tab) do
		print(string.format("%-30s %10d", string.format("%s:", enemy.name), enemy.score))
	end
	print("------------------")
end

function CodexWorld:enter()
    self.camera:move(conf.viewport_size.x / 2, conf.viewport_size.y / 2)

    self:ref("menu_root", self:spawn_object(O.Menu.GenericMenuRoot(0, 0, 1, 1)))

    self:ref("back_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(MENU_ITEM_H_PADDING, MENU_ITEM_V_PADDING, "⮌",
            10, 10, false))):focus()

    signal.connect(self.back_button, "selected", self, "exit_menu_requested", function()
		local s = self.sequencer
		s:start(function()
			self.handling_input = false
			s:wait(1)
			self:emit_signal("exit_menu_requested")
		end)
    end)

	self:ref("cycle_category_button",
        self:add_menu_item(O.CodexMenu.CodexMenuCycle(MENU_ITEM_H_PADDING + 17, MENU_ITEM_V_PADDING + 14, "",
            ICON_SIZE * NUM_OBJECT_COLUMNS - 37, 10, false)))
		
	self.cycle_category_button.get_value_func = function()
		return tr["codex_key_" .. self.category_selected]
	end
	self.cycle_category_button.set_value_func = function(value)
		self:open_page(value, 1)
	end
	self.cycle_category_button:set_options(PAGE_CATEGORY_ORDER)

    self.cycle_category_button:add_neighbor(self.back_button, "up")
    self.back_button:add_neighbor(self.cycle_category_button, "down")

	self.cycle_category_button:quiet_cycle(START_PAGE)
    -- self:open_page(self.category_selected, self.page_number)
end

function CodexWorld:update(dt)
    local input = self:get_input_table()
    
	self.focused_on_entry = self.menu_root.focused_child and self.menu_root.focused_child.is_codex_entry_button
	
	if input.ui_cancel_pressed then
        if self.focused_on_entry and input.last_input_device == "gamepad" then
			self.cycle_category_button:focus()
        else
            self.back_button:select()
		end
	end
end


local hp_categories = {
	enemy = true,
	hazard = true,
	rescue = true,
}

local score_categories = {
	enemy = true,
	rescue = true,
}

local weapon_categories = {
	secondary_weapon = true,
}

local ignore_sprite_categories = {
	glossary = true,
}

function CodexWorld:open_spawn_description(spawn)

    self:play_sfx("ui_ranking_tick", 0.35)
	
    if spawn.codex_save_name then
		savedata:clear_new_codex_item(spawn.codex_save_name)
	end
	
	local x = conf.viewport_size.x / 2 + conf.viewport_size.x / 4 - 2
    -- local y = conf.viewport_size.y / 2
	local current_y = MENU_ITEM_V_PADDING + 18
	
    self:clear_spawn_description()

	-- self:ref("sequence_director", self:spawn_object(GameObject2D())):add_time_stuff()

    -- local s = self.sequence_director.sequencer
	-- local sprite_height = graphics.texture_data[spawn.sprite]:getHeight()
	local sprite_height = 25

	-- s:start(function()

	local title = ""
	if not spawn.unknown and tr:has_key(spawn.name) then
		title = tr[spawn.name]
	elseif spawn.unknown then
		title = spawn.name
	else
		title = "[MISSING NAME]"
	end

	local description = ""
	if not spawn.unknown and tr:has_key(spawn.description) then
		description = tr[spawn.description]
	elseif spawn.unknown then
		description = spawn.description
	else
		description = "[MISSING DESCRIPTION]"
	end

	local spawn_title = self:add_object(O.CodexMenu.CodexSpawnText(x, current_y, title, true, Color.green, 0, true))
    self:add_tag(spawn_title, "sequence_object")
	current_y = current_y + 5
	
	local delay = 1
	
	if not ignore_sprite_categories[spawn.page_category] then
		current_y = current_y + sprite_height / 2
		local spawn_sprite = self:add_object(O.CodexMenu.CodexSpawnSprite(x, current_y, spawn.sprite, delay))
        spawn_sprite.z_index = -1
        delay = delay + 1
		current_y = current_y + sprite_height / 2
		self:add_tag(spawn_sprite, "sequence_object")
	end


	
	
	local increment = 12

	if hp_categories[spawn.page_category] then
		local hp_text = self:add_object(O.CodexMenu.CodexSpawnText(x, current_y, string.format(tr.codex_hp_text, spawn.class.max_hp or "???"), false, Color.red, delay, true))
		self:add_tag(hp_text, "sequence_object")
		current_y = current_y + increment
		delay = delay + 1
	end

    if score_categories[spawn.page_category] then
        local text = spawn.score or (spawn.class and spawn.class.spawn_data and spawn.class.spawn_data.score) or "???"
        if spawn.class and spawn.class.spawn_data and spawn.class.spawn_data.boss then
			text = "???"
		end
		local score_text = self:add_object(O.CodexMenu.CodexSpawnText(x, current_y, string.format(tr.codex_score_text, text), false, Color.green, delay, true))
		self:add_tag(score_text, "sequence_object")
		current_y = current_y + increment	
		delay = delay + 1
	end
		
	if weapon_categories[spawn.page_category] then
		-- current_y = current_y + increment
		-- local ammo_count1 = string.fraction(spawn.class.minimum_ammo_needed_to_use_normalized or spawn.class.ammo_needed_per_use_normalized)
		-- local ammo_count1_text = spawn.class.minimum_ammo_needed_to_use and tr.artefact_guide_min_ammo_requirement or tr.artefact_guide_ammo_requirement
		-- local tip3 = ammo_count1_text:format(ammo_count1)
		local tip2 = tr.artefact_guide_ammo_gain:format(string.fraction(spawn.class.ammo_gain_per_level_normalized))
		local weapon_text = self:add_object(O.CodexMenu.CodexSpawnText(x, current_y, tip2, false, Color.green, 2, true))
		self:add_tag(weapon_text, "sequence_object")
		current_y = current_y + increment
		delay = delay + 1
		
		-- local weapon_text2 = self:add_object(O.CodexMenu.CodexSpawnText(x, current_y, tip3, false, Color.orange, delay, true))
		-- self:add_tag(weapon_text2, "sequence_object")
		-- current_y = current_y + increment
		-- delay = delay + 1
	end

    
    if (type(spawn.xp) == "number" and spawn.xp > 0) or type(spawn.xp) == "function" then
        local xp_text = type(spawn.xp) == "function" and tr.codex_variable_score or comma_sep(spawn.xp)
        if spawn.class.spawn_data.boss then
            xp_text = "???"
        end
        local xp_text_object = self:add_object(O.CodexMenu.CodexSpawnText(x, current_y, tr.codex_item_xp:format(xp_text), false, Color.blue, delay, true))
        self:add_tag(xp_text_object, "sequence_object")
        current_y = current_y + increment
        delay = delay + 1
    end

    if spawn.level_bonus then

        if (type(spawn.level_bonus.score) == "number" and spawn.level_bonus.score > 0) or type(spawn.level_bonus.score) == "function" then
            local negative = spawn.level_bonus.negative
            local score = spawn.level_bonus.score
            if negative and type(score) == "number" then
                score = -score
            end
            local score_text = type(spawn.level_bonus.score) == "function" and tr.codex_variable_score or comma_sep(score)
            local level_bonus_text = self:add_object(O.CodexMenu.CodexSpawnText(x, current_y, tr.codex_level_bonus_score:format(score_text), false, negative and Color.red or Color.yellow, delay, true))
            self:add_tag(level_bonus_text, "sequence_object")
            current_y = current_y + increment
            delay = delay + 1
        end

        if type(spawn.level_bonus.score_multiplier) == "number" and spawn.level_bonus.score_multiplier > 0 then
            local mul = spawn.level_bonus.score_multiplier
            local negative = spawn.level_bonus.negative
            if negative then
                mul = -mul
            end
            local level_bonus_text2 = self:add_object(O.CodexMenu.CodexSpawnText(x, current_y, tr.codex_level_bonus_score_multiplier:format(mul), false,  negative and Color.red or Color.green, delay, true))
            self:add_tag(level_bonus_text2, "sequence_object")
            current_y = current_y + increment
            delay = delay + 1
        end

        if (type(spawn.level_bonus.xp) == "number" and spawn.level_bonus.xp > 0) or type(spawn.level_bonus.xp) == "function" then
            local xp_text = type(spawn.level_bonus.xp) == "function" and tr.codex_variable_score or comma_sep(spawn.level_bonus.xp)
            local level_bonus_text3 = self:add_object(O.CodexMenu.CodexSpawnText(x, current_y, tr.codex_item_xp:format(xp_text), false, Color.blue, delay, true))
            self:add_tag(level_bonus_text3, "sequence_object")
            current_y = current_y + increment
            delay = delay + 1
        end

    end

    local spawn_description = self:add_object(O.CodexMenu.CodexSpawnText(x, current_y, description, false, Color.white, delay, true))
    self:add_tag(spawn_description, "sequence_object")
    local text_height = spawn_description.text_height

end


function CodexWorld:clear_spawn_description()

	for _, object in self:get_objects_with_tag("sequence_object"):ipairs() do
		object:queue_destroy()
	end
end

function CodexWorld:get_number_of_objects_per_page()
	if self.category_selected == "glossary" or self.category_selected == "levelbonus" then
		return GLOSSARY_PAGE_LENGTH
	end
	return OBJECTS_PER_PAGE
end

function CodexWorld:cycle_page(direction)

    if self.page_number + direction < 1 then
        return
	end

	if self.page_number + direction > idiv((#self.spawn_tables[self.category_selected] or 0), self:get_number_of_objects_per_page()) + 1 then
		return
	end

    self.page_number = self.page_number + direction
    if self.page_number < 1 then
        self.page_number = #self.spawn_tables[self.category_selected]
    end
    self:open_page(self.category_selected, self.page_number)
end
function CodexWorld:open_page(page_category, page_number)

	self:defer(function() self:_open_page(page_category, page_number) end)
end

function CodexWorld:_open_page(page_category, page_number)
	
	local previous_focused = self.previous_page_button and self.previous_page_button.focused
	local next_focused = self.next_page_button and self.next_page_button.focused

	local cycle_category_width = ICON_SIZE * NUM_OBJECT_COLUMNS
	local cycle_category_x = MENU_ITEM_H_PADDING

	if self.previous_page_button then
		self.previous_page_button:queue_destroy()
		self:unref("previous_page_button")
	end
	if self.next_page_button then
		self.next_page_button:queue_destroy()
		self:unref("next_page_button")
	end
	




	-- self.cycle_category_button:add_neighbor(self.next_page_button, "right")
	-- self.cycle_category_button:add_neighbor(self.previous_page_button, "left")
    -- self.previous_page_button:add_neighbor(self.next_page_button, "left")
    -- self.previous_page_button:add_neighbor(self.cycle_category_button, "right")
    -- self.next_page_button:add_neighbor(self.cycle_category_button, "left")
	-- self.next_page_button:add_neighbor(self.previous_page_button, "right")



    local spawns = self.spawn_tables[page_category]

    self.page_number = page_number
    self.category_selected = page_category
	self.page_category_index = table.find(PAGE_CATEGORY_ORDER, page_category)
    -- self.cycle_category_button:set_text(page_category:upper())
	-- self.next_page_button:remove_neighbor("right")

	-- self.previous_page_button:remove_neighbor("right")
	

	self.cycle_category_button:focus()


    if page_number == 1 then
		
    else
		self:ref("previous_page_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(MENU_ITEM_H_PADDING, MENU_ITEM_V_PADDING + 14, "←", 15, 10, false)))
		
		signal.connect(self.previous_page_button, "selected", self, "previous_page", function() self:cycle_page(-1) end)
		
		if previous_focused then
			self.previous_page_button:focus()
		end
		
        self.cycle_category_button:add_neighbor(self.previous_page_button, "left")
		self.previous_page_button:add_neighbor(self.cycle_category_button, "right")
		self.previous_page_button:add_neighbor(self.back_button, "up")

		cycle_category_x = cycle_category_x + 17
		cycle_category_width = cycle_category_width - 37/2

    end


    if page_number == idiv((#self.spawn_tables[self.category_selected] or 0) - 1, self:get_number_of_objects_per_page()) + 1 then

    else
		self:ref("next_page_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(MENU_ITEM_H_PADDING + ICON_SIZE * NUM_OBJECT_COLUMNS - 18, MENU_ITEM_V_PADDING + 14, " →", 15, 10, false)))

		signal.connect(self.next_page_button, "selected", self, "next_page", function() self:cycle_page(1) end)

        self.cycle_category_button:add_neighbor(self.next_page_button, "right")
        self.next_page_button:add_neighbor(self.cycle_category_button, "left")
		self.next_page_button:add_neighbor(self.back_button, "up")

        if next_focused then
            self.next_page_button:focus()
        end
		
		cycle_category_width = cycle_category_width - 37/2
    end

    -- if self.previous_page_button.focusable then
		-- self.previous
    -- end
	
    self.cycle_category_button:move_to(cycle_category_x, self.cycle_category_button.pos.y)
	self.cycle_category_button.width = cycle_category_width

	
    local page = {}
	
	
	local len = table.length(spawns)
	local start = (page_number - 1) * self:get_number_of_objects_per_page() + 1
    local finish = start + self:get_number_of_objects_per_page() - 1
	
	if finish > len then
		finish = len
	end

	for i = start, finish do
		table.insert(page, spawns[i])
	end


	for i = 1, #self.object_buttons do
		self.object_buttons[i]:queue_destroy()
	end

	table.clear(self.object_buttons)

    for i = 1, #page do
        self.object_buttons[i] = self:add_spawn_button(page[i], i)
    end

    if self.category_selected == "glossary" or self.category_selected == "levelbonus" then
        if #self.object_buttons > 0 then
            self.cycle_category_button:add_neighbor(self.object_buttons[1], "down", true)
            
            for i = 1, #self.object_buttons - 1 do
                self.object_buttons[i]:add_neighbor(self.object_buttons[i + 1], "down", true)
            end

            self.object_buttons[#self.object_buttons]:add_neighbor(self.object_buttons[1], "down", true)
        end
        return
    end
	
	if #self.object_buttons > 0 then
        self.cycle_category_button:add_neighbor(self.object_buttons[1], "down")
		if self.next_page_button then
			self.next_page_button:add_neighbor(self.object_buttons[1], "down")
		end
		if self.previous_page_button then
			self.previous_page_button:add_neighbor(self.object_buttons[1], "down")
		end
	end

	for i = 1, #self.object_buttons do
        local x, y = id_to_xy(i, NUM_OBJECT_COLUMNS)
		local button = self.object_buttons[i]
        -- if y == 1 then
            -- button:add_neighbor(self.cycle_category_button, "up")
        -- end
		
        local button_below = self.object_buttons[xy_to_id(x, y + 1, NUM_OBJECT_COLUMNS)]
		if button_below and button_below ~= button then
            button:add_neighbor(button_below, "down")
			button_below:add_neighbor(button, "up")
        else
			local top_button = self.object_buttons[xy_to_id(x, 1, NUM_OBJECT_COLUMNS)]
			if top_button and top_button ~= button then	
				button:add_neighbor(top_button, "down")
				top_button:add_neighbor(button, "up")
			end
		end


        local right_id = xy_to_id(x + 1, y, NUM_OBJECT_COLUMNS)
		local right_x, right_y = id_to_xy(right_id, NUM_OBJECT_COLUMNS)

        if right_y > y then
            right_id = xy_to_id(1, y, NUM_OBJECT_COLUMNS)
        end
		
		local right_button = self.object_buttons[right_id]
		if right_button and right_button ~= button then
			button:add_neighbor(right_button, "right")
			right_button:add_neighbor(button, "left")
        else
			local leftmost_button = self.object_buttons[xy_to_id(1, y, NUM_OBJECT_COLUMNS)]
			if leftmost_button and leftmost_button ~= button then
                button:add_neighbor(leftmost_button, "right")
				leftmost_button:add_neighbor(button, "left")
			end
		end
	end
end


local unknown_entry = {
	icon = textures.ui_codex_unknown,
	sprite = textures.ui_codex_unknown_sprite,
	name = "???",
	description = "????????????????????\n????????????????????\n????????????????????",
	unknown = true,
}

local unknown_glossary_entry = {
	-- icon = textures.ui_codex_unknown,
	sprite = textures.ui_codex_unknown_sprite,
	name = "???",
	description = "????????????????????\n????????????????????\n????????????????????",
	unknown = true,
    glossary_entry = true,
    text_color = Color.darkgrey,
}

function CodexWorld:add_spawn_button(spawn, index)

	if not savedata:check_codex_item(spawn.codex_save_name) and not spawn.start_unlocked then
		spawn = spawn.glossary_entry and unknown_glossary_entry or unknown_entry
	end
	
    local x = MENU_ITEM_H_PADDING + ((index - 1) % NUM_OBJECT_COLUMNS) * (ICON_SIZE)
    local y = MENU_ITEM_V_PADDING + floor((index - 1) / NUM_OBJECT_COLUMNS) * (ICON_SIZE) + 25

    if spawn.glossary_entry then
        x = MENU_ITEM_H_PADDING
        y = MENU_ITEM_V_PADDING + (GLOSSARY_ICON_SIZE) * (index - 1) + 25
    end

	-- if graphics.depalettized[icon] == nil then icon = unknown_entry.icon end

    local button = self.menu_root:add_child(self:add_object(O.CodexMenu.CodexEntryButton(x, y, spawn.icon, spawn, spawn.glossary_entry and (tr:has_key(spawn.name) and tr[spawn.name] or spawn.name):upper(), ICON_SIZE * NUM_OBJECT_COLUMNS - 2, spawn.text_color)))

	signal.connect(button, "focused", self, "open_spawn_description", function()
		self:defer(function() self:open_spawn_description(spawn) end)
	end)
	
	return button
end

function CodexWorld:add_menu_item(item)
	self.menu_root:add_child(self:spawn_object(item))
	return item
end
 

function CodexWorld:get_spawns(page_category)

    local spawns = {}
	
    if page_category == "all" then
        for _, v in ipairs(SPAWN_CATEGORY_ORDER) do
            table.extend(spawns, self:get_spawns(v))
        end
		return spawns
	end

    if page_category == "glossary" or page_category == "levelbonus" then
        local tab

        if page_category == "glossary" then
            tab = {
                {
                    name = "codex_glossary_name_lvl",
                    description = "codex_glossary_desc_lvl",
                    start_unlocked = true,
                },
                {
                    name = "codex_glossary_name_wave",
                    description = "codex_glossary_desc_wave",
                    start_unlocked = true,
                },
                {
                    name = "codex_glossary_name_upgrade",
                    description = "codex_glossary_desc_upgrade",
                    start_unlocked = true,
                },
                {
                    name = "codex_glossary_name_artefact",
                    description = "codex_glossary_desc_artefact",
                    start_unlocked = true,
                },
                {
                    name = "codex_glossary_name_earned_x",
                    description = "codex_glossary_desc_earned_x",
                    start_unlocked = true,
                },
                {
                    name = "codex_glossary_name_xp",
                    description = "codex_glossary_desc_xp",
                    start_unlocked = true,
                },
                {
                    name = "room_has_max_points",
                    description = "codex_glossary_room_has_max_points",
                    start_unlocked = true,
                },
                {
                    name = "room_is_hard",
                    description = "codex_glossary_room_is_hard",
                },

            }

            local curses = {

            }

            for key, data in pairs(Room.curses) do
                table.insert(curses, {
                    curse = data,
                    name = key,
                    description = key .. "_desc",
                })
            end
            table.sort(curses, function(a, b)
                
                local a_min_level = a.curse.min_level or 1
                local b_min_level = b.curse.min_level or 1

                if a_min_level ~= b_min_level then
                    return a_min_level < b_min_level
                end

                return
                    tr[a.name] < tr[b.name]
            end)

            for _, v in ipairs(curses) do
                table.insert(tab, v)
            end

        elseif page_category == "levelbonus" then
            tab = {}
            for k, v in pairs(LevelBonus) do
                table.insert(tab, {
                    name = v.text_key,
                    description = v.text_key .. "_codex",
                    level_bonus =  v
                })
            end
            table.sort(tab, function(a, b) return tr[a.name] < tr[b.name] end)
        end

        for _, v in ipairs(tab) do
            v.sprite = textures.ui_codex_unknown_sprite
            v.glossary_entry = true
            v.codex_save_name = v.name
            v.text_color = page_category == "glossary" and Color.orange or Color.cyan
        end


        for _, v in ipairs(tab) do
            table.insert(spawns, v)
        end
    end


    if page_category == "enemy" or page_category == "hazard" or page_category == "rescue" then
		local spawn_group_order = {
        }
        for _, v in ipairs(SpawnDataTable.data_by_type[page_category]) do
            if v.spawn_group then
                for _, group in ipairs(v.spawn_group) do
                    spawn_group_order[group] = true
                end
            end
        end
		
		local spawn_group_order_table = {}
		for k, _ in pairs(spawn_group_order) do
			table.insert(spawn_group_order_table, k)
		end
		
		table.sort(spawn_group_order_table, function(a, b)
			if a == "basic" and b ~= "basic" then
				return true
			end
			if a ~= "basic" and b == "basic" then
				return false
			end
			return a < b
		end)
	

        local tab = table.sorted(SpawnDataTable.data_by_type[page_category], function(a, b)

			if a.boss and not b.boss then
				return false
			end
			if b.boss and not a.boss then
				return true
			end

			local a_spawn_group = a.spawn_group and table.copy(a.spawn_group) or "basic"
            local b_spawn_group = b.spawn_group and table.copy(b.spawn_group) or "basic"
			
            if type(a_spawn_group) == "table" then
				table.erase(a_spawn_group, "basic")
				if #a_spawn_group >= 1 then
					a_spawn_group = a_spawn_group[1]
				else
					a_spawn_group = "basic"
				end
			end
			if type(b_spawn_group) == "table" then
				table.erase(b_spawn_group, "basic")
				if #b_spawn_group >= 1 then
					b_spawn_group = b_spawn_group[1]
				else
					b_spawn_group = "basic"
				end
			end

			local a_spawn_group_index = table.find(spawn_group_order_table, a_spawn_group)
			local b_spawn_group_index = table.find(spawn_group_order_table, b_spawn_group)

			if a_spawn_group_index ~= b_spawn_group_index then
				return a_spawn_group_index < b_spawn_group_index
			end


			local a_min_level = a.min_level or 1
			local b_min_level = b.min_level or 1
			if a_min_level ~= b_min_level then
				return a_min_level < b_min_level
			end

            if a.level then
                if a.level == b.level then
                    if a.spawn_points == b.spawn_points then
                        return a.name < b.name
                    else
                        return a.spawn_points < b.spawn_points
                    end
                else
                    return a.level < b.level
                end
            end
			
			return a.name < b.name

        end)

        for i = 1, #tab do
			
            local spawn = tab[i]

            if spawn.name == "BaseSpawn" then
                goto continue
            end

			if spawn.codex_hidden then
				goto continue
			end

            local entry = {
                icon = spawn.codex_icon or spawn.icon,
				sprite = spawn.codex_sprite or spawn.icon,
                name = "codex_name_" .. spawn.name:lower(),
                description = "codex_desc_" .. spawn.name:lower(),
                codex_save_name = spawn.name,
                class = spawn.class,
                max_hp = spawn.max_hp,
				page_category = page_category,
            }
			
            if page_category == "enemy" or page_category == "hazard" then
                entry.level = spawn.level
                entry.min_level = spawn.min_level
                if page_category == "enemy" then
                    entry.score = spawn.score
                    entry.xp = spawn.class:get_xp()
                end
            end
			
            table.insert(spawns, entry)
			::continue::
		end
    elseif page_category == "artefact" or page_category == "secondary_weapon" or page_category == "pickups" then
        local tab = {}

		local sort = function(a, b)
			return a.name < b.name
		end
		local upgrades = table.sorted(table.values(PickupDataTable.upgrades), sort)
		local hearts = table.sorted(table.values(PickupDataTable.hearts), sort)
		local powerups = table.sorted(table.values(PickupDataTable.powerups), sort)

		
        if page_category == "pickups" then
            for i = 1, #upgrades do
                table.insert(tab, upgrades[i])
            end
			
			for i = 1, #hearts do
				table.insert(tab, hearts[i])
			end
			
			for i = 1, #powerups do
				table.insert(tab, powerups[i])
			end
        elseif page_category == "artefact" then
			local artefacts = table.sorted(table.values(PickupDataTable.artefacts), sort)
			for i = 1, #artefacts do
				if not artefacts[i].is_secondary_weapon then
					table.insert(tab, artefacts[i])
				end
			end
		elseif page_category == "secondary_weapon" then
			local artefacts = table.sorted(table.values(PickupDataTable.artefacts), sort)
			for i = 1, #artefacts do
				if artefacts[i].is_secondary_weapon then
					table.insert(tab, artefacts[i])
				end
			end
		end

		for i = 1, #tab do
			local t = tab[i]
            if t.base then
                goto continue
            end
			
			if t.codex_hidden then
				goto continue
			end

			local entry = {
				icon = t.icon,
				sprite = t.sprite or t.textures[1],
				name = t.name,
                description = t.description,
				codex_save_name = t.name,
				page_category = page_category,
				class = t,
            }
			
			if page_category == "secondary_weapon" then
				entry.ammo = t.ammo
				entry.ammo_gain_per_level = t.ammo_gain_per_level
				entry.ammo_needed_per_use = t.ammo_needed_per_use
				entry.starting_ammo = t.starting_ammo
			end

			table.insert(spawns, entry)
			
			::continue::
		end
	elseif page_category == "glossary" then
		local tab = {}
		for _, v in ipairs(SpawnDataTable.data_by_type["enemy"]) do
			table.insert(tab, v)
		end
		table.sort(tab, function(a, b) return a.name < b.name end)
	end

	return spawns
end

function CodexWorld:draw()
    local font = fonts.depalettized.image_bigfont1
	graphics.set_font(font)
	graphics.print(tr.menu_codex_button, font, 28, MENU_ITEM_V_PADDING - 3, 0, 1, 1)
	CodexWorld.super.draw(self)
end

return CodexWorld
