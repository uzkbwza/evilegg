(import-macros {: l-extend : fn-inherit} :macros.object)

(l-extend CanvasLayer main-screen)
(l-extend World main-world)

(fn main-world.enter [self]
	(self:init_camera))

(fn main-screen.new [self]
	(self.super.new self))

(fn main-screen.enter [self]
	(self:ref :world (self:add_world (main-world 0 0))))

(fn main-screen.update [self dt])

(fn main-screen.draw [self])

main-screen
