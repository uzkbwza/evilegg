local TextPopupEffect = Effect:extend("TextPopupEffect")




-- palette_stack:push(Color.red)

function TextPopupEffect:new(x, y, text, palette_stack, duration)
    TextPopupEffect.super.new(self, x, y + 1)
	-- self.persist = true
    self.text = text
	self.duration = duration or 120
    self.z_index = 2
	self.palette_stack = palette_stack
    self.random_offset = rng:randi(0, 1000)
    self.width = fonts.image_font1:getWidth(text)
    self.height = fonts.image_font1:getHeight(text)
	if palette_stack == nil then
		self.palette_stack = PaletteStack(Color.black)
		-- self.palette_stack:push(Color.black)
		self.palette_stack:push(Palette.notif_base_border, 1)
        self.palette_stack:push(Palette.notif_base, 1)
    else
		self.palette_stack = palette_stack
	end
end

function TextPopupEffect:update(dt)
	if not self.custom_movement then
		self:move(0, -0.5 * dt)
	end
	if self.pos.x - self.width / 2 < self.world.room.left then
		self:move_to(self.world.room.left + self.width / 2, self.pos.y)
	end
    if self.pos.x + self.width / 2 > self.world.room.right then
        self:move_to(self.world.room.right - self.width / 2, self.pos.y)
    end
    if self.pos.y - self.height / 2 < self.world.room.top - self.world.room.vert_padding then
        self:move_to(self.pos.x, self.world.room.top + self.height / 2 - self.world.room.vert_padding)
    end
	if self.pos.y + self.height / 2 > self.world.room.bottom then
        self:move_to(self.pos.x, self.world.room.bottom - self.height / 2)
    end
end

function TextPopupEffect:draw(elapsed, tick, t)
	-- if not self.world.showing_hud then return end
	graphics.set_color(Color.white)
	if tick > self.duration - 20 and gametime.tick % 2 == 0 then
		return
	end
    local text = tostring(self.text)
    local offsx, offsy = graphics.text_center_offset(text, fonts.image_font1)
	self.palette_stack:set_palette_offset(2, self.tick / 3)
	self.palette_stack:set_palette_offset(3, self.tick / 3)
    -- pal:set_palette_offset(3, tick / 2 + self.random_offset)
    graphics.set_font(fonts.depalettized.image_font1)
	graphics.print_outline(Color.black, text, offsx, offsy)
    graphics.set_font(fonts.image_font1)
    graphics.printp(text, fonts.image_font1, self.palette_stack, 0, offsx, offsy)
end

return TextPopupEffect
