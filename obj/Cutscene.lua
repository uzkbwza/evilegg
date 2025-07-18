local Cutscene = GameObject2D:extend("Cutscene")
local BeginningCutscene = Cutscene:extend("BeginningCutscene")
local EndingCutscene1 = Cutscene:extend("EndingCutscene1")
local EndingCutscene2 = Cutscene:extend("EndingCutscene2")

local PLANET_Y = 25
local EGG_Y = -35
local SUN_Y = -60

function Cutscene:new(x, y)
	Cutscene.super.new(self, x, y)
	self:add_time_stuff()
	self.z_index = 1000
end

local STAR_COLORS = {
	Color.darkblue,
	Color.purple,
	Color.magenta,
	Color.white,

}

local function generate_stars(seed)
	local irng = rng:new_instance()
	irng:set_seed(seed or 0)
	local width = 600
	local height = 500
	local stars = {}
	for _ = 1, 500 do
		local star = {
			x = irng:randi(-width / 2, width / 2),
			y = irng:randi(-height / 2, height / 2),
			color = irng:choose(STAR_COLORS),
			offset = irng:randi(),
			flicker_time = irng:randi(2, 12),
		}
		table.insert(stars, star)
	end

	return stars
end

local function draw_stars(stars)
	graphics.push("all")
	for _, star in ipairs(stars) do
		if not iflicker(gametime.tick + star.offset, 2, star.flicker_time) then
			graphics.set_color(star.color)
			graphics.points(star.x, star.y)
		end
	end
	graphics.pop()
end

function EndingCutscene1:new(x, y)
	EndingCutscene1.super.new(self, x, y)
	self.stars = generate_stars()
	self.stencil_points = {}
	self.drawing_in_points = {}
	self:init_state_machine()

end

function EndingCutscene1:enter()
	local s = self.world.timescaled.sequencer
	s:start(function()
		-- s:wait(10)
		self:start_stopwatch("infect_world")
		s:wait(20)
		self:start_stopwatch("drawing_in_particles")
	end)
	local overlay_tex = textures.cutscene_infected_planet_greenoid
	local data = graphics.texture_data[overlay_tex]
	local height = data:getHeight()
	local width = data:getWidth()
	-- self.stencil_canvas = graphics.new_canvas(width, height)
	self.stencil_width = width
	self.stencil_height = height
end

function EndingCutscene1:state_Scene1_exit()
	self:pause_stopwatch("infect_world")
end

function EndingCutscene1:state_Scene1_enter()
	local s = self.world.timescaled.sequencer
	s:start(function()
		s:wait(163)
		self:change_state("Scene2")
	end)
end

function EndingCutscene1:state_Scene1_update(dt)
	local stopwatch = self:get_stopwatch("infect_world")
	if stopwatch then
		if self.is_new_tick and #self.stencil_points < 50 then
			local progress = clamp(stopwatch.elapsed / 600, 0, 1)
			local point = {
				x = rng:randi(-self.stencil_width / 2, self.stencil_width / 2),
				y = -self.stencil_height / 2,
				speed = rng:randf(0.5, 3.0)
			}
			point.start_y = point.y
			table.insert(self.stencil_points, point)
		end
	end
	for i = #self.stencil_points, 1, -1 do
		local point = self.stencil_points[i]
		point.y = point.y + dt * 0.085 * point.speed
		-- if point.y > self.stencil_height then
		-- table.remove(self.stencil_points, i)
		-- end
	end
	local stopwatch2 = self:get_stopwatch("drawing_in_particles")
	if stopwatch2 then
		for i=1, 1 do
			if self.is_new_tick and rng:percent(clamp(stopwatch2.elapsed / 50, 0, 1) * 90) then
				local point = {
					dist = max(abs(rng:randfn(10, 20)), 10),
					angle = rng:randf(0, tau),
					speed = rng:randf(0.5, 3.0),
					vel = 0,
				}
				self.drawing_in_points[point] = true
			end
		end
	end
	local particles_to_remove = {}
	for point, _ in pairs(self.drawing_in_points) do
		point.vel = point.vel + dt * 0.085 * point.speed
		point.dist = point.dist - point.vel * dt
		point.x, point.y = vec2_from_polar(point.dist + 7, point.angle)
		-- point.angle = point.angle + dt * 0.085 * point.vel
		if point.dist < 0 then
			table.insert(particles_to_remove, point)
		end
	end
	for i = #particles_to_remove, 1, -1 do
		self.drawing_in_points[particles_to_remove[i]] = nil
	end
end


function EndingCutscene1:state_Scene1_draw()
	draw_stars(self.stars)
	graphics.set_color(Color.white)
	if iflicker(self.tick, 1, 2) then
		graphics.draw_centered(textures.cutscene_sun, 0, SUN_Y)
	end

	graphics.push("all")
	for point, _ in pairs(self.drawing_in_points) do
		graphics.set_color(Color.magenta)
		graphics.points(point.x, point.y + EGG_Y)
	end
	graphics.pop()

	graphics.drawp_centered(textures.cutscene_tiny_egg, Palette.bothways, idiv(self.tick, 1), 0, EGG_Y)
	graphics.drawp_centered(textures.cutscene_planet_greenoid, nil, 0, 0, PLANET_Y)
	local stopwatch = self:get_stopwatch("infect_world")
	if stopwatch then
		graphics.push("all")
		local overlay_tex = textures.cutscene_infected_planet_greenoid
		local data = graphics.texture_data[overlay_tex]
		-- local height = data:getHeight()
		-- local width = data:getWidth()

		
		graphics.set_stencil_mode("draw", 1)
		-- graphics.rectangle("fill", -width / 2, -height / 2 + PLANET_Y, width, height * progress)
		graphics.push("all")
		-- graphics.set_canvas(self.stencil_canvas)
		-- graphics.origin()
		graphics.set_line_width(12)
		for _, point in ipairs(self.stencil_points) do
			graphics.line(point.x, point.start_y + PLANET_Y, point.x, point.y + PLANET_Y)
		end
		graphics.pop()
		-- graphics.draw_centered(self.stencil_canvas, 0, PLANET_Y)


		graphics.set_stencil_mode("test", 1)
		graphics.drawp_centered(overlay_tex, Palette.bothways, idiv(self.tick, 1), 0, PLANET_Y)
		graphics.pop()

	end
end

function EndingCutscene1:state_Scene2_enter()
end


function EndingCutscene2:new(x, y)
	EndingCutscene2.super.new(self, x, y)
end

AutoStateMachine(EndingCutscene1, "Scene1")

return {
	Cutscene = Cutscene,
	BeginningCutscene = BeginningCutscene,
	EndingCutscene1 = EndingCutscene1,
	EndingCutscene2 = EndingCutscene2
}
