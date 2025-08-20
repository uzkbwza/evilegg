local Cutscene = GameObject2D:extend("Cutscene")
local BeginningCutscene = Cutscene:extend("BeginningCutscene")
local EndingCutscene1 = Cutscene:extend("EndingCutscene1")
local GoodEndCutscene = Cutscene:extend("GoodEndCutscene")
local OkEndCutscene = Cutscene:extend("OkEndCutscene")
local FinalScoreCutscene = Cutscene:extend("FinalScoreCutscene")
local BigRescueSpriteSheet = SpriteSheet(textures["ally_rescue-sheet"], 12, 10)
local BigRescueSpriteSheet2 = SpriteSheet(textures["ally_rescue_big-sheet"], 24, 19)
local Poisson = require "lib.poisson"
local PoissonVariableDensity = require "lib.poisson_variable_density"

local PLANET_Y = 25
local EGG_Y = -35
local SUN_Y = -60


local LAST_PLANET_STARS_SEED = 5245
local LAST_PLANET_STARS_SEED2 = 5246
local GREENOID_STARS_SEED = 52474
local GREENOID_STARS_SEED2 = 52485
local GREENOID_STARS_SEED3 = 52503

local SKIP_CUTSCENE1 = false
local SKIP_CUTSCENE2 = false

SKIP_CUTSCENE1 = SKIP_CUTSCENE1 and debug.enabled
SKIP_CUTSCENE2 = SKIP_CUTSCENE2 and debug.enabled

local EGG_SHEET = SpriteSheet(textures.cutscene_enemy_egg, 12, 13)

function Cutscene:new(x, y)
	Cutscene.super.new(self, x, y)
	self:add_time_stuff()
    self:add_tag_on_enter("cutscene")
	self.z_index = -1000
end

function Cutscene:enter_shared()
    Cutscene.super.enter_shared(self)
    if self.world then
        -- self.world.rendering_content = false
    end
end

function Cutscene:exit_shared()
    Cutscene.super.exit_shared(self)
    if self.world then
        -- self.world.rendering_content = true
    end
end

local STAR_COLORS = {
    Color.white,
	Color.magenta,
	Color.purple,
	Color.darkblue,

}

