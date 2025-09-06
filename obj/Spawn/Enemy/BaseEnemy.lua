local BaseEnemy = GameObject2D:extend("BaseEnemy")
local DeathFlash = require("fx.enemy_death_flash")
local DeathSplatter = require("fx.enemy_death_pixel_splatter")
local FungalDeathSplatter = require("fx.enemy_death_pixel_fungal_splatter")
local LastEnemyTarget = require("fx.last_enemy_target")
local LifeFlash = require("fx.enemy_life_flash")

BaseEnemy.is_base_enemy = true

function BaseEnemy:new(x, y)
    BaseEnemy.super.new(self, x, y)

	self.terrain_collision_radius = self.terrain_collision_radius or 2
    self.body_height = self.body_height or 0
    -- self.aim_radius = self.aim_radius or 3
    self.hurt_bubble_radius = self.hurt_bubble_radius or 5
	self.hit_bubble_radius = self.hit_bubble_radius or 3
	self.hit_bubble_damage = self.hit_bubble_damage or 1
    self.max_hp = self.max_hp or 1

	-- self.difficulty_shield = min(floor(game_state.level / 10), 4)
	-- self.difficulty_shield = floor(10)
	self:lazy_mixin(Mixins.Behavior.Flippable)
	self:lazy_mixin(Mixins.Behavior.TwinStickEntity)
	self:lazy_mixin(Mixins.Behavior.Health)
    self:lazy_mixin(Mixins.Behavior.Hittable)
    self:lazy_mixin(Mixins.Behavior.RandomOffsetPulse)
	self:lazy_mixin(Mixins.Behavior.SimplePhysics2D)

    self.random_offset = rng:randi(0, 255)
	self.random_offset_ratio = self.random_offset / 255
    self.flip = 1

    self:add_signal("died")
	if self.auto_state_machine then
		self:init_state_machine()
	end
end

function BaseEnemy:hazard_init()
    self:add_tag("hazard")
end

function BaseEnemy:life_flash()
    local bx, by = self:get_body_center()
    self:spawn_object(LifeFlash(bx, by, self.pos.x, self.pos.y, self:get_sprite(), self.life_flash_size_mod or 1))
end

function BaseEnemy:get_score()
	return self.spawn_data.score
end

function BaseEnemy:get_xp()
    local score = self:get_score()
    if score > 0 then
        -- local real_score = game_state:determine_score(score)
        -- return max(real_score * 0.0005, score * 0.005)
		return score * 0.1
	end
	return 0
end

function BaseEnemy:make_required_kill_on_enter()
	self:add_enter_function(self.make_required_kill)
end

function BaseEnemy:make_required_kill()
	self:add_tag("wave_enemy")
	self.world:register_non_wave_enemy_required_kill(self)
end

function BaseEnemy:enter_shared()
    self:add_tag("enemy")
    BaseEnemy.super.enter_shared(self)
	if not self:get_bubble("hurt", "main") and not self.no_hurt_bubble then
		self:add_hurt_bubble(0, 0, self.hurt_bubble_radius, "main")
	end
    if not self:get_bubble("hit", "main") and self.hit_bubble_radius and self.hit_bubble_radius > 0 then
        self:add_hit_bubble(0, 0, self.hit_bubble_radius, "main", self.hit_bubble_damage)
    end

    if self.spawn_sfx then
        self:play_sfx(self.spawn_sfx, self.spawn_sfx_volume or 1.0, self.spawn_sfx_pitch or 1.0)
    -- else
		-- if self:has_tag("wave_enemy") then
        --     self:play_sfx("enemy_spawn", 0.5, 1.0)
		-- elseif self:has_tag("hazard") then
        --     self:play_sfx("enemy_spawn", 0.5, 1.0)
		-- end
    end
    if self.spawn_cry then
		self:start_timer("spawn_cry", 6  , function()
			self:play_sfx(self.spawn_cry, self.spawn_cry_volume or 1.0, self.spawn_cry_pitch or 1.0)
		end)
	end
end

