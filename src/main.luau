local Types = require("types")
local Stdio = require("@lune/stdio")
local ArgParse = require("../submodules/argparse")
local Commands = require("commands")

local function main()
    local parser = ArgParse("bloxy-lune")
    for name, command in Commands :: { Types.Command<any> } do
		command.name = name
		local p = parser:command(command.name, command.description)
		command.args(p)
		p:action(function(args)
			args[name] = nil
			command.run(args)
		end)
	end
    local args = parser:parse()
end

return main
