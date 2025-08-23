local EggRoom = require("room.Room"):extend("EggRoom")
local EggElevator = require("obj.EggElevator")
local EggRoomDirector = GameObject:extend("EggRoomDirector")
local Cutscenes = require("obj.Cutscene")

EggRoom.can_highlight_enemies = false

EggRoomDirector.is_egg_director = true

local EvilPlayer = require("obj.Spawn.Enemy.EvilPlayer")
local EvilGreenoidBoss = require("obj.Spawn.Enemy.EvilGreenoidBoss")
local EggBoss = require("obj.Spawn.Enemy.EggBoss")[1]

local bosses = {
	"EvilPlayer",
}

function EggRoom:new(...)
    EggRoom.super.new(self, ...)
	self.is_egg_room = true
end

function EggRoom:build(room_params)
    EggRoom.super.build(self, room_params)
end

function EggRoom:generate_waves()
    local waves = {}
    local rescue_waves = {}

    return waves, rescue_waves
end

function EggRoom:should_spawn_waves()
    return false
end

function EggRoom:initialize(world)
	game_state.boss_level = true
    self.director = world:spawn_object(EggRoomDirector())
    signal.connect(self.director, "destroyed", self, "on_director_destroyed", function()
		self.director = nil
	end)
end

function EggRoom:get_clear_color()
	return self.director and self.director:get_clear_color() or nil
end

function EggRoom:get_border_color()
    return self.director and self.director:get_border_color() or nil
end

function EggRoom:get_screen_border_color()
    return self.director and self.director:get_screen_border_color() or nil
end

function EggRoomDirector:new()
    EggRoomDirector.super.new(self)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self:add_time_stuff()
end

function EggRoomDirector:get_clear_color()

    if self.world.clock_slowed then return nil end

    if self:is_timer_running("phase2_landing_fade") then
        -- local t = self:timer_progress("phase2_landing_fade")
        local color = Color.grey
        return color
    end
    local cutscene = self.world:get_first_object_with_tag("cutscene")
    if cutscene and cutscene.get_clear_color then
        return cutscene:get_clear_color()
    end

    if self.glow_floor then
        self.glow_floor_color = self.glow_floor_color or Color.darkblue:clone()
        local color = self.glow_floor_color
        local color2 = Color.darkblue
        local stopwatch = self:get_stopwatch("time_since_cracked_egg")
        if stopwatch then
            local t = sin01(stopwatch.elapsed / 3)

            local amt = 0.15
            local mod = 0.25
            color.r = lerp(color2.r, color2.r * t, amt) * mod       
            color.g = lerp(color2.g, color2.g * t, amt) * mod
            color.b = lerp(color2.b, color2.b * t, amt) * mod
        end
        return color
    end

	return nil
end

function EggRoomDirector:get_screen_border_color()
    if self.glow_floor then
        self.glow_border_color = self.glow_border_color or Color.magenta:clone()
        local color = self.glow_border_color
        local color2 = Palette.rainbow:tick_color(self.elapsed * 0.5)
        local stopwatch = self:get_stopwatch("time_since_cracked_egg")
        if stopwatch then
            local t = sin01(stopwatch.elapsed / 3)

            local amt = 0.55
            local mod = 1
            color.r = lerp(color2.r, color2.r * t, amt) * mod
            color.g = lerp(color2.g, color2.g * t, amt) * mod
            color.b = lerp(color2.b, color2.b * t, amt) * mod
        end
        return color
    end
    
    return Color.black
end

function EggRoomDirector:get_border_color()
    if self.glow_floor then
        return self:get_screen_border_color()
    end
	if self.phase4_landing then
		return Color.transparent
	end
	if self.world.state == "RoomClear" then return nil end
    local stopwatch = self:get_stopwatch("time_since_killed_elevator")
    if stopwatch then
        local color = Color.darkergrey
        self.elevator_kill_color = self.elevator_kill_color or Color(color.r, color.g, color.b, 1)
        local mod = clamp01(stopwatch.elapsed / 90)
        -- print(mod)
        self.elevator_kill_color.r = color.r * mod
        self.elevator_kill_color.g = color.g * mod
        self.elevator_kill_color.b = color.b * mod
        return self.elevator_kill_color
    end
	local stopwatch2 = self:get_stopwatch("time_since_cracked_egg")
	if stopwatch2 then
        local color = Color.darkergrey
        self.elevator_kill_color = self.elevator_kill_color or Color(color.r, color.g, color.b, 1)
        local mod = clamp01(stopwatch2.elapsed / 180) * 0.6
		-- print(mod)
		self.elevator_kill_color.r = color.r * mod
		self.elevator_kill_color.g = color.g * mod
		self.elevator_kill_color.b = color.b * mod
		return self.elevator_kill_color
	end
	return Color.black
