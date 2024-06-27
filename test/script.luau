local sc = Instance.new("ModuleScript", workspace)
sc.Source = [[
return {
	err = function()
		
	end
}
]]
local mod = require(sc)
print(mod)
mod.err()
