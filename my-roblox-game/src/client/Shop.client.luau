local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shop = require(ReplicatedStorage.Shared.Shop)
local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Format = require(ReplicatedStorage.Shared.Format)
local confetti = require(ReplicatedStorage.Shared.Confetti)

local player = Players.LocalPlayer
local money = player:WaitForChild("leaderstats"):WaitForChild("Money")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local CREAM = Color3.fromRGB(255, 248, 240)
local PINK = Color3.fromRGB(255, 120, 200)
local ORANGE = Color3.fromRGB(255, 160, 60)
local GOLD = Color3.fromRGB(255, 200, 40)
local PURPLE = Color3.fromRGB(170, 110, 255)
local GREEN = Color3.fromRGB(90, 200, 120)
local GRAY = Color3.fromRGB(180, 175, 180)
local DARK = Color3.fromRGB(80, 50, 70)
local WHITE = Color3.new(1, 1, 1)
local FONT = Enum.Font.FredokaOne

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

local function makeButton(text, color)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = color
	button.Font = FONT
	button.TextScaled = true
	button.TextColor3 = WHITE
	button.Text = text
	addCorner(button)
	addStroke(button, WHITE, 3)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = button
	return button
end

local function pop(target, from)
	local scale = target:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", target)
	scale.Scale = from or 1.2
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function shake(target)
	local start = target.Position
	for _, dx in { -8, 8, -6, 6, 0 } do
		target.Position = start + UDim2.fromOffset(dx, 0)
		task.wait(0.04)
	end
	target.Position = start
end

local function makePanel(titleText, color)
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.9, 0.75)
	panel.BackgroundColor3 = CREAM
	panel.Visible = false
	addCorner(panel, UDim.new(0, 24))
	addStroke(panel, color, 4)
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(560, 480)
	sizeLimit.Parent = panel

	local title = makeText(titleText, color)
	title.Position = UDim2.new(0, 20, 0, 12)
	title.Size = UDim2.new(1, -90, 0, 36)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local close = makeButton("X", color)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 12)
	close.Size = UDim2.fromOffset(40, 40)
	close.Parent = panel
	close.Activated:Connect(function()
		panel.Visible = false
	end)

	return panel
end

local gui = Instance.new("ScreenGui")
gui.Name = "Shop"
gui.ResetOnSpawn = false

local shopPanel = makePanel("🛒 Upgrade Shop", ORANGE)
shopPanel.Parent = gui
local spinPanel = makePanel("🎁 Lucky Spin", PINK)
spinPanel.Parent = gui
local rollPanel = makePanel("🎲 Squishy Roll", PURPLE)
rollPanel.Parent = gui

local panels = { Shop = shopPanel, Spin = spinPanel, Roll = rollPanel }

local function open(panel)
	local wasOpen = panel.Visible
	for _, other in panels do
		other.Visible = false
	end
	if not wasOpen then
		panel.Visible = true
		pop(panel, 0.8)
	end
end

-- Buttons in the bottom right
local shopButton = makeButton("🛒 Shop", ORANGE)
shopButton.AnchorPoint = Vector2.new(1, 1)
shopButton.Position = UDim2.new(1, -16, 1, -16)
shopButton.Size = UDim2.fromOffset(170, 46)
shopButton.Parent = gui
shopButton.Activated:Connect(function()
	open(shopPanel)
end)

local spinButton = makeButton("🎁 Lucky Spin", PINK)
spinButton.AnchorPoint = Vector2.new(1, 1)
spinButton.Position = UDim2.new(1, -16, 1, -72)
spinButton.Size = UDim2.fromOffset(170, 46)
spinButton.Parent = gui
spinButton.Activated:Connect(function()
	open(spinPanel)
end)

local rollButton = makeButton("🎲 Roll", PURPLE)
rollButton.AnchorPoint = Vector2.new(1, 1)
rollButton.Position = UDim2.new(1, -16, 1, -128)
rollButton.Size = UDim2.fromOffset(170, 46)
rollButton.Parent = gui
rollButton.Activated:Connect(function()
	open(rollPanel)
end)

