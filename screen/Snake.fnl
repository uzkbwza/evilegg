(import-macros {: l-extend } :macros.object)
(local grid-size conf.viewport_size.x)
(local empty-cell 0)
(local food-cell 1)
(local snake-cell 2)
(l-extend CanvasLayer game)
(fn game.enter [self]
	(self:start-game!))
(fn game.start-game! [self]
	(let [s self.sequencer
		  grid {}
		  snake-dir (Vec2 0 -1)]
		(set self.grid grid)
		(set self.snake-length 1)
		(set self.finished? false)
		(set self.snake-dir (Vec2 0 -1))
		(set self.last-dir (Vec2 0 -1))
		(set self.snake-position (Vec2 (floor (/ grid-size 2)) (floor (/ grid-size 2))))
		(set self.snake-cells [])
		(for [y 1 grid-size]
			(tset grid y {})
			(for [x 1 grid-size]
				(tset (. grid y) x empty-cell)))
		(for [i 1 3]
			(self:add-snake-cell self.snake-position.x self.snake-position.y))
		(self:place-random-fruit!)
		(self:update-state!)
		(s:start (fn []
			(while (not self.finished?)
				(s:wait 5)
				(self:update-state!))
			(self:start-game!)))))
(fn game.update-state! [self]
	(self:try-move-snake self.snake-dir.x self.snake-dir.y))
(fn game.place-random-fruit! [self]
	(var x (rng.randi 1 grid-size))
	(var y (rng.randi 1 grid-size))
	(while (not= empty-cell (self:get-cell-type x y))
		(set x (rng.randi 1 grid-size))
		(set y (rng.randi 1 grid-size)))
	(self:add-food-cell x y))
(fn game.try-move-snake [self dx dy]
	(let [pos self.snake-position
		  new-x (+ 1 (% (- (+ dx pos.x) 1) grid-size))
		  new-y (+ 1 (% (- (+ dy pos.y) 1) grid-size))
		  existing-cell-type (self:get-cell-type new-x new-y)]
		(set self.last-dir (Vec2 dx dy))
		(case existing-cell-type
			0 (self:move-snake-to new-x new-y true)
			1 (do (self:move-snake-to new-x new-y)
					(self:place-random-fruit!))
			2 (self:end-game!))))
(fn game.end-game! [self] 
	(set self.finished? true))
(fn game.move-snake-to [self new-x new-y clear]
	(let [pos self.snake-position]
		(when clear
			(self:clear-snake-tail-segment!))
		(set pos.x new-x)
		(set pos.y new-y)
		(self:add-snake-cell new-x new-y)))
(fn game.add-snake-cell [self x y]
	(table.insert self.snake-cells (self.snake-position:clone))
	(tset self.grid y x snake-cell))
(fn game.clear-snake-tail-segment! [self]
	(let [cells self.snake-cells
		  tail-pos (. cells 1)]
		  	(self:clear-cell tail-pos.x tail-pos.y)
			(table.remove cells 1)))
(fn game.update [self]
	(let [input (self:get_input_table)]
		(when (and input.move_up_pressed (not= self.last-dir.y 1))
			(set self.snake-dir.x 0)
			(set self.snake-dir.y -1))
		(when (and input.move_left_pressed (not= self.last-dir.x 1))
			(set self.snake-dir.x -1)
			(set self.snake-dir.y 0))
		(when (and input.move_right_pressed (not= self.last-dir.x -1))
			(set self.snake-dir.x 1)
			(set self.snake-dir.y 0))
		(when (and input.move_down_pressed (not= self.last-dir.y -1))
			(set self.snake-dir.x 0)
			(set self.snake-dir.y 1))))
(fn game.clear-cell [self x y] 
	(tset self.grid y x empty-cell))
(fn game.add-food-cell [self x y]
	(tset self.grid y x food-cell))
(fn game.get-cell-type [self x y]
	(. self.grid y x))
(fn game.draw [self]
		(for [y 1 grid-size]
			(for [x 1 grid-size]
				(let [cell_type  (self:get-cell-type x y)]
				(when (> cell_type 0)
					(let [color (if (= snake-cell cell_type) Color.white Color.red)]
						(graphics.set_color color)
						(graphics.points x y)))))))
game
