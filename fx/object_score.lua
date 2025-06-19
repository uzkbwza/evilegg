
local ObjectScore = Effect:extend("ObjectScore")
function ObjectScore:new(x, y, score, label)
    ObjectScore.super.new(self, x, y)
    self.score = score
	self.label = label
    self.duration = 30 + score / 10
	if label then
		self.duration = self.duration + 60
	end
    self.font = fonts["PressStart2P-8"]
	self.z_index = -1
	global_state:add_score(self.score)
end

function ObjectScore:update(dt)
end

function ObjectScore:draw(elapsed, ticks, t)
    graphics.set_font(self.font)
	if ticks > self.duration - 10 and floor(ticks / 2) % 2 == 0 then return end
    local text = self.label or self.score
    local text_width = self.font:getWidth(text)

	local yoffs = ticks / 2

	
	if self.label or self.score >= 750 then
		local layers = min(floor(yoffs), self.label and 5 or min(self.score / 200, 10))
        for i = 1, layers do
            graphics.set_color(Color.white)
            graphics.print_outline_no_diagonals(graphics.color_flash(i, 2), text, -text_width / 2,
                -floor(yoffs) + (layers - i))
        end
		-- graphics.set_color(graphics.color_flash(2, 1))
	else
		-- graphics.set_color(Color.white)
	end
	graphics.set_color(Color.white)

	
    graphics.print_outline_no_diagonals((self.label or self.score >= 500) and graphics.color_flash(0, 2) or Color.black, text, -text_width / 2, -floor(yoffs))
end

return ObjectScore

