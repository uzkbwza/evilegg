local Graph = Object:extend("Graph")

function Graph:new(starting_graph, bidirectional)
    self.nodes = {}
    self.id2n = {}
    self.n2id = {}
    self.index = 1
    self.bidirectional = bidirectional or true

    if type(starting_graph) == "table" then
        for node, value in pairs(starting_graph) do
            self:add_node(node)
            
            if type(value) == "table" then
                if value[1] then -- array
                    for _, connection in ipairs(value) do
                        self:add_edge(node, connection, bidirectional)
                    end
                else -- dictionary
                    for connection, weight in pairs(value) do
                        self:add_edge(node, connection, bidirectional, weight)
                    end
                end
            elseif value ~= nil then
                self:add_edge(node, value, bidirectional)
            end
        end
    elseif starting_graph ~= nil then
        self:add_node(starting_graph)
    end
end

function Graph:_compute_cost(from, to)
    if not self.nodes[from][to] then
        assert(from == to)
        return 0.0
    end

    local weight = self.nodes[from][to]

    return weight
end

function Graph:replace_node(id, new_node)
    local old_node = self.id2n[id]
    
    self.nodes[new_node] = self.nodes[old_node]
    self.nodes[old_node] = nil
    
    for node, connections in pairs(self.nodes) do
        for connection, weight in pairs(connections) do
            if connection == old_node then
                connections[new_node] = weight
                connections[connection] = nil
            end
        end
    end
    
    self.n2id[old_node] = nil
    self.n2id[new_node] = id
    self.id2n[id] = new_node
end

function Graph:remove_node(node_to_remove)
    self.nodes[node_to_remove] = nil
    for _, edge_list in pairs(self.nodes) do
        edge_list[node_to_remove] = nil
    end
    
    local id = self.n2id[node_to_remove]
    self.n2id[node_to_remove] = nil
    self.id2n[id] = nil
end

function Graph:add_edge(node1, node2, bidirectional, weight)
    if bidirectional == nil then bidirectional = self.bidirectional end
    weight = weight or 1
    
    self:add_node(node1)
    self:add_node(node2)
    
    self.nodes[node1][node2] = weight
    if bidirectional then
        self.nodes[node2][node1] = weight
    end
end

function Graph:remove_edge(node1, node2, bidirectional)
    if bidirectional == nil then bidirectional = self.bidirectional end
    
    self.nodes[node1][node2] = nil
    if bidirectional then
        self.nodes[node2][node1] = nil
    end
end

function Graph:is_node_connected(node1, node2)
    return self.nodes[node1][node2] ~= nil
end

function Graph:dist_from_path(path)
    if #path <= 1 then
        return 0
    end
    
    local total_dist = 0
    for i = 1, #path - 1 do
        local current = path[i]
        local next = path[i + 1]
        total_dist = total_dist + self:_compute_cost(current, next)
    end
    return total_dist
end

function Graph:print_graph()
    for node, edges in pairs(self.nodes) do
        local edge_text = ""
        for edge, weight in pairs(edges) do
            edge_text = edge_text .. tostring(edge) .. ": " .. tostring(weight) .. ", "
        end
        print(tostring(node) .. ": [" .. edge_text .. "]")
    end
end

return Graph
