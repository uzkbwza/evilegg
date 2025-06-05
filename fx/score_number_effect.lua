local ScoreNumberEffect = Effect:extend("ScoreNumberEffect")

local palette_low = PaletteStack(Color.black)
local palette_low_mid = PaletteStack(Color.black)
local palette_mid = PaletteStack(Color.black)
local palette_high = PaletteStack(Color.black)

palette_low:push(Palette.score_pickup_border, 4)
palette_low:push(Palette.score_pickup_low)
palette_low_mid:push(Palette.score_pickup_border, 4)
palette_low_mid:push(Palette.score_pickup_low_mid)
palette_mid:push(Palette.score_pickup_border, 4)
palette_mid:push(Palette.score_pickup_mid)
palette_high:push(Palette.score_pickup_border, 4)
palette_high:push(Palette.score_pickup_hi)

-- palette:push(Color.red)

function ScoreNumberEffect:new(x, y, score)
    ScoreNumberEffect.super.new(self, x, y+1)
    self.score = score
    self.game_score_low_mid = game_state:determine_score(200)
    self.game_score_mid = game_state:determine_score(500)
	self.game_score_high = game_state:determine_score(1000)
    self.duration = 60
	self.z_index = 0
    self.random_offset = rng:randi_range(0, 1000)
	self.palette = palette_low
	if self.score >= self.game_score_high then
		self.palette = palette_high
	elseif self.score >= self.game_score_mid then
		self.palette = palette_mid
	elseif self.score >= self.game_score_low_mid then
		self.palette = palette_low_mid
	end
end

function ScoreNumberEffect:draw(elapsed, tick, t)
	graphics.set_color(Color.white)
	if tick > 40 and gametime.tick % 2 == 0 then
		return
	end
    local text = tostring(self.score)
    local offsx, offsy = graphics.text_center_offset(text, fonts.score_pickup_font)
	local palette = self.palette
	palette:set_palette_offset(2, tick / 5 + self.random_offset)
    palette:set_palette_offset(3, tick / 2 + self.random_offset)
    graphics.set_font(fonts.depalettized.score_pickup_font_white)
	graphics.print_outline(Palette.score_pickup_outline:tick_color(floor(tick / 1.5 + self.random_offset)), text, offsx, offsy - t * 10)
    graphics.set_font(fonts.score_pickup_font)
    graphics.printp(text, fonts.score_pickup_font, palette, 0, offsx, offsy - t * 10)
end

return ScoreNumberEffect
