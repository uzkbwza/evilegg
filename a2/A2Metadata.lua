local M = {}

local A2Print = require("a2.A2Print")
local A2Util = require("a2.A2Util")
local json = require("lib.json")
local A2Settings = require("a2.A2Settings")

-- This class holds persistent info for arcade2.
-- It keeps track of signed in users, and also keeps
-- track of which scores/replays have and haven't been
-- synced.
M.A2Metadata = {}

-- You can call A2Metadata.load() and then access and
-- make changes to A2Metadata.data, then call A2Metadata.save()
M.data = nil


function M.make_new_data()
    M.data = {}

    -- Since device ID is not permanent, we must store it
    -- the first time we get it and hold onto it forever.
    M.data.machine_id = ""

    -- Prevents user from changing machine_id to whatever they want.
    -- It's invalid unless it's hashed correctly with the game secret.
    M.data.machine_id_hash = ""


    -- List of string usernames.
    -- The first user is the main user.
    -- Additional users are helpers for multiplayer -- we'll store the
    -- usernames so they don't have to re-enter them all the time if they
    -- play together frequently.
    M.data.users = {} --array

    -- Array of string 
    -- users is a subset of muiltiplayer_users. 
    -- While users would shrink to 1 when you go into single player, multiplayer_users
    -- never shrinks unless you do logout_user.
    -- This allows us to remember the last "team" that played, so if they switch from
    -- multiplayer to singleplayer and back again, they aren't tediously asked to
    -- provide usernames again.
    M.data.multiplayer_users = {} --array


    -- Dictionary of device-specific tokens for any player that has ever logged in.
    -- Key is username.
    -- They only get removed if you specifically do logout_user, else they are kept
    -- around forever in case there is still unsynchronized data around.
    M.data.tokens = {}   --dict


    -- Array of A2MetadataScore 
    -- List of score metadata. We can only sync for users who are logged in and have a token.[br][br]
    -- You don't need to worry about users editing this file, because md5 hashes are used to ensure the
    -- immutability of the data.
    -- [br][br]
    -- Eventually, [member A2MetadataScore.my_hash] will be submitted alongside a valid token for the user.
    -- If the token is invalid, it's probably just because the user changed their password or username.
    -- If the hash is invalid, it's a sign of likely cheating, and the score will not be shown in the
    -- scoreboard. Instead the submission will be kept internally as evidence of cheating.
    --[br][br]
    -- Note that machine id is included in the hash. Replays must be synced by the device they were made on.
    M.data.scores = {}  --array


    -- Cached from the last successfull call to the ingame_news endpoint.
    -- This way you can display the news immediately instead of having to wait
    -- for it to load every time.
    M.data.ingame_news = ""

    -- constantly incrementing score id for local ids
    M.data.last_local_score_id = 0


    return M.data
end


-- Returns what the next local score ID will be (without changing it), useful for giving your replays unique names
function M.next_local_score_id()
    local data = M.get_data()
	return data.last_local_score_id + 1
end


-- Returns the next local score ID while also incrementing it in the save file
function M.new_local_score_id()
    local data = M.get_data()
    data.last_local_score_id = data.last_local_score_id + 1
    M.save()
	return data.last_local_score_id
end


-- Convenience function which calls load() if it hasn't been called yet.
function M.get_data()
	if M.data == nil then
		M.load()
    end
	return M.data
end


function M.get_token(username)
	M.get_data()
	
    for index, value in ipairs(M.data.tokens) do
        if value == username then
            return M.data.tokens[username]
        end
    end
    return ""
end



-- Loads static [member A2Metadata.data] from the default save file name, or returns default values if none exists yet
function M.load()

    local data_path = A2Settings.A2_DATA_FILE   -- don't think this needs to be absolute-ized in love

	if M.data == nil then
        A2Print.print("Doing a2metadata.load")
        M.make_new_data()

        if love.filesystem.exists(data_path) then
            A2Print.print("Loading metadata from " .. love.filesystem.getSaveDirectory() .. "/" .. data_path)
            local json_str = love.filesystem.read(data_path)
            M.data = json.decode(json_str)
            -- rather than do any manual deserialization to classes like I did in Godot i'm just gonna hope the structure comes
            -- out of the JSON in the same state it went in and use that.
        end
	end


	return M.data
end


-- Saves [member A2Metadata.data]  to default save file
function M.save()
	A2Print.print("Saving A2Metadata to " .. love.filesystem.getSaveDirectory() .. "/" .. A2Settings.A2_DATA_FILE)
	local json_str = json.encode(M.get_data())
    love.filesystem.write(A2Settings.A2_DATA_FILE, json_str)
end


-- Removes score submissions which have web IDs (and have therefore been successfully submitted).
function M.cull_submitted_scores()
	M.load()
	
	for i = #M.data.scores, 1, -1 do -- iterate backwards so we can remove without messing up the ONE-BASED index
		if A2Util.str_bool(M.data.scores[i].web_id) then
			if A2Util.str_bool(M.data.scores[i].replay_file) and not M.data.scores[i].replay_file_uploaded then -- can't be culled yet, there is a replay yet to be uploaded
				if love.filesystem.exists(M.data.scores[i].replay_file) then
					goto continue_loop
				else
					print("WARNING: Replay " .. M.data.scores[i].replay_file .. " was missing. May cull score with web_id " .. M.data.scores[i].web_id)
                end
            end
					
					
			if A2Util.str_bool(M.data.scores[i].mini_replay_file) and not M.data.scores[i].mini_replay_file_uploaded then
				if love.filesystem.exists(M.data.scores[i].mini_replay_file) then
					goto continue_loop
				else
					print("WARNING: Mini replay " .. M.data.scores[i].mini_replay_file .. " was missing. May cull score with web_id " .. M.data.scores[i].web_id)
                end
            end
					
			
			-- cull replay and mini-replay
			if A2Util.str_bool(M.data.scores[i].replay_file) and love.filesystem.exists(M.data.scores[i].replay_file) then
				love.filesystem.remove(M.data.scores[i].replay_file)
				A2Print.print("Culled replay " .. M.data.scores[i].replay_file)
            end

			if A2Util.str_bool(M.data.scores[i].mini_replay_file) and love.filesystem.exists(M.data.scores[i].mini_replay_file) then
				love.filesystem.remove(M.data.scores[i].mini_replay_file)
				A2Print.print("Culled replay " .. M.data.scores[i].mini_replay_file)
            end
			
			table.remove(M.data.scores, i)
			A2Print.print("Culled score " .. tostring(i) )

            ::continue_loop::
        end
    end


	M.save()
end


return M