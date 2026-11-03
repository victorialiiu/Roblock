-- Cute panel on the left: active buffs as bubbly slots, and your current stats
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shop = require(ReplicatedStorage.Shared.Shop)

local player = Players.LocalPlayer

local PINK = Color3.fromRGB(255, 120, 200)
local SOFT_PINK = Color3.fromRGB(255, 180, 220)
local PLUM = Color3.fromRGB(110, 60, 100)
local WHITE = Color3.new(1, 1, 1)
local FONT = Enum.Font.FredokaOne
local SLOT_SIZE = 50

local BUFF_COLORS = {
	Speed = Color3.fromRGB(255, 215, 90),
	Money = Color3.fromRGB(120, 220, 140),
	Luck = Color3.fromRGB(110, 220, 190),
	Jump = Color3.fromRGB(120, 190, 255),
	Mutation = Color3.fromRGB(255, 140, 210),
	Jackpot = Color3.fromRGB(185, 140, 255),
}

local STATS = {
	{ Id = "Speed", Name = "Speed", Icon = "👟", Color = Color3.fromRGB(150, 230, 200) },
	{ Id = "Jump", Name = "Jump", Icon = "🦘", Color = Color3.fromRGB(170, 215, 255) },
	{ Id = "Health", Name = "Health", Icon = "💖", Color = Color3.fromRGB(255, 185, 210) },
	{ Id = "Money", Name = "Money", Icon = "💰", Color = Color3.fromRGB(255, 215, 175) },
	{ Id = "Luck", Name = "Luck", Icon = "🍀", Color = Color3.fromRGB(185, 240, 170) },
	{ Id = "Mutate", Name = "Mutate", Icon = "✨", Color = Color3.fromRGB(215, 190, 255) },
}

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

local function addGradient(parent, top, bottom)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(top, bottom)
	gradient.Rotation = 90
	gradient.Parent = parent
end

local function makeText(parent, text, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = parent
	return label
end

local function makeCircle(parent, size, position, color)
	local circle = Instance.new("Frame")
	circle.Size = size
	circle.Position = position
	circle.BackgroundColor3 = color
	addCorner(circle)
	circle.Parent = parent
	return circle
end

local gui = Instance.new("ScreenGui")
gui.Name = "Status"
gui.ResetOnSpawn = false

local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0, 0.5)
holder.Position = UDim2.new(0, 16, 0.42, 0)
holder.Size = UDim2.fromOffset(220, 330)
holder.BackgroundTransparency = 1
holder.Parent = gui

local holderLayout = Instance.new("UIListLayout")
holderLayout.Padding = UDim.new(0, 10)
holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
holderLayout.Parent = holder

---------------------------------------------------------------- Buff slots

local buffRow = Instance.new("Frame")
buffRow.Size = UDim2.new(1, 0, 0, SLOT_SIZE + 22)
buffRow.BackgroundTransparency = 1
buffRow.LayoutOrder = 1
buffRow.Parent = holder

local buffLayout = Instance.new("UIListLayout")
buffLayout.FillDirection = Enum.FillDirection.Horizontal
buffLayout.Padding = UDim.new(0, 8)
buffLayout.Parent = buffRow

local slots = {}
for _, prize in Shop.Prizes do
	if prize.Duration then
		local color = BUFF_COLORS[prize.Id] or SOFT_PINK

		local slot = Instance.new("Frame")
		slot.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE + 22)
		slot.BackgroundTransparency = 1
		slot.Visible = false
		slot.Parent = buffRow

		local bubble = Instance.new("Frame")
		bubble.AnchorPoint = Vector2.new(0.5, 0.5)
		bubble.Position = UDim2.fromOffset(SLOT_SIZE / 2, SLOT_SIZE / 2)
		bubble.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
		bubble.BackgroundColor3 = WHITE
		bubble.ClipsDescendants = true
		addCorner(bubble, UDim.new(0, 16))
		addStroke(bubble, WHITE, 3)
		addGradient(bubble, color:Lerp(WHITE, 0.45), color)
		bubble.Parent = slot

		local icon = makeText(bubble, prize.Icon, WHITE)
		icon.Position = UDim2.fromOffset(8, 6)
		icon.Size = UDim2.new(1, -16, 1, -16)

		-- Drains as the buff runs out
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Position = UDim2.fromScale(0, 1)
		bar.Size = UDim2.new(1, 0, 0, 5)
		bar.BackgroundColor3 = WHITE
		bar.BorderSizePixel = 0
		bar.Parent = bubble

		local timer = makeText(slot, "", PLUM)
		timer.AnchorPoint = Vector2.new(0.5, 0)
		timer.Position = UDim2.new(0.5, 0, 0, SLOT_SIZE + 4)
		timer.Size = UDim2.fromOffset(SLOT_SIZE, 18)
		timer.BackgroundTransparency = 0
		timer.BackgroundColor3 = WHITE
		addCorner(timer)
		addStroke(timer, color, 2)

		local scale = Instance.new("UIScale")
		scale.Parent = slot

		slots[prize] = { Slot = slot, Bubble = bubble, Bar = bar, Timer = timer, Scale = scale, Longest = 0 }
	end
end