-- Lobby booths open these screens
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local panel = panels[prompt:GetAttribute("Opens")]
	if panel and not panel.Visible then
		open(panel)
	end
end)

-- Little "!" on the shop button when you can afford something
local badge = makeText("!", WHITE)
badge.AnchorPoint = Vector2.new(0.5, 0.5)
badge.Position = UDim2.fromScale(0, 0)
badge.Size = UDim2.fromOffset(26, 26)
badge.BackgroundTransparency = 0
badge.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
badge.Visible = false
addCorner(badge)
badge.Parent = shopButton

---------------------------------------------------------------- Upgrade shop

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 16, 0, 60)
list.Size = UDim2.new(1, -32, 1, -76)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = shopPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list

local rows = {}

local function updateShop()
	local canAfford = false
	for _, row in rows do
		local level = Shop.getLevel(player, row.Upgrade.Id)
		local maxed = level >= row.Upgrade.MaxLevel
		local cost = Shop.upgradeCost(row.Upgrade, level)
		local affordable = not maxed and money.Value >= cost
		canAfford = canAfford or affordable

		row.Level.Text = "Level " .. level .. " / " .. row.Upgrade.MaxLevel
		row.Fill.Size = UDim2.fromScale(level / row.Upgrade.MaxLevel, 1)
		row.Buy.Text = if maxed then "MAX" else Format.money(cost)
		row.Buy.BackgroundColor3 = if affordable then GREEN else GRAY
	end
	badge.Visible = canAfford
end

for i, upgrade in Shop.Upgrades do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 92)
	row.BackgroundColor3 = WHITE
	row.LayoutOrder = i
	addCorner(row, UDim.new(0, 16))
	addStroke(row, ORANGE, 2)
	row.Parent = list

	local icon = makeText(upgrade.Icon, WHITE)
	icon.Position = UDim2.fromOffset(10, 14)
	icon.Size = UDim2.fromOffset(60, 60)
	icon.Parent = row

	local name = makeText(upgrade.Name, DARK)
	name.Position = UDim2.fromOffset(80, 8)
	name.Size = UDim2.new(1, -210, 0, 26)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = row

	local description = makeText(upgrade.Description, GRAY)
	description.Position = UDim2.fromOffset(80, 36)
	description.Size = UDim2.new(1, -210, 0, 18)
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.Parent = row

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(80, 62)
	bar.Size = UDim2.new(1, -210, 0, 14)
	bar.BackgroundColor3 = Color3.fromRGB(240, 230, 230)
	addCorner(bar)
	bar.Parent = row

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = ORANGE
	addCorner(fill)
	fill.Parent = bar

	local level = makeText("", DARK)
	level.AnchorPoint = Vector2.new(1, 0)
	level.Position = UDim2.new(1, -12, 0, 8)
	level.Size = UDim2.fromOffset(110, 20)
	level.Parent = row

	local buy = makeButton("", GREEN)
	buy.AnchorPoint = Vector2.new(1, 1)
	buy.Position = UDim2.new(1, -12, 1, -10)
	buy.Size = UDim2.fromOffset(110, 46)
	buy.Parent = row

	buy.Activated:Connect(function()
		if remotes.BuyUpgrade:InvokeServer(upgrade.Id) then
			pop(row, 1.08)
			confetti(gui, 20)
		else
			shake(buy)
		end
	end)

	table.insert(rows, { Upgrade = upgrade, Level = level, Fill = fill, Buy = buy })
end

money.Changed:Connect(updateShop)
player.AttributeChanged:Connect(updateShop)
updateShop()

---------------------------------------------------------------- Lucky Spin

