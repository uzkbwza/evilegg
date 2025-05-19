local MainMenuButton = require("obj.Menu.MenuButton"):extend("MainMenuButton")

local MainMenuButtonLetter = GameObject2D:extend("MainMenuButtonLetter")

local WIDTH = 150
-- local WIDTH = 1
local HEIGHT = 18

function MainMenuButton:new(x, y, text)
    -- self.centered = true
    MainMenuButton.super.new(self, x, y, WIDTH, HEIGHT)
    self.text = text
    self.font = fonts.image_bigfont1
    self.text_width = self.font:getWidth(self.text)
    self.press_mode = "press"
    self.letter_disappear_offset = 0
    -- self.width = max(self.width, self.text_width * 1.25)
end

function MainMenuButton:disappear_animation()

end

function MainMenuButton:enter()
    self:ref_array("letters")
	local width = 0
    for i = 1, #self.text do
		local char = self.text:sub(i, i)
		local letter = self:spawn_object(MainMenuButtonLetter(self.pos.x + width, self.pos.y, char, self.font, self))
		width = self.font:getWidth(self.text:sub(1, i))
        self:ref_array_push("letters", letter).z_index = self.z_index + 0.1
		self:bind_destruction(letter)
	end

	self:move(-WIDTH / 2, 0)
end

function MainMenuButton:on_selected()
    local s = self.sequencer
	self:play_sfx("ui_menu_button_selected1", 0.6)
	s:start(function()
        self.select_highlight = true
		s:wait(10)
		self.select_highlight = false
	end)
end

function MainMenuButton:on_focused()
    self:play_sfx("ui_menu_button_focused1", 0.6)
	local s = self.sequencer
	s:start(function()
		self.focus_highlight = true
		s:wait(1)
		self.focus_highlight = false
	end)
end

function MainMenuButton:draw()
	local x, y, w, h = self:get_rect_local()
	if self.focus_highlight then
		graphics.set_color(Color.darkgreen)
        -- graphics.line(x, y+h+1, x+w, y + h+1)
		graphics.rectangle("fill", x, y, w, h)
    else
		-- graphics.set_color(Color.green)
		-- graphics.line(x, y+h+1, x+w, y + h+1)
	end
end

function MainMenuButton:update(dt)
    local width = 0
    local total_width = self.font:getWidth(self.text) * (self.focused and 1.35 or 1)
	if self.focused then
		total_width = total_width - self.font:getWidth(self.letters[1].text) / 2
	end
    for i = 1, #self.letters do
        local letter = self.letters[i]
        width = self.font:getWidth(self.text:sub(1, i-1)) * (self.focused and 1.35 or 1)
        local target_x = self.pos.x + width - total_width / 2 + WIDTH / 2
        local target_y = self.pos.y
        letter:move_to(splerp_vec(letter.pos.x, letter.pos.y, target_x, target_y, 50, dt))
        if self.is_new_tick and rng.percent(33) then
            if self.focused and not letter.focused then
                letter:focus()
            elseif not self.focused and letter.focused then
                letter:unfocus()
            end
        end
    end
    -- self.width = max(width, WIDTH)
	-- self.width = width
end

function MainMenuButtonLetter:new(x, y, text, font, owner)
	MainMenuButtonLetter.super.new(self, x, y)
	self.text = text
    self.font = font
	self.palette_stack = PaletteStack(Color.black)
	self.palette_stack:push(Color.darkgreen)
    self.palette_stack:push(Color.white)
	self.random_offset = rng.randi()
	self:add_time_stuff()
    self.highlight_outline_color = Color.green
    self.width = self.font:getWidth(self.text)
	self:ref("owner", owner)
end

function MainMenuButtonLetter:flicker()
	local on = rng.percent(80)
    self.highlight_outline_color = on and Color.green or Color.darkgreen
	self:start_timer("flicker", rng.randi_range(1, on and 400 or 3), function()
        self:defer(function() self:flicker() end)
	end)
end

function MainMenuButtonLetter:update(dt)

end

function MainMenuButtonLetter:focus()
	self.focused = true
end

function MainMenuButtonLetter:unfocus()
	self.focused = false
end

function MainMenuButtonLetter:draw()
	graphics.set_color(Color.white)
    self.palette_stack:set_color(2, self.focused and (self.highlight_outline_color) or Color.darkergrey)
	if self.owner and (self.owner.select_highlight or self.owner.focus_highlight) then
        self.palette_stack:set_color(3, Color.green)
        -- if idivmod_eq_zero(self.tick, 1, 2) then
		self.palette_stack:set_color(2, Color.green)
		-- end
	else
		self.palette_stack:set_color(3, self.focused and Color.black or Color.white)
	end
	-- self.palette_stack:set_color(3, self.focused and Color.black or Color.white)
    graphics.set_font(self.font)
	-- local y = 0.7 * sin(self.elapsed * 0.2 + self.random_offset1 * 100)
    graphics.printp(self.text, self.font, self.palette_stack, 0, 0, 0)
end

return MainMenuButton
