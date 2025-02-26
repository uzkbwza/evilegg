fennel = require("lib.fennel")
debug.traceback = fennel.traceback
table.insert(package.loaders, function(filename)
   if love.filesystem.getInfo(filename) then
      return function(...)
         return fennel.eval(love.filesystem.read(filename), {env=_G, filename=filename}, ...), filename
      end
   end
end)

-- jump into Fennel
require("lib/test.fnl")
