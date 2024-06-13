local Process = require("@lune/process")
local BloxyLune = {}

local function main()
	print(Process.args)
end

if Process.args then
	main()
end

return BloxyLune
