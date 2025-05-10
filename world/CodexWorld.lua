local CodexWorld = World:extend("CodexWorld")
local O = require("obj")
local SpawnDataTable = require("obj.spawn_data")
local PickupDataTable = require("obj.pickup_table")

local MENU_ITEM_H_PADDING = 12
local MENU_ITEM_V_PADDING = 6

local NUM_OBJECT_COLUMNS = 5
local NUM_OBJECT_ROWS = 8

local ICON_SIZE = 25

local OBJECTS_PER_PAGE = NUM_OBJECT_ROWS * NUM_OBJECT_COLUMNS

local SPAWN_CATEGORY_ORDER = {
	"enemy",
	"hazard",
	"rescue",
	"pickups",
	"artefact",
	"secondary_weapon",
}

local PAGE_CATEGORY_ORDER = table.extend({"all"}, SPAWN_CATEGORY_ORDER)

function CodexWorld:new(x, y)
    CodexWorld.super.new(self, x, y)
    self:add_signal("exit_menu_requested")
    self.object_buttons = {}
    self.page_number = 1
    self.category_index_selected = 1
    self.category_selected = PAGE_CATEGORY_ORDER[self.category_index_selected]
    self.spawn_tables = {}
    for _, page in ipairs(PAGE_CATEGORY_ORDER) do
        self.spawn_tables[page] = {}
        for _, spawn in ipairs(self:get_spawns(page)) do
            table.insert(self.spawn_tables[page], spawn)
        end
        self.spawn_tables[page].count = #self.spawn_tables[page]
    end
	self.draw_sort = self.y_sort
end

function CodexWorld:enter()
    self.camera:move(conf.viewport_size.x / 2, conf.viewport_size.y / 2)

    self:ref("menu_root", self:spawn_object(O.Menu.GenericMenuRoot(0, 0, 1, 1)))

    self:ref("back_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(MENU_ITEM_H_PADDING, MENU_ITEM_V_PADDING, tr.menu_back_button,
            50, 10, false))):focus()

    signal.connect(self.back_button, "selected", self, "exit_menu_requested", function()
		local s = self.sequencer
		s:start(function()
			self.handling_input = false
			s:wait(1)
			self:emit_signal("exit_menu_requested")
		end)
    end)

    self:ref("previous_page_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(MENU_ITEM_H_PADDING, MENU_ITEM_V_PADDING + 12, "←",
            15, 10, false)))

	self:ref("cycle_category_button",
        self:add_menu_item(O.CodexMenu.CodexMenuCycle(MENU_ITEM_H_PADDING + 17, MENU_ITEM_V_PADDING + 12, "",
            ICON_SIZE * NUM_OBJECT_COLUMNS - 37, 10, false)))
		
	self.cycle_category_button.get_value_func = function()
		return tr["codex_key_" .. self.category_selected]
	end
	self.cycle_category_button.set_value_func = function(value)
		self:open_page(value, 1)
	end
	self.cycle_category_button:set_options(PAGE_CATEGORY_ORDER)

	self:ref("next_page_button",
        self:add_menu_item(O.PauseScreen.PauseScreenButton(MENU_ITEM_H_PADDING + ICON_SIZE * NUM_OBJECT_COLUMNS - 18, MENU_ITEM_V_PADDING + 12, " →",
            15, 10, false)))

    self.back_button:add_neighbor(self.cycle_category_button, "down")
	self.cycle_category_button:add_neighbor(self.next_page_button, "right")
	self.cycle_category_button:add_neighbor(self.previous_page_button, "left")
    self.next_page_button:add_neighbor(self.cycle_category_button, "left")
    self.previous_page_button:add_neighbor(self.cycle_category_button, "right")
    self.previous_page_button:add_neighbor(self.next_page_button, "left")
	self.next_page_button:add_neighbor(self.previous_page_button, "right")

    self.cycle_category_button:add_neighbor(self.back_button, "up")
	self.next_page_button:add_neighbor(self.back_button, "up")
	self.previous_page_button:add_neighbor(self.back_button, "up")

    signal.connect(self.previous_page_button, "selected", self, "previous_page", function() self:cycle_page(-1) end)
    signal.connect(self.next_page_button, "selected", self, "next_page", function() self:cycle_page(1) end)
    self:open_page(self.category_selected, self.page_number)
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


