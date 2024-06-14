local RunService = game:GetService("RunService")

RunService:BindToRenderStep("sans", Enum.RenderPriority.Camera.Value, function(dt)
	print(dt)
end)

task.wait(5)

RunService:UnbindFromRenderStep("sans")