function BaseEnemy:highlight_self()
	if not self.target_highlighted then
		self.target_highlighted = true
        local object = self:spawn_object(LastEnemyTarget(self.pos.x, self.pos.y, self))
		signal.connect(object, "destroyed", self, "on_target_highlight_destroyed", function()
			self.target_highlighted = false
		end)
	end
end

function BaseEnemy:get_damage(object)
    return self.hit_bubble_damage or 1
end

function BaseEnemy:hit_by(object)
    local damage = 0

    if object.is_bubble then
		local bubble = object
        object = object.parent
		damage = (object.get_damage and object:get_damage(self)) or bubble.damage
    else
		damage = (object.get_damage and object:get_damage(self)) or object.damage
    end

	local invuln = self:is_invulnerable()

	if not self.no_damage_flash and not invuln and not self.started_death_sequence then
		self:start_timer("damage_flash", 12)
	end

	
    if not invuln then
        self:damage(damage)
    end
	
    if self.hp <= 0 and not self.started_death_sequence then
		self.started_death_sequence = true
        self:death_sequence(object)
		self:stop_timer("damage_flash")
	else
		if self.started_death_sequence then
			-- self:play_sfx("enemy_exploder_beep", 0.5)
		elseif self.hurt_sfx and not invuln then
			self:play_sfx(self.hurt_sfx, self.hurt_sfx_volume or 1.0, self.hurt_sfx_pitch or 1.0)
		elseif not (self:has_tag("enemy_bullet") or self:has_tag("hazard")) and not invuln then
            self:play_sfx("enemy_hurt", 0.25, 1.0)
        elseif invuln then
			self:play_sfx("enemy_shield_hit", 0.7, 1.0)
		end
    end
end



function BaseEnemy:death_sequence(hit_by)
	self:die(hit_by)
end

function BaseEnemy:is_invulnerable()
    if self:is_tick_timer_running("shield_invuln") then
        return true
    end
	if self:is_tick_timer_running("hit_invuln_tick") then
		return true
	end
    return false
end

function BaseEnemy:normal_death_effect(hit_by)
	local sprite = self:get_sprite()
	local hit_vel_x, hit_vel_y
    if self.is_simple_physics_object and self.applying_physics then
        hit_vel_x, hit_vel_y = self.vel.x, self.vel.y
    else
        hit_vel_x, hit_vel_y = 0, 0
    end
    
    local hit_point_x, hit_point_y = self.pos.x, self.pos.y
	local center_out_velocity_multiplier = self.center_out_velocity_multiplier or 1
    if hit_by then
        if hit_by.reset_death_particle_hit_velocity then
            hit_vel_x, hit_vel_y = 0, 0
        end
        if hit_by.get_death_particle_hit_velocity then
            local extra_vel_x, extra_vel_y = hit_by:get_death_particle_hit_velocity(self)

            hit_vel_x = hit_vel_x + extra_vel_x
            hit_vel_y = hit_vel_y + extra_vel_y
        end

        if hit_by.center_out_velocity_multiplier then
            center_out_velocity_multiplier = center_out_velocity_multiplier * hit_by.center_out_velocity_multiplier
        end


        if hit_by.get_death_particle_hit_point then
            hit_point_x, hit_point_y = hit_by:get_death_particle_hit_point(self)
        else
            hit_point_x, hit_point_y = hit_by.pos.x, hit_by.pos.y
        end

        if hit_vel_x == 0 and hit_vel_y == 0 then
            hit_point_x, hit_point_y = self.pos.x, self.pos.y
            local diff = self.pos:direction_to(hit_by.pos)
            hit_vel_x = -diff.x * 10
            hit_vel_y = -diff.y * 10
        end
    end
    
    -- print(hit_vel_x, hit_vel_y)

	local bx, by

	if self.get_death_flash_position then
		bx, by = self:get_death_flash_position()
    else
		bx, by = self:get_body_center()
	end

	self:spawn_object(DeathFlash(bx, by, sprite, self.death_flash_size_mod or 1, nil, nil, nil, nil, hit_vel_x, hit_vel_y))
	if not self.no_death_splatter then
		local class = DeathSplatter
		-- if game_state.artefacts.death_cap and self:has_tag("wave_enemy") then
        if game_state.artefacts.death_cap and not self.is_enemy_bullet and not self:has_tag("fungus") then
            class = FungalDeathSplatter
        end

		self:spawn_object(class(bx, by, self.flip, sprite, Palette[sprite], 2, hit_vel_x, hit_vel_y, hit_point_x, hit_point_y, center_out_velocity_multiplier))
	end