function CodexWorld:open_spawn_description(spawn)

	savedata:clear_new_codex_item(spawn.codex_save_name)

	local x = conf.viewport_size.x / 2 + conf.viewport_size.x / 4
	local y = conf.viewport_size.y / 2

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

        local spawn_title = self:add_object(O.CodexMenu.CodexSpawnText(x, y - 5 - sprite_height / 2, title, true, Color.green, 0))
		self:add_tag(spawn_title, "sequence_object")
		-- s:wait(2)
    local spawn_sprite = self:add_object(O.CodexMenu.CodexSpawnSprite(x, y, spawn
    .sprite, 1))
		spawn_sprite.z_index = -1
		self:add_tag(spawn_sprite, "sequence_object")
		-- s:wait(2)
        
        local spawn_description = self:add_object(O.CodexMenu.CodexSpawnText(x, y + sprite_height / 2, description, false, Color.white, 2))
		self:add_tag(spawn_description, "sequence_object")
		local text_height = spawn_description.text_height
		-- s:wait(text_height / 60)
	-- end)
	
end


function CodexWorld:clear_spawn_description()

	for _, object in self:get_objects_with_tag("sequence_object"):ipairs() do
		object:queue_destroy()
	end
end

function CodexWorld:cycle_page(direction)

    if self.page_number + direction < 1 then
        return
	end

	if self.page_number + direction > idiv((#self.spawn_tables[self.category_selected] or 0), OBJECTS_PER_PAGE) + 1 then
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
    local spawns = self.spawn_tables[page_category]

    self.page_number = page_number
    self.category_selected = page_category
	self.page_category_index = table.find(PAGE_CATEGORY_ORDER, page_category)
    -- self.cycle_category_button:set_text(page_category:upper())
    if page_number == 1 then
        self.previous_page_button:set_text("-")
    else
        self.previous_page_button:set_text("←")
    end


    if page_number == idiv((#self.spawn_tables[self.category_selected] or 0), OBJECTS_PER_PAGE) + 1 then
        self.next_page_button:set_text(" -")
    else
        self.next_page_button:set_text(" →")
    end

	
    local page = {}
	
	
	local len = table.length(spawns)
	local start = (page_number - 1) * OBJECTS_PER_PAGE + 1
    local finish = start + OBJECTS_PER_PAGE - 1
	
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
	
	if #self.object_buttons > 0 then
		self.cycle_category_button:add_neighbor(self.object_buttons[1], "down")
		self.next_page_button:add_neighbor(self.object_buttons[1], "down")
		self.previous_page_button:add_neighbor(self.object_buttons[1], "down")
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

function CodexWorld:add_spawn_button(spawn, index)

	if not savedata:check_codex_item(spawn.codex_save_name) then
	-- if not savedata:check_codex_item(spawn.codex_save_name) and not debug.enabled then
		spawn = unknown_entry
	end

	local x = MENU_ITEM_H_PADDING + ((index - 1) % NUM_OBJECT_COLUMNS) * (ICON_SIZE)
	local y = MENU_ITEM_V_PADDING + floor((index - 1) / NUM_OBJECT_COLUMNS) * (ICON_SIZE) + 25


    local button = self.menu_root:add_child(self:add_object(O.CodexMenu.CodexEntryButton(x, y, spawn.icon, spawn)))

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
                icon = spawn.icon,
				sprite = spawn.codex_sprite or spawn.icon,
                name = "codex_name_" .. spawn.name:lower(),
                description = "codex_desc_" .. spawn.name:lower(),
				codex_save_name = spawn.name,
            }
			
            if page_category == "enemy" or page_category == "hazard" then
                entry.level = spawn.level
                entry.min_level = spawn.min_level
                if page_category == "enemy" then
                    entry.score = spawn.score
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
	end

	return spawns
end


return CodexWorld
