local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage.Shared.Shop)
local Format = require(ReplicatedStorage.Shared.Format)
local UI = require(ReplicatedStorage.Shared.UI)
local confetti = require(ReplicatedStorage.Shared.Confetti)

local player = Players.LocalPlayer
local money = player:WaitForChild("leaderstats"):WaitForChild("Money")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Instance.new("ScreenGui")
gui.Name = "Rebirth"
gui.ResetOnSpawn = false

local panel = UI.panel("🌟 Rebirth", UI.GOLD, Vector2.new(460, 420))
panel.Parent = gui

local openButton = UI.menuButton(gui, "🌟 Rebirth", UI.GOLD, "right", 4)
openButton.Activated:Connect(function()
	UI.toggle(panel)
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt:GetAttribute("Opens") == "Rebirth" and not panel.Visible then
		UI.toggle(panel)
	end
end)

local info = UI.text("", UI.DARK)
info.Position = UDim2.new(0, 20, 0, 58)
info.Size = UDim2.new(1, -40, 0, 22)
info.Parent = panel

-- Now -> after rebirth, for each thing you get
local rows = Instance.new("Frame")
rows.Position = UDim2.new(0, 20, 0, 90)
rows.Size = UDim2.new(1, -40, 0, 180)
rows.BackgroundTransparency = 1
rows.Parent = panel
local rowLayout = Instance.new("UIListLayout")
rowLayout.Padding = UDim.new(0, 8)
rowLayout.Parent = rows

local function makeRow()
	local label = UI.text("", UI.DARK)
	label.Size = UDim2.new(1, 0, 0, 36)
	label.BackgroundTransparency = 0
	label.BackgroundColor3 = UI.WHITE
	UI.corner(label)
	UI.stroke(label, UI.GOLD, 2)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 7)
	padding.PaddingBottom = UDim.new(0, 7)
	padding.Parent = label
	label.Parent = rows
	return label
end

local moneyRow = makeRow()
local plotRow = makeRow()
local equipRow = makeRow()
local bagRow = makeRow()

local warning = UI.text("You lose your money and upgrades. You keep every squishy!", UI.GRAY)
warning.Position = UDim2.new(0, 20, 1, -124)
warning.Size = UDim2.new(1, -40, 0, 18)
warning.Parent = panel

local rebirthButton = UI.button("", UI.GOLD)
rebirthButton.AnchorPoint = Vector2.new(0.5, 1)
rebirthButton.Position = UDim2.new(0.5, 0, 1, -20)
rebirthButton.Size = UDim2.fromOffset(260, 56)
UI.stroke(rebirthButton, UI.WHITE, 3)
rebirthButton.Parent = panel

local function arrow(label, now, after)
	return label .. ":  " .. now .. "  →  " .. after
end

local function update()
	local rebirths = Shop.getRebirths(player)
	local cost = Shop.rebirthCost(rebirths)
	local nextMoney = 1 + Shop.REBIRTH_MONEY * (rebirths + 1)
	local nextPlots = math.min(Shop.BASE_PLOTS + Shop.PLOTS_PER_REBIRTH * (rebirths + 1), Shop.MAX_PLOTS)
	local nextEquips = math.min(Shop.BASE_EQUIPS + Shop.EQUIPS_PER_REBIRTH * (rebirths + 1), Shop.MAX_EQUIPS)

	info.Text = "Rebirths: " .. rebirths
	moneyRow.Text = arrow("💰 Money", "x" .. 1 + Shop.REBIRTH_MONEY * rebirths, "x" .. nextMoney)
	plotRow.Text = arrow("🏠 Pedestals", Shop.plotCount(player), nextPlots)
	equipRow.Text = arrow("⚡ Equip slots", Shop.equipSlots(player), nextEquips)
	bagRow.Text = arrow("🎒 Bag", Shop.bagSize(player), Shop.bagSize(player) + Shop.BAG_PER_REBIRTH)

	rebirthButton.Text = "REBIRTH  " .. Format.money(cost)
	rebirthButton.BackgroundColor3 = if money.Value >= cost then UI.GOLD else UI.GRAY
end

-- Two taps so nobody rebirths by accident
local confirming = false
rebirthButton.Activated:Connect(function()
	if not confirming then
		confirming = true
		rebirthButton.Text = "Tap again to rebirth!"
		task.delay(3, function()
			confirming = false
			update()
		end)
		return
	end
	confirming = false
	if remotes:WaitForChild("Rebirth"):InvokeServer() then
		confetti(gui, 150)
		UI.pop(panel, 1.1)
	end
	update()
end)

money.Changed:Connect(update)
player.AttributeChanged:Connect(update)
update()

gui.Parent = player:WaitForChild("PlayerGui")
