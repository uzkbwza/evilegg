local CircularBuffer = setmetatable({}, {
    __call = function(cls, size)
        return setmetatable({
            buffer = {},      -- Holds the actual data
            size = size,      -- Maximum size of the buffer
            cursor = 0,       -- Current position in the buffer
            count = 0,        -- Number of elements currently in the buffer
        }, {
            __index = cls
        })
    end
})

-- Add a value to the circular buffer
function CircularBuffer:push(value)
    self.cursor = (self.cursor % self.size) + 1
    self.buffer[self.cursor] = value
    self.count = math.min(self.count + 1, self.size)
end

-- Get value at specific index (offset from cursor)
function CircularBuffer:get(index)
    if index < 1 or index > self.count then
        return nil
    end
    
    -- Calculate the actual position considering the cursor and wrap-around
    local position = self.cursor - self.count + index
    if position <= 0 then
        position = position + self.size
    end
    
    return self.buffer[position]
end

-- Iterator function for ipairs support
function CircularBuffer:ipairs()
    local index = 0
    local count = self.count
    
    return function()
        index = index + 1
        if index <= count then
            return index, self:get(index)
        end
    end
end

return CircularBuffer
