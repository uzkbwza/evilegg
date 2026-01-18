-- In Lua, I'm just using a dictionary instead of an actual class.
-- I just slapped in the original Godot code as a reference
-- to what is supposed to be in an A2MetadataScore.

local M = {}

function M.new()
    local ret = {
        usernames={},   --Array[String]
        level="",
        score=0,
        frame_length=0,
        run_achievements="",
        subscores="",
        date=os.date("%Y-%m-%dT%H:%M:%S"),
        replay_file="",
        mini_replay_file="",
        replay_name="",
        meta_str="",
        web_id="",
        local_id=0,
        replay_file_hash="",
        mini_replay_file_hash="",
        replay_file_uploaded=false,
        mini_replay_file_uploaded=false,
        my_hash=""
    }
    return ret
end


return M



-- class_name A2MetadataScore

-- ## [b]"usernames"[/b]: Since multiplayer scores are supported, there can be more than one (single entry for singleplayer games) [br][br]
-- var usernames : Array[String] = []

-- ## [b]"level"[/b] : level ID.
-- var level : String = ""

-- ## [b]"score"[/b] : the score achieved.
-- var score : int = 0

-- ## [b]"frame_length"[/b] : length of the replay, or, if no replays, this is just the playthrough frame length
-- ## used to calculate lifetime playtimes and achievement playtimes.
-- var frame_length : int = 0

-- ## [b]"run_achievements"[/b] : array of achievements the player got during this specific run.
-- ## It is kept as a raw JSON string, because this string itself is used as part of the hashing
-- ## verification, so we can't afford any changes in whitespace etc.
-- ## Format: [ {"username": "username1", "achievement": "achievement1", "frame": 123, "playtime":10000}, {"username": "username2", "achievement": "achievement2", "frame": 456, "playtime":20000} ]
-- ## "playtime" is allowed to be ommitted, but if submitted it will keep track of how long they played the game before getting the achievement.
-- var run_achievements : String

-- ## [b]"subscores"[/b] " : array of subscores (other metrics besides the main score) to keep track of.
-- ## It is kept as a raw JSON string, because this string itself is used as part of the hashing
-- ## verification, so we can't afford any changes in whitespace etc.
-- ## Format: {"subscore1": 123, "subscore2": 456}
-- var subscores : String

-- ## [b]"date"[/b] : system time this score was achieved, defaults to current UTC time in format YYYY-MM-DDTHH:MM:SS
-- var date : String = Time.get_datetime_string_from_system(true)

-- ## [b]"replay_file"[/b] : path relative to "user://", or absolute path. Or "" if this game doesn't use replays
-- var replay_file : String = ""

-- ## [b]"mini_replay_file"[/b] : Filename for gthe mini-replay (replayed on website only)
-- var mini_replay_file = "";

-- ## [b]"replay_name"[/b] : generally would be changed by the user after submit_score, does not need to be hashed
-- var replay_name : String = ""

-- ## [b]"meta_str"[/b] : general purpose string, put any additional info you want to keep about this score.
-- var meta_str : String = ""

-- ## [b]"web_id"[/b] : was this score ever synced to the server? if so, this is its id, and maybe it could eventually be culled
-- var web_id : String = ""

-- ## [b]"local_id"[/b] : local ID in case you want to view replay, add clips etc
-- var local_id : int = 0


-- ## Submitted in the first submit_score call to arcade2.
-- ## A second PUT request is necessary to upload the replay file, and it will be matched against this.
-- var replay_file_hash := ""

-- ## Hash for mini-replay file (replayed on website only)
-- var mini_replay_file_hash := ""

-- ## Set to true when we get a successful response from the server for the replay file upload.
-- ## If replay_file is blank, it doesn't matter if this is false.
-- ## If replay_file is not blank and this is false, we should keep trying.
-- var replay_file_uploaded := false

-- ## Equivalent to replay_file_uploaded, but for the mini-replay file.
-- var mini_replay_file_uploaded := false


-- ## [b]"my_hash"[/b] : A hash created by the following format:
-- ## [codeblock]                                                                                                                                                                                                                                                                                                                                                                      ##     var replay_hash = MD5 hash of the entire replay file's binary data, or "" for games with no replays
-- 	##     var hash = (
-- 	## 					usernames[0].md5_text() + usernames[1].md5_text() + ... +        #NOTE: can't include tokens as they might change between replay recording and submission
-- 	## 					machine_unique_id.md5_text() +
-- 	##					A2Settings.GAME_NAME.md5_text() +
-- 	##					level.md5_text() +
-- 	##					str(score).md5_text() +
-- 	##					frame_length +
-- 	##					exact_achievements_json.md5_text() +
-- 	##                  exact_subscores_json.md5_text() +
-- 	##					date.md5_text() +
-- 	##					meta_str.md5_text() +
-- 	##					md5(replay file bytes) +
-- 	##					A2Settings.GAME_SECRET_KEY.md5_text()
-- 	##				  ).md5_text()
-- ## [codeblock]
-- ## The reason for the redundant .md5_text() calls is that this should theoretically make it harder for memory editors to
-- ## find the game's secret key. They can't just search for username in memory and find something attached to the secret
-- ## key. They could still edit the score in memory before the hash is made, but at least their replay would probably reveal the 
-- ## cheating.
-- var my_hash : String = ""