end

function EggRoomDirector:enter()
	-- game_state.cutscene_hide_hud = true

    local world = self.world
    local s = self.sequencer
    s:start(function()
        s:wait(15)
        -- world:on_room_clear()
        self:ref("egg_elevator", world:spawn_object(EggElevator(world, 0, 0)))
        signal.connect(self.egg_elevator, "player_choice_made", self, "on_player_choice_made")
    end)
    world.draining_bullet_powerup = true
end


function EggRoomDirector:on_player_choice_made(choice, player)
    local world = self.world
    local s = self.sequencer
    s:start(function()
        local elevator = self.egg_elevator
        if choice == "kill_elevator" then
			game_state.cutscene_hide_hud = false

			audio.play_music_if_stopped("music_evil_player_theme")

			local boss = rng:choose(bosses)
            self["boss_" .. boss](self)
			
			if self.world.player_died then
				return
			end
			
			audio.stop_music()

			self.world:on_room_clear()
            self.world.play_music_next_level = true

			game_state:on_egg_room_cleared()
			
        elseif choice == "kill_egg" then
            game_state:on_final_room_entered()
            world:clear_floor_canvas()
            self:ref("egg_boss", world:spawn_object(EggBoss()))
            local closest_player = self:get_any_player(player)
			while not closest_player do
				s:wait(1)
				closest_player = self:get_any_player(player)
			end
			closest_player:move_to(0, 70)
			
			-- audio.stop_music()\
            audio.play_music_if_stopped("music_egg_boss_ambience", 1.0)
			
            signal.connect(self.egg_boss, "cracked", self, "on_egg_boss_cracked", function()
				self:start_stopwatch("time_since_cracked_egg")
				game_state.cutscene_hide_hud = false
            end, true)
			
			signal.connect(self.egg_boss, "phase2_landing", self, "on_egg_boss_phase2_landing", function()
				self:start_timer("phase2_landing_fade", 5, function()
				end)
				audio.play_music("music_egg_boss2", 1.0)
			end, true)

			signal.connect(self.egg_boss, "phase4_landing", self, "on_egg_boss_phase4_landing", function()
                self.phase4_landing = true
                self.world.room:set_bounds(1400, 1400)
                audio.stop_all_object_sfx(self.world.canvas_layer)
                audio.stop_music()
                -- self:start_timer("phase4_landing_music", 30, function()
				-- 	-- audio.play_music("music_egg_boss3", 1.0)
				-- end)
				-- audio.play_music("music_egg_boss1", 1.0)

                game_state.cutscene_hide_hud = true
                game_state.cutscene_no_cursor = true
			end, true)
			
            signal.connect(self.egg_boss, "cutscene1_over", self, "on_egg_boss_cutscene1_over", function()
                self.world.fog_of_war = true
                self.world.players[1]:change_state("Cutscene")
                self.glow_floor = true
                self.phase4_landing = false
                self.world.big_room = true
                game_state.cutscene_hide_hud = false
                game_state.cutscene_no_cursor = false
                game_state.cutscene_no_pause = false
                local dist = 650
                local tp_to_center = false
                if debug.enabled and tp_to_center then
                    self.world.players[1]:move_to(0, 0)
                elseif rng:coin_flip() then
                    self.world.players[1]:move_to(rng:randf(-dist, dist), dist * rng:rand_sign())
                else
                    self.world.players[1]:move_to(dist * rng:rand_sign(), rng:randf(-dist, dist))
                end


                -- self.world.camera_target:move_to(self.world.players[1].pos.x, self.world.players[1].pos.y)
                -- self.world.camera:move_to(self.world.players[1].pos.x, self.world.players[1].pos.y)

                self.world.camera_target:move_to(0, 0)
                self.world.camera:move_to(0, 0)

                s:start(function()
                    s:wait(120)

                    s:tween(function(t)
                        local cx, cy = self.world.players[1].pos.x, self.world.players[1].pos.y
                        self.world.camera_target:move_to(vec2_lerp(0, 0, cx, cy, t))
                        self.world.camera:move_to(vec2_lerp(0, 0, cx, cy, t))

                    end, 0, 1, 180, "inOutCubic")

                    self.world.players[1]:change_state("Walk")

                    self.world.room.free_camera = true
                    self.egg_boss.phase6_camera_intro = false
                end)

            end, true)


            signal.connect(self.egg_boss, "phase7_enter", self, "on_egg_boss_phase7_enter", function()

                if not self.world.players[1] then
                    return
                end

                self.world.players[1].force_invuln = true


                local s = self.world.sequencer
                s:start(function()
                    s:wait(1)
                    for _, object in self.world.objects:ipairs() do
                        if not object.is_egg_boss and not object.persist and object ~= self then
                            object:queue_destroy()
                        end
                    end

                    s:wait(1)
                    self.world:clear_floor_canvas()
                    self.world.floor_drawing = false
                    self.glow_floor = false
                
                    game_state.cutscene_hide_hud = true
                    game_state.cutscene_no_cursor = true
                    game_state.cutscene_no_pause = true
                    audio.stop_music()
                    
                    self.world.object_time_scale = 0.0125
                    s:wait(60)
                    self.world.rendering_content = false
                    s:wait(90)
                    if self.world.players[1] then
                        self.world.rendering_content = true
                        self.world.room.free_camera = false
                        self.world.camera_target:move_to(0, 0)

                        game_state.cutscene_no_cursor = false

                        self.world.players[1]:change_state("Cutscene")
                        self.world.object_time_scale = 1
                        self.world.players[1]:hide()
                        local final_object = self.world:get_first_object_with_tag("final_object")
                        if final_object then    
                            local diff = final_object.pos - self.world.players[1].pos
                            diff:limit_length(200)
                            self.world.players[1]:movev_to(final_object.pos - diff)
                        end

                    end


                    s:wait(60)

                    if self.world.players[1] then
                        self.world.players[1]:show()
                        self.world.room.free_camera = true
                        self.world.fog_of_war = false
                        self.world.players[1]:change_state("Walk")
                    end
                    -- self.world.fog_of_war = false
                end)
            end, true)

            signal.connect(self.egg_boss, "final_object_died", self, "on_final_object_died", function()
                local s = self.world.sequencer
                s:start(function()
                    self.world.room.free_camera = false
                    game_state.cutscene_no_cursor = true
                    
                    s:start(function()
                        local start_x, start_y = self.world.camera_target.pos.x, self.world.camera_target.pos.y
                        s:tween(function(t) 
                            self.world.camera_target:move_to(vec2_lerp(start_x, start_y, 0, 0, t))
                        end, 0, 1, 120, "inOutCubic")
                        s:wait(10)
                    end)

                    game_state.twin_saved = game_state.artefacts.sacrificial_twin
                    game_state:end_game()
                    self.final_boss_killed = true
                    if self.world.players[1] then
                        self.world.players[1]:change_state("Cutscene")
                        -- self.world.players[1]:hide()
                    end
                end)
            end, true)

            signal.connect(self.egg_boss, "final_object_animation1_complete", self, "on_final_object_animation1_complete",
            function()
                game_state.force_bonus_screen = true
                self.world:emit_signal("force_bonus_screen")
                while self.world.waiting_on_bonus_screen do
                    s:wait(1)
                end
                self:ref("final_score_cutscene", self.world:spawn_object(Cutscenes.FinalScoreCutscene(0, 0)))
                while self.final_score_cutscene do
                    s:wait(1)
                end
                game_state.cutscene_no_cursor = false
                game_state.force_cursor = true
                -- game_state.cutscene_hide_hud = false
                self.world:on_final_boss_end_sequence_finished()
            end, true)
		end
    end)
