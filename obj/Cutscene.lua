local Cutscene = GameObject2D:extend("Cutscene")
local BeginningCutscene = Cutscene:extend("BeginningCutscene")
local EndingCutscene1 = Cutscene:extend("EndingCutscene1")
local EndingCutscene2 = Cutscene:extend("EndingCutscene2")
local BigRescueSpriteSheet = SpriteSheet(textures["ally_rescue-sheet"], 12, 10)
local Poisson = require "lib.poisson"

local PLANET_Y = 25
local EGG_Y = -35
local SUN_Y = -60

local SKIP_CUTSCENE1 = false

SKIP_CUTSCENE1 = SKIP_CUTSCENE1 and debug.enabled

function Cutscene:new(x, y)
	Cutscene.super.new(self, x, y)
	self:add_time_stuff()
    self:add_tag_on_enter("cutscene")
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
    self.is_drawing_in_greenoids = true
    self:init_state_machine()
    local width = conf.viewport_size.y * (16 / 9) * 1.5
    local height = conf.viewport_size.y * 1.5
    local poisson = Poisson(width, height, 6, 3)
    local points = poisson:generate()
    self.irng = rng:new_instance()

    self.greenoids = {
    }
    for _, point in ipairs(points) do
        table.insert(self.greenoids, {
            x = point[1] - width / 2,
            y = point[2] - height / 2,
            size = 1.0,
            random_offset = rng:randi(),
        })
    end

    print(#self.greenoids)

    table.sort(self.greenoids, function(a, b) return a.y < b.y end)
end

function EndingCutscene1:enter()
	local s = self.world.timescaled.sequencer
	s:start(function()
        if self.is_destroyed then return end
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
    if SKIP_CUTSCENE1 then self:queue_destroy() end
end

function EndingCutscene1:state_Scene1_exit()
	self:pause_stopwatch("infect_world")
end

function EndingCutscene1:state_Scene1_enter()
    local s = self.world.timescaled.sequencer
    s:start(function()
        if self.is_destroyed then return end
        if not self.scene1_started then
            self.scene1_started = true

            s:wait(163)
            self:change_state("Scene2")
        else
            self:start_destroy_timer(240)
            s:wait(75)
            self:spawn_tower() 
        end
    end)
end

function EndingCutscene1:get_clear_color()
    if self.showing_tower then
        -- local color = Color.darkpurple:clone()
        -- local stopwatch = self:get_stopwatch("spawn_tower")
        -- if stopwatch then
        --     local t = 1 - clamp01(stopwatch.elapsed / 240)
        --     color.r = color.r * t
        --     color.g = color.g * t
        --     color.b = color.b * t
        -- end
        return Color.darkpurple
    end
    return nil
end

function EndingCutscene1:spawn_tower()
    self.showing_tower = true
    self.world.camera:set_rumble_directly(1)

    self.is_drawing_in_greenoids = false
    self.drawing_in_points = {}
    self:start_stopwatch("spawn_tower")
    -- self.world.camera:start_rumble(3, 180, ease("inCubic"), true, true)
    -- self:play_sfx("enemy_evil_egg_pillar_spawn")
end


function EndingCutscene1:state_Scene1_update(dt)
	local stopwatch = self:get_stopwatch("infect_world")
	if stopwatch then
		if self.is_new_tick and #self.stencil_points < 75 then
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
		point.y = point.y + dt * 0.035 * point.speed * (self.showing_tower and 4 or 1)
		-- if point.y > self.stencil_height then
		-- table.remove(self.stencil_points, i)
		-- end
	end
	local stopwatch2 = self:get_stopwatch("drawing_in_particles")
	if stopwatch2 then
		for i=1, 1 do
			if self.is_new_tick and rng:percent(clamp(stopwatch2.elapsed / 50, 0, 1) * 90) and self.is_drawing_in_greenoids then
				local point = {
					dist = max(abs(rng:randfn(10, 20)), 10),
					angle = deg2rad(90) + rng:randf(-tau/4, tau/4),
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
    if not self.showing_tower then 
	    draw_stars(self.stars)
    end
	graphics.set_color(Color.white)
	if iflicker(self.tick, 1, 2) then
		graphics.draw_centered(textures.cutscene_sun, 0, SUN_Y)
	end

	graphics.push("all")
	for point, _ in pairs(self.drawing_in_points) do
		graphics.set_color(Color.green)
		graphics.points(point.x, point.y + EGG_Y)
	end
	graphics.pop()

    if not self.showing_tower then
		graphics.drawp_centered(textures.cutscene_tiny_egg, Palette.bothways, idiv(self.tick, 1), 0, EGG_Y)
    end
    graphics.drawp_centered(textures.cutscene_planet_greenoid, self.showing_tower and Palette.cutscene_egg_greenoid_planet, self.showing_tower and idiv(self.tick, 3) or 0, 0, PLANET_Y)
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
    
    if self.showing_tower then
        graphics.drawp_centered(textures.cutscene_egg_pillar, Palette.bothways, idiv(self.tick + 2, 1), 0, EGG_Y - 154)
    end
end


function EndingCutscene1:state_Scene2_enter()
    local s = self.world.timescaled.sequencer
    s:start(function()
        s:wait(240)
        self:change_state("Scene1")
    end)
end
 
function EndingCutscene1:state_Scene2_update(dt)
    for _, greenoid in ipairs(self.greenoids) do
        -- greenoid.x = greenoid.x + dt * 0.085 * greenoid.speed
        -- greenoid.y = greenoid.y + dt * 0.085 * greenoid.speed
    end
end


local ASCEND_TIME = 80

function EndingCutscene1:state_Scene2_draw()
    for _, greenoid in ipairs(self.greenoids) do
        local texture_id = iflicker(self.state_tick + greenoid.random_offset, 10, 2) and 1 or 2
        local texture = BigRescueSpriteSheet:get_frame(texture_id)
        local irng = self.irng
        irng:set_seed(greenoid.random_offset)
        local delay = irng:randi(0, 300 + vec2_magnitude_squared(greenoid.x, greenoid.y) / 100)
        local t = clamp(inverse_lerp(delay, delay + ASCEND_TIME, self.state_tick), 0, 1)
        local ascend_offset = -400 * ease("inCubic")(t)

        if t < 1 then
            graphics.drawp_centered(texture, nil, 0, greenoid.x, greenoid.y + ascend_offset)
        end
    end
end

function EndingCutscene1:exit()
    if self.world and self.world.camera and self.world.camera.set_rumble_directly then
        self.world.camera:set_rumble_directly(0)
    end
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
