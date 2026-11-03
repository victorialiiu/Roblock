local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Passes = require(ReplicatedStorage.Shared.Passes)
local UI = require(ReplicatedStorage.Shared.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Instance.new("ScreenGui")
gui.Name = "Passes"
gui.ResetOnSpawn = false

local panel = UI.panel("⭐ Passes", UI.BLUE, Vector2.new(520, 470))
panel.Parent = gui

local openButton = UI.menuButton(gui, "⭐ Passes", UI.BLUE, "left", 2)
openButton.Activated:Connect(function()
	UI.toggle(panel)
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt:GetAttribute("Opens") == "Passes" and not panel.Visible then
		UI.toggle(panel)
	end
end)

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 16, 0, 60)
list.Size = UDim2.new(1, -32, 1, -76)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function makeRow(item, order, buttonText, onBuy)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 86)
	row.BackgroundColor3 = UI.WHITE
	row.LayoutOrder = order
	UI.corner(row, UDim.new(0, 16))
	UI.stroke(row, UI.BLUE, 2)
	row.Parent = list

	local icon = UI.text(item.Icon, UI.WHITE)
	icon.Position = UDim2.fromOffset(10, 13)
	icon.Size = UDim2.fromOffset(60, 60)
	icon.Parent = row

	local name = UI.text(item.Name, UI.DARK)
	name.Position = UDim2.fromOffset(80, 8)
	name.Size = UDim2.new(1, -210, 0, 26)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = row

	local description = UI.text(item.Description, UI.GRAY)
	description.Position = UDim2.fromOffset(80, 36)
	description.Size = UDim2.new(1, -210, 0, 40)
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.TextWrapped = true
	description.Parent = row

	local buy = UI.button(buttonText, UI.GREEN)
	buy.AnchorPoint = Vector2.new(1, 0.5)
	buy.Position = UDim2.new(1, -12, 0.5, 0)
	buy.Size = UDim2.fromOffset(110, 46)
	buy.Parent = row
	buy.Activated:Connect(onBuy)
	return buy
end

local passButtons = {}
for i, pass in Passes.List do
	passButtons[pass.Id] = makeRow(pass, i, "Get", function()
		remotes.BuyPass:FireServer(pass.Id)
	end)
end

makeRow(Passes.LuckyBox, #Passes.List + 1, "Open!", function()
	remotes.BuyBox:FireServer()
end)

local function update()
	for passId, button in passButtons do
		local owned = Passes.owns(player, passId)
		button.Text = if owned then "Owned ✅" else "Get"
		button.BackgroundColor3 = if owned then UI.GRAY else UI.GREEN
		button.AutoButtonColor = not owned
	end
end

player.AttributeChanged:Connect(update)
update()

gui.Parent = player:WaitForChild("PlayerGui")
