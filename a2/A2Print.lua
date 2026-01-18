local M = {}

local A2Settings = require("a2.A2Settings")

M.last_msg = "" --for debugging


-- verbosity = minimum amount of A2Settings.WEB_REQUEST_VERBOSITY to print this:
function M.print(pstr, verbosity)
    if verbosity == nil then
        verbosity = 1
    end

	if A2Settings.WEB_REQUEST_VERBOSITY >= verbosity then
		M.last_msg = pstr
		print(pstr)
    end
end

return M