---------------------------------------------------------------- Stats card

local cardHeight = 52 + #STATS * 32

local card = Instance.new("Frame")
card.Size = UDim2.fromOffset(220, cardHeight)
card.BackgroundTransparency = 1
card.LayoutOrder = 2
card.Parent = holder

-- Soft shadow behind the card
local shadow = Instance.new("Frame")
shadow.Position = UDim2.fromOffset(4, 5)
shadow.Size = UDim2.fromScale(1, 1)
shadow.BackgroundColor3 = Color3.fromRGB(200, 120, 180)
shadow.BackgroundTransparency = 0.6
addCorner(shadow, UDim.new(0, 20))
shadow.Parent = card

local face = Instance.new("Frame")
face.Size = UDim2.fromScale(1, 1)
face.BackgroundColor3 = WHITE
addCorner(face, UDim.new(0, 20))
addStroke(face, SOFT_PINK, 3)
addGradient(face, Color3.fromRGB(255, 252, 254), Color3.fromRGB(255, 230, 243))
face.Parent = card

local header = makeText(face, "✨ My Stats ✨", WHITE)
header.AnchorPoint = Vector2.new(0.5, 0)
header.Position = UDim2.new(0.5, 0, 0, 10)
header.Size = UDim2.fromOffset(150, 28)
header.BackgroundTransparency = 0
header.BackgroundColor3 = PINK
addCorner(header)
local headerPadding = Instance.new("UIPadding")
headerPadding.PaddingTop = UDim.new(0, 4)
headerPadding.PaddingBottom = UDim.new(0, 4)
headerPadding.Parent = header
local headerStroke = Instance.new("UIStroke")
headerStroke.Color = Color3.fromRGB(200, 70, 150)
headerStroke.Thickness = 1.5
headerStroke.Parent = header

-- Little hearts in the corners
for _, corner in { { 12, 12 }, { 190, 12 } } do
	local heart = makeText(face, "♡", SOFT_PINK)
	heart.Position = UDim2.fromOffset(corner[1], corner[2])
	heart.Size = UDim2.fromOffset(20, 20)
end

local statLabels = {}
for i, stat in STATS do
	local row = Instance.new("Frame")
	row.Position = UDim2.fromOffset(10, 46 + (i - 1) * 32)
	row.Size = UDim2.new(1, -20, 0, 27)
	row.BackgroundColor3 = stat.Color:Lerp(WHITE, 0.55)
	addCorner(row)
	addStroke(row, stat.Color, 1.5)
	row.Parent = face

	local iconBubble = makeCircle(row, UDim2.fromOffset(23, 23), UDim2.fromOffset(2, 2), WHITE)
	local icon = makeText(iconBubble, stat.Icon, WHITE)
	icon.Position = UDim2.fromOffset(3, 3)
	icon.Size = UDim2.new(1, -6, 1, -6)

	local name = makeText(row, stat.Name, PLUM)
	name.Position = UDim2.fromOffset(32, 5)
	name.Size = UDim2.new(0.5, -32, 1, -10)
	name.TextXAlignment = Enum.TextXAlignment.Left

	local value = makeText(row, "", stat.Color:Lerp(PLUM, 0.6))
	value.Position = UDim2.new(0.5, 0, 0, 4)
	value.Size = UDim2.new(0.5, -10, 1, -8)
	value.TextXAlignment = Enum.TextXAlignment.Right

	statLabels[stat.Id] = value
end

local function round(number, places)
	local factor = 10 ^ (places or 0)
	return math.floor(number * factor + 0.5) / factor
end

local function update()
	local time = os.clock()
	for prize, slot in slots do
		local left = Shop.boostTimeLeft(player, prize.Id)
		local active = left > 0

		if active and not slot.Slot.Visible then
			-- Pop in when a new buff starts
			slot.Scale.Scale = 0.3
			TweenService:Create(slot.Scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			slot.Longest = 0
		end
		slot.Slot.Visible = active

		if active then
			slot.Longest = math.max(slot.Longest, left)
			local seconds = math.ceil(left)
			slot.Timer.Text = string.format("%d:%02d", seconds // 60, seconds % 60)
			slot.Bar.Size = UDim2.new(left / slot.Longest, 0, 0, 5)

			-- Wiggle when it's about to run out
			slot.Bubble.Rotation = if left < 5 then math.sin(time * 18) * 8 else 0
			slot.Timer.TextColor3 = if left < 5 then Color3.fromRGB(230, 60, 100) else PLUM
		end
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		statLabels.Speed.Text = tostring(round(humanoid.WalkSpeed, 1))
		statLabels.Jump.Text = tostring(round(humanoid.JumpHeight, 1))
		statLabels.Health.Text = math.ceil(humanoid.Health) .. "/" .. math.ceil(humanoid.MaxHealth)
	end
	statLabels.Money.Text = "x" .. round(Shop.moneyMultiplier(player), 2)
	statLabels.Luck.Text = "x" .. round(Shop.getLuck(player), 2)
	statLabels.Mutate.Text = round(Shop.getMutationChance(player, true) * 100) .. "%"
end

gui.Parent = player:WaitForChild("PlayerGui")

while true do
	update()
	task.wait(1 / 30)
end