local reel = Instance.new("Frame")
reel.AnchorPoint = Vector2.new(0.5, 0)
reel.Position = UDim2.new(0.5, 0, 0, 60)
reel.Size = UDim2.fromOffset(220, 150)
reel.BackgroundColor3 = WHITE
addCorner(reel, UDim.new(0, 20))
addStroke(reel, GOLD, 5)
reel.Parent = spinPanel

local reelIcon = makeText("❓", WHITE)
reelIcon.Position = UDim2.fromOffset(0, 10)
reelIcon.Size = UDim2.new(1, 0, 0, 90)
reelIcon.Parent = reel

local reelName = makeText("Spin to win a boost!", DARK)
reelName.Position = UDim2.new(0, 10, 0, 104)
reelName.Size = UDim2.new(1, -20, 0, 32)
reelName.Parent = reel

local spinNow = makeButton("SPIN  " .. Format.money(Shop.SPIN_COST), GOLD)
spinNow.AnchorPoint = Vector2.new(0.5, 0)
spinNow.Position = UDim2.new(0.5, 0, 0, 222)
spinNow.Size = UDim2.fromOffset(220, 56)
spinNow.Parent = spinPanel

local message = makeText("", Color3.fromRGB(230, 60, 80))
message.AnchorPoint = Vector2.new(0.5, 0)
message.Position = UDim2.new(0.5, 0, 0, 282)
message.Size = UDim2.new(0.8, 0, 0, 20)
message.Parent = spinPanel

-- Every prize and its chance, so everyone knows the odds
local odds = Instance.new("Frame")
odds.Position = UDim2.new(0, 16, 0, 310)
odds.Size = UDim2.new(1, -32, 1, -322)
odds.BackgroundTransparency = 1
odds.Parent = spinPanel

local oddsLayout = Instance.new("UIGridLayout")
oddsLayout.CellSize = UDim2.new(0.5, -4, 0, 24)
oddsLayout.CellPadding = UDim2.fromOffset(8, 4)
oddsLayout.Parent = odds

local totalWeight = 0
for _, prize in Shop.Prizes do
	totalWeight += prize.Weight
end
for _, prize in Shop.Prizes do
	local chance = math.floor(prize.Weight / totalWeight * 1000 + 0.5) / 10
	local label = makeText(prize.Icon .. " " .. prize.Name .. "  " .. chance .. "%", DARK)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = odds
end

