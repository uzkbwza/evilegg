local LeaderboardEntryButton = require("obj.Menu.MenuButton"):extend("LeaderboardEntryButton")

function LeaderboardEntryButton:new(x, y)
    LeaderboardEntryButton.super.new(self, x, y, 220, 18)
end

function LeaderboardEntryButton:draw()
    local x, y, w, h = self:get_rect_local()
    if self.focused then
        -- graphics.set_color(Color.green)
        -- graphics.rectangle("line", x-1, y, w+2, h)
    end
end


function LeaderboardEntryButton:on_focused()
	self:play_sfx("ui_menu_button_focused1", 0.6)
end

function LeaderboardEntryButton:on_selected()
	self:play_sfx("ui_menu_button_selected1", 0.6)
end

return LeaderboardEntryButton