end

function BaseEnemy:flash_death_effect(size_mod)
	local bx, by = self:get_body_center()
	self:spawn_object(DeathFlash(bx, by, self:get_sprite(), size_mod or 1))
end

function BaseEnemy:die(hit_by)
	self:emit_signal("died")
	self:death_effect(hit_by)
	self:queue_destroy()
end

function BaseEnemy:death_effect(hit_by) 
    self:normal_death_effect(hit_by)
    if self.death_sfx then
        self:play_sfx(self.death_sfx, self.death_sfx_volume or 1.0, self.death_sfx_pitch or 1.0)
    else
        if self:has_tag("wave_enemy") then
            self:play_sfx("enemy_death", 0.5, 1.0)
			self:play_sfx("enemy_death3", 0.35, 1.0)
            self:play_sfx("enemy_death2", 1.0, 1.0)
		elseif self:has_tag("hazard") then
            self:play_sfx("hazard_death", 1.0, 1.0)
		elseif self:has_tag("enemy_bullet") then
			self:play_sfx("bullet_death", 0.5, 1.0)
		else
			self:play_sfx("misc_death", 1.0, 1.0)
		end
    end
	if self.death_cry then
		self:play_sfx(self.death_cry, self.death_cry_volume or 1.0, self.death_cry_pitch or 1.0)
	end
end

function BaseEnemy:get_time_scale()

	local modifier = 1
    
	if self.world.clock_slowed then
        modifier = modifier / 3
    end

	return modifier
end

function BaseEnemy:update_shared(dt)
    BaseEnemy.super.update_shared(self, dt * self:get_time_scale())
    self:collide_with_terrain()
end

function BaseEnemy:get_sprite()
	return textures.enemy_base
end
function BaseEnemy:get_default_palette()
    return Palette[self:get_sprite()]
end

function BaseEnemy:get_palette()
	return nil, nil
end

function BaseEnemy:get_palette_shared()
	local offset = 0

    if self:is_timer_running("damage_flash") then
        offset = self.tick / 3
        return Palette.cmyk, offset
    end

	if self:is_tick_timer_running("shield_invuln") then
		offset = idiv(self.tick, 2)
		return Palette.shielded, offset
	end

	-- local doubletick = floor(self.random_offset + self.tick / 2)
    -- if doubletick % 300 < 4 then
	-- 	return Palette.death_disintegration, doubletick
	-- end
	
	local palette, offs = self:get_palette()

	palette = palette or self:get_default_palette()
	offset = offs or 0

	return palette, offset
end

function BaseEnemy:get_draw_offset()
    local x, y = BaseEnemy.super.get_draw_offset(self)
    -- if self:is_timer_running("damage_flash") then
    -- 	x = floor(self.tick / 2) % 2 == 0 and 1 or -1
    -- 	y = floor(self.tick / 3) % 2 == 0 and 1 or -1
    -- end
    return x, y
end

function BaseEnemy:spawn_wave_enemy(enemy_object)
	self.world:spawn_wave_enemy(enemy_object)
end

function BaseEnemy:get_sprite_flip()
	return self.flip, 1
end

function BaseEnemy:queue_destroy()
	BaseEnemy.super.queue_destroy(self)
end

function BaseEnemy:draw()
	
    self:body_translate()

	self:draw_sprite()
end

function BaseEnemy:draw_sprite()
	local palette, palette_index = self:get_palette_shared()
	local h_flip, v_flip = self:get_sprite_flip()

	graphics.drawp_centered(self:get_sprite(), palette, palette_index, 0, 0, 0, h_flip, v_flip)
end

return BaseEnemy
