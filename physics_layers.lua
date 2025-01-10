PHYSICS_TERRAIN = 1
PHYSICS_PLAYER = 2
PHYSICS_OBJECT = 3
PHYSICS_ENEMY = 4
PHYSICS_HAZARD = 5

function to_layer_bit(...)
    local layers = {...}
    local b = 0
    for _, layer in ipairs(layers) do
        b = bit.bor(b, bit.lshift(1, layer - 1))
    end
    return b
end