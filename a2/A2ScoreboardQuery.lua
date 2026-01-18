local M = {}

local A2Settings = require "a2.A2Settings"

-- Use this to configure a call to A2Web.web_get_scoreboard
function M.new()
    local ret = {}

    -- Page 0 is the top scores, unless you're using relative_to_user / center_on, in which case it's the page centered on the user team.
    ret.page = 0

    -- How many scores to get at once for the pagination. Lower may load faster, but require more loads
    ret.perpage = 1000

    -- If used with end_place, will ignore page settings and return a range of places.
    ret.start_place = -1

    -- If used with start_place, will ignore page settings and return a range of places.
    ret.end_place = -1

    -- Returns the unicode string users can optionally append to their username.
    ret.get_score_sig = true

    -- Returns the time this score was submitted.
    ret.get_date_time = true

    -- Returns a list of run achievements that were acquired during the run.
    ret.get_run_achievements = true

    -- Returns the frame number on which each run achievement was acquired.
    ret.get_run_achievement_frames = false

    -- Returs a URL to a scoreboard sig image, if the user has uploaded one.
    ret.get_score_sig_img_content_type = false

    -- Returns the user's profile picture content type if applicable.
    -- Note this may also return  "steam" in which case they have a Steam profile picture, but
    -- we aren't sure whether it's PNG or JPEG.
    ret.get_profile_pic_content_type = true

    -- <summary>
    -- Returns a list of badge image URLs (achievements etc) that the user has displayed, up to 9.
    ret.get_display_badges = true

    -- Gets the number of times they submitted to this level (e.g. "wins")
    ret.get_submission_count = false

    -- Gets the amount of frames they've spend playing this level.
    ret.get_playtime = false


    -- Returns the user's Discord ID if they have linked the profile to their Discord.
    ret.get_discord_id = false

    -- Returns a replay ID you can use to download the replay file or launch the discussion page.
    ret.get_replays = true

    -- List of usernames that form the team this page should be relative to.
    -- If left blank, will use the signed in users.
    -- Array of strings
    ret.center_on = {}


    ret.game_version_identifier = A2Settings.GAME_VERSION

    -- Setting this will prompt an is_me return for the username which matches my_username.
    -- This is useful because Steam users may be using a pseudo-username of "steam-" + steamid,
    -- so the backend will convert this to return the appropriate is_me.
    ret.my_username = ""

    return ret
end

return M