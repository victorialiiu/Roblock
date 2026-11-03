-- Leaderboard window: tabs for each period, a bar chart of the top earners, and where you stand
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Leaderboards = require(ReplicatedStorage.Shared.Leaderboards)
local Format = require(ReplicatedStorage.Shared.Format)
local UI = require(ReplicatedStorage.Shared.UI)

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("Leaderboards")

local MEDALS = { "🥇", "🥈", "🥉" }
local BAR_COLORS = {
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(190, 200, 220),
	Color3.fromRGB(230, 160, 100),
}
local BAR_COLOR = Color3.fromRGB(255, 160, 215)
local MY_COLOR = Color3.fromRGB(120, 200, 255)

local gui = Instance.new("ScreenGui")
gui.Name = "Leaderboard"
gui.ResetOnSpawn = false

local panel = UI.panel("🏆 Leaderboards", UI.GOLD, Vector2.new(600, 520))
panel.Parent = gui

local openButton = UI.menuButton(gui, "🏆 Leaders", UI.GOLD, "left", 3)
openButton.Activated:Connect(function()
	UI.toggle(panel)
end)

-- Tabs
local tabs = Instance.new("Frame")
tabs.Position = UDim2.new(0, 16, 0, 56)
tabs.Size = UDim2.new(1, -32, 0, 34)
tabs.BackgroundTransparency = 1
tabs.Parent = panel
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabs

local timerLabel = UI.text("", UI.DARK)
timerLabel.Position = UDim2.new(0, 16, 0, 96)
timerLabel.Size = UDim2.new(1, -32, 0, 18)
timerLabel.Parent = panel

-- How you're doing, pinned under the chart
local myCard = UI.text("", UI.WHITE)
myCard.AnchorPoint = Vector2.new(0, 1)
myCard.Position = UDim2.new(0, 16, 1, -14)
myCard.Size = UDim2.new(1, -32, 0, 36)
myCard.BackgroundTransparency = 0
myCard.BackgroundColor3 = MY_COLOR
UI.corner(myCard)
local myPadding = Instance.new("UIPadding")
myPadding.PaddingTop = UDim.new(0, 7)
myPadding.PaddingBottom = UDim.new(0, 7)
myPadding.Parent = myCard
myCard.Parent = panel

-- The chart: one bar per player, as long as their earnings compared to #1
local chart = Instance.new("ScrollingFrame")
chart.Position = UDim2.new(0, 16, 0, 120)
chart.Size = UDim2.new(1, -32, 1, -180)
chart.BackgroundColor3 = UI.WHITE
chart.BorderSizePixel = 0
chart.ScrollBarThickness = 6
chart.CanvasSize = UDim2.new()
chart.AutomaticCanvasSize = Enum.AutomaticSize.Y
UI.corner(chart, UDim.new(0, 14))
chart.Parent = panel
local chartLayout = Instance.new("UIListLayout")
chartLayout.Padding = UDim.new(0, 5)
chartLayout.SortOrder = Enum.SortOrder.LayoutOrder
chartLayout.Parent = chart
local chartPadding = Instance.new("UIPadding")
chartPadding.PaddingTop = UDim.new(0, 8)
chartPadding.PaddingBottom = UDim.new(0, 8)
chartPadding.PaddingLeft = UDim.new(0, 8)
chartPadding.PaddingRight = UDim.new(0, 8)
chartPadding.Parent = chart

local selected = Leaderboards.Periods[2]
local tabButtons = {}

local function readBoard(periodId)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, folder[periodId].Value)
	return if ok and data.Entries then data.Entries else {}
end

local function addBar(rank, entry, top, isMe)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, if rank <= 3 then 38 else 30)
	row.BackgroundTransparency = 1
	row.LayoutOrder = rank
	row.Parent = chart

	local place = UI.text(MEDALS[rank] or "#" .. rank, UI.DARK)
	place.Size = UDim2.new(0, 40, 1, 0)
	place.Parent = row

	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 46, 0, 0)
	track.Size = UDim2.new(1, -46, 1, 0)
	track.BackgroundColor3 = Color3.fromRGB(250, 238, 246)
	UI.corner(track)
	track.Parent = row

	local color = if isMe then MY_COLOR else BAR_COLORS[rank] or BAR_COLOR
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromScale(0, 1)
	bar.BackgroundColor3 = color
	UI.corner(bar)
	bar.Parent = track
	-- Bars grow in when you open a tab
	local share = if top > 0 then math.max(entry.Value / top, 0.04) else 0
	TweenService:Create(bar, TweenInfo.new(0.5 + rank * 0.03, Enum.EasingStyle.Quint), { Size = UDim2.fromScale(share, 1) }):Play()

	local name = UI.text(entry.Name .. (if isMe then " (you!)" else ""), UI.DARK)
	name.Position = UDim2.new(0, 12, 0, 5)
	name.Size = UDim2.new(0.6, -12, 1, -10)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 2
	name.Parent = track

	local value = UI.text(Format.money(entry.Value), UI.DARK)
	value.AnchorPoint = Vector2.new(1, 0)
	value.Position = UDim2.new(1, -12, 0, 5)
	value.Size = UDim2.new(0.4, -12, 1, -10)
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.ZIndex = 2
	value.Parent = track
end

local function render()
	for _, child in chart:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	for period, button in tabButtons do
		button.BackgroundColor3 = if period == selected then UI.GOLD else UI.GRAY
	end

	local entries = readBoard(selected.Id)
	local top = if entries[1] then entries[1].Value else 0
	local myRank = nil
	for rank, entry in entries do
		local isMe = entry.UserId == player.UserId
		if isMe then
			myRank = rank
		end
		addBar(rank, entry, top, isMe)
	end
	if #entries == 0 then
		local empty = UI.text("Nobody yet... go be #1! 🌧️", UI.GRAY)
		empty.Size = UDim2.new(1, 0, 0, 30)
		empty.Parent = chart
	end

	local mine = player:GetAttribute("Earned_" .. selected.Id) or 0
	if myRank then
		myCard.Text = "You're #" .. myRank .. " with " .. Format.money(mine) .. "!"
	elseif top > 0 and #entries >= Leaderboards.TOP then
		local last = entries[#entries].Value
		myCard.Text = "You: " .. Format.money(mine) .. " • " .. Format.money(math.max(last - mine + 1, 0)) .. " more to make the board!"
	else
		myCard.Text = "You: " .. Format.money(mine) .. " " .. Leaderboards.STAT_NAME
	end

	local endsAt = Leaderboards.endOf(selected.Id, os.time())
	local prize = Leaderboards.Prizes[selected.Id]
	local prizeText = if prize then " • #1 wins " .. prize.Squishy .. "!" else ""
	timerLabel.Text = (if endsAt then "Resets in " .. Leaderboards.formatTimeLeft(endsAt - os.time()) else "Forever and ever") .. prizeText
end

for i, period in Leaderboards.Periods do
	local button = UI.button(period.Icon .. " " .. period.Name, UI.GRAY)
	button.Size = UDim2.new(0.25, -5, 1, 0)
	button.LayoutOrder = i
	button.Parent = tabs
	button.Activated:Connect(function()
		selected = period
		render()
	end)
	tabButtons[period] = button
end

for _, value in folder:GetChildren() do
	value.Changed:Connect(function()
		if panel.Visible then
			render()
		end
	end)
end
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	if panel.Visible then
		render()
	end
end)
player.AttributeChanged:Connect(function(name)
	if panel.Visible and string.sub(name, 1, 7) == "Earned_" then
		render()
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