local busy = false
spinNow.Activated:Connect(function()
	if busy then
		return
	end
	busy = true
	message.Text = ""

	local prizeId = remotes.Spin:InvokeServer()
	if not prizeId then
		message.Text = "Not enough money! Catch more squishies 🌧️"
		shake(spinNow)
		busy = false
		return
	end

	-- Flick through prizes, slowing down, then land on the real one
	local started = os.clock()
	local delay = 0.04
	while os.clock() - started < Shop.SPIN_TIME - 0.3 do
		local prize = Shop.Prizes[math.random(#Shop.Prizes)]
		reelIcon.Text = prize.Icon
		reelName.Text = prize.Name
		pop(reel, 1.05)
		task.wait(delay)
		delay *= 1.12
	end
	task.wait(math.max(0, Shop.SPIN_TIME - (os.clock() - started)))

	local prize = Shop.PrizesById[prizeId]
	reelIcon.Text = prize.Icon
	reelName.Text = prize.Name .. "!"
	pop(reel, 1.4)
	if prize.Weight <= 15 then
		confetti(gui, if prize.Weight <= 2 then 120 else 50)
	end
	busy = false
end)

---------------------------------------------------------------- Squishy Roll

local rollReel = Instance.new("Frame")
rollReel.AnchorPoint = Vector2.new(0.5, 0)
rollReel.Position = UDim2.new(0.5, 0, 0, 60)
rollReel.Size = UDim2.fromOffset(220, 150)
rollReel.BackgroundColor3 = WHITE
addCorner(rollReel, UDim.new(0, 20))
addStroke(rollReel, PURPLE, 5)
rollReel.Parent = rollPanel

local rollIcon = makeText("🎲", WHITE)
rollIcon.Position = UDim2.fromOffset(0, 10)
rollIcon.Size = UDim2.new(1, 0, 0, 90)
rollIcon.Parent = rollReel

local rollName = makeText("Roll for a squishy!", DARK)
rollName.Position = UDim2.new(0, 10, 0, 104)
rollName.Size = UDim2.new(1, -20, 0, 32)
rollName.Parent = rollReel

local rollNow = makeButton("ROLL  " .. Format.money(Shop.ROLL_COST), PURPLE)
rollNow.AnchorPoint = Vector2.new(0.5, 0)
rollNow.Position = UDim2.new(0.5, 0, 0, 222)
rollNow.Size = UDim2.fromOffset(220, 56)
rollNow.Parent = rollPanel

local rollMessage = makeText("", Color3.fromRGB(230, 60, 80))
rollMessage.AnchorPoint = Vector2.new(0.5, 0)
rollMessage.Position = UDim2.new(0.5, 0, 0, 282)
rollMessage.Size = UDim2.new(0.8, 0, 0, 20)
rollMessage.Parent = rollPanel

-- Chance of each rarity (before your luck upgrades)
local rollOdds = Instance.new("Frame")
rollOdds.Position = UDim2.new(0, 16, 0, 310)
rollOdds.Size = UDim2.new(1, -32, 1, -322)
rollOdds.BackgroundTransparency = 1
rollOdds.Parent = rollPanel

local rollOddsLayout = Instance.new("UIGridLayout")
rollOddsLayout.CellSize = UDim2.new(0.5, -4, 0, 24)
rollOddsLayout.CellPadding = UDim2.fromOffset(8, 4)
rollOddsLayout.SortOrder = Enum.SortOrder.LayoutOrder
rollOddsLayout.Parent = rollOdds

local rarityTotal = 0
for _, rarity in SquishyTypes.Rarities do
	rarityTotal += rarity.Weight
end
for name, rarity in SquishyTypes.Rarities do
	if rarity.Weight > 0 then
		local label = makeText(name .. "  " .. math.floor(rarity.Weight / rarityTotal * 1000 + 0.5) / 10 .. "%", rarity.Color)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = rarity.Order
		label.Parent = rollOdds
	end
end

local rollable = {}
for _, squishy in SquishyTypes.List do
	if squishy.Value then
		table.insert(rollable, squishy)
	end
end

local rolling = false
rollNow.Activated:Connect(function()
	if rolling then
		return
	end
	rolling = true
	rollMessage.Text = ""

	local squishyName, mutationName = remotes.Roll:InvokeServer()
	if not squishyName then
		rollMessage.Text = "Not enough money! Sell some squishies 💰"
		shake(rollNow)
		rolling = false
		return
	end

	local started = os.clock()
	local delay = 0.04
	while os.clock() - started < Shop.SPIN_TIME - 0.3 do
		local squishy = rollable[math.random(#rollable)]
		rollIcon.Text = squishy.Icon
		rollName.Text = squishy.Name
		rollName.TextColor3 = DARK
		pop(rollReel, 1.05)
		task.wait(delay)
		delay *= 1.12
	end
	task.wait(math.max(0, Shop.SPIN_TIME - (os.clock() - started)))

	local squishy = SquishyTypes.ByName[squishyName]
	local rarity = SquishyTypes.Rarities[squishy.Rarity]
	local mutation = SquishyTypes.Mutations[mutationName]
	rollIcon.Text = squishy.Icon
	rollName.Text = SquishyTypes.itemName(squishyName, mutationName) .. "!"
	rollName.TextColor3 = if mutation then mutation.Color else rarity.Color
	pop(rollReel, 1.4)
	if rarity.Order >= 3 or mutation then
		confetti(gui, if rarity.Order >= 5 then 120 else 50)
	end
	rolling = false
end)

gui.Parent = player:WaitForChild("PlayerGui")
