local Process = require("@lune/process")
local Main = require("src/main")
local Commands = require("src/commands")

if Process.args then
	Main()
end

return Commands