local function generate_stars(seed, width, height, amount)
	local irng = rng:new_instance()
	irng:set_seed(seed or 0)
	local width = width or 1200
	local height = height or 600
	local stars = {}
    for _ = 1, amount or 500 do
        local color_index = irng:randi(1, #STAR_COLORS)
        local color = STAR_COLORS[color_index]

		local star = {
			x = irng:randi(-width / 2, width / 2),
			y = irng:randi(-height / 2, height / 2),
			offset = irng:randi(),
			flicker_time = irng:randi(2, 12),
            color = color,
            color_index = color_index,
		}
		table.insert(stars, star)
	end

    table.sort(stars, function(a, b) return a.color_index > b.color_index end)

	return stars
end

local function draw_stars(stars, trans_y)
    trans_y = trans_y or 0
    graphics.push("all")
    
    graphics.translate(0, trans_y * 1 / 4)
    local current_color_index = stars[1].color_index
    graphics.set_color(stars[1].color)

	for _, star in ipairs(stars) do
		if not iflicker(gametime.tick + star.offset, 2, star.flicker_time) then
			graphics.points(star.x, star.y)
            if star.color_index ~= current_color_index then
                graphics.translate(0, trans_y * 1 / 4)
                current_color_index = star.color_index
                graphics.set_color(star.color)
            end
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
    game_state.cutscene_no_cursor = true
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
    game_state.cutscene_no_cursor = false
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

function GoodEndCutscene:new(x, y)
    GoodEndCutscene.super.new(self, x, y)
    self.stars = generate_stars(GREENOID_STARS_SEED)
    self.stencil_points = {}
    self.drawing_in_points = {}
    self:init_state_machine()
    -- local width = conf.viewport_size.y * (16 / 9) * 1.5
    -- local height = conf.viewport_size.y * 1.5
    -- local poisson = Poisson(width, height, 6, 3, nil, self.irng)
    -- local points = poisson:generate()
    self.irng = rng:new_instance()
    local overlay_tex = textures.cutscene_infected_planet_greenoid
	local data = graphics.texture_data[overlay_tex]
	local height = data:getHeight()
	local width = data:getWidth()
	-- self.stencil_canvas = graphics.new_canvas(width, height)
	self.stencil_width = width
    self.stencil_height = height
    for i = 1, 800 do
        self:progress_stencil(1)
    end
    
    -- self:start_destroy_timer(500)

    self:start_tick_timer("dark", 150, function() 
        self.dark = true
        self:start_tick_timer("darker", 15, function() 
            self.darker = true
            self:start_tick_timer("finish", 20, function() 
                self.finished = true
            end)
        end)
    end)
    -- self:start_destroy_timer(200)

    if SKIP_CUTSCENE2 then
        self.finished = true
        self:hide()
    end
end

function GoodEndCutscene:progress_stencil(dt)
    local stopwatch = self:get_stopwatch("infect_world")
	-- if stopwatch then
    if #self.stencil_points < 75 then
        local point = {
            x = rng:randi(-self.stencil_width / 2, self.stencil_width / 2),
            y = -self.stencil_height / 2,
            speed = rng:randf(0.5, 3.0)
        }
        point.start_y = point.y
        table.insert(self.stencil_points, point)
    end
	-- end
	for i = #self.stencil_points, 1, -1 do
		local point = self.stencil_points[i]
		point.y = point.y + dt * 0.035 * point.speed * (self.showing_tower and 4 or 1)
	end
end

function GoodEndCutscene:state_Scene1_update(dt)
    for i = #self.stencil_points, 1, -1 do
		local point = self.stencil_points[i]
		point.y = point.y - dt * 0.035 * point.speed * 0.24 
	end
end


function GoodEndCutscene:state_Scene1_draw()


    -- local trans_y = ease("inOutCubic")(clamp01((self.state_elapsed - 160) / 220))
    local trans_y = 0

    graphics.push("all")

    draw_stars(self.stars, trans_y * 4000)
    graphics.pop()

    graphics.push("all")
    graphics.translate(0, trans_y * 8000)


	graphics.set_color(Color.white)
    if iflicker(gametime.tick, 1, 2) then
        graphics.draw_centered(textures.cutscene_sun, 0, SUN_Y)
    end
    
    graphics.pop()

    graphics.push("all")

    graphics.translate(0, trans_y * 10000)

    local palette = self.dark and Palette.planet_greenoid_dark or nil

    if self.darker then
        palette = Palette.planet_greenoid_darker
    end

    graphics.drawp_centered(textures.cutscene_planet_greenoid, palette, 0, 0, PLANET_Y)

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
    graphics.drawp_centered(overlay_tex, Palette.player_absorbed, 5, 0, PLANET_Y)
    graphics.pop()
    
    graphics.pop()
end


function OkEndCutscene:new(x, y)
    OkEndCutscene.super.new(self, x, y)
    self.stars = generate_stars(GREENOID_STARS_SEED)
    self.stencil_points = {}
    self.drawing_in_points = {}
    self:init_state_machine()
    -- local width = conf.viewport_size.y * (16 / 9) * 1.5
    -- local height = conf.viewport_size.y * 1.5
    -- local poisson = Poisson(width, height, 6, 3, nil, self.irng)
    -- local points = poisson:generate()
    self.irng = rng:new_instance()
    local irng = self.irng
    irng:set_seed(999)
    local overlay_tex = textures.cutscene_infected_planet_greenoid
	local data = graphics.texture_data[overlay_tex]
	local height = data:getHeight()
	local width = data:getWidth()
	-- self.stencil_canvas = graphics.new_canvas(width, height)
	self.stencil_width = width
    self.stencil_height = height
    self.camera_shake_amount = 0
    for i = 1, 800 do
        self:progress_stencil(1)
    end
    
    -- self:start_destroy_timer(1000)

    self:start_tick_timer("finished", 400, function() 
        -- self.finished = true
    end)
    -- self:start_destroy_timer(200)

    if SKIP_CUTSCENE2 then
        self.finished = true
        self:hide()
    end

    self.greenoids = {}
    local pwidth = 400
    local pheight = 150
    local poisson = PoissonVariableDensity(pwidth, pheight, function(x, y) return lerp(8, 30, vec2_distance(x, y, 0.5, 0.5) * 2) end, 12, 43, 3, nil, irng)
    for i, point in ipairs(poisson:generate()) do
        if i > game_state.rescues_saved then
            break
        end
        table.insert(self.greenoids, {
            x = point[1] - pwidth / 2,
            y = (point[2] - pheight / 2) * 0.7 + 40,
            random_offset = irng:randi(0, 255),
            ready = true,
            get_sprite_index = function(tab)
                local index = 1
                local freq = tab.random_offset % 30 + 50
                if iflicker(self.state_tick + tab.random_offset, 3, freq) or iflicker(self.state_tick + tab.random_offset + 7, 3, freq) then
                    index = 4
                end
                return index
            end
        })
    end

    table.sort(self.greenoids, function(a, b)
        return a.y < b.y
    end)


    local s = self.sequencer
    
    local num_greenoids_process = 0

    while num_greenoids_process < min(6, game_state.rescues_saved) do
        local index = irng:randi(1, #self.greenoids)
        if not self.greenoids[index].ready then
            goto continue
        end
        self.greenoids[index].ready = false
        s:start(function()
            s:wait(irng:randi(20, 250))
            self.greenoids[index].ready = true
            self:play_sfx("cutscene_rescue_pickup", 0.85)
            s:tween(function(t)
                self.greenoids[index].laser_amount = t
            end, 0, 1, 9, "linear")
            self.greenoids[index].laser_amount = nil
        end)
        num_greenoids_process = num_greenoids_process + 1
        ::continue::
    end

end

function OkEndCutscene:progress_stencil(dt)
    local stopwatch = self:get_stopwatch("infect_world")
	-- if stopwatch then
    if #self.stencil_points < 75 then
        local point = {
            x = rng:randi(-self.stencil_width / 2, self.stencil_width / 2),
            y = -self.stencil_height / 2,
            speed = rng:randf(0.5, 3.0)
        }
        point.start_y = point.y
        table.insert(self.stencil_points, point)
    end
	-- end
	for i = #self.stencil_points, 1, -1 do
		local point = self.stencil_points[i]
		point.y = point.y + dt * 0.055 * point.speed * (self.showing_tower and 4 or 1)
	end
end

local greenoid_ship_escape_frames = {
    textures.cutscene_greenoid_ship_escape1,
    textures.cutscene_greenoid_ship_escape2,
    textures.cutscene_greenoid_ship_escape3,
    textures.cutscene_greenoid_ship_escape4,
    textures.cutscene_greenoid_ship_escape5,
}

function OkEndCutscene:state_Scene1_enter()
    self.camera_shake_amount = 0.0
    local s = self.sequencer
    s:start(function()
        s:wait(220)
        self:start_stopwatch("explode")
        s:wait(160)
        self.greenoid_ship = {
            position = Vec2(10, 60),
            sprite = function() 
                return gametime.tick % 2 == 0 and 1 or 2
            end,
        }
        local start_x, start_y = self.greenoid_ship.position.x, self.greenoid_ship.position.y
        s:tween(function(time)
            local t = clamp01(time / 200)
            local t2 = clamp01((time - 100) / 100)
            local x, y = vec2_from_polar(100 + t * ease("outCubic")(t) * 50, -tau * 0.15 + (tau * 0.65) * -ease("linear")(t))
            y = y * 0.5
            x = -x
            if t > 0.35 then
                self.greenoid_ship.sprite = 3
            end
            if t > 0.45 then
                self.greenoid_ship.sprite = 4
            end
            if t > 0.75 then
                self.greenoid_ship.sprite = 5
            end
            -- if t > 0.7 then
            --     self.greenoid_ship.sprite = 6
            -- end
            y = y - ease("inExpo")(t2) * 1000
            x = x - ease("inExpo")(t2) * 800
            self.greenoid_ship.position.x = start_x + x
            self.greenoid_ship.position.y = start_y + y
        end, 0, 200, 200, "linear")
        self.greenoid_ship = nil
        s:wait(30)
        self.finished = true
    end)
end

function OkEndCutscene:state_Scene1_update(dt)
    for i = #self.stencil_points, 1, -1 do
		local point = self.stencil_points[i]
		point.y = point.y + dt * 0.035 * point.speed * 0.24 * ((self.state_elapsed + 40) / 20)
	end
end


function OkEndCutscene:state_Scene1_draw()


    local trans_y = 0

    graphics.push("all")

    draw_stars(self.stars, trans_y * 4000)
    graphics.pop()

    graphics.push("all")
    graphics.translate(0, trans_y * 8000)


	graphics.set_color(Color.white)
    if iflicker(gametime.tick, 1, 2) then
        graphics.draw_centered(textures.cutscene_sun, 0, SUN_Y)
    end
    
    graphics.pop()

    graphics.push("all")

    graphics.translate(0, trans_y * 10000)


    local stopwatch = self:get_stopwatch("explode")

    if stopwatch then

        graphics.push("all")

        graphics.translate(0, PLANET_Y)

        local NUM_RINGS = 20
        local RING_RESOLUTION = 5

        local base_size = 112 / 2

        for ring = NUM_RINGS, 0, -1 do
            local res = 1
            local radius = 0
            if ring > 0 then
                radius = lerp(1, base_size, ring / NUM_RINGS)
                res = ceil((radius * tau) / RING_RESOLUTION)
            end
            for i = 1, res do
                local irng = self.irng
                irng:set_seed(i * 57 + i * 100 + ring * 59)

                local t1 = clamp01(stopwatch.elapsed / irng:randf(180, 280))
                local t2 = clamp01((stopwatch.elapsed - 60) / irng:randf(60, 200))

                if t2 < 1 then
                    local x, y = vec2_from_polar(radius, tau * (i / res))
                    x, y = vec2_mul_scalar(x, y, remap01(math.bump(t1), 1, 1.5))
                    x, y = vec2_lerp(x, y, 0, -base_size, ease("inExpo")(t2))
                    graphics.set_color(Palette.player_absorbed:tick_color(self.tick + irng:randi(), 0, 3))
                    graphics.rectangle_centered("fill", x, y, 4, 4)
                end
            end
        end
        graphics.pop()

    else
        graphics.drawp_centered(textures.cutscene_planet_greenoid, self.finished and Palette.planet_greenoid_dark or nil, 0, 0, PLANET_Y)
    
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
    
    
        graphics.set_stencil_mode("test", 1)
        graphics.drawp_centered(overlay_tex, Palette.player_absorbed, 5, 0, PLANET_Y)
        graphics.pop()
    end

    if self.greenoid_ship then
        graphics.draw_centered(greenoid_ship_escape_frames[resolve(self.greenoid_ship.sprite)], self.greenoid_ship.position.x, self.greenoid_ship.position.y, 0)
    end

    -- graphics.draw_centered(self.stencil_canvas, 0, PLANET_Y)
    
    graphics.pop()
end

function OkEndCutscene:state_Scene2_enter()

    self.camera_shake_amount = 0.5
    -- self.camera_shake_amount = self.camera_shake_amount + dt * 0.01
    self:play_sfx_if_stopped("cutscene_greenoid_ship_hum", 0.7, 1.0, true)
    self:start_timer("scene_switch", 300, function()
        self:change_state("Scene1")
    end)
end

function OkEndCutscene:state_Scene2_exit()
    self:stop_sfx("cutscene_greenoid_ship_hum")
end

function OkEndCutscene:exit()
    self:stop_sfx("cutscene_greenoid_ship_hum")
end

function OkEndCutscene:state_Scene2_draw()
    graphics.drawp_centered(textures.cutscene_greenoid_ship_interior_alternate, nil, 0, 0, -50)

    for _, greenoid in ipairs(self.greenoids) do
        if not greenoid.ready then
            goto continue
        end
        graphics.push("all")
        -- local texture_id = iflicker(self.state_tick + greenoid.random_offset, 10, 2) and 1 or 2
        local texture_id = greenoid:get_sprite_index()
        local texture = BigRescueSpriteSheet2:get_frame(texture_id)

        graphics.translate(greenoid.x, greenoid.y)
        if greenoid.laser_amount then
            graphics.set_color(iflicker(self.state_tick + greenoid.random_offset, 4, 2) and Color.green or Color.white)
            local laser_width = 20 * (1 - ease("inCubic")(greenoid.laser_amount))
            local laser_end = 800 * ease("outCubic")(greenoid.laser_amount)
            local laser_start = 800 * ease("inCubic")(greenoid.laser_amount)
            local laser_x = -laser_width / 2
            local laser_y = laser_start - 800
            graphics.rectangle("fill", laser_x, laser_y, laser_width, laser_end - laser_start)
        else
            graphics.set_color(Color.white)
            graphics.draw_centered(texture, 0)
        end
        graphics.pop()
        ::continue::
    end
end

function FinalScoreCutscene:new(x, y)
    FinalScoreCutscene.super.new(self, x, y)

    self.z_index = 1001

    local end_game_bonuses = {}

    for _, bonus in ipairs(game_state.end_game_bonuses) do
        table.insert(end_game_bonuses, bonus)
    end

    table.sort(end_game_bonuses, function(a, b)
        if a.multiplier == b.multiplier then
            return a.text_key > b.text_key
        end
        return a.multiplier > b.multiplier
    end)

    self.end_game_bonuses = end_game_bonuses
    self.current_multiplier = 1.0
    self.next_multiplier = 0
    self.current_ones = 1
    self.current_tenths = 0
    self.displayed_score = 0
    self.next_ones = 1
    self.next_tenths = 0
    self.next_score = 0
    self.current_score = 0
    self.start_score = game_state.score
    self.next_t = 0
    self.startup_t = 0
    self.bonus_text = ""
    self:start_stopwatch("bonus_t")
    self:hide()
    
    self.dark = true
end

function FinalScoreCutscene:enter()
    local s = self.sequencer
    s:start(function()

        s:wait(30)

        s:start(function()
            s:wait(20)
            self:show()
            s:wait(5)
            self.dark = false
        end)        
        
        s:tween(function(t)
            self.startup_t = t
        end, 0, 1, 30, "linear")
        


        s:tween(function(t)
            local old_displayed_score = self.displayed_score
            self.displayed_score = lerp(0, self.start_score, t)
            if old_displayed_score ~= self.displayed_score and self.is_new_tick and self.tick % 2 == 0 then
                self:play_sfx("ui_game_over_stat_display_tick")
            end
        end, 0, 1, 100, "linear")
        self.current_score = self.displayed_score

        for i = 1, #self.end_game_bonuses do
            s:wait(45)
            self.next_t = 0
            local bonus = self.end_game_bonuses[i]
            self.next_ones = floor(self.current_multiplier + bonus.multiplier)
            self.next_tenths = floor((self.current_multiplier + bonus.multiplier - self.next_ones) * 10)
            self.next_multiplier = self.current_multiplier + bonus.multiplier
            self.next_score = self.start_score * self.next_multiplier

            -- s:start(function()
            self:start_stopwatch("bonus_t")
            -- self.bonus_text = tr[bonus.text_key]:upper() .. " [×" .. bonus.multiplier .. "]"
            self.bonus_text = tr[bonus.text_key]:upper()
            -- end)

            local last = i == #self.end_game_bonuses

            self.between_bonuses = true
            s:tween(function(t)
                self.next_t = t
                local old_displayed_score = self.displayed_score
                self.displayed_score = lerp(self.current_score, self.next_score, t)
                if old_displayed_score ~= self.displayed_score and self.is_new_tick and self.tick % 4 == 0 then
                    self:play_sfx("ui_end_bonus_tick", 0.6)
                end
                game_state:set_score(self.displayed_score)
            end, 0, 1, last and 150 or 120, "linear")
            self.between_bonuses = false

            if last then
                self:play_sfx("ui_end_bonus_final_impact", 1.0)
            else
                self:play_sfx("ui_end_bonus_impact", 1.0)
            end

            self.current_ones = self.next_ones
            self.current_tenths = self.next_tenths
            self.current_multiplier = self.next_multiplier
            self.current_score = self.next_score
        end

        self.done_with_bonuses = true
        
        game_state:set_score(self.current_score)

        s:wait(100)
        self.dark = true
        s:wait(5)
        
        self:hide()

        s:wait(10)

        self:queue_destroy()
    end)
end

function FinalScoreCutscene:draw()

    graphics.set_font(fonts.depalettized.image_font2)
    graphics.set_color(self.dark and Color.darkergreen or Color.green)
    
    local x = -12
    local text = tr.cutscene_final_score
    local score_text = comma_sep(stepify_floor(self.displayed_score, 10))
    graphics.print(utf8.sub(text, 1, self.startup_t * utf8.len(text)), x, -10)

    graphics.push("all")
    if not self.dark then
        local palette = Palette.final_score_2
        if self.between_bonuses then
            palette = Palette.final_score_1
        elseif self.done_with_bonuses then
            palette = Palette.final_score_3
        end
        graphics.set_color(palette:tick_color(self.tick, 0, 1))
    end
    graphics.print(utf8.sub(score_text, 1, self.startup_t * utf8.len(score_text)), x, 2)
    graphics.pop()

    graphics.set_font(fonts.depalettized.bignum)
    local ones_t = self.next_ones ~= self.current_ones and self.next_t or 0
    local tenths_t = self.next_tenths ~= self.current_tenths and self.next_t or 0

    local y = -13

    local dist = 32

    graphics.push("all")
    
    graphics.set_stencil_mode("draw", 55)
    
    graphics.rectangle_centered("fill", 0, 0, 800, 27)
    
    graphics.set_stencil_mode("test", 55)
    
    graphics.print(tostring(floor(self.current_ones)), x - 32, lerp(y, y + dist, ones_t) - (dist * 2 * (1 - self.startup_t)))
    graphics.print(tostring(floor(self.next_ones)), x - 32, lerp(y - dist, y, ones_t))
    graphics.print(tostring(floor(self.current_tenths)), x - 16, lerp(y, y + dist, tenths_t) - (dist * 2 * (1 - self.startup_t)))
    graphics.print(tostring(floor(self.next_tenths)), x - 16, lerp(y - dist, y, tenths_t))

    


    if self.startup_t >= 1 then
        graphics.print(".", x - 19, y)
        graphics.print("x", x - 40, y)
    end
    
    graphics.pop()


    local TEXT_LIMIT = 100

    if self.bonus_text ~= "" then
        graphics.set_font(fonts.depalettized.image_font2)
        local len = utf8.len(self.bonus_text)
        local t = clamp01(self:get_stopwatch("bonus_t").elapsed / len / 2)
        graphics.printf_interpolated(self.bonus_text, fonts.depalettized.image_font2, -TEXT_LIMIT / 2, y + dist, TEXT_LIMIT, "left", t)
    end
end

AutoStateMachine(EndingCutscene1, "Scene1")
AutoStateMachine(GoodEndCutscene, "Scene1")
AutoStateMachine(OkEndCutscene, "Scene2")
AutoStateMachine(BeginningCutscene, "Scene0")

return {
	Cutscene = Cutscene,
	BeginningCutscene = BeginningCutscene,
	EndingCutscene1 = EndingCutscene1,
	GoodEndCutscene = GoodEndCutscene,
	OkEndCutscene = OkEndCutscene,
	FinalScoreCutscene = FinalScoreCutscene
}
