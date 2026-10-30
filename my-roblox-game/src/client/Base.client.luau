local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)

local player = Players.LocalPlayer
local inventory = player:WaitForChild("Inventory")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local bases = workspace:WaitForChild("Bases")

local CREAM = Color3.fromRGB(255, 248, 240)
local MINT = Color3.fromRGB(80, 200, 170)
local GRAY = Color3.fromRGB(180, 175, 180)
local DARK = Color3.fromRGB(80, 50, 70)
local WHITE = Color3.new(1, 1, 1)
local FONT = Enum.Font.FredokaOne

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(1, 0)
	corner.Parent = parent
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
	padding.PaddingTop = UDim.new(0, 7)
	padding.PaddingBottom = UDim.new(0, 7)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = button
	return button
end

local gui = Instance.new("ScreenGui")
gui.Name = "Base"
gui.ResetOnSpawn = false

local homeButton = makeButton("🏠 My Base", MINT)
homeButton.AnchorPoint = Vector2.new(0, 1)
homeButton.Position = UDim2.new(0, 16, 1, -152)
homeButton.Size = UDim2.fromOffset(170, 46)
local stroke = Instance.new("UIStroke")
stroke.Color = WHITE
stroke.Thickness = 3
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = homeButton
homeButton.Parent = gui
homeButton.Activated:Connect(function()
	remotes.GoToBase:FireServer()
end)

-- Only show the "Show off a squishy" prompts on your own base
local function updatePrompts(base)
	local mine = base:GetAttribute("Owner") == player.UserId
	for _, prompt in base:GetDescendants() do
		if prompt:IsA("ProximityPrompt") then
			prompt.Enabled = mine
		end
	end
end

local function watchBase(base)
	updatePrompts(base)
	base:GetAttributeChangedSignal("Owner"):Connect(function()
		updatePrompts(base)
	end)
	base.DescendantAdded:Connect(function(child)
		if child:IsA("ProximityPrompt") then
			updatePrompts(base)
		end
	end)
end
for _, base in bases:GetChildren() do
	watchBase(base)
end
bases.ChildAdded:Connect(watchBase)

---------------------------------------------------------------- Pick a squishy for a pedestal

local picker = Instance.new("Frame")
picker.AnchorPoint = Vector2.new(0.5, 0.5)
picker.Position = UDim2.fromScale(0.5, 0.5)
picker.Size = UDim2.fromScale(0.9, 0.7)
picker.BackgroundColor3 = CREAM
picker.Visible = false
addCorner(picker, UDim.new(0, 24))
local pickerStroke = Instance.new("UIStroke")
pickerStroke.Color = MINT
pickerStroke.Thickness = 4
pickerStroke.Parent = picker
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(460, 440)
sizeLimit.Parent = picker
picker.Parent = gui

local pickerTitle = makeText("Show off which squishy?", MINT)
pickerTitle.Position = UDim2.new(0, 20, 0, 12)
pickerTitle.Size = UDim2.new(1, -90, 0, 34)
pickerTitle.TextXAlignment = Enum.TextXAlignment.Left
pickerTitle.Parent = picker

local closeButton = makeButton("X", MINT)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.Size = UDim2.fromOffset(40, 40)
closeButton.Parent = picker
closeButton.Activated:Connect(function()
	picker.Visible = false
end)

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 16, 0, 60)
list.Size = UDim2.new(1, -32, 1, -76)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = picker

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list

local function choose(slot, itemName)
	remotes.Showcase:InvokeServer(slot, itemName)
	picker.Visible = false
end

local function openPicker(slot)
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local clearButton = makeButton("Empty this pedestal", GRAY)
	clearButton.Size = UDim2.new(1, -8, 0, 40)
	clearButton.LayoutOrder = -math.huge
	clearButton.Parent = list
	clearButton.Activated:Connect(function()
		choose(slot, nil)
	end)

	for _, count in inventory:GetChildren() do
		local squishy, mutationName = SquishyTypes.parseItem(count.Name)
		if squishy then
			local mutation = SquishyTypes.Mutations[mutationName]
			local color = if mutation then mutation.Color else SquishyTypes.Rarities[squishy.Rarity].Color
			local value = SquishyTypes.valueOf(squishy, mutationName)
			local button = makeButton(squishy.Icon .. " " .. count.Name .. "  (x" .. count.Value .. ")", color)
			button.Size = UDim2.new(1, -8, 0, 40)
			button.LayoutOrder = -value
			button.Parent = list
			button.Activated:Connect(function()
				choose(slot, count.Name)
			end)
		end
	end

	picker.Visible = true
	local scale = picker:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", picker)
	scale.Scale = 0.8
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local slot = prompt:GetAttribute("Slot")
	if slot and prompt:IsDescendantOf(bases) then
		openPicker(slot)
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
