local ExploderEnemy = Object:extend("ExploderEnemy")


function ExploderEnemy:__mix_init()
	self.death_sequence = self.exploder_death_sequence
end

function ExploderEnemy:exploder_death_sequence(object)
    local s = self.sequencer
    self.melee_attacking = false
    self.intangible = true
    self.about_to_explode = true
    self:play_sfx("enemy_exploder_beep", 0.5)
    s:start(function()
        s:wait(2)
		self:die()
    end)
end

return ExploderEnemy
