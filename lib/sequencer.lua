
Sequencer = Object:extend("Sequencer")

-- Example usage: 
--[[
s:start(function()
		-- wait for one second
		s:wait(60)
		-- print hello
		print("hello")
		-- tween my position to the left over a second
		s:tween_property(self.pos, "x", self.pos.x, -30, 60.0, "inOutQuad")
		-- wait until i move back to the right
		s:wait_for(function() return self.pos.x >= 0 end)
		-- print goodbye
		print("goodbye")
end)
]]

function Sequencer:new()
    self.running = {}
	self.running_indices = {}
	self.suspended = {}
	self.dt = 0
	self.elapsed = 0
end

function Sequencer:start(func)
    local co = coroutine.create(func)
    self:init_coroutine(co)
    return co
end

function Sequencer:stop(co)
	if co == nil then return end
    local index = self.running_indices[co]
	if index == nil then return end

	local length = #self.running
    local last = self.running[length]
    self.running[index] = last
    self.running_indices[last] = index
    self.running[length] = nil
    self.running_indices[co] = nil
	
	self.suspended[co] = nil
end

function Sequencer:do_while(condition, f)

	local func = (function()
		while condition() do
			self:call(f)
		end
	end)

	self:start(func)
end

function Sequencer:start_chain(...)
	self:start(self:chain(...))
end

function Sequencer:loop(func, times)
	assert(times == nil or type(times) == "number", "times must be a number")
	if times == nil then
		while true do
			self:call(func)
		end
	end
	for i = 1, times do
		self:call(func)
	end
end

function Sequencer:clear_all()
	self.running = {}
	self.running_indices = {}
	self.suspended = {}
end

function Sequencer:init_coroutine(co)
    table.insert(self.running, co)
	self.running_indices[co] = #self.running
end

function Sequencer:update(dt)

	if (not self.running) or table.is_empty(self.running) then
		return
	end

	self.dt = dt

	for _, co in ipairs(self.running) do
		self.current_chain = co
        if self.suspended[co] == nil then
			if coroutine.status(co) ~= "dead" then
				local status, val, traceback = coroutine.xpcall(co)
				if not status then
					error(val .. "\n" .. traceback)
				end
			end
		end
	end

    for i = #self.running, 1, -1 do
		local co = self.running[i]
        if not (self.suspended[co] ~= nil or coroutine.status(co) ~= "dead") then
			self:stop(co)
		end
	end

	-- table.fast_remove(self.running, function(t, i, j)
	-- 	local co = t[i]
	-- 	return self.suspended[co] ~= nil or coroutine.status(co) ~= "dead"
	-- end)

	self.elapsed = self.elapsed + dt
	-- print(#self.running)

end

function Sequencer:wait(duration)
	local finish = self.elapsed + duration
	while self.elapsed < finish do
		coroutine.yield()
	end
end

function Sequencer:tween(func, value_start, value_end, duration, easing, step)
	local start = self.elapsed
    local finish = self.elapsed + duration
	local ease_func
	easing = easing or "linear"
	if type(easing) == "string" then
		ease_func = ease(easing)
	else
		ease_func = easing
	end

	if step == nil then
		step = 0
	end

	while self.elapsed < finish do
		local t = clamp01(ease_func(stepify_safe((self.elapsed - start) / duration, step)))
		func(value_start + t * (value_end - value_start))
		coroutine.yield()
	end
end

function Sequencer:tween_method(obj, method, value_start, value_end, duration, easing, step)
	local start = self.elapsed
    local finish = self.elapsed + duration
	local ease_func
	easing = easing or "linear"
	if type(easing) == "string" then
		ease_func = ease(easing)
	else
		ease_func = easing
	end

	if step == nil then
		step = 0
	end

	while self.elapsed < finish do
		local t = clamp01(ease_func(stepify_safe((self.elapsed - start) / duration, step)))
		method(obj, value_start + t * (value_end - value_start))
		coroutine.yield()
	end
end


function Sequencer:tween_property(obj, property, value_start, value_end, duration, easing, step)
	return self:tween(function(value) obj[property] = value end, value_start, value_end, duration, easing, step)
end

function Sequencer:suspend(chain)
	chain = chain or self.current_chain
	self.suspended[chain] = true
	self.running[chain] = nil
end

function Sequencer:resume(chain)
	chain = chain or self.current_chain
	self.suspended[chain] = nil
	self.running[chain] = true
	self:init_coroutine(chain)
end

function Sequencer:wait_for(func)
	-- if Object.is(func, Signal) then
		-- self:suspend(self.current_chain)
		-- if Object.is(func, GameObjectSignal) then 
		-- 	func:connect(nil, function() self:resume(self.current_chain) end, true)
		-- else
		-- func:connect(function() self:resume(self.current_chain) end, true)
		-- end
		-- return
	-- end
	while not func() do
		coroutine.yield()
	end
end

function Sequencer:wait_for_signal(obj, signal_id)
	local chain = self.current_chain
	self:suspend(chain)
    signal.connect(obj, signal_id, self, "resume_after_obj_signal_" .. tostring(signal_id),
        function(...)
			self.signal_output = {...}
            self:resume(chain)
        end,
			true)
    if signal.get(obj, "destroyed") then
		if not signal.is_connected(obj, "destroyed", self, "cancel_chain") then
			signal.connect(obj, "destroyed", self, "cancel_chain", function() self:stop(chain) end, true)
		end
    end
	coroutine.yield()
end

function Sequencer:call(func)
	local co = coroutine.create(func)
	while coroutine.status(co) ~= "dead" do
		local status, val = coroutine.resume(co)
		if not status then
			error(val)
		end
		if val then
			self:call(val)
		end
		coroutine.yield()
	end
end

function Sequencer:destroy()
    self.running = nil
    self.running_indices = nil
    self.current_chain = nil
    self.signal_output = nil
	self.suspended = nil
	self.dt = nil
	self.elapsed = nil
end
