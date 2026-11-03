-- Getting between the lobby island and the squishy hunting map.
-- Walk into a portal, or use the travel button on screen (it fires the Travel remote)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lobby = require(ReplicatedStorage.Shared.Lobby)
local World = require(ReplicatedStorage.Shared.World)

local COOLDOWN = 2
local FONT = Enum.Font.FredokaOne

-- Where you land
local DESTINATIONS = {
	World = CFrame.new(World.CENTER + Vector3.new(0, 4, 10)),
	Lobby = CFrame.new(Lobby.CENTER + Vector3.new(0, 4, -50)),
}

local travelRemote = Instance.new("RemoteEvent")
travelRemote.Name = "Travel"
travelRemote.Parent = ReplicatedStorage:WaitForChild("Remotes")

local folder = Instance.new("Folder")
folder.Name = "Portals"
folder.Parent = workspace

local lastTravel = {}

local function travel(player, destination)
	local cframe = DESTINATIONS[destination]
	local character = player.Character
	if not cframe or not character or os.clock() - (lastTravel[player] or 0) < COOLDOWN then
		return
	end
	lastTravel[player] = os.clock()
	character:PivotTo(cframe)
end

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
	part.Parent = folder
	return part
end

-- A glowing ring you walk through. The front faces lookAt
local function makePortal(position, lookAt, destination, text, color)
	local base = CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z))
	-- Round pad on the ground (cylinders lie on their side, so turn it flat)
	makePart(Vector3.new(1, 14, 14), base * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.new(1, 1, 1), Enum.PartType.Cylinder)

	-- Ring made of glowing blocks
	for i = 1, 16 do
		local angle = i / 16 * math.pi * 2
		local block = makePart(Vector3.new(1.6, 1.6, 1.2), base * CFrame.new(math.cos(angle) * 6, 7 + math.sin(angle) * 6, 0), color)
		block.Material = Enum.Material.Neon
	end

	-- The swirly middle you touch
	local door = makePart(Vector3.new(0.4, 11, 11), base * CFrame.new(0, 7, 0) * CFrame.Angles(0, math.pi / 2, 0), color, Enum.PartType.Cylinder)
	door.Material = Enum.Material.ForceField
	door.Transparency = 0.2
	door.CanCollide = false
	door.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			travel(player, destination)
		end
	end)

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(240, 50)
	sign.StudsOffset = Vector3.new(0, 8, 0)
	sign.MaxDistance = 150
	sign.Parent = door
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = color:Lerp(Color3.new(0, 0, 0), 0.4)
	label.TextStrokeTransparency = 0
	label.Text = text
	label.Parent = sign
end

-- Lobby portal: out past the booths, before the bases
makePortal(Lobby.CENTER + Vector3.new(0, 0, -62), Lobby.CENTER, "World", "🌧️ Go Squishy Hunting!", Color3.fromRGB(110, 210, 255))

-- The safe spawn pad in the middle of the hunting map, with a portal home
local flat = CFrame.Angles(0, 0, math.pi / 2)
makePart(Vector3.new(1, World.SPAWN_RADIUS * 2 + 4, World.SPAWN_RADIUS * 2 + 4), CFrame.new(World.CENTER + Vector3.new(0, 0.3, 0)) * flat, Color3.new(1, 1, 1), Enum.PartType.Cylinder)
makePart(Vector3.new(1.2, World.SPAWN_RADIUS * 2, World.SPAWN_RADIUS * 2), CFrame.new(World.CENTER + Vector3.new(0, 0.4, 0)) * flat, Color3.fromRGB(200, 235, 255), Enum.PartType.Cylinder)
makePortal(World.CENTER + Vector3.new(0, 1, -14), World.CENTER, "Lobby", "🏠 Back to the Lobby", Color3.fromRGB(255, 130, 210))

travelRemote.OnServerEvent:Connect(function(player, destination)
	if destination == "World" or destination == "Lobby" then
		travel(player, destination)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastTravel[player] = nil
end)
