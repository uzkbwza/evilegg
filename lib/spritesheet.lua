local SpriteSheet = Object:extend("SpriteSheet")
	
function SpriteSheet:new(texture, sprite_width, sprite_height)
    sprite_width = floor(sprite_width)
    sprite_height = floor(sprite_height)

	if type(texture) == "string" then
		texture = textures[texture]
	end

    self.texture = texture
    local width, height = texture:getPixelDimensions()
    if width % sprite_width ~= 0 then
        error("Sprite width does not divide evenly into texture width")
    end
    if height % sprite_height ~= 0 then
        error("Sprite height does not divide evenly into texture height")
    end
    self.sprite_width = sprite_width
    self.sprite_height = sprite_height
    for y = 1, floor(height / sprite_height) do
        for x = 1, floor(width / sprite_width) do
            local id = xy_to_id(x, y, floor(width / sprite_width))
            local sx = (x - 1) * sprite_width
            local sy = (y - 1) * sprite_height

            self[id] = {
                __isquad = true,
                texture = texture,
                quad = love.graphics.newQuad(sx, sy, sprite_width, sprite_height, width,
                    height),
                width = sprite_width,
                height = sprite_height,
                x = sx,
                y = sy,
            }
        end
    end
end

function SpriteSheet:get_frame(id)
    return self:get_quad(id)
end

function SpriteSheet:get_quad(id)
    local id = clamp(id, 1, #self)
    return self[id]
end

function SpriteSheet:random()
    return self[rng.randi(1, #self)]
end

function SpriteSheet:loop(tick, ticks_per_frame, offset)
	offset = offset or 0
    return self[floor((tick / ticks_per_frame) % (#self - offset) + 1 + offset)	]
end

function SpriteSheet:get_animation(ticks_per_frame)
    local animation = {}
	local length = #self
    for i = 1, length do
        animation[(i - 1) * ticks_per_frame + 1] = self[i]
    end
	animation[(length) * ticks_per_frame + 1] = "end"
	return Animation(animation)
end

function SpriteSheet:interpolate(t)
    -- t = 0..1
	local id = floor(clamp((t * #self) + 1, 1, #self))
	return self[id]
end

return SpriteSheet

