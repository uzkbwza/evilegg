
-- Linear easing
local function linear(t)
    return t
end

-- Quadratic easing
local function inQuad(t)
    return t * t
end

local function outQuad(t)
    return t * (2 - t)
end

local function inOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

local function outInQuad(t)
    if t < 0.5 then
        return outQuad(2 * t) / 2
    else
        return inQuad(2 * t - 1) / 2 + 0.5
    end
end

-- Cubic easing
local function inCubic(t)
    return t * t * t
end

local function outCubic(t)
    local f = t - 1
    return f * f * f + 1
end

local function inOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        local f = (2 * t) - 2
        return 0.5 * f * f * f + 1
    end
end

local function outInCubic(t)
    if t < 0.5 then
        return outCubic(2 * t) / 2
    else
        return inCubic(2 * t - 1) / 2 + 0.5
    end
end

-- Quartic easing
local function inQuart(t)
    return t * t * t * t
end

local function outQuart(t)
    local f = t - 1
    return 1 - f * f * f * f
end

local function inOutQuart(t)
    if t < 0.5 then
        return 8 * t * t * t * t
    else
        local f = t - 1
        return -8 * f * f * f * f + 1
    end
end

local function outInQuart(t)
    if t < 0.5 then
        return outQuart(2 * t) / 2
    else
        return inQuart(2 * t - 1) / 2 + 0.5
    end
end

-- Quintic easing
local function inQuint(t)
    return t * t * t * t * t
end

local function outQuint(t)
    local f = t - 1
    return f * f * f * f * f + 1
end

local function inOutQuint(t)
    if t < 0.5 then
        return 16 * t * t * t * t * t
    else
        local f = (2 * t) - 2
        return 0.5 * f * f * f * f * f + 1
    end
end

local function outInQuint(t)
    if t < 0.5 then
        return outQuint(2 * t) / 2
    else
        return inQuint(2 * t - 1) / 2 + 0.5
    end
end

-- Sine easing
local function inSine(t)
    return -math.cos(t * (math.pi / 2)) + 1
end

local function outSine(t)
    return math.sin(t * (math.pi / 2))
end

local function inOutSine(t)
    return -0.5 * (math.cos(math.pi * t) - 1)
end

local function outInSine(t)
    if t < 0.5 then
        return outSine(2 * t) / 2
    else
        return inSine(2 * t - 1) / 2 + 0.5
    end
end

-- Exponential easing
local function inExpo(t)
    if t == 0 then
        return 0
    else
        return math.pow(2, 10 * (t - 1))
    end
end

local function outExpo(t)
    if t == 1 then
        return 1
    else
        return 1 - math.pow(2, -10 * t)
    end
end

local function inOutExpo(t)
    if t == 0 then
        return 0
    elseif t == 1 then
        return 1
    elseif t < 0.5 then
        return 0.5 * math.pow(2, (20 * t) - 10)
    else
        return -0.5 * math.pow(2, -20 * t + 10) + 1
    end
end

local function outInExpo(t)
    if t < 0.5 then
        return outExpo(2 * t) / 2
    else
        return inExpo(2 * t - 1) / 2 + 0.5
    end
end

-- Circular easing
local function inCirc(t)
    return 1 - math.sqrt(1 - t * t)
end

local function outCirc(t)
    local f = t - 1
    return math.sqrt(1 - f * f)
end

local function inOutCirc(t)
    if t < 0.5 then
        return 0.5 * (1 - math.sqrt(1 - 4 * t * t))
    else
        local f = (2 * t) - 2
        return 0.5 * (math.sqrt(1 - f * f) + 1)
    end
end

local function outInCirc(t)
    if t < 0.5 then
        return outCirc(2 * t) / 2
    else
        return inCirc(2 * t - 1) / 2 + 0.5
    end
end

-- Elastic easing
local function inElastic(t)
    if t == 0 or t == 1 then
        return t
    else
        return -math.pow(2, 10 * (t - 1)) * math.sin((t - 1.1) * 5 * math.pi)
    end
end

local function outElastic(t)
    if t == 0 or t == 1 then
        return t
    else
        return math.pow(2, -10 * t) * math.sin((t - 0.1) * 5 * math.pi) + 1
    end
end

local function inOutElastic(t)
    if t == 0 or t == 1 then
        return t
    elseif t < 0.5 then
        return -0.5 * math.pow(2, 20 * t - 10) * math.sin((20 * t - 11.125) * (2 * math.pi) / 4.5)
    else
        return math.pow(2, -20 * t + 10) * math.sin((20 * t - 11.125) * (2 * math.pi) / 4.5) * 0.5 + 1
    end
