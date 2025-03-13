local BigHopper = require("obj.Spawn.Enemy.Hopper"):extend("BigHopper")

function BigHopper:new(x, y)
    self.default_body_height = 8
    self.number_hop_bullets = 30
    self.hop_speed = 1.0
    self.max_hp = 10
    self.min_wait_time = 120
    self.max_wait_time = 360
    BigHopper.super.new(self, x, y)
    self.drag = 0.05

    self.terrain_collision_radius = self.terrain_collision_radius * 2
    self.hurt_bubble_radius = self.hurt_bubble_radius * 2
    self.hit_bubble_radius = self.hit_bubble_radius * 2
    self.body_height_mod = 15
    self.hop_sfx = "enemy_big_hopper_hop"
    self.shoot_sfx = "enemy_big_hopper_shoot"
end



function BigHopper:state_Hopping_enter()
	BigHopper.super.state_Hopping_enter(self)
	self.drag = 0.025
end

function BigHopper:state_Hopping_exit()
	BigHopper.super.state_Hopping_exit(self)
	self.drag = 0.05
end

function BigHopper:get_sprite()
    return self.sprite == textures.enemy_hopper1 and textures.enemy_bighopper1
        or self.sprite == textures.enemy_hopper2 and textures.enemy_bighopper2
		or self.sprite == textures.enemy_hopper3 and textures.enemy_bighopper3
end

return BigHopper