end

function EggRoomDirector:boss_EvilPlayer()
    local elevator = self.egg_elevator
	local s = self.sequencer
	local world = self.world
	self:start_stopwatch("time_since_killed_elevator")
	local num_guys = 5 + game_state.egg_rooms_cleared
	for i = 1, num_guys do
		local angle = i * tau / num_guys + tau / 8
		local dir = Vec2(1, 0):rotate_in_place(angle)
		local evil_player = world:spawn_object(EvilPlayer(elevator.pos.x, elevator.pos.y))
		world:register_spawn_wave_enemy(evil_player)
		evil_player.angle_offset = angle
		evil_player.num_evil_players = num_guys
		local movement = dir * 90
		local evil_player_ref = "evil_player_" .. i
		evil_player.guy_offset = i
		self:ref(evil_player_ref, evil_player)
		-- evil_player:apply_impulse(force.x, force.y)
		s:start(function()
			s:tween(function(t)
				if self[evil_player_ref] then
					self[evil_player_ref]:move_to(elevator.pos.x + movement.x * t,
						elevator.pos.y + movement.y * t)
				end
			end, 0, 1, 46, "inCubic")

            if not self[evil_player_ref] then
                return
            end

			self[evil_player_ref]:wakeup()


		end)
		s:wait(4)
	end

	s:wait(4)

    while self.world:get_number_of_objects_with_tag("evil_player") > 0 do
        s:wait(1)
    end

	s:wait(60)
	
	if self.world.player_died then
		return
	end
	

    self:ref("greenoid_boss", self.world:spawn_object(EvilGreenoidBoss()))
	while self.greenoid_boss do
		s:wait(1)
	end
end

return EggRoom
