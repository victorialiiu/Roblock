-- The Squishy Pass window: XP bar, then a scrolling row of tiers with a free and a premium reward each
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SquishyPass = require(ReplicatedStorage.Shared.SquishyPass)
local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Format = require(ReplicatedStorage.Shared.Format)
local Leaderboards = require(ReplicatedStorage.Shared.Leaderboards)
local UI = require(ReplicatedStorage.Shared.UI)
local confetti = require(ReplicatedStorage.Shared.Confetti)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local PREMIUM = Color3.fromRGB(255, 180, 40)
local COLUMN_WIDTH = 112

local gui = Instance.new("ScreenGui")
gui.Name = "SquishyPass"
gui.ResetOnSpawn = false

local panel = UI.panel("🎟️ Squishy Pass", UI.PINK, Vector2.new(760, 470))
panel.Parent = gui

local openButton = UI.menuButton(gui, "🎟️ Squishy Pass", UI.PINK, "right", 5)
openButton.Activated:Connect(function()
	UI.toggle(panel)
end)

-- Little "!" when there's something to claim
local badge = UI.text("!", UI.WHITE)
badge.AnchorPoint = Vector2.new(0.5, 0.5)
badge.Size = UDim2.fromOffset(26, 26)
badge.BackgroundTransparency = 0
badge.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
badge.Visible = false
UI.corner(badge)
badge.Parent = openButton

local seasonLabel = UI.text("", UI.DARK)
seasonLabel.Position = UDim2.new(0, 20, 0, 52)
seasonLabel.Size = UDim2.new(0.6, -20, 0, 20)
seasonLabel.TextXAlignment = Enum.TextXAlignment.Left
seasonLabel.Parent = panel

local premiumButton = UI.button("", PREMIUM)
premiumButton.AnchorPoint = Vector2.new(1, 0)
premiumButton.Position = UDim2.new(1, -62, 0, 14)
premiumButton.Size = UDim2.fromOffset(200, 38)
UI.stroke(premiumButton, UI.WHITE, 3)
premiumButton.Parent = panel
premiumButton.Activated:Connect(function()
	remotes.BuyPassPremium:FireServer()
end)

-- XP bar
local xpBar = Instance.new("Frame")
xpBar.Position = UDim2.new(0, 20, 0, 80)
xpBar.Size = UDim2.new(1, -40, 0, 24)
xpBar.BackgroundColor3 = Color3.fromRGB(245, 225, 240)
UI.corner(xpBar)
xpBar.Parent = panel
local xpFill = Instance.new("Frame")
xpFill.BackgroundColor3 = UI.PINK
UI.corner(xpFill)
xpFill.Parent = xpBar
local xpLabel = UI.text("", UI.DARK)
xpLabel.Size = UDim2.new(1, 0, 1, -6)
xpLabel.Position = UDim2.fromOffset(0, 3)
xpLabel.ZIndex = 2
xpLabel.Parent = xpBar

-- Track names on the left
local function trackName(text, color, top)
	local label = UI.text(text, color)
	label.Position = UDim2.new(0, 16, 0, top)
	label.Size = UDim2.fromOffset(70, 22)
	label.Parent = panel
end
trackName("FREE", UI.GRAY, 180)
trackName("⭐ PREMIUM", PREMIUM, 300)

local row = Instance.new("ScrollingFrame")
row.Position = UDim2.new(0, 92, 0, 116)
row.Size = UDim2.new(1, -108, 1, -132)
row.BackgroundTransparency = 1
row.BorderSizePixel = 0
row.ScrollBarThickness = 8
row.ScrollingDirection = Enum.ScrollingDirection.X
row.CanvasSize = UDim2.new()
row.AutomaticCanvasSize = Enum.AutomaticSize.X
row.Parent = panel
local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.Padding = UDim.new(0, 8)
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Parent = row

local cells = {}

