local RunService = game:GetService("RunService")

RunService.Heartbeat:Connect(function(dt)
	print(dt)
end)
