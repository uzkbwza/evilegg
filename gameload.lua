-- this file is used to load custom code before the game starts
-- but after the game has been initialized

if debug.enabled then
	function Screens.LevelEditor:custom_map_process(tab)
		print("custom_map_process")
	end
end
