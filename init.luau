local ArgParse = require("submodules/argparse")
local Lib = require("lib")

local parser = ArgParse("bloxy-luau")
parser:argument("script", "Script to run")
parser:option("--place", "Place file")
parser:option("--addon", "Addon script")
parser:option("--localplayer", "LocalPlayer")
parser:option("--localplayername", "LocalPlayer named")
parser:action(function(args)
	Lib.run({
		place = args.place,
		script = args.script,
		addon = args.addon and require(args.addon:gsub(".luau", ""):gsub(".lua", "")) or nil,
		localplayer = args.localplayer,
		localplayername = args.localplayername
	})
end)

parser:parse()
