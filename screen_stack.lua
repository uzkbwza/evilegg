local ScreenStack = Object:extend("ScreenStack")

function ScreenStack:new()
    self.stack = {}
    self.queue = {}
    self.sequencer = Sequencer()
    self.screen_above = nil
    self.screen_below = nil
end

function ScreenStack:push_deferred(screen)
    table.push_back(self.queue, screen)
end

function ScreenStack:pop_deferred()
    table.push_back(self.queue, "pop")
end

function ScreenStack:push_screen(screen)
    screen = self:screen_from_name(screen)
    if self.stack[1] then
        self.stack[1].screen_above = screen
        screen.screen_below = self.stack[1]
    end

    table.push_front(self.stack, screen)
    self:init_screen(screen)
end

function ScreenStack:init_screen(screen)
    screen.stack = self
    signal.connect(screen, "screen_pushed", self, "push_deferred", self.push_deferred)
    signal.connect(screen, "screen_popped", self, "pop_deferred", self.pop_deferred)
    screen:enter_shared()
    
    collectgarbage()
end

function ScreenStack:replace_screen(screen, new)
    for i, v in ipairs(self.stack) do 
        if v == screen then 
            v:exit_shared()
            
            local new_screen = self:screen_from_name(new)
            self.stack[i] = new_screen
            self:init_screen(new_screen)
            collectgarbage()
            return
        end
    end
end

function ScreenStack:pop_screen()
    local screen = table.pop_front(self.stack)
    if screen then
        screen:exit_shared()
    end
    if self.stack[1] then
        self.stack[1].screen_above = nil
    end
    collectgarbage()
    if screen then 
        screen:destroy()
    end
end

function ScreenStack:screen_from_name(screen)
    if type(screen) == "string" then
        return require("screen." .. game_screens[screen])()
    end
    return screen
end

function ScreenStack:transition_to_screen(new_screen)
    self:pop_screen()
    self.stack = {}
    self:push_deferred(new_screen)
end

function ScreenStack:update_input_stack(input_table)
    local screen_process_input = true
    for _, v in ipairs(self.stack) do
        v.input = screen_process_input and input_table or input.dummy
        if v.blocks_input then
            screen_process_input = false
        end
    end
end

function ScreenStack:update(dt)
    -- input
    self:update_input_stack(input)
    
    -- update queue
    while table.length(self.queue) > 0 do
        local screen = table.pop_front(self.queue)
        if screen == "pop" then
            self:pop_screen()
        else
            self:push_screen(screen)
        end
    end

    -- update screens
    for _, v in ipairs(self.stack) do
        v:update_shared(dt)    
        if v.blocks_logic then
            break
        end
    end
    self.sequencer:update(dt)
end

function ScreenStack:draw()
    graphics.screen_stack = self.stack
    graphics.draw_loop()
end

return ScreenStack 