end

local function outInElastic(t)
    if t < 0.5 then
        return outElastic(2 * t) / 2
    else
        return inElastic(2 * t - 1) / 2 + 0.5
    end
end

-- Back easing
local function inBack(t)
    local s = 1.70158
    return t * t * ((s + 1) * t - s)
end

local function outBack(t)
    local s = 1.70158
    local f = t - 1
    return f * f * ((s + 1) * f + s) + 1
end

local function inOutBack(t)
    local s = 1.70158 * 1.525
    if t < 0.5 then
        return 0.5 * (t * 2) * (t * 2) * ((s + 1) * t * 2 - s)
    else
        local f = t * 2 - 2
        return 0.5 * (f * f * ((s + 1) * f + s) + 2)
    end
end

local function outInBack(t)
    if t < 0.5 then
        return outBack(2 * t) / 2
    else
        return inBack(2 * t - 1) / 2 + 0.5
    end
end

-- Bounce easing

local function outBounce(t)
    if t < (1 / 2.75) then
        return 7.5625 * t * t
    elseif t < (2 / 2.75) then
        local f = t - (1.5 / 2.75)
        return 7.5625 * f * f + 0.75
    elseif t < (2.5 / 2.75) then
        local f = t - (2.25 / 2.75)
        return 7.5625 * f * f + 0.9375
    else
        local f = t - (2.625 / 2.75)
        return 7.5625 * f * f + 0.984375
    end
end

local function inBounce(t)
    return 1 - outBounce(1 - t)
end


local function inOutBounce(t)
    if t < 0.5 then
        return inBounce(t * 2) * 0.5
    else
        return outBounce(t * 2 - 1) * 0.5 + 0.5
    end
end

local function outInBounce(t)
    if t < 0.5 then
        return outBounce(2 * t) / 2
    else
        return inBounce(2 * t - 1) / 2 + 0.5
    end
end

local function constant0(t)
    return 0
end

local function constant1(t)
    return 1
end

local ease = {
	linear    = linear,
	inQuad    = inQuad,    outQuad    = outQuad,    inOutQuad    = inOutQuad,    outInQuad    = outInQuad,
	inCubic   = inCubic,   outCubic   = outCubic,   inOutCubic   = inOutCubic,   outInCubic   = outInCubic,
	inQuart   = inQuart,   outQuart   = outQuart,   inOutQuart   = inOutQuart,   outInQuart   = outInQuart,
	inQuint   = inQuint,   outQuint   = outQuint,   inOutQuint   = inOutQuint,   outInQuint   = outInQuint,
	inSine    = inSine,    outSine    = outSine,    inOutSine    = inOutSine,    outInSine    = outInSine,
	inExpo    = inExpo,    outExpo    = outExpo,    inOutExpo    = inOutExpo,    outInExpo    = outInExpo,
	inCirc    = inCirc,    outCirc    = outCirc,    inOutCirc    = inOutCirc,    outInCirc    = outInCirc,
	inElastic = inElastic, outElastic = outElastic, inOutElastic = inOutElastic, outInElastic = outInElastic,
	inBack    = inBack,    outBack    = outBack,    inOutBack    = inOutBack,    outInBack    = outInBack,
	inBounce  = inBounce,  outBounce  = outBounce,  inOutBounce  = inOutBounce,  outInBounce  = outInBounce,
	constant0 = constant0, constant1 = constant1
}

-- keeping this around so you remember that you did this wrong
-- set this in the metatable, not the table itself
-- function ease.__call(...) 
-- 	return ease[...]
-- end

-- local mt = {
-- 	__call = function(_, ...)
-- 		return ease[...]
-- 	end
-- }

return function (ease_type)
	--- linear   		
	--- inQuad   		outQuad   		inOutQuad   	outInQuad    
	--- inCubic  		outCubic  		inOutCubic  	outInCubic   
	--- inQuart  		outQuart  		inOutQuart  	outInQuart   
	--- inQuint  		outQuint  		inOutQuint  	outInQuint   
	--- inSine   		outSine   		inOutSine   	outInSine    
	--- inExpo   		outExpo   		inOutExpo   	outInExpo    
	--- inCirc   		outCirc   		inOutCirc   	outInCirc    
	--- inElastic		outElastic		inOutElastic	outInElastic 
	--- inBack   		outBack   		inOutBack   	outInBack    
	--- inBounce 		outBounce 		inOutBounce 	outInBounce  
	return ease[ease_type]
end
