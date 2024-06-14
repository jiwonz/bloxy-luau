--!strict

--[[
	Provides a connection to a loop that runs every frame. This is used
	in the custom Heartbeat implementation in lune/test.lua
--]]

local task = require("@lune/task")

type Listener = {
	callback: (number) -> (),
	disconnected: boolean,
}

local Runtime = {}
Runtime.__index = Runtime
Runtime._running = false
Runtime._listeners = {} :: { { Listener } }

local currentPriority = 0
local LAST_PRIORITY = 2000 + 3

function Runtime._loop()
	if Runtime._running then
		return
	end
	Runtime._running = true
	while next(Runtime._listeners) ~= nil do
		local listeners = Runtime._listeners
		local dt = task.wait()
		while LAST_PRIORITY >= currentPriority do
			local buf = listeners[currentPriority]
			if buf then
				for _, listener in buf do
					if not listener.disconnected then
						listener.callback(dt)
					end
				end
			end
			currentPriority += 1
		end
		while currentPriority > 0 do
			currentPriority -= 1
			local buf = listeners[currentPriority]
			if buf then
				for i, listener in buf do
					if listener.disconnected then
						table.remove(buf, i)
						if #buf <= 0 then
							listeners[currentPriority] = nil
						end
					end
				end
			end
		end
		currentPriority = 0
		-- for _, listener in listeners do
		-- 	if not listener.disconnected then
		-- 		listener.callback(dt)
		-- 	end
		-- end
		-- for i = #listeners, 1, -1 do
		-- 	if listeners[i].disconnected then
		-- 		table.remove(listeners, i)
		-- 	end
		-- end
	end
	Runtime._running = false
end

function Runtime:Wait()
	local thread = coroutine.running()
	local conn
	conn = self:Connect(function(dt)
		conn:Disconnect()
		coroutine.resume(thread, dt)
	end)
	return coroutine.yield()
end

function Runtime:Connect(callback: (number) -> ())
	--print(callback)
	local listener: Listener = {
		callback = callback,
		disconnected = false,
	}

	--table.insert(Runtime._listeners, listener)
	local buf = Runtime._listeners[self.priority]
	if not buf then
		buf = {}
		Runtime._listeners[self.priority] = buf
	end
	table.insert(buf, listener)
	task.spawn(Runtime._loop)

	return {
		Connected = true,
		Disconnect = function(self)
			self.Connected = false
			listener.disconnected = true
		end,
	}
end

function Runtime.new(priority: number)
	return setmetatable({ priority = priority }, Runtime)
end

return Runtime
