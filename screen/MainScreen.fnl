(local Main-world (World:extend :MainWorld))
(local Main-screen (Canvas-layer:extend :MainScreen))
(fn Main-world.new [self x y] (Main-world.super.new self x y))
(fn Main-world.enter [self] (self:create_camera))
(fn Main-world.update [self dt])
(fn Main-world.draw [self])
(fn Main-screen.enter [self]
  (self:ref :world (self:add_world (Main-world 0 0))))
(fn Main-screen.update [self dt])
(fn Main-screen.draw [self])
Main-screen	
