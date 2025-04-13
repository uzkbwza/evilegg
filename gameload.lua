-- this file is used to load custom code before the game starts
-- but after the game has been initialized

if debug.enabled then
	function Screens.LevelEditor:custom_map_process(tab)
		print("custom_map_process")
	end
end

graphics.load_image_font("score_pickup_font", "font_score_pickup", "0123456789")
graphics.load_image_font("score_pickup_font_white", "font_score_pickup_white", "0123456789")
graphics.load_image_font("image_font1", "font_font1", " ABCDEFGHIJKLMNOPQRSTUVWXYZ+-1234567890[].×")
graphics.load_image_font("image_font2", "font_font2", " ABCDEFGHIJKLMNOPQRSTUVWXYZ+-1234567890[].×")
graphics.load_image_font("image_bigfont1", "font_bigfont1", " APRHOSITNCXDEFQUVGLKBMWJZY")

BaseEnemy = require("obj.Spawn.Enemy.BaseEnemy")
Worlds = filesystem.get_modules("world")
