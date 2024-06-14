--// $Packages
local FS = require("@lune/fs")
local Roblox = require("@lune/roblox")
local Luau = require("@lune/luau")
local Task = require("@lune/task")
local Stdio = require("@lune/stdio")
local DT = require("../utils/datetime")
local Runtime = require("../utils/runtime")
local ReducedInstance = require("../utils/reduced_instance")

--// $CommandConfig
local Types = require("../types")
local Command = {} :: Types.Command<{
    script: string,
    place: string?
}>
Command.description = "Run a script"

function Command.run(args)
	Task.spawn(function()
		local place = args.place
		if place then
			place = FS.readFile(place)
		else
			place = Roblox.serializePlace(Roblox.Instance.new("DataModel"))
		end
		local game = Roblox.deserializePlace(place)
		local script = Roblox.Instance.new("Script")
		script.Name = "Script"
		script.Source = FS.readFile(args.script)
		script.Parent = game:GetService("ServerScriptService")

		local MODULE_REGISTRY = {}
		local lockedRobloxMethod = {
			"deserializePlace",
			"deserializeModel",
			"serializePlace",
			"serializeModel",
			"getAuthCookie",
			"getReflectionDatabase",
			"implementProperty",
			"implementMethod"
		}
		for i, v in lockedRobloxMethod do
			lockedRobloxMethod[v] = Roblox[v]
		end

		local function rbxPrint(...)
			local vars = { ... }
			for i, v in vars do
				if type(v) == "userdata" then
					vars[i] = tostring(v)
				end
			end
			print(table.unpack(vars))
		end

		local function rbxWarn(...)
			Stdio.write(Stdio.style("bold"))
			Stdio.write(Stdio.color("yellow"))
			rbxPrint(...)
			Stdio.write(Stdio.color("reset"))
			Stdio.write(Stdio.style("reset"))
		end

		local function implementRobloxMethods()
			-- DEPENDENTS: [Jest]
			Roblox.implementMethod("Instance", "WaitForChild", function(self, ...)
				local child = self:FindFirstChild(...)
				local childName = select(1, { ... })
				assert(
					child,
					`WaitForChild is not implemented in Lune, so FindFirstChild was substituted but {self:GetFullName()} does not contain child {childName} at the time of calling.`
				)
				return child
			end)

			-- DEPENDENTS: [Jest]
			Roblox.implementMethod("Instance", "isA", function(self, className: string)
				return self:IsA(className)
			end)

			-- DEPENDENTS: [Jest]
			Roblox.implementProperty("RunService", "Heartbeat", function()
				return {
					Wait = function(_self)
						local thread = coroutine.running()
						local conn
						conn = Runtime:Connect(function(dt)
							conn:Disconnect()
							coroutine.resume(thread, dt)
						end)
						return coroutine.yield()
					end,
					Connect = Runtime.Connect,
				}
			end)
		end

		local rbxRequire

		local function loadScript(sc: Roblox.Instance)
			sc = ReducedInstance.once(sc)
			if not sc:IsA("LuaSourceContainer") then
				error("Attempt to load a non LuaSourceContainer")
			end

			local bytecodeSuccess, bytecode = pcall(Luau.compile, (sc :: any).Source)
			if not bytecodeSuccess then
				error(bytecode)
			end

			local callableFn = Luau.load(bytecode, {
				debugName = sc:GetFullName(),
				environment = setmetatable({
					game = game,
					script = sc,
					--require = requireModule,
					tick = os.clock,
					task = Task,
					DateTime = DateTime,
					print = rbxPrint,
					warn = rbxWarn,
					workspace = game:GetService("Workspace"),
					require = rbxRequire,
					-- error = rbxError
					--debug = Debug,
				}, { __index = function(self, k)
					local method = Roblox[k]
					if lockedRobloxMethod[k] == method then
						return nil
					end
					return method
				end}) :: any,
			})
			return callableFn
		end

		rbxRequire = function(moduleScript: Roblox.Instance)
			assert(moduleScript and moduleScript:IsA("ModuleScript"), `Attempt to require a non ModuleScript {moduleScript}`)

			local cached = MODULE_REGISTRY[moduleScript]
			if cached then
				return cached
			end

			local func = loadScript(moduleScript)

			local thread = coroutine.running()
			Task.spawn(function()
				local result = func()
				Task.spawn(thread, result)
			end)
			local result = coroutine.yield()
			MODULE_REGISTRY[moduleScript] = result
			return result
		end

		-- local rbxError = function<T>(message: T, level: number?)
		-- 	local stacks = debug.traceback():split("\n")
		-- 	stacks[#stacks] = nil
		-- 	Stdio.write(Stdio.style("bold"))
		-- 	Stdio.write(Stdio.color("red"))
		-- 	rbxPrint(message)
		-- 	Stdio.write(Stdio.color("reset"))
		-- 	Stdio.write(Stdio.style("reset"))

		-- 	Stdio.write(Stdio.color("blue"))
		-- 	print("Stack Begin")
		-- 	for i, v in stacks do
		-- 		local splited = v:split(":")
		-- 		local line = splited[#splited]
		-- 		local fullname = v:match('"(.-)"')
		-- 		print(`Script '{fullname}', Line {line}`)
		-- 	end
		-- 	print("Stack End")
		-- 	Stdio.write(Stdio.color("reset"))
		-- end

		implementRobloxMethods()
		local func = loadScript(script)
		Task.spawn(func)
	end)
end

function Command.args(parser)
	parser:argument("script", "Script to run")
    parser:option("--place", "Place file")
end

return Command
