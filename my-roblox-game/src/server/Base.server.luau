local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Format = require(ReplicatedStorage.Shared.Format)
local InventoryService = require(script.Parent.InventoryService)
local buildSquishy = require(script.Parent.MakeSquishy).build

local PLOT_COUNT = 8
local PLOT_DISTANCE = 110
local PLOT_SIZE = 36
local SLOTS = 8
local FONT = Enum.Font.FredokaOne

local PLOT_COLORS = {
	Color3.fromRGB(255, 205, 230),
	Color3.fromRGB(205, 230, 255),
	Color3.fromRGB(215, 255, 215),
	Color3.fromRGB(255, 240, 190),
	Color3.fromRGB(230, 210, 255),
	Color3.fromRGB(255, 215, 190),
	Color3.fromRGB(200, 250, 240),
	Color3.fromRGB(255, 220, 250),
}

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local showcaseRemote = Instance.new("RemoteFunction")
showcaseRemote.Name = "Showcase"
showcaseRemote.Parent = remotes

local goToBaseRemote = Instance.new("RemoteEvent")
goToBaseRemote.Name = "GoToBase"
goToBaseRemote.Parent = remotes

local folder = Instance.new("Folder")
folder.Name = "Bases"
folder.Parent = workspace

local plots = {}

local function makePart(parent, size, cframe, color, shape)
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

local function makeSign(part)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = part

	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromScale(1, 0.6)
	name.BackgroundTransparency = 1
	name.Font = FONT
	name.TextScaled = true
	name.TextColor3 = Color3.fromRGB(255, 120, 200)
	name.Parent = gui

	local worth = name:Clone()
	worth.Position = UDim2.fromScale(0, 0.6)
	worth.Size = UDim2.fromScale(1, 0.4)
	worth.TextColor3 = Color3.fromRGB(60, 170, 90)
	worth.Parent = gui

	return name, worth
end

for i = 1, PLOT_COUNT do
	local angle = (i - 0.5) * math.pi * 2 / PLOT_COUNT
	local center = Vector3.new(math.sin(angle), 0, math.cos(angle)) * PLOT_DISTANCE
	-- The front of the base (-Z) faces the lobby
	local base = CFrame.lookAt(center, Vector3.zero)

	local model = Instance.new("Model")
	model.Name = "Base" .. i
	model:SetAttribute("Owner", 0)
	model.Parent = folder

	makePart(model, Vector3.new(PLOT_SIZE + 2, 0.8, PLOT_SIZE + 2), base * CFrame.new(0, 0.4, 0), Color3.new(1, 1, 1))
	makePart(model, Vector3.new(PLOT_SIZE, 1, PLOT_SIZE), base * CFrame.new(0, 0.5, 0), PLOT_COLORS[i])

	local front = -PLOT_SIZE / 2 + 2
	makePart(model, Vector3.new(0.6, 7, 0.6), base * CFrame.new(-7, 4, front), Color3.new(1, 1, 1))
	makePart(model, Vector3.new(0.6, 7, 0.6), base * CFrame.new(7, 4, front), Color3.new(1, 1, 1))
	local sign = makePart(model, Vector3.new(15, 4, 0.5), base * CFrame.new(0, 6, front), Color3.new(1, 1, 1))
	local nameLabel, worthLabel = makeSign(sign)

	local plot = {
		Model = model,
		Owner = nil,
		Home = base * CFrame.new(0, 4, front + 5),
		NameLabel = nameLabel,
		WorthLabel = worthLabel,
		Pedestals = {},
		Slots = {},
		Displays = {},
	}

	for slot = 1, SLOTS do
		local x = ((slot - 1) % 4 - 1.5) * 8
		local z = if slot <= 4 then 2 else 11
		local pedestal = makePart(
			model,
			Vector3.new(2, 4, 4),
			base * CFrame.new(x, 2, z) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.new(1, 1, 1),
			Enum.PartType.Cylinder
		)
		pedestal.Name = "Pedestal" .. slot

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Show off a squishy"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Slot", slot)
		prompt.Parent = pedestal

		plot.Pedestals[slot] = base * CFrame.new(x, 3, z)
	end

	plot.NameLabel.Text = "Empty Base"
	plot.WorthLabel.Text = ""
	plots[i] = plot
end

local function plotOf(player)
	for _, plot in plots do
		if plot.Owner == player then
			return plot
		end
	end
	return nil
end

local function updateSign(plot)
	if not plot.Owner then
		plot.NameLabel.Text = "Empty Base"
		plot.WorthLabel.Text = ""
		return
	end

	local worth = 0
	for _, itemName in plot.Slots do
		local squishy, mutationName = SquishyTypes.parseItem(itemName)
		if squishy then
			worth += SquishyTypes.valueOf(squishy, mutationName)
		end
	end
	plot.NameLabel.Text = plot.Owner.DisplayName .. "'s Base"
	plot.WorthLabel.Text = "Showcase worth " .. Format.money(worth)
end

local function showSlot(plot, slot)
	if plot.Displays[slot] then
		plot.Displays[slot]:Destroy()
		plot.Displays[slot] = nil
	end

	local itemName = plot.Slots[slot]
	local squishy, mutationName = SquishyTypes.parseItem(itemName or "")
	if not squishy then
		return
	end

	local size = SquishyTypes.Rarities[squishy.Rarity].Size
	local body = buildSquishy(squishy, mutationName, size, CFrame.identity)
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false

	-- Model:PivotTo moves the body and every piece welded to it
	local display = Instance.new("Model")
	display.Name = itemName
	body.Parent = display
	display.PrimaryPart = body
	display:PivotTo(plot.Pedestals[slot] * CFrame.new(0, body.Size.Y / 2, 0))
	display.Parent = plot.Model
	plot.Displays[slot] = display
end

-- Take squishies off display if the owner sold or traded them away
local function checkSlots(plot)
	local used = {}
	for slot = 1, SLOTS do
		local itemName = plot.Slots[slot]
		if itemName then
			used[itemName] = (used[itemName] or 0) + 1
			if used[itemName] > InventoryService.count(plot.Owner, itemName) then
				plot.Slots[slot] = nil
				showSlot(plot, slot)
			end
		end
	end
	updateSign(plot)
end

local function claim(player)
	for _, plot in plots do
		if not plot.Owner then
			plot.Owner = player
			plot.Model:SetAttribute("Owner", player.UserId)
			updateSign(plot)

			local inventory = player:WaitForChild("Inventory")
			local function watch(count)
				count.Changed:Connect(function()
					if plot.Owner == player then
						checkSlots(plot)
					end
				end)
			end
			inventory.ChildAdded:Connect(watch)
			for _, count in inventory:GetChildren() do
				watch(count)
			end
			inventory.ChildRemoved:Connect(function()
				if plot.Owner == player then
					checkSlots(plot)
				end
			end)
			return
		end
	end
end

Players.PlayerAdded:Connect(claim)
for _, player in Players:GetPlayers() do
	task.spawn(claim, player)
end

Players.PlayerRemoving:Connect(function(player)
	local plot = plotOf(player)
	if not plot then
		return
	end
	plot.Owner = nil
	plot.Model:SetAttribute("Owner", 0)
	for slot = 1, SLOTS do
		plot.Slots[slot] = nil
		showSlot(plot, slot)
	end
	updateSign(plot)
end)

-- itemName = nil takes the squishy off the pedestal
showcaseRemote.OnServerInvoke = function(player, slot, itemName)
	local plot = plotOf(player)
	if not plot or typeof(slot) ~= "number" or not plot.Pedestals[slot] then
		return false
	end
	if itemName ~= nil then
		if typeof(itemName) ~= "string" then
			return false
		end
		local alreadyShown = 0
		for otherSlot, shown in plot.Slots do
			if shown == itemName and otherSlot ~= slot then
				alreadyShown += 1
			end
		end
		if InventoryService.count(player, itemName) <= alreadyShown then
			return false
		end
	end

	plot.Slots[slot] = itemName
	showSlot(plot, slot)
	updateSign(plot)
	return true
end

goToBaseRemote.OnServerEvent:Connect(function(player)
	local plot = plotOf(player)
	if plot and player.Character then
		player.Character:PivotTo(plot.Home)
	end
end)
