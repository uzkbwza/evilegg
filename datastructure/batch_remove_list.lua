local BatchRemoveList = Object:extend("BatchRemoveList")

function BatchRemoveList:new()
    self.__array = {}
    self.__to_remove = {}
end

function BatchRemoveList:push(value)
    table.insert(self.__array, value)
end

function BatchRemoveList:ipairs()
    local index = 0
    local t = self.__array
    return function()
        index = index + 1
        if t[index] then
            return index, t[index]
        end
    end
end

function BatchRemoveList:length()
    return #self.__array
end

function BatchRemoveList:queue_remove(value)
    self.__to_remove[value] = true
end

function BatchRemoveList:is_empty()
    return #self.__array == 0
end

function BatchRemoveList:apply_removals()

    if table.is_empty(self.__to_remove) then return end

    for obj in pairs(self.__to_remove) do
        table.erase(self.__array, obj)
    end
    table.clear(self.__to_remove)
end

return BatchRemoveList
