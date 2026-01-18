-- Compiles the a2 directory to usable bytecode in the a2_bc directory.
-- NOTE: Run this before release. Then delete the a2 directory and rename a2_bc to a2.

-- Reference: https://stackoverflow.com/questions/76592586/is-there-a-way-to-package-your-love2d-game-into-a-bytecode-distributable

file_bases = {
    'A2ErrorReturn',
    'A2Metadata',
    'A2MetadataRunAchievement',
    'A2MetadataScore',
    'A2MetadataSubscore',
    'A2Print',
    'A2ScoreboardQuery',
    'A2Settings',
    'A2Util',
    'A2Web',
    'A2WebReturn'
}


for i,file_base in ipairs(file_bases) do
    -- Compile `test.lua` to bytecode, strip debug info
    local source = "a2/" .. file_base .. ".lua"
    local dest = "a2_bc/" .. file_base .. ".bc"
    local dest_lua = "a2_bc/" .. file_base .. ".lua"
    local bytecode = string.dump(assert(love.filesystem.load(source)), true)

    local f = assert(io.open(dest, "wb"))
    f:write(bytecode)
    f:close()

    -- Add additional lua file which just loads the bytecode
    local lf = assert(io.open(dest_lua, "w"))
    lf:write("return assert(love.filesystem.load(\"a2/" .. file_base .. ".bc\"))()\n")
    lf:close()

    print("Compiled `" .. source .. "` to `" .. dest .. "` and `" .. dest_lua .. "`")
end

-- love.event.quit()
