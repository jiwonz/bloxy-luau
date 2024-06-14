local module1 = Instance.new("ModuleScript")
module1.Source = "task.wait(1); print(\"hello world\") return nil"
module1.Name = "module1"
print(script)
module1.Parent = script

local m1 = require(module1)
local m2 = require(module1)
