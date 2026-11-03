-- Region walls are solid for you until you unlock that region, then they fade away.
-- Your character's physics runs on your computer, so making the wall solid here is what blocks you
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Regions = require(ReplicatedStorage.Shared.Regions)

local player = Players.LocalPlayer
local folder = workspace:WaitForChild("RegionGates")

local function updateWall(wall)
	local region = Regions.ByName[wall:GetAttribute("Region") or ""]
	if not region then
		return
	end
	local open = Regions.canEnter(player, region)
	wall.CanCollide = not open
	wall.Transparency = if open then 0.85 else 0.1
end

local function updateAll()
	for _, child in folder:GetChildren() do
		updateWall(child)
	end
end

folder.ChildAdded:Connect(updateWall)
player:GetAttributeChangedSignal("UnlockedRegions"):Connect(updateAll)
player:GetAttributeChangedSignal("Rebirths"):Connect(updateAll)
updateAll()
