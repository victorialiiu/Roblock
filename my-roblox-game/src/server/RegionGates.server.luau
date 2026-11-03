-- Locked regions: a glowing wall around each region with an Unlock requirement (see src/shared/Regions/),
-- gates you can pay at once you have enough rebirths, and a check that bounces anyone who sneaks in.
-- The walls are solid only for players who can't enter yet (RegionGates.client.luau handles that).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Regions = require(ReplicatedStorage.Shared.Regions)
local World = require(ReplicatedStorage.Shared.World)
local Format = require(ReplicatedStorage.Shared.Format)
local notify = require(script.Parent.Notify)

local WALL_HEIGHT = 120
local WALL_SEGMENT = 16
local GATES_PER_RING = 6
local FONT = Enum.Font.FredokaOne

local folder = Instance.new("Folder")
folder.Name = "RegionGates"
folder.Parent = workspace

local function requirementText(region)
	local unlock = region.Unlock
	local parts = {}
	if unlock.Rebirths > 0 then
		table.insert(parts, unlock.Rebirths .. " rebirth" .. (if unlock.Rebirths > 1 then "s" else ""))
	end
	if unlock.Cost > 0 then
		table.insert(parts, Format.money(unlock.Cost))
	end
	return table.concat(parts, " + ")
end

local function buildWall(region)
	local radius = region.Inner
	local count = math.ceil(2 * math.pi * radius / WALL_SEGMENT)
	local width = 2 * math.pi * radius / count + 0.5
	for i = 1, count do
		local angle = i / count * math.pi * 2
		local position = World.CENTER + Vector3.new(math.sin(angle) * radius, WALL_HEIGHT / 2 - 20, math.cos(angle) * radius)
		local wall = Instance.new("Part")
		wall.Name = region.Name .. " Wall"
		wall.Anchored = true
		wall.CanCollide = false
		wall.CanTouch = false
		wall.CastShadow = false
		wall.Size = Vector3.new(width, WALL_HEIGHT, 1)
		wall.CFrame = CFrame.lookAt(position, World.CENTER + Vector3.new(0, position.Y, 0))
		wall.Color = region.Color
		wall.Material = Enum.Material.ForceField
		wall:SetAttribute("Region", region.Name)
		wall.Parent = folder
	end
end

local function groundAt(x, z)
	local result = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -400, 0))
	return if result then result.Position.Y else 0
end

local function buildGate(region, angle)
	local spot = World.CENTER + Vector3.new(math.sin(angle), 0, math.cos(angle)) * (region.Inner - 6)
	local post = Instance.new("Part")
	post.Name = region.Name .. " Gate"
	post.Anchored = true
	post.Size = Vector3.new(4, 6, 4)
	post.Position = Vector3.new(spot.X, groundAt(spot.X, spot.Z) + 3, spot.Z)
	post.Color = region.Color
	post.Material = Enum.Material.SmoothPlastic
	post.Parent = folder

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(240, 60)
	sign.StudsOffset = Vector3.new(0, 6, 0)
	sign.MaxDistance = 120
	sign.Parent = post
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = "🔒 " .. region.Icon .. " " .. region.Name .. "\n" .. requirementText(region)
	label.Parent = sign

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Unlock " .. region.Name
	prompt.ObjectText = requirementText(region)
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("UnlockRegion", region.Name)
	prompt.Parent = post
	prompt.Triggered:Connect(function(player)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats or Regions.canEnter(player, region) then
			return
		end
		if not Regions.hasRebirths(player, region) then
			notify(player, "🔒 You need " .. region.Unlock.Rebirths .. " rebirths to unlock " .. region.Name)
			return
		end
		if leaderstats.Money.Value < region.Unlock.Cost then
			notify(player, "🔒 " .. region.Name .. " costs " .. Format.money(region.Unlock.Cost))
			return
		end
		leaderstats.Money.Value -= region.Unlock.Cost
		local paid = player:GetAttribute("UnlockedRegions") or ""
		player:SetAttribute("UnlockedRegions", (if paid == "" then "" else paid .. ",") .. region.Name)
		notify(player, "🎉 " .. region.Icon .. " " .. region.Name .. " unlocked! x" .. region.Luck .. " luck in there")
	end)
end

-- The first locked region this far out, if there is one
local function lockedRegionAt(player, distance)
	for _, region in Regions.List do
		if distance < region.Inner then
			return nil
		end
		if not Regions.canEnter(player, region) then
			return region
		end
	end
	return nil
end

for _, region in Regions.List do
	if region.Unlock then
		buildWall(region)
	end
end

-- Gates sit on the ground, so wait for the terrain
while not workspace:GetAttribute("TerrainReady") do
	task.wait(1)
end
for _, region in Regions.List do
	if region.Unlock then
		for i = 1, GATES_PER_RING do
			buildGate(region, (i - 0.5) / GATES_PER_RING * math.pi * 2)
		end
	end
end

-- Bounce back anyone who got past a wall they shouldn't have (lag, glitches, exploits)
while true do
	task.wait(0.5)
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and World.contains(root.Position) then
			local offset = (root.Position - World.CENTER) * Vector3.new(1, 0, 1)
			local region = lockedRegionAt(player, offset.Magnitude)
			if region and offset.Magnitude > 0 then
				local back = World.CENTER + offset.Unit * (region.Inner - 10)
				player.Character:PivotTo(CFrame.new(back.X, groundAt(back.X, back.Z) + 4, back.Z))
				notify(player, "🔒 " .. region.Name .. " is locked! Unlock it at a gate: " .. requirementText(region))
			end
		end
	end
end
