local part = Instance.new("Part")
part.Size = Vector3.new(10, 1, 10)
part.Position = Vector3.new(0, 0.5, 20)
part.Anchored = true
part.BrickColor = BrickColor.new("Really red")
part.Parent = workspace

part.Touched:Connect(function(hit)
	local humanoid = hit.Parent:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end)
