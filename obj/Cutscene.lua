local Cutscene = GameObject2D:extend("Cutscene")
local BeginningCutscene = Cutscene:extend("BeginningCutscene")
local EndingCutscene1 = Cutscene:extend("EndingCutscene1")
local EndingCutscene2 = Cutscene:extend("EndingCutscene2")
local BigRescueSpriteSheet = SpriteSheet(textures["ally_rescue-sheet"], 12, 10)
local Poisson = require "lib.poisson"
local PoissonVariableDensity = require "lib.poisson_variable_density"

local PLANET_Y = 25
local EGG_Y = -35
local SUN_Y = -60

local SKIP_CUTSCENE1 = false
local LAST_PLANET_STARS_SEED = 5245
local LAST_PLANET_STARS_SEED2 = 5246
local GREENOID_STARS_SEED = 5247
local GREENOID_STARS_SEED2 = 5248
local GREENOID_STARS_SEED3 = 5250

SKIP_CUTSCENE1 = SKIP_CUTSCENE1 and debug.enabled

local EGG_SHEET = SpriteSheet(textures.cutscene_enemy_egg, 12, 13)

function Cutscene:new(x, y)
	Cutscene.super.new(self, x, y)
	self:add_time_stuff()
    self:add_tag_on_enter("cutscene")
	self.z_index = -1000
end

local STAR_COLORS = {
	Color.darkblue,
	Color.purple,
	Color.magenta,
	Color.white,

}

local function generate_stars(seed, width, height, amount)
	local irng = rng:new_instance()
	irng:set_seed(seed or 0)
	local width = width or 1200
	local height = height or 600
	local stars = {}
	for _ = 1, amount or 500 do
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


