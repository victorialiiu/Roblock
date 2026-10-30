local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Format = require(ReplicatedStorage.Shared.Format)
local confetti = require(ReplicatedStorage.Shared.Confetti)

local player = Players.LocalPlayer
local inventory = player:WaitForChild("Inventory")
local tradeRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Trade")

local CREAM = Color3.fromRGB(255, 248, 240)
local BLUE = Color3.fromRGB(90, 170, 255)
local PINK = Color3.fromRGB(255, 120, 200)
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
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = button
	return button
end

local function makePanel(titleText, maxSize)
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.9, 0.8)
	panel.BackgroundColor3 = CREAM
	panel.Visible = false
	addCorner(panel, UDim.new(0, 24))
	addStroke(panel, BLUE, 4)
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = maxSize
	sizeLimit.Parent = panel

	local title = makeText(titleText, BLUE)
	title.Position = UDim2.new(0, 20, 0, 12)
	title.Size = UDim2.new(1, -90, 0, 34)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel
	return panel, title
end

local function makeGrid(parent, position, size, cellWidth)
	local grid = Instance.new("ScrollingFrame")
	grid.Position = position
	grid.Size = size
	grid.BackgroundColor3 = WHITE
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 5
	grid.CanvasSize = UDim2.new()
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	addCorner(grid, UDim.new(0, 12))
	grid.Parent = parent

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(cellWidth, 30)
	layout.CellPadding = UDim2.fromOffset(4, 4)
	layout.Parent = grid

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.Parent = grid
	return grid
end

local gui = Instance.new("ScreenGui")
gui.Name = "Trade"
gui.ResetOnSpawn = false

-- Little message at the top of the screen
local notice = makeText("", WHITE)
notice.AnchorPoint = Vector2.new(0.5, 0)
notice.Position = UDim2.new(0.5, 0, 0, 120)
notice.Size = UDim2.fromOffset(420, 36)
notice.BackgroundColor3 = BLUE
notice.BackgroundTransparency = 0
notice.Visible = false
addCorner(notice)
notice.Parent = gui

local noticeCount = 0
local function notify(text)
	noticeCount += 1
	local thisNotice = noticeCount
	notice.Text = text
	notice.Visible = true
	task.delay(3, function()
		if noticeCount == thisNotice then
			notice.Visible = false
		end
	end)
end

---------------------------------------------------------------- Pick who to trade with

local tradeButton = makeButton("🤝 Trade", BLUE)
tradeButton.AnchorPoint = Vector2.new(1, 1)
tradeButton.Position = UDim2.new(1, -16, 1, -184)
tradeButton.Size = UDim2.fromOffset(170, 46)
addStroke(tradeButton, WHITE, 3)
tradeButton.Parent = gui

local pickPanel = makePanel("🤝 Trade with...", Vector2.new(400, 420))
pickPanel.Parent = gui

local pickClose = makeButton("X", BLUE)
pickClose.AnchorPoint = Vector2.new(1, 0)
pickClose.Position = UDim2.new(1, -12, 0, 12)
pickClose.Size = UDim2.fromOffset(40, 40)
pickClose.Parent = pickPanel
pickClose.Activated:Connect(function()
	pickPanel.Visible = false
end)

local playerList = Instance.new("ScrollingFrame")
playerList.Position = UDim2.new(0, 16, 0, 60)
playerList.Size = UDim2.new(1, -32, 1, -76)
playerList.BackgroundTransparency = 1
playerList.BorderSizePixel = 0
playerList.CanvasSize = UDim2.new()
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.Parent = pickPanel

local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 6)
playerLayout.Parent = playerList

local function showPlayers()
	for _, child in playerList:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local others = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			others += 1
			local button = makeButton("Trade with " .. other.DisplayName, BLUE)
			button.Size = UDim2.new(1, -8, 0, 44)
			button.Parent = playerList
			button.Activated:Connect(function()
				tradeRemote:FireServer("request", other)
				pickPanel.Visible = false
				notify("Trade request sent to " .. other.DisplayName .. "!")
			end)
		end
	end
	if others == 0 then
		local empty = makeText("Nobody else is here yet!", DARK)
		empty.Size = UDim2.new(1, 0, 0, 30)
		empty.Parent = playerList
	end
end

tradeButton.Activated:Connect(function()
	pickPanel.Visible = not pickPanel.Visible
	if pickPanel.Visible then
		showPlayers()
	end
end)

---------------------------------------------------------------- Incoming request

local incoming = Instance.new("Frame")
incoming.AnchorPoint = Vector2.new(0.5, 0)
incoming.Position = UDim2.new(0.5, 0, 0, 165)
incoming.Size = UDim2.fromOffset(360, 110)
incoming.BackgroundColor3 = CREAM
incoming.Visible = false
addCorner(incoming, UDim.new(0, 18))
addStroke(incoming, BLUE, 3)
incoming.Parent = gui

local incomingText = makeText("", DARK)
incomingText.Position = UDim2.fromOffset(12, 10)
incomingText.Size = UDim2.new(1, -24, 0, 34)
incomingText.Parent = incoming

local acceptButton = makeButton("Yes!", GREEN)
acceptButton.Position = UDim2.new(0, 16, 1, -54)
acceptButton.Size = UDim2.new(0.5, -24, 0, 42)
acceptButton.Parent = incoming

local declineButton = makeButton("No thanks", GRAY)
declineButton.Position = UDim2.new(0.5, 8, 1, -54)
declineButton.Size = UDim2.new(0.5, -24, 0, 42)
declineButton.Parent = incoming

local requestFrom = nil
acceptButton.Activated:Connect(function()
	incoming.Visible = false
	tradeRemote:FireServer("respond", requestFrom, true)
end)
declineButton.Activated:Connect(function()
	incoming.Visible = false
	tradeRemote:FireServer("respond", requestFrom, false)
end)

