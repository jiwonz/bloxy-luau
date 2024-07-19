local sc = Instance.new("ModuleScript", workspace)
sc.Source = [[
return {
	err = function()
		print("ez")
	end
}
]]
local mod = require(sc)
print(mod)
mod.err()
