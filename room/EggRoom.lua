local EggRoom = require("room.Room"):extend("EggRoom")
local EggElevator = require("obj.EggElevator")
local EggRoomDirector = GameObject:extend("EggRoomDirector")

EggRoom.can_highlight_enemies = false

local EvilPlayer = require("obj.Spawn.Enemy.EvilPlayer")
local EvilGreenoidBoss = require("obj.Spawn.Enemy.EvilGreenoidBoss")
local EggBoss = require("obj.Spawn.Enemy.EggBoss")

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

function EggRoom:get_border_color()
	return self.director and self.director:get_border_color() or nil
end

function EggRoomDirector:new()
    EggRoomDirector.super.new(self)
	self:lazy_mixin(Mixins.Behavior.AllyFinder)
	self:add_time_stuff()
end

function EggRoomDirector:get_border_color()
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
        local color = Color.nearblack
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
			audio.play_music_if_stopped("music_evil_player_theme")

			local boss = rng:choose(bosses)
            self["boss_" .. boss](self)
			
			if self.world.player_died then
				return
			end
			
			audio.stop_music()

			self.world:on_room_clear()
			
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
				-- audio.play_music("music_egg_boss1", 1.0)
			end, true)
			
            while self.egg_boss do
                s:wait(1)
            end

			self.world:on_final_boss_killed()
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
