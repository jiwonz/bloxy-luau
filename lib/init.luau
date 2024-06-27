--!strict

local FS = require("@lune/fs")
local Roblox = require("@lune/roblox")
local Luau = require("@lune/luau")
local Task = require("@lune/task")
local Stdio = require("@lune/stdio")
local DT = require("utils/datetime")
local Runtime = require("utils/runtime")
local ReducedInstance = require("utils/reduced_instance")

local module = {}

function module.run(args: {place: string, script: string, addon: { environment: { [string]: any }? , hooks: { onExit: (exitWithError: boolean) -> () }? }? })
	local rootThread = coroutine.running()
	Task.spawn(function()
		local mainScriptThread = coroutine.running()
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
		} :: { [any]: any }
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
			local renderStepBinds = {}
			Roblox.implementMethod("RunService", "BindToRenderStep", function(self, name: string, priority : number, func: () -> ())
				local runtime = Runtime.new(priority)
				renderStepBinds[name] = runtime:Connect(func)
			end :: any)
			Roblox.implementMethod("RunService", "UnbindFromRenderStep", function(self, name: string)
				renderStepBinds[name]:Disconnect()
				renderStepBinds[name] = nil
			end :: any)

			local RenderStepped = Runtime.new(2000)
			Roblox.implementProperty("RunService", "RenderStepped", function()
				return RenderStepped
			end)
			Roblox.implementProperty("RunService", "PreRender", function()
				return RenderStepped
			end)

			local PreAnimation = Runtime.new(2000 + 1)
			Roblox.implementProperty("RunService", "PreAnimation", function()
				return PreAnimation
			end)

			local Stepped = Runtime.new(2000 + 2)
			Roblox.implementProperty("RunService", "Stepped", function()
				return Stepped
			end)
			Roblox.implementProperty("RunService", "PreSimulation", function()
				return Stepped
			end)

			local Heartbeat = Runtime.new(2000 + 3)
			Roblox.implementProperty("RunService", "Heartbeat", function()
				return Heartbeat
			end)
			Roblox.implementProperty("RunService", "PostSimulation", function()
				return Heartbeat
			end)
		end

		local rbxRequire
		local rbxInstance = {}
		rbxInstance.fromExisting = function(instance)
			local t = typeof(instance)
			if t == "Instance" then
				return Roblox.Instance.new((instance :: any).ClassName)
			else
				error(`invalid argument #1 to 'fromExisting' (Instance expected, got {t})`)
			end
		end :: <T>(T) -> (T)
		rbxInstance.new = function(className: string, parent: Roblox.Instance?)
			local instance = Roblox.Instance.new(className)
			if parent then
				instance.Parent = parent
			end
			return instance
		end

		local rbxError = function<T>(message: T?, level: number?)
			local stacks = debug.traceback(nil, level and level + 1 or 2):split("\n")
			stacks[#stacks] = nil
			stacks[#stacks] = nil
			Stdio.write(Stdio.style("bold"))
			Stdio.write(Stdio.color("red"))
			if stacks[1] then
				rbxPrint(stacks[1]..": "..tostring(message))
			else
				rbxPrint(message)
				stacks[1] = tostring(message)
			end
			Stdio.write(Stdio.color("reset"))
			Stdio.write(Stdio.style("reset"))

			Stdio.write(Stdio.color("blue"))
			print("Stack Begin")
			for _, v in stacks do
				local fullname = v:match('"(.-)"')
				if not fullname then
					continue
				end
				local line = v:gsub(fullname, ""):match("%]:(%d+)")
				print(`Script '{fullname}', Line {line}`)
			end
			print("Stack End")
			Stdio.write(Stdio.color("reset"))
			if coroutine.running() == mainScriptThread then
				print("omfg main script thread is dead by error!")
				coroutine.resume(rootThread, true)
			end
			coroutine.yield()
		end

		local function loadScript(sc: Roblox.Instance) -- wrapInModuleFunction: to determine the module returns nil or nothing
			-- sc = ReducedInstance.once(sc)
			if not sc:IsA("LuaSourceContainer") then
				error("Attempt to load a non LuaSourceContainer")
			end

			local source = (sc :: any).Source
			local bytecodeSuccess, bytecode = pcall(Luau.compile, source)
			if not bytecodeSuccess then
				error(bytecode)
			end

			local scriptEnv = {
				game = game,
				script = sc,
				tick = os.clock,
				task = Task,
				DateTime = DT,
				print = rbxPrint,
				warn = rbxWarn,
				workspace = game:GetService("Workspace"),
				require = rbxRequire,
				Instance = rbxInstance,
				error = rbxError
				--debug = Debug,
			}
			if args.addon and args.addon.environment then
				for k, v in args.addon.environment do
					scriptEnv[k] = v
				end
			end

			local callableFn = Luau.load(bytecode, {
				debugName = sc:GetFullName(),
				environment = setmetatable(scriptEnv, { __index = function(self, k)
					local method = Roblox[k]
					if lockedRobloxMethod[k] == method then
						return nil
					end
					return method
				end}) :: any,
			})
			return function()
				local result = table.pack(pcall(callableFn))
				if not result[1] then
					rbxError(result[2])
				end
				local out = {}
				for i = 2, result.n do
					table.insert(out, result[i])
				end
				return table.unpack(out)
			end
		end

		rbxRequire = function(moduleScript: Roblox.Instance)
			assert(moduleScript and moduleScript:IsA("ModuleScript"), `Attempt to require a non ModuleScript {moduleScript}`)

			local cached = MODULE_REGISTRY[moduleScript]
			if cached then
				return cached[1]
			end

			local func = loadScript(moduleScript)

			local thread = coroutine.running()

			local isSuspended = false
			local pack
			isSuspended = coroutine.status(Task.spawn(function()
				pack = table.pack(func())
				if isSuspended then
					Task.spawn(thread)
				end
			end)) ~= "dead"
			if isSuspended then
				coroutine.yield() --- reuse moduleFunction as identifier for cache (MODULE_REGISTRY)
			end
			assert(pack.n == 1, "Module code did not return exactly one value")
			local result = pack[1]
			MODULE_REGISTRY[moduleScript] = pack
			return result
		end

		implementRobloxMethods()
		local func = loadScript(script)
		func()
		coroutine.resume(rootThread, false)
	end)
	local exitWithError = coroutine.yield()
	if args.addon and args.addon.hooks then
		args.addon.hooks.onExit(exitWithError)
	end
end

return module
