local startTime = os.clock()
local printLog = {}

return {
	environment = {
		print = function(...)
			local t = {...}
			for i, v in t do
				t[i] = tostring(v)
			end
			table.insert(printLog, {
				content = table.concat(t, " "),
				t = os.clock() - startTime
			})
		end
	},
	hooks = {
		onExit = function(err)
			print("exit!", printLog)
		end
	}
}
