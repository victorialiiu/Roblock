-- Rain of colorful confetti over the screen. Call from a LocalScript
local TweenService = game:GetService("TweenService")

local COLORS = {
	Color3.fromRGB(255, 120, 200),
	Color3.fromRGB(255, 230, 100),
	Color3.fromRGB(120, 220, 255),
	Color3.fromRGB(150, 255, 150),
	Color3.fromRGB(200, 150, 255),
}

return function(gui, amount)
	for _ = 1, amount or 40 do
		local piece = Instance.new("Frame")
		piece.Size = UDim2.fromOffset(math.random(8, 14), math.random(8, 14))
		piece.Position = UDim2.new(math.random(), 0, -0.05, 0)
		piece.Rotation = math.random(0, 360)
		piece.BackgroundColor3 = COLORS[math.random(#COLORS)]
		piece.BorderSizePixel = 0
		piece.ZIndex = 10
		piece.Parent = gui

		local fallTime = math.random(15, 30) / 10
		TweenService:Create(piece, TweenInfo.new(fallTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(piece.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, 1.05, 0),
			Rotation = piece.Rotation + math.random(-360, 360),
		}):Play()
		task.delay(fallTime, function()
			piece:Destroy()
		end)
	end
end
