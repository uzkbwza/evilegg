local MainScreen = CanvasLayer:extend("MainScreen")

-- cracked out mixin demo
-- TODO: name it something different... mixins?

local TestMixup = Object:extend("TestMixup")
local TestMixup2 = Object:extend("TestMixup2")

function TestMixup:__mix_init(...)
    print("TestMixup init", ...)
end

function TestMixup:test()
    print("TestMixup test")
end

function TestMixup2:__mix_init(...)
    print("TestMixup2 init", ...)
end

function TestMixup2:test2()
    print("TestMixup2 test")
end

local TestObject = Object:extend("TestObject")

-- implement mixin on class with global args for initializing instances
TestObject:implement(TestMixup, "(init arg 1)", "(init arg 2)")

function TestObject:new()
    TestObject.super.new(self)

	self:test()
	-- > TestMixup test

	-- TODO: error if already initialized?
    -- mix_init:
    -- initialize instance with one of its class's mixins
    -- this is not done automatically because some mixins
	-- may rely on other things to be initialized first
	-- use global args implicitly
	self:mix_init(TestMixup)
    -- > TestMixup init (init arg 1) (init arg 2)


    -- override global args
    self:mix_init(TestMixup, "(hi)")
	-- > TestMixup init (hi) (init arg 2)

	-- dyna mixin:
	-- dynamic mixin, adds methods to the instance without having to implement it on the class
	-- will error if mixin is already implemented on the class
    self:dyna_mixin(TestMixup2, "hi")
    -- > TestMixup2 init hi
	self:test2()
	-- > TestMixup2 test

	-- Lazy mixin:
	-- implements the mixin on the class if it is not already implemented
	-- then initializes the instance with the mixin
    self:lazy_mixin(TestMixup2, "hi")
	-- > TestMixup2 init hi
	self:test2()
	-- > TestMixup2 test
end

function MainScreen:new()
    MainScreen.super.new(self)
	local t = TestObject()
    -- t:test()
	local t2 = TestObject()
	-- t2:test()
	
end

function MainScreen:update(dt)
end

return MainScreen
