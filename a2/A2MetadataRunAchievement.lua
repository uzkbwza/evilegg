local M = {}

function M.new()
    return {
        username = "",  -- username who got this achievement during the run (could be useful info during multiplayer)
        achievement = "", -- achievement identifier
        frame = 0 -- time in frames where they got this achievement during the run
    }
end

return M