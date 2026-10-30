-- Copy this file to make a new event. It needs a Name, a Start, and a Stop.
local LavaRain = {}
LavaRain.Name = "Lava Rain"

local running = false
local drops = {}

function LavaRain.Start()
	running = true
	task.spawn(function()
		while running do
			local drop = Instance.new("Part")
			drop.Size = Vector3.new(4, 4, 4)
			drop.Position = Vector3.new(math.random(-60, 60), 80, math.random(-60, 60))
			drop.Material = Enum.Material.Neon
			drop.BrickColor = BrickColor.new("Really red")
			drop.Touched:Connect(function(hit)
				local humanoid = hit.Parent:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.Health = 0
				end
			end)
			drop.Parent = workspace
			table.insert(drops, drop)
			task.wait(0.2)
		end
	end)
end

-- Clean up everything Start made
function LavaRain.Stop()
	running = false
	for _, drop in drops do
		drop:Destroy()
	end
	table.clear(drops)
end

return LavaRain