function BeginningCutscene:new(x, y)
    BeginningCutscene.super.new(self, x, y)


    self.stars = generate_stars(LAST_PLANET_STARS_SEED)
    self.stars2 = generate_stars(LAST_PLANET_STARS_SEED2)
    self.greenoid_stars = generate_stars(GREENOID_STARS_SEED)
    self.greenoid_stars2 = generate_stars(GREENOID_STARS_SEED2)
    self.greenoid_stars3 = generate_stars(GREENOID_STARS_SEED3, 300, 300, 200)
    self.greenoid_stars4 = generate_stars(GREENOID_STARS_SEED3, nil, nil, 200)

    game_state.cutscene_hide_hud = true
    game_state.cutscene_no_pause = true
    self:init_state_machine()
    self.below_egg_y_offset = 0

    local irng = rng:new_instance()
    irng:set_seed(1)
    self.irng = irng

    local eggs = {}

    local EGGS_WIDTH = 700
    local EGGS_HEIGHT = 2200

    local poisson = PoissonVariableDensity(EGGS_WIDTH, EGGS_HEIGHT, function(x, y)
        return (remap_clamp(1 - pow(1 - y, 0.5), 0, 1, 16, 256))
    end, 3, 16, 128, irng)

    local points = poisson:generate()

    print("num eggs:", #points)

    for _, point in ipairs(points) do
        local egg_sheet_frame = irng:coin_flip() and 8 or 16
        local egg = {
            -- speed = irng:randf(0.9, 1.1),
            speed = 1.0,
            x = point[1] - EGGS_WIDTH / 2,
            y = point[2] - EGGS_HEIGHT - 300,
            random_offset = irng:randi(),
        }
        if irng:percent(25) then
            egg_sheet_frame = irng:randi(1, 16)
        end

        egg.tex = EGG_SHEET:get_frame(egg_sheet_frame)
        

        egg.trail_color = egg_sheet_frame <= 8 and Color.red or Color.orange


        if irng:percent(50) then
            egg.trail_color = Color.darkgrey
            egg.trail_outline = true
        end

        table.insert(eggs, egg)
    end

    self.eggs = eggs
    
    table.insert(eggs, {
        tex = textures.player_egg,
        x = -30,
        y = -800,
        speed = 0.5,
        good = true,
        trail_color = Color.magenta,
        -- scale = 1.0,
    })
    
    table.insert(eggs, {
        tex = textures.pickup_artefact_twin,
        x = 30,
        y = -800,
        speed = 0.45,
        good = false,
        trail_color = Color.magenta,
        -- scale = 1.0,
    })
    
    table.sort(eggs, function(a, b) return a.speed < b.speed end)
    
end

local BEAT_LENGTH = 7 * 32
local TRANSITION_LENGTH = 40

local INTRO_SCENE6_LENGTH = BEAT_LENGTH * 2

function BeginningCutscene:enter()
    local s = self.sequencer
    s:start(function()
        -- s:wait(debug.enabled and 1 or 20)
        -- s:wait(8 * 32)
        
        
        -- if debug.enabled then
        --     self:change_state("Scene6")
        --     s:wait(INTRO_SCENE6_LENGTH)
        --     self:change_state("Scene0")
        --     s:wait(TRANSITION_LENGTH * 2)
        --     self:queue_destroy()
        --     return
        -- end

        s:wait(60)
        
        audio.play_music("music_intro", 1, false)
        
        
        self:change_state("Scene1")
        s:wait(BEAT_LENGTH)
        -- self:change_state("Scene0")
        -- s:wait(TRANSITION_LENGTH)
        self:change_state("Scene2")
        s:wait(BEAT_LENGTH - TRANSITION_LENGTH)
        self:change_state("Scene0")
        s:wait(TRANSITION_LENGTH)
        self:change_state("Scene3")
        s:wait((BEAT_LENGTH * 1.5))
        -- self:change_state("Scene0")
        -- s:wait(TRANSITION_LENGTH)
        self:change_state("Scene4")
        -- audio.play_music("music_intro2", 0.9, false)
        s:wait((BEAT_LENGTH * 2 - TRANSITION_LENGTH * 2))
        self:change_state("Scene0")
        s:wait(TRANSITION_LENGTH * 2)
        -- self:change_state("Scene0")
        self:play_sfx("cutscene_egg_sound_2", 0.7)
        -- s:wait(BEAT_LENGTH / 2)
        self:change_state("Scene5")
        s:wait(BEAT_LENGTH - 40)
        self:play_sfx("cutscene_egg_sound_3", 0.7)
        s:wait(40)
        -- self:change_state("Scene0")
        -- s:wait(TRANSITION_LENGTH * 2)
        self:change_state("Scene6")
        s:wait(INTRO_SCENE6_LENGTH)
        self:change_state("Scene0")
        s:wait(TRANSITION_LENGTH * 2)
        self:queue_destroy()
    end)
end

function BeginningCutscene:update(dt)
    if not game_state.unskippable_intro then
        local input = self:get_input_table()
        if input.skip_intro_pressed then
            audio.stop_music()
            game_state.skip_intro = true
            self:stop_sfx("cutscene_egg_sound_1")
            self:stop_sfx("cutscene_egg_sound_2")
            self:stop_sfx("cutscene_egg_sound_3")
            self:stop_sfx("cutscene_greenoid_ship_hum")
            self:play_sfx("ui_menu_button_selected1", 0.6)
            self:queue_destroy()
        end
    end
end

function BeginningCutscene:state_Scene0_enter()
    
end

function BeginningCutscene:state_Scene1_enter()
    local s = self.world.timescaled.sequencer
    -- self:play_sfx("cutscene_egg_sound_1", 0.7)
end

function BeginningCutscene:state_Scene1_draw()
    self:draw_planet(false)
end

function BeginningCutscene:state_Scene2_enter()
    self:play_sfx("cutscene_egg_sound_1", 0.7)
    local delay = 60
    self:interpolate_property_after_eased("below_egg_y_offset", 0, 120, delay, BEAT_LENGTH - TRANSITION_LENGTH - delay,
        "inCubic")
end

function BeginningCutscene:state_Scene2_draw()
    draw_stars(self.stars2)

    graphics.push("all")


	if iflicker(gametime.tick, 1, 2) then
		graphics.draw_centered(textures.cutscene_sun, -40, -20)
	end

    graphics.translate(self.state_elapsed * 0.06 - 10, 0)

    local yoffs = -20 + sin(self.state_elapsed * 0.02) * 2
    yoffs = yoffs - self.below_egg_y_offset

    graphics.drawp_centered(textures.cutscene_egg_from_below, nil, 0, 20, yoffs)

    graphics.pop()



    graphics.push("all")
    
    
    graphics.translate(50 -self.state_elapsed * 0.15, 0)

    graphics.drawp_centered(textures.cutscene_planet_horizon1, nil, 0, 0, 25)

    
    graphics.pop()
end


function BeginningCutscene:state_Scene3_draw()
    draw_stars(self.greenoid_stars2)

    graphics.set_color(Color.white)

    graphics.push("all")


    if iflicker(gametime.tick, 1, 2) then
        graphics.draw_centered(textures.cutscene_sun, 30, -60)
    end

    graphics.translate(self.state_elapsed * 0.05 + 5, 0)

    local yoffs = -20 + sin(self.state_elapsed * 0.02) * 2
    yoffs = yoffs - self.below_egg_y_offset

    -- graphics.drawp_centered(textures.cutscene_egg_from_below, nil, 0, 20, yoffs)

    graphics.pop()


    graphics.push("all")


    graphics.translate(-60 + self.state_elapsed * 0.07, 0)



    local ship_shine = iflicker(self.state_tick + 2, 14, 15) or iflicker(self.state_tick + 3, 5, 60) or iflicker(self.state_tick + 5, 22, 6)

    if gametime.tick % 2 ~= 0 then
        ship_shine = false
    end

    graphics.drawp_centered(ship_shine and textures.cutscene_greenoid_ship2 or textures.cutscene_greenoid_ship1, nil, 0, 30 - self.state_elapsed * 0.05, -70)


    graphics.drawp_centered(textures.cutscene_greenoid_cloud1, nil, 0, -60 - self.state_elapsed * 0.32 * 1.1, -30)
    graphics.drawp_centered(textures.cutscene_greenoid_cloud2, nil, 0, 290 + self.state_elapsed * 0.21 * 1.1, -80)

    graphics.drawp_centered(textures.cutscene_greenoid_horizon, nil, 0, 0, 0)


    graphics.pop()
end

function BeginningCutscene:state_Scene4_enter()
    self:play_sfx("cutscene_greenoid_ship_hum", 0.4, 1.0, true)
    self.ship_greenoids = {
        {
            sprite = textures.ally_rescue_big5,
            x = -2,
            y = 67
        },
        {
            sprite = textures.ally_rescue_big4,
            x = -46,
            y = 70
        },
        {
            sprite = function()
                if iflicker(self.tick, 2, 80)  or iflicker(self.tick + 5, 2, 80) then
                    return textures.ally_rescue_big2
                end
                return textures.ally_rescue_big1
            end,
            x = 30,
            y = 82 
        },

        {
            sprite = textures.ally_rescue_big2,
            x = 67,
            y = 75 
        },

        
        {
            sprite = function()
                if iflicker(20 + self.tick, 2, 120)  or iflicker(self.tick + 5, 2, 110) then
                    return textures.ally_rescue_big2
                end
                return textures.ally_rescue_big1
            end,
            x = -67,
            y = 76 
        },

    }

    local REACTION_START = 60

    self:start_tick_timer("greenoid1_sprite_change", REACTION_START + 100, function()
        self.ship_greenoids[1].sprite = textures.ally_rescue_big4
    end)

    self:start_tick_timer("greenoid3_sprite_change", REACTION_START + 180, function()
        self.ship_greenoids[3].sprite = textures.ally_rescue_big4
    end)

    self:start_tick_timer("greenoid4_sprite_change", REACTION_START + 200, function()
        self.ship_greenoids[4].sprite = function()
            if iflicker(self.tick, 2, 80)  or iflicker(self.tick + 5, 2, 80) then
                return textures.ally_rescue_big2
            end
            return textures.ally_rescue_big1
        end
    end)

    self:start_tick_timer("greenoid5_sprite_change", REACTION_START + 160, function()
        self.ship_greenoids[5].sprite = textures.ally_rescue_big4
    end)

    
    self:start_tick_timer("greenoid4_sprite_change2", REACTION_START + 230, function()
        self.ship_greenoids[4].sprite = textures.ally_rescue_big4
    end)

    self.egg_shadow_size = 0
    self:interpolate_property_after_eased("egg_shadow_size", 0, 50, 100, 350, "linear")

    local STEP_DIST = 3

    local walk_up_sequence = function(greenoid, amount, delay)
        local target_y = greenoid.y - amount
        local s = self.sequencer
        s:start(function()
            s:wait(delay)
            while greenoid.y > target_y do
                local start_y = greenoid.y
                local walk = function(t)
                    greenoid.y = start_y - t * STEP_DIST - math.bump(t) * 5
                end
                s:tween(walk, 0, 1, 20, "linear")
            end
        end)
    end
    
    walk_up_sequence(self.ship_greenoids[3], 7, REACTION_START + 200)
    -- walk_up_sequence(self.ship_greenoids[5], 3, REACTION_START + 170)
end

function BeginningCutscene:state_Scene4_exit()
    self:stop_sfx("cutscene_greenoid_ship_hum")
end

function BeginningCutscene:state_Scene4_draw()
    draw_stars(self.greenoid_stars3)

    -- graphics.push("all")
    -- graphics.translate(0, 0)

    graphics.push("all")
    graphics.translate( - self.state_elapsed * 0.015, - self.state_elapsed * 0.007)
    graphics.drawp_centered(textures.cutscene_planet_greenoid_from_above1, nil, 0, -50, -30)

    -- if not iflicker(gametime.tick, 1, 3) then
    graphics.push("all")
    -- graphics.set_color(Color.white)
    graphics.set_stencil_mode("draw", 1)
    
    graphics.push("all")
    graphics.set_shader(graphics.shader.stencil_mask_alpha)
    graphics.poly_regular("fill", 20, -70, self.egg_shadow_size, 16, -deg2rad(15), 0.8, 1.0)
    graphics.pop()
    
    graphics.set_stencil_mode("test", 1)
    graphics.set_color(Color.white)
    graphics.draw_centered(textures.cutscene_planet_greenoid_from_above2, -50, -30)
    -- graphics.draw_centered(textures.cutscene_planet_greenoid_from_above1, -50, -30)
    graphics.pop()
    -- end


    graphics.pop()

    graphics.drawp_centered(textures.cutscene_greenoid_ship_interior, nil, 0, 0, 0)
    
    
    for _, greenoid in ipairs(self.ship_greenoids) do
        graphics.drawp_centered(resolve(greenoid.sprite), nil, 0, greenoid.x, greenoid.y)
    end
    
    graphics.drawp_centered(textures.cutscene_greenoid_ship_interface_front, nil, 0, 0, 90)
    -- graphics.pop()
end



function BeginningCutscene:draw_planet(greenoid)

    draw_stars(greenoid and self.greenoid_stars or self.stars)


    graphics.set_color(Color.white)
  


    graphics.set_color(Color.white)
	if iflicker(gametime.tick, 1, 2) then
		graphics.draw_centered(textures.cutscene_sun, 0, SUN_Y)
	end

    graphics.drawp_centered(textures.cutscene_tiny_egg, nil, 0, 0, EGG_Y)

    graphics.drawp_centered(greenoid and textures.cutscene_planet_greenoid or textures.cutscene_infected_planet_greenoid, nil, 0, 0, PLANET_Y)
end
function BeginningCutscene:state_Scene5_enter()
    self.enemy_line_t = 0
    self:interpolate_property_after_eased("enemy_line_t", 0, 1, 100, 200, "linear")
end

function BeginningCutscene:state_Scene5_draw()
    self:draw_planet(true)
    if self.enemy_line_t > 0 then
        graphics.set_color(Color.red)
        graphics.set_line_width(2)
        graphics.line(0, EGG_Y + 2, 0, EGG_Y + 2 + self.enemy_line_t * 6)
    end
end


function BeginningCutscene:state_Scene6_enter()
    self.falling_egg_particles = batch_remove_list()
    self.falling_egg_particle_association = {}

end

function BeginningCutscene:state_Scene6_update(dt)


    local irng = self.irng
    local rng_state = irng:randi()
    irng:set_seed(self.state_tick)

    for _, egg in ipairs(self.eggs) do
        egg.y = egg.y + dt * egg.speed * 5.0
        if self.is_new_tick and irng:percent(5) and egg.y > -300 and egg.y < 300 then
            local particle = {
                x = egg.x + irng:randf(-8, 8),
                y = egg.y + irng:randf(-8, 8),
                -- speed = irng:randf(0.1, 0.5),
                lifetime = irng:randf(30, 60),
                elapsed = 0,
                egg = egg,
            }
            self.falling_egg_particles:push(particle)
            self.falling_egg_particle_association[egg] = self.falling_egg_particle_association[egg] or makelist()
            self.falling_egg_particle_association[egg]:push(particle)
        end
    end


    for _, particle in (self.falling_egg_particles):ipairs() do
        particle.y = particle.y + dt * 0.2
        particle.elapsed = particle.elapsed + dt
        if particle.elapsed > particle.lifetime then
            self.falling_egg_particles:queue_remove(particle)
            self.falling_egg_particle_association[particle.egg]:remove(particle)
        end
    end

    irng:set_seed(rng_state)

    self.falling_egg_particles:apply_removals()
end

function BeginningCutscene:state_Scene6_draw()
    graphics.push("all")
    local offset = 25
    graphics.translate(offset - offset * self.state_elapsed / INTRO_SCENE6_LENGTH, 0)
    local dark = self.state_elapsed >= INTRO_SCENE6_LENGTH - 10
    if not dark then
        draw_stars(self.greenoid_stars4)
    end

    local darker = self.state_elapsed >= INTRO_SCENE6_LENGTH - 5
    -- self:draw_planet(true)




    if not darker then
        for _, egg in ipairs(self.eggs) do
            if self.falling_egg_particle_association[egg] then
                graphics.set_color(dark and Color.darkergrey or (egg.trail_color))
                for _, particle in (self.falling_egg_particle_association[egg]):ipairs() do
                    local t = particle.elapsed / particle.lifetime
                    -- local size = 4.0 * (1 - t)
                    -- graphics.rectangle_centered(egg.trail_outline and "line" or "fill", particle.x, particle.y, size, size)
                    if t > 0.5 then
                        graphics.points(particle.x, particle.y)
                    else
                        graphics.rectangle_centered("fill", particle.x, particle.y, 2, 2)
                    end
                end
            end
        end
        for _, egg in ipairs(self.eggs) do
            graphics.set_color(Color.white)
            graphics.drawp_centered(dark and EGG_SHEET:get_frame(17) or egg.tex, nil, 0, egg.x, egg.y)
        end
    end
    

    graphics.pop()
end


function BeginningCutscene:exit()
    game_state.cutscene_hide_hud = false
    if self.world and self.world.timescaled then
        local s = self.world.timescaled.sequencer
        s:start(function()
            s:wait(2)
            game_state.cutscene_no_pause = false
        end)
    end
end


function EndingCutscene1:new(x, y)
    EndingCutscene1.super.new(self, x, y)
	self.stars = generate_stars(GREENOID_STARS_SEED)
	self.stencil_points = {}
    self.drawing_in_points = {}
    self.is_drawing_in_greenoids = true
    self:init_state_machine()
    local width = conf.viewport_size.y * (16 / 9) * 1.5
    local height = conf.viewport_size.y * 1.5
    local poisson = Poisson(width, height, 6, 3, nil, self.irng)
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
	if iflicker(gametime.tick, 1, 2) then
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
AutoStateMachine(BeginningCutscene, "Scene0")

return {
	Cutscene = Cutscene,
	BeginningCutscene = BeginningCutscene,
	EndingCutscene1 = EndingCutscene1,
	EndingCutscene2 = EndingCutscene2
}
