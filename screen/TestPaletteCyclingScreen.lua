local MainScreen = CanvasLayer:extend("MainScreen")

local TestObject = GameObject2D:extend("TestObject")


function TestObject:new(x, y)
	TestObject.super.new(self, x, y)
    self:add_elapsed_ticks()
    self.palette_selected = 1
	self.texture = textures.palette_cycle_test_image
    self.palettes = {
        Palette[self.texture],
		PaletteStack( Palette[self.texture], Palette.cmyk),
		PaletteStack( Palette.greytoblack, Palette.cmyk),
		Palette.bothways,
        Palette.rainbow,
        Palette.fire,
		Palette.redblue,
        Palette.lightup,
    }


    self.cycle_selected = 0
	
	self.offset = 0
    self.cycle = 0
	self.time = 0

	self.show_default = false
end

function TestObject:update(dt)
	self.show_default = input.keyboard_held["lshift"]
    if input.keyboard_pressed["z"] then
        self.cycle_selected = self.cycle_selected + 1
        if self.cycle_selected > 3 then
            self.cycle_selected = 0
        end
		self.offset = 0
		self.time = 0
    end
	if input.keyboard_pressed["x"] then
		self.palette_selected = self.palette_selected + 1
        if self.palette_selected > #self.palettes then
            self.palette_selected = 1
        end
        self.offset = 0
		self.time = 0
	end

	if input.keyboard_pressed["left"] then
		self.offset = self.offset + 1
	end
	if input.keyboard_pressed["right"] then
		self.offset = self.offset - 1
	end

    if input.keyboard_pressed["r"] then
        self.offset = 0
		self.time = 0
    end

	self.cycle = 0

    if self.cycle_selected == 1 then
        self.cycle = floor(self.time / 5)
    elseif self.cycle_selected == 2 then
        self.cycle = floor(self.time / 2)
    elseif self.cycle_selected == 3 then
        self.cycle = floor(self.time)
    end

	self.time = self.time + dt
end

function TestObject:draw()

	local palette = self.palettes[self.palette_selected]

    if palette == false then palette = nil end
	


	if self.show_default then
		graphics.draw_centered(self.texture)
    else
		if palette ~= nil and Object.is(palette, PaletteStack) then
			palette:set_palette_offset(2, self.cycle)
			graphics.drawp_centered(self.texture, palette, self.offset)
		else
			graphics.drawp_centered(self.texture, palette, self.cycle + self.offset)
		end
	end
end

function MainScreen:new()
	MainScreen.super.new(self)
    local a = "hi"
	self.clear_color = Color.black

    local world = World()
    world:init_camera()
	
    self.world = self:add_world(world)
end

function MainScreen:enter()
	self:ref("testobject", self.world:spawn_object(TestObject(0,0)))
end

function MainScreen:update(dt)
    local input = self:get_input_table()

end

function MainScreen:draw()
    MainScreen.super.draw(self)

	local palette = self.testobject.palettes[self.testobject.palette_selected]

    if palette == false then palette = Palette[self.testobject.texture] end
	

	local colors
    if Object.is(palette, PaletteStack) then
		colors = palette:get_color_array(self.testobject.offset)
	else
		colors = palette:get_color_array(self.testobject.cycle + self.testobject.offset)
	end

	local rect_width = 8
    local rect_height = 10
	local num_colors = #colors
	for i, color in ipairs(colors) do
		graphics.set_color(color)
		graphics.rectangle("fill", (i-1) * rect_width + self.viewport_size.x / 2 - (num_colors * rect_width) / 2, self.viewport_size.y - rect_height, rect_width, rect_height)
	end
end

return MainScreen
