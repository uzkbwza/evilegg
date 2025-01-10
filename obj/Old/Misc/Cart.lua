local Cart = GameObject:extend("Cart")

function Cart:new(x, y)
	Cart.super.new(self, x, y)
end

function Cart:update(dt)
end

function Cart:draw()
	graphics.draw_centered(textures.friendly_placeholder1)
end

return Cart