---------------------------------------------------------------- Trade window

local window, windowTitle = makePanel("Trading", Vector2.new(640, 500))
window.Parent = gui

local function column(text, x)
	local label = makeText(text, DARK)
	label.Position = UDim2.new(x, 16, 0, 52)
	label.Size = UDim2.new(0.5, -24, 0, 22)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = window

	local worth = makeText("", Color3.fromRGB(60, 170, 90))
	worth.AnchorPoint = Vector2.new(1, 0)
	worth.Position = UDim2.new(x + 0.5, -8, 0, 52)
	worth.Size = UDim2.new(0.25, 0, 0, 22)
	worth.TextXAlignment = Enum.TextXAlignment.Right
	worth.Parent = window

	local grid = makeGrid(window, UDim2.new(x, 16, 0, 78), UDim2.new(0.5, -24, 0.38, -40), 132)
	return grid, worth
end

local myGrid, myWorth = column("You give", 0)
local theirGrid, theirWorth = column("You get", 0.5)

local yoursLabel = makeText("Your squishies (tap to add)", DARK)
yoursLabel.Position = UDim2.new(0, 16, 0.38, 46)
yoursLabel.Size = UDim2.new(1, -32, 0, 20)
yoursLabel.TextXAlignment = Enum.TextXAlignment.Left
yoursLabel.Parent = window

local inventoryGrid = makeGrid(window, UDim2.new(0, 16, 0.38, 70), UDim2.new(1, -32, 0.62, -150), 140)

local statusLabel = makeText("", DARK)
statusLabel.Position = UDim2.new(0, 16, 1, -72)
statusLabel.Size = UDim2.new(1, -32, 0, 20)
statusLabel.Parent = window

local readyButton = makeButton("Ready", GREEN)
readyButton.Position = UDim2.new(0, 16, 1, -48)
readyButton.Size = UDim2.new(0.5, -24, 0, 40)
readyButton.Parent = window

local cancelButton = makeButton("Cancel", GRAY)
cancelButton.Position = UDim2.new(0.5, 8, 1, -48)
cancelButton.Size = UDim2.new(0.5, -24, 0, 40)
cancelButton.Parent = window

local state = nil

local function worthOf(offer)
	local total = 0
	for itemName, amount in offer do
		local squishy, mutationName = SquishyTypes.parseItem(itemName)
		if squishy then
			total += SquishyTypes.valueOf(squishy, mutationName) * amount
		end
	end
	return total
end

local function addChip(grid, itemName, amount, onClick)
	local squishy, mutationName = SquishyTypes.parseItem(itemName)
	if not squishy then
		return
	end
	local mutation = SquishyTypes.Mutations[mutationName]
	local color = if mutation then mutation.Color else SquishyTypes.Rarities[squishy.Rarity].Color

	local chip = makeButton(squishy.Icon .. " " .. itemName .. " x" .. amount, color)
	chip.AutoButtonColor = onClick ~= nil
	chip.Parent = grid
	if onClick then
		chip.Activated:Connect(onClick)
	end
end

local function clear(grid)
	for _, child in grid:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
end

local function render()
	if not state then
		return
	end
	windowTitle.Text = "🤝 Trading with " .. state.Partner.DisplayName

	clear(myGrid)
	for itemName, amount in state.Mine do
		addChip(myGrid, itemName, amount, function()
			tradeRemote:FireServer("offer", itemName, amount - 1)
		end)
	end
	clear(theirGrid)
	for itemName, amount in state.Theirs do
		addChip(theirGrid, itemName, amount, nil)
	end
	clear(inventoryGrid)
	for _, count in inventory:GetChildren() do
		local left = count.Value - (state.Mine[count.Name] or 0)
		if left > 0 then
			addChip(inventoryGrid, count.Name, left, function()
				tradeRemote:FireServer("offer", count.Name, (state.Mine[count.Name] or 0) + 1)
			end)
		end
	end

	-- Showing what each side is worth helps nobody get tricked
	myWorth.Text = "Worth " .. Format.money(worthOf(state.Mine))
	theirWorth.Text = "Worth " .. Format.money(worthOf(state.Theirs))

	readyButton.Text = if state.MyReady then "Ready ✅ (tap to undo)" else "Ready"
	readyButton.BackgroundColor3 = if state.MyReady then Color3.fromRGB(60, 160, 90) else GREEN
	if state.Countdown then
		statusLabel.Text = "Both ready! Trading in " .. state.Countdown .. "..."
	elseif state.TheirReady then
		statusLabel.Text = state.Partner.DisplayName .. " is ready! ✅"
	else
		statusLabel.Text = "Tap squishies to add them. Both press Ready to trade."
	end
end

readyButton.Activated:Connect(function()
	if state then
		tradeRemote:FireServer("ready", not state.MyReady)
	end
end)
cancelButton.Activated:Connect(function()
	tradeRemote:FireServer("cancel")
end)

tradeRemote.OnClientEvent:Connect(function(action, data)
	if action == "incoming" then
		requestFrom = data
		incomingText.Text = data.DisplayName .. " wants to trade! 🤝"
		incoming.Visible = true
		local scale = incoming:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", incoming)
		scale.Scale = 0.6
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		task.delay(20, function()
			if requestFrom == data then
				incoming.Visible = false
			end
		end)
	elseif action == "state" then
		local opening = state == nil
		state = data
		window.Visible = true
		pickPanel.Visible = false
		render()
		if opening then
			local scale = window:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", window)
			scale.Scale = 0.8
			TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	elseif action == "closed" then
		state = nil
		window.Visible = false
		notify(data)
		if string.find(data, "complete") then
			confetti(gui, 80)
		end
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
