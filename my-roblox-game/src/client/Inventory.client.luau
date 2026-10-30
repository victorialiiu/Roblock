local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Format = require(ReplicatedStorage.Shared.Format)
local Shop = require(ReplicatedStorage.Shared.Shop)
local confetti = require(ReplicatedStorage.Shared.Confetti)

local player = Players.LocalPlayer
local inventory = player:WaitForChild("Inventory")

local CREAM = Color3.fromRGB(255, 248, 240)
local PINK = Color3.fromRGB(255, 120, 200)
local LAVENDER = Color3.fromRGB(180, 150, 255)
local DARK = Color3.fromRGB(80, 50, 70)
local GREEN = Color3.fromRGB(60, 170, 90)
local WHITE = Color3.new(1, 1, 1)
local FONT = Enum.Font.FredokaOne

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 230, 120)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 255, 160)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(130, 190, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 140, 255)),
})

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(1, 0)
	corner.Parent = parent
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
end

local function makeText(text, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	return label
end

local function makePill(parent, text, color)
	local pill = Instance.new("Frame")
	pill.Size = UDim2.new(0.48, 0, 1, 0)
	pill.BackgroundColor3 = color
	addCorner(pill)
	pill.Parent = parent

	local label = makeText(text, WHITE)
	label.Size = UDim2.new(1, -8, 1, -2)
	label.Position = UDim2.new(0, 4, 0, 1)
	local stroke = Instance.new("UIStroke")
	stroke.Color = DARK
	stroke.Thickness = 1
	stroke.Parent = label
	label.Parent = pill
end

local gui = Instance.new("ScreenGui")
gui.Name = "Inventory"
gui.ResetOnSpawn = false

local openButton = Instance.new("TextButton")
openButton.AnchorPoint = Vector2.new(0, 1)
openButton.Position = UDim2.new(0, 16, 1, -96)
openButton.Size = UDim2.new(0, 170, 0, 46)
openButton.BackgroundColor3 = LAVENDER
openButton.Font = FONT
openButton.TextScaled = true
openButton.TextColor3 = WHITE
openButton.Text = "🎒 Inventory"
addCorner(openButton)
addStroke(openButton, WHITE, 3)
local buttonPadding = Instance.new("UIPadding")
buttonPadding.PaddingTop = UDim.new(0, 8)
buttonPadding.PaddingBottom = UDim.new(0, 8)
buttonPadding.Parent = openButton
openButton.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.9, 0.75)
panel.BackgroundColor3 = CREAM
panel.Visible = false
addCorner(panel, UDim.new(0, 24))
addStroke(panel, PINK, 4)
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(680, 480)
sizeLimit.Parent = panel
panel.Parent = gui

local title = makeText("My Squishies", PINK)
title.Position = UDim2.new(0, 20, 0, 12)
title.Size = UDim2.new(1, -90, 0, 36)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local summary = makeText("", DARK)
summary.Position = UDim2.new(0, 20, 0, 50)
summary.Size = UDim2.new(1, -40, 0, 20)
summary.TextXAlignment = Enum.TextXAlignment.Left
summary.Parent = panel

local boostsLabel = makeText("", LAVENDER)
boostsLabel.Position = UDim2.new(0, 20, 0, 72)
boostsLabel.Size = UDim2.new(1, -40, 0, 18)
boostsLabel.TextXAlignment = Enum.TextXAlignment.Left
boostsLabel.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.Size = UDim2.fromOffset(40, 40)
closeButton.BackgroundColor3 = PINK
closeButton.Font = FONT
closeButton.TextScaled = true
closeButton.TextColor3 = WHITE
closeButton.Text = "X"
addCorner(closeButton)
closeButton.Parent = panel

local grid = Instance.new("ScrollingFrame")
grid.Position = UDim2.new(0, 16, 0, 100)
grid.Size = UDim2.new(1, -32, 1, -116)
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.ScrollBarThickness = 6
grid.ScrollBarImageColor3 = PINK
grid.CanvasSize = UDim2.new()
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.Parent = panel

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(130, 168)
layout.CellPadding = UDim2.fromOffset(10, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = grid

local emptyLabel = makeText("No squishies yet! Go catch some falling ones 🌧️", DARK)
emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
emptyLabel.Position = UDim2.fromScale(0.5, 0.55)
emptyLabel.Size = UDim2.new(0.8, 0, 0, 30)
emptyLabel.Parent = panel

local function refresh()
	emptyLabel.Visible = #inventory:GetChildren() == 0
	local caught = 0
	for _, count in inventory:GetChildren() do
		caught += count.Value
	end
	summary.Text = "You've caught " .. caught .. " squishies!"

	local boosts = {}
	for name, amount in SquishyTypes.getPassives(inventory) do
		if amount > 0 then
			table.insert(boosts, SquishyTypes.formatBoost(name, amount))
		end
	end
	boostsLabel.Text = if #boosts > 0 then "Boosts: " .. table.concat(boosts, "   ") else "Boosts: none yet"
end

-- Floating "+1 Golden Butter  +$20" text when you catch one
local function toast(count, value, color, big)
	local label = makeText("+1 " .. count.Name .. "   +" .. Format.money(value * Shop.moneyMultiplier(player)), color)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.72)
	label.Size = UDim2.new(0.5, 0, 0, if big then 44 else 30)
	local stroke = Instance.new("UIStroke")
	stroke.Color = DARK
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = gui

	TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {
		Position = UDim2.fromScale(0.5, 0.62),
		TextTransparency = 1,
	}):Play()
	task.delay(1.2, function()
		label:Destroy()
	end)
