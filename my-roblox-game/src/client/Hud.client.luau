local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Weather = require(ReplicatedStorage.Shared.Weather)
local Format = require(ReplicatedStorage.Shared.Format)
local Regions = require(ReplicatedStorage.Shared.Regions)
local World = require(ReplicatedStorage.Shared.World)

local player = Players.LocalPlayer
local status = ReplicatedStorage:WaitForChild("Status")
local currentEvent = ReplicatedStorage:WaitForChild("CurrentEvent")
local leaderstats = player:WaitForChild("leaderstats")
local money = leaderstats:WaitForChild("Money")

local PINK = Color3.fromRGB(255, 120, 200)
local WHITE = Color3.new(1, 1, 1)
local FONT = Enum.Font.FredokaOne

local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false

local function addCorner(parent)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = parent
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
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

local function pop(target)
	local scale = target:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", target)
	scale.Scale = 1.25
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- Red flash when you get hurt
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 0, 60)
flash.BackgroundTransparency = 1
flash.Parent = gui

local function watchHealth(character)
	local humanoid = character:WaitForChild("Humanoid")
	local last = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		if health < last then
			flash.BackgroundTransparency = 0.5
			TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		end
		last = health
	end)
end
if player.Character then
	task.spawn(watchHealth, player.Character)
end
player.CharacterAdded:Connect(watchHealth)

-- Title that wobbles back and forth
local title = makeText("SQUISHY RAIN", PINK)
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.new(0.5, 0, 0, 10)
title.Size = UDim2.new(0.6, 0, 0, 60)
addStroke(title, WHITE, 4)
title.Parent = gui

title.Rotation = -3
TweenService:Create(
	title,
	TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Rotation = 3 }
):Play()

-- Weather countdown under the title
local statusPill = Instance.new("Frame")
statusPill.AnchorPoint = Vector2.new(0.5, 0)
statusPill.Position = UDim2.new(0.5, 0, 0, 76)
statusPill.Size = UDim2.new(0, 440, 0, 36)
statusPill.BackgroundColor3 = Color3.new(0, 0, 0)
statusPill.BackgroundTransparency = 0.4
addCorner(statusPill)
statusPill.Parent = gui

local statusLabel = makeText(status.Value, WHITE)
statusLabel.Size = UDim2.new(1, -24, 1, -8)
statusLabel.Position = UDim2.new(0, 12, 0, 4)
statusLabel.Parent = statusPill

status.Changed:Connect(function(value)
	statusLabel.Text = value
end)

-- Money in the bottom left
local counter = Instance.new("Frame")
counter.AnchorPoint = Vector2.new(0, 1)
counter.Position = UDim2.new(0, 16, 1, -16)
counter.Size = UDim2.new(0, 200, 0, 64)
counter.BackgroundColor3 = Color3.fromRGB(90, 200, 120)
addCorner(counter)
addStroke(counter, WHITE, 3)
counter.Parent = gui

local moneyLabel = makeText("", WHITE)
moneyLabel.Size = UDim2.new(1, -32, 1, -16)
moneyLabel.Position = UDim2.new(0, 16, 0, 8)
moneyLabel.Parent = counter

local lastMoney = money.Value
moneyLabel.Text = Format.money(lastMoney)
money.Changed:Connect(function(value)
	moneyLabel.Text = Format.money(value)
	if value > lastMoney then
		pop(counter)
	end
	lastMoney = value
end)

-- Big banner when weather or an event starts
local banner = makeText("", Color3.fromRGB(255, 240, 120))
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.new(0.5, 0, 0.35, 0)
banner.Size = UDim2.new(0.8, 0, 0, 90)
banner.Visible = false
addStroke(banner, Color3.fromRGB(120, 0, 80), 5)
banner.Parent = gui

local subtitle = makeText("", WHITE)
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Position = UDim2.new(0.5, 0, 1, 0)
subtitle.Size = UDim2.new(0.8, 0, 0, 40)
addStroke(subtitle, Color3.fromRGB(120, 0, 80), 3)
subtitle.Parent = banner

local bannerCount = 0
currentEvent.Changed:Connect(function(value)
	if value == "" then
		return
	end

	local weathers = Weather.parse(value)
	if #weathers > 0 then
		local mutations = Weather.mutationsOf(weathers)
		local combo = if #weathers > 1 then "COMBO! " else ""
		subtitle.Text = combo .. table.concat(mutations, " + ") .. " squishies are falling! Up to x" .. SquishyTypes.multiplierOf(mutations) .. " money"
		subtitle.TextColor3 = SquishyTypes.Mutations[mutations[#mutations]].Color
	else
		subtitle.Text = "Watch out!"
		subtitle.TextColor3 = WHITE
	end

	bannerCount += 1
	local thisBanner = bannerCount
	banner.Text = value .. "!!"
	banner.Visible = true
	pop(banner)
	task.delay(4, function()
		if bannerCount == thisBanner then
			banner.Visible = false
		end
	end)
end)

-- Pop-up messages from the server (bag full, auto sold, rebirth...)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local noticeHolder = Instance.new("Frame")
noticeHolder.AnchorPoint = Vector2.new(0.5, 0)
noticeHolder.Position = UDim2.new(0.5, 0, 0, 160)
noticeHolder.Size = UDim2.fromOffset(460, 200)
noticeHolder.BackgroundTransparency = 1
noticeHolder.Parent = gui
local noticeLayout = Instance.new("UIListLayout")
noticeLayout.Padding = UDim.new(0, 6)
noticeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
noticeLayout.Parent = noticeHolder

remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text)
	local notice = makeText(text, WHITE)
	notice.Size = UDim2.fromOffset(460, 34)
	notice.BackgroundTransparency = 0.15
	notice.BackgroundColor3 = Color3.fromRGB(255, 120, 200)
	addCorner(notice)
	addStroke(notice, WHITE, 2)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = notice
	notice.Parent = noticeHolder
	pop(notice)
	task.delay(3.5, function()
		notice:Destroy()
	end)
end)

-- Which region you're in, under the weather countdown
local regionLabel = makeText("", WHITE)
regionLabel.AnchorPoint = Vector2.new(0.5, 0)
regionLabel.Position = UDim2.new(0.5, 0, 0, 116)
regionLabel.Size = UDim2.fromOffset(300, 26)
addStroke(regionLabel, Color3.fromRGB(120, 0, 80), 2)
regionLabel.Parent = gui

task.spawn(function()
	local lastRegion = nil
	while true do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local region = root and Regions.at(root.Position)
		if region ~= lastRegion then
			lastRegion = region
			local onMap = root ~= nil and World.contains(root.Position)
			regionLabel.Text = if region
				then region.Icon .. " " .. region.Name .. "  •  x" .. region.Luck .. " luck"
				elseif onMap then "🌈 Spawn • head out to find squishies!"
				else "🏠 Lobby"
			regionLabel.TextColor3 = if region then region.Color:Lerp(WHITE, 0.4) else WHITE
			pop(regionLabel)
		end
		task.wait(0.25)
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
