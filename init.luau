local ArgParse = require("submodules/argparse")
local Lib = require("lib")

local parser = ArgParse("bloxy-luau")
parser:argument("script", "Script to run")
parser:option("--place", "Place file")
parser:option("--addon", "Addon script")
parser:action(function(args)
	Lib.run({
		place = args.place,
		script = args.script,
		addon = args.addon and require(args.addon:gsub(".luau", ""):gsub(".lua", "")) or nil
	})
end)

parser:parse()
