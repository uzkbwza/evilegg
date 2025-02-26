local Pit = GameObject:extend("Pit")

function Pit:new(x, y)
    Pit.super.new(self, x, y)
end

return Pit
