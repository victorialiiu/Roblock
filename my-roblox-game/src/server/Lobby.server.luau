local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lobby = require(ReplicatedStorage.Shared.Lobby)

local BOOTH_DISTANCE = 24
local FONT = Enum.Font.FredokaOne

-- Opens is which screen the booth's prompt opens on the player's screen
local BOOTHS = {
	{ Name = "Upgrade Shop", Icon = "🛒", Opens = "Shop", Color = Color3.fromRGB(255, 160, 60), Angle = 45 },
	{ Name = "Lucky Spin", Icon = "🎁", Opens = "Spin", Color = Color3.fromRGB(255, 120, 200), Angle = 135 },
	{ Name = "Squishy Roll", Icon = "🎲", Opens = "Roll", Color = Color3.fromRGB(170, 110, 255), Angle = 225 },
	{ Name = "Sell Squishies", Icon = "💰", Opens = "Inventory", Color = Color3.fromRGB(90, 200, 120), Angle = 315 },
	{ Name = "Rebirth", Icon = "🌟", Opens = "Rebirth", Color = Color3.fromRGB(255, 200, 40), Angle = 0 },
	{ Name = "Passes", Icon = "⭐", Opens = "Passes", Color = Color3.fromRGB(90, 170, 255), Angle = 180 },
}

local model = Instance.new("Model")
model.Name = "Lobby"
model.Parent = workspace

local function makePart(size, cframe, color, shape)
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.Parent = model
	return part
end

-- Round pink floor with a white rim
local flat = CFrame.Angles(0, 0, math.pi / 2)

-- The floating island the whole lobby (and everyone's base) sits on, with a fluffy cloud underneath
local island = makePart(Vector3.new(6, Lobby.ISLAND_RADIUS * 2, Lobby.ISLAND_RADIUS * 2), CFrame.new(Lobby.CENTER + Vector3.new(0, -2.7, 0)) * flat, Color3.fromRGB(170, 235, 150), Enum.PartType.Cylinder)
island.Name = "Island"
local rim = makePart(Vector3.new(5.6, Lobby.ISLAND_RADIUS * 2 + 4, Lobby.ISLAND_RADIUS * 2 + 4), CFrame.new(Lobby.CENTER + Vector3.new(0, -3, 0)) * flat, Color3.new(1, 1, 1), Enum.PartType.Cylinder)
rim.Name = "IslandRim"
for i = 1, 10 do
	local angle = i / 10 * math.pi * 2
	local size = 40 + (i % 3) * 15
	local puff = makePart(Vector3.new(size, size * 0.5, size), CFrame.new(Lobby.CENTER + Vector3.new(math.sin(angle) * 90, -18 - (i % 2) * 6, math.cos(angle) * 90)), Color3.fromRGB(255, 245, 252), Enum.PartType.Ball)
	puff.CanCollide = false
	puff.Material = Enum.Material.SmoothPlastic
end
makePart(Vector3.new(0.8, Lobby.RADIUS * 2 + 4, Lobby.RADIUS * 2 + 4), CFrame.new(Lobby.CENTER + Vector3.new(0, 0.4, 0)) * flat, Color3.new(1, 1, 1), Enum.PartType.Cylinder)
makePart(Vector3.new(1, Lobby.RADIUS * 2, Lobby.RADIUS * 2), CFrame.new(Lobby.CENTER + Vector3.new(0, 0.5, 0)) * flat, Color3.fromRGB(255, 205, 230), Enum.PartType.Cylinder)

local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Lobby.CENTER + Vector3.new(0, 1.5, 0)
spawn.Color = Color3.new(1, 1, 1)
spawn.Material = Enum.Material.SmoothPlastic
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = model

local function addSign(part, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
end

for _, booth in BOOTHS do
	local angle = math.rad(booth.Angle)
	local position = Lobby.CENTER + Vector3.new(math.sin(angle), 0, math.cos(angle)) * BOOTH_DISTANCE
	-- The booth's front (-Z) faces the middle of the lobby
	local base = CFrame.lookAt(position, Lobby.CENTER)

	local counter = makePart(Vector3.new(10, 3, 3), base * CFrame.new(0, 2.5, 0), booth.Color)
	makePart(Vector3.new(0.8, 8, 0.8), base * CFrame.new(-4.6, 5, 1.2), Color3.new(1, 1, 1))
	makePart(Vector3.new(0.8, 8, 0.8), base * CFrame.new(4.6, 5, 1.2), Color3.new(1, 1, 1))
	makePart(Vector3.new(11, 0.8, 5), base * CFrame.new(0, 9.4, 0.5), booth.Color)

	local sign = makePart(Vector3.new(9, 2.5, 0.4), base * CFrame.new(0, 7.5, 1.3), Color3.new(1, 1, 1))
	addSign(sign, booth.Icon .. " " .. booth.Name, booth.Color)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = booth.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Opens", booth.Opens)
	prompt.Parent = counter
end

-- Big floating title over the lobby
local titleAnchor = makePart(Vector3.one, CFrame.new(Lobby.CENTER + Vector3.new(0, 22, 0)), Color3.new(1, 1, 1))
titleAnchor.Transparency = 1
titleAnchor.CanCollide = false

local title = Instance.new("BillboardGui")
title.Size = UDim2.fromScale(40, 12)
title.Parent = titleAnchor

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.fromScale(1, 0.65)
titleText.BackgroundTransparency = 1
titleText.Font = FONT
titleText.TextScaled = true
titleText.TextColor3 = Color3.fromRGB(255, 120, 200)
titleText.TextStrokeTransparency = 0
titleText.TextStrokeColor3 = Color3.new(1, 1, 1)
titleText.Text = "SQUISHY RAIN"
titleText.Parent = title

local subtitle = titleText:Clone()
subtitle.Position = UDim2.fromScale(0, 0.65)
subtitle.Size = UDim2.fromScale(1, 0.35)
subtitle.TextColor3 = Color3.new(1, 1, 1)
subtitle.TextStrokeColor3 = Color3.fromRGB(120, 0, 80)
subtitle.Text = "Catch • Equip • Sell • Trade • Rebirth!"
subtitle.Parent = title
