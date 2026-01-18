local M = {}

-- This is where you configure the settings for your arcade 2 game.
-- Most importantly, you need to set the GAME_NAME and GAME_SECRET_KEY for
-- your game. Having a unique randomized secret key helps ensure score
-- submissions are legit.
M.ARCADE2_BASEURL = "https://arcade2000.io/"   -- MUST HAVE TRAILING SLASH
--M.ARCADE2_BASEURL = "http://127.0.0.1:8000/"    -- kept around for Seb's testing convenience
M.A2_DATA_FILE = "arcade2000.json"  -- note that this contains buffered score submissions. due to hashing, users could open and look at this file, but editing would cause submissions to fail (and be flagged for cheating)

-- Used for validation of scores. Must be set on arcade2.io for your levels.
-- Don't share it or anyone would be able to submit fake scores for your game.
M.GAME_NAME = "evilegg"
M.GAME_SECRET_KEY = "iSkJXdNNhcGVGqI9Ax8OJqnFtg3GvI4S" 
M.GAME_VERSION = (IS_EXPORT and "" or "debug_") .. GAME_LEADERBOARD_VERSION:gsub("%.", "_")    -- change this to "v1" when you're ready for release, or create your own version # through the site

print(M.GAME_VERSION)

-- 0 = no prints
-- 1 = request / response prints
-- 2 = request / response / response body prints
M.WEB_REQUEST_VERBOSITY = 2



-- Disabling this not recommended
-- There is not currently a reason to keep submitted scores around in the JSON,
-- but in the future there may be games with involved replay / clip systems that
-- might utilize them.
M.AUTO_CULL_SUBMITTED_SCORES = true

return M
