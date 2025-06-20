local Cutscene = GameObject2D:extend("Cutscene")
local BeginningCutscene = Cutscene:extend("BeginningCutscene")
local EndingCutscene1 = Cutscene:extend("EndingCutscene1")
local EndingCutscene2 = Cutscene:extend("EndingCutscene2")



return { Cutscene, BeginningCutscene, EndingCutscene1, EndingCutscene2 }