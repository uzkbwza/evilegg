local NameEntryWorld = World:extend("NameEntryWorld")
local O = require("obj")
local utf8 = require('utf8')


local MENU_WIDTH = 130
local MENU_HEIGHT = 70

local CHARACTERS = {
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"1","2","3","4","5","6","7","8","9","0",
	".",",","/","!","?","'","\"","[","]","-","+",
	"_",
	"←",
	"✓",
}

local MAX_LENGTH = 18

local BUTTON_AREA_WIDTH = MENU_WIDTH - 10
local BUTTON_AREA_HEIGHT = MENU_HEIGHT - 10

local BUTTON_WIDTH = 12
local BUTTON_HEIGHT = 12

function NameEntryWorld:new(x, y)
    NameEntryWorld.super.new(self, x, y)
    self:add_signal("name_selected")
	self.text = ""
	self.button_objects = {}
	self.gamepad_nav_only = true
end

function NameEntryWorld:enter()

	signal.connect(input, "text_input", self, "on_text_input")
	-- local middle_x, middle_y = conf.viewport_size.x / 2, conf.viewport_size.y / 2
	-- self.camera:move(middle_x, middle_y)

	self:ref("menu_root",
		self:spawn_object(O.Menu.GenericMenuRoot(-MENU_WIDTH / 2, -MENU_HEIGHT / 2, MENU_WIDTH,
			MENU_HEIGHT)))


	local columns = floor(BUTTON_AREA_WIDTH / BUTTON_WIDTH)
	local rows = floor(BUTTON_AREA_HEIGHT / BUTTON_HEIGHT)

	for i = 1, #CHARACTERS do
		local c = CHARACTERS[i]
		local x = (i - 1) % columns * (BUTTON_WIDTH) - BUTTON_AREA_WIDTH / 2
		local y = floor((i - 1) / columns) * (BUTTON_HEIGHT) - BUTTON_AREA_HEIGHT / 2

		local button_object = self.menu_root:add_child(self:spawn_object(O.NameEntryMenu.NameEntryCharacterButton(x, y, c, BUTTON_WIDTH - 1, BUTTON_HEIGHT - 1, false)))
		button_object.color = Color.white
		if c == "←" then
			self:ref("backspace_button", button_object)
			-- button_object.color = Color.white
		elseif c == "✓" then
			self:ref("confirm_button", button_object)
			button_object.color = Color.green
		elseif c == "_" then
			self:ref("space_button", button_object)
			button_object.color = Color.darkgrey
		end
		table.insert(self.button_objects, button_object)
		signal.connect(button_object, "selected", self, "on_character_selected", function()
			self.invalid_name = false
			self:stop_timer("invalid_name_effect")
			if c == "←" then
				self.text = self.text:sub(1, -2)
			elseif c == "✓" then
				if self:is_valid_name() then
					local s = self.sequencer
					self.text = string.strip_whitespace(self.text, true, true)
					self.text = self.text:sub(1, MAX_LENGTH)
					self:emit_signal("name_selected", self.text)
					self.done = true
				else
					self:invalid_name_effect()
				end
			elseif c == "_" then
				self.text = self.text .. " "
				self.text = string.strip_whitespace(self.text, true, false)
				self.text = self.text:sub(1, MAX_LENGTH)
			else
				self.text = self.text .. c
				self.text = string.strip_whitespace(self.text, true, false)
				self.text = self.text:sub(1, MAX_LENGTH)
			end
		end)
		self.button_object_map = self.button_object_map or {}
		self.button_object_map[c] = button_object
	end

	self.button_objects[1]:focus()

	for i = 1, #self.button_objects do
		local x, y = id_to_xy(i, columns)
		local button = self.button_objects[i]
		-- if y == 1 then
		-- button:add_neighbor(self.cycle_category_button, "up")
		-- end

		local button_below = self.button_objects[xy_to_id(x, y + 1, columns)]
		if button_below and button_below ~= button then
			button:add_neighbor(button_below, "down")
			button_below:add_neighbor(button, "up")
		else
			local top_button = self.button_objects[xy_to_id(x, 1, columns)]
			if top_button and top_button ~= button then
				button:add_neighbor(top_button, "down")
				top_button:add_neighbor(button, "up")
			end
		end


		local right_id = xy_to_id(x + 1, y, columns)
		local right_x, right_y = id_to_xy(right_id, columns)

		if right_y > y then
			right_id = xy_to_id(1, y, columns)
		end

		local right_button = self.button_objects[right_id]
		if right_button and right_button ~= button then
			button:add_neighbor(right_button, "right")
			right_button:add_neighbor(button, "left")
		else
			local leftmost_button = self.button_objects[xy_to_id(1, y, columns)]
			if leftmost_button and leftmost_button ~= button then
				button:add_neighbor(leftmost_button, "right")
				leftmost_button:add_neighbor(button, "left")
			end
		end
	end
end

function NameEntryWorld:on_text_input(text)
	if self.done then return end

	if text == " " then
		self.space_button:select()
	else
		if self.button_object_map[text:upper()] then
			self.button_object_map[text:upper()]:focus()
			self.button_object_map[text:upper()]:select()
		end
	end
end

function NameEntryWorld:update(dt)
	local input = self:get_input_table()
	if input.keyboard_pressed["backspace"] or input:any_joystick_pressed("b") then
		-- self.backspace_button:focus()
		self.backspace_button:select()
	end

	if input.keyboard_pressed["return"] or input:any_joystick_pressed("start") then
		if self.confirm_button.focused then
			self.confirm_button:select()
		else
			self.confirm_button:focus()
		end
	end
end

function NameEntryWorld:is_valid_name()
	return string.strip_whitespace(self.text) ~= ""
end

function NameEntryWorld:invalid_name_effect()
	self:start_timer("invalid_name_effect", 90)
	self.invalid_name = true
end

function NameEntryWorld:draw()
    local font = fonts.depalettized.image_font2
	graphics.set_font(font)
	
	graphics.set_color(Palette.rainbow:tick_color(self.tick, 0, 10))
    
	graphics.print_centered(self.text ~= "" and self.text or tr.name_entry_prompt:upper(), font, 0, -MENU_HEIGHT / 2 - 10)
	
	if self.invalid_name and (not self:is_timer_running("invalid_name_effect") or self.tick % 2 == 0) then
		graphics.print_centered("INVALID NAME", font, 0, MENU_HEIGHT / 2 + 8)
	end

	graphics.rectangle_centered("line", 0, 0, MENU_WIDTH, MENU_HEIGHT)
	NameEntryWorld.super.draw(self)
end

return NameEntryWorld