end

local function addCard(count, isNew)
	local squishy = SquishyTypes.ByName[count:GetAttribute("Squishy")]
	if not squishy then
		return
	end
	local mutationName = count:GetAttribute("Mutation")
	local mutation = SquishyTypes.Mutations[mutationName]
	local rarity = SquishyTypes.Rarities[squishy.Rarity]
	local highlight = if mutation then mutation.Color else rarity.Color
	local value = SquishyTypes.valueOf(squishy, mutationName)
	local big = rarity.Order >= 3 or mutation ~= nil
	local celebrate = rarity.Order >= 4 or (mutation ~= nil and mutation.Multiplier >= 10)

	local card = Instance.new("Frame")
	card.BackgroundColor3 = WHITE
	card.LayoutOrder = -value
	addCorner(card, UDim.new(0, 16))
	addStroke(card, highlight, 3)

	local icon = Instance.new("Frame")
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 10)
	icon.Size = UDim2.fromOffset(64, 64)
	icon.BackgroundColor3 = SquishyTypes.colorFor(squishy, mutationName)
	addCorner(icon)
	addStroke(icon, WHITE, 2)
	if mutation and mutation.Rainbow then
		icon.BackgroundColor3 = WHITE
		local gradient = Instance.new("UIGradient")
		gradient.Color = RAINBOW
		gradient.Parent = icon
	end
	icon.Parent = card

	local emoji = makeText(squishy.Icon, WHITE)
	emoji.Size = UDim2.fromScale(0.75, 0.75)
	emoji.Position = UDim2.fromScale(0.125, 0.125)
	emoji.Parent = icon

	local name = makeText(count.Name, DARK)
	name.Position = UDim2.new(0, 6, 0, 78)
	name.Size = UDim2.new(1, -12, 0, 20)
	name.Parent = card

	local tags = Instance.new("Frame")
	tags.Position = UDim2.new(0, 6, 0, 100)
	tags.Size = UDim2.new(1, -12, 0, 18)
	tags.BackgroundTransparency = 1
	local tagLayout = Instance.new("UIListLayout")
	tagLayout.FillDirection = Enum.FillDirection.Horizontal
	tagLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tagLayout.Padding = UDim.new(0, 4)
	tagLayout.Parent = tags
	makePill(tags, squishy.Rarity, rarity.Color)
	if mutation then
		makePill(tags, mutationName .. " x" .. mutation.Multiplier, mutation.Color)
	end
	tags.Parent = card

	local moneyLabel = makeText("Worth " .. Format.money(value), GREEN)
	moneyLabel.Position = UDim2.new(0, 6, 0, 121)
	moneyLabel.Size = UDim2.new(1, -12, 0, 18)
	moneyLabel.Parent = card

	local passiveLabel = makeText(SquishyTypes.formatBoost(squishy.Passive, squishy.Boost) .. " each", LAVENDER)
	passiveLabel.Position = UDim2.new(0, 6, 0, 141)
	passiveLabel.Size = UDim2.new(1, -12, 0, 18)
	passiveLabel.Parent = card

	local countPill = makeText("", WHITE)
	countPill.AnchorPoint = Vector2.new(1, 0)
	countPill.Position = UDim2.new(1, -6, 0, 6)
	countPill.Size = UDim2.fromOffset(40, 22)
	countPill.BackgroundTransparency = 0
	countPill.BackgroundColor3 = PINK
	addCorner(countPill)
	countPill.Parent = card

	local last = count.Value
	countPill.Text = "x" .. last
	local function caught()
		toast(count, value, highlight, big)
		if celebrate then
			confetti(gui)
		end
	end

	count.Changed:Connect(function(newCount)
		if newCount > last then
			caught()
		end
		last = newCount
		countPill.Text = "x" .. newCount
		refresh()
	end)

	card.Parent = grid
	if isNew then
		caught()
	end
	refresh()
end

for _, count in inventory:GetChildren() do
	addCard(count, false)
end
inventory.ChildAdded:Connect(function(count)
	addCard(count, true)
end)
refresh()

local function setOpen(open)
	panel.Visible = open
	if open then
		refresh()
		local scale = panel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", panel)
		scale.Scale = 0.8
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end

openButton.Activated:Connect(function()
	setOpen(not panel.Visible)
end)
closeButton.Activated:Connect(function()
	setOpen(false)
end)

gui.Parent = player:WaitForChild("PlayerGui")