local function makeCell(column, tier, reward, premium, top)
	local cell = Instance.new("Frame")
	cell.Position = UDim2.fromOffset(0, top)
	cell.Size = UDim2.new(1, 0, 0, 112)
	cell.BackgroundColor3 = if premium then Color3.fromRGB(255, 240, 205) else UI.WHITE
	UI.corner(cell, UDim.new(0, 14))
	local stroke = UI.stroke(cell, if premium then PREMIUM else UI.GRAY, 2)
	cell.Parent = column

	if not reward then
		local empty = UI.text("—", UI.GRAY)
		empty.Size = UDim2.fromScale(1, 1)
		empty.Parent = cell
		return
	end

	local icon, text = SquishyPass.describe(reward, SquishyTypes, Shop, Format)
	local iconLabel = UI.text(icon, UI.WHITE)
	iconLabel.Position = UDim2.new(0, 0, 0, 6)
	iconLabel.Size = UDim2.new(1, 0, 0, 38)
	iconLabel.Parent = cell

	local name = UI.text(text, UI.DARK)
	name.Position = UDim2.new(0, 6, 0, 46)
	name.Size = UDim2.new(1, -12, 0, 28)
	name.TextWrapped = true
	name.Parent = cell

	local claim = UI.button("", UI.GREEN)
	claim.Position = UDim2.new(0, 8, 1, -32)
	claim.Size = UDim2.new(1, -16, 0, 26)
	claim.Parent = cell
	claim.Activated:Connect(function()
		if remotes.ClaimPassTier:InvokeServer(tier, premium) then
			UI.pop(cell, 1.15)
			confetti(gui, if SquishyPass.Tiers[tier].Exclusive and premium then 150 else 25)
		end
	end)

	table.insert(cells, { Tier = tier, Premium = premium, Claim = claim, Stroke = stroke })
end

for tier, info in SquishyPass.Tiers do
	local column = Instance.new("Frame")
	column.Size = UDim2.new(0, COLUMN_WIDTH, 1, -12)
	column.BackgroundTransparency = 1
	column.LayoutOrder = tier
	column.Parent = row

	local number = UI.text(if info.Exclusive then "🌟 " .. tier else tostring(tier), UI.DARK)
	number.Size = UDim2.new(1, 0, 0, 24)
	number.Parent = column

	makeCell(column, tier, info.Free, false, 30)
	makeCell(column, tier, info.Premium, true, 152)
	if info.Exclusive then
		number.Text = "🌟 SEASON EXCLUSIVE"
		number.TextColor3 = Color3.fromRGB(255, 110, 230)
	end
end

local function update()
	local xp = SquishyPass.getXp(player)
	local tier = SquishyPass.tierOf(xp)
	local maxed = tier >= #SquishyPass.Tiers
	local into = xp - tier * SquishyPass.XP_PER_TIER
	local premium = SquishyPass.isPremium(player)

	seasonLabel.Text = SquishyPass.SEASON_NAME .. " • ends in " .. Leaderboards.formatTimeLeft(SquishyPass.ENDS_AT - os.time())
	xpFill.Size = UDim2.fromScale(if maxed then 1 else into / SquishyPass.XP_PER_TIER, 1)
	xpLabel.Text = if maxed then "Tier " .. tier .. " • MAXED! 🎉" else "Tier " .. tier .. "  •  " .. into .. " / " .. SquishyPass.XP_PER_TIER .. " XP (catch squishies!)"

	premiumButton.Text = if premium then "⭐ Premium ✅" else "⭐ Get Premium"
	premiumButton.AutoButtonColor = not premium

	local claimable = false
	for _, cell in cells do
		local claimed = SquishyPass.isClaimed(player, cell.Tier, cell.Premium)
		local unlocked = tier >= cell.Tier
		local locked = cell.Premium and not premium
		local canClaim = unlocked and not claimed and not locked
		claimable = claimable or canClaim

		cell.Claim.Text = if claimed then "✅" elseif locked then "🔒" elseif unlocked then "Claim!" else "Tier " .. cell.Tier
		cell.Claim.BackgroundColor3 = if canClaim then UI.GREEN else UI.GRAY
		cell.Claim.AutoButtonColor = canClaim
		cell.Stroke.Thickness = if canClaim then 4 else 2
	end
	badge.Visible = claimable
end

player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 4) == "Pass" then
		update()
	end
end)
update()

gui.Parent = player:WaitForChild("PlayerGui")

-- Keep the season countdown fresh
while true do
	task.wait(30)
	update()
end
