-- Daily, weekly, monthly, and all-time leaderboards for money earned. Settings are in src/shared/Leaderboards.luau.
--   * Earnings get added to an OrderedDataStore per period every minute
--   * The top players are put in ReplicatedStorage.Leaderboards for the UI and the lobby board
--   * The top 3 on any board get an overhead tag
--   * When a week or month ends, its winners get an exclusive squishy (even if they're offline)
-- Needs "Enable Studio Access to API Services" to work in Studio.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Leaderboards = require(ReplicatedStorage.Shared.Leaderboards)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Format = require(ReplicatedStorage.Shared.Format)
local InventoryService = require(script.Parent.InventoryService)
local notify = require(script.Parent.Notify)

local BOARD_ROWS = 10
local BOARD_CYCLE_TIME = 8
local FONT = Enum.Font.FredokaOne

local folder = Instance.new("Folder")
folder.Name = "Leaderboards"
folder.Parent = ReplicatedStorage

-- Each one holds JSON: { Key = "Weekly_2914", Entries = { { UserId, Name, Value }, ... } }
local boards = {}
for _, period in Leaderboards.Periods do
	local value = Instance.new("StringValue")
	value.Name = period.Id
	value.Value = HttpService:JSONEncode({ Entries = {} })
	value.Parent = folder
	boards[period.Id] = { Value = value, Entries = {} }
end

local prizeStore = nil
pcall(function()
	prizeStore = DataStoreService:GetDataStore("LeaderboardPrizes_v1")
end)

local function storeFor(key)
	local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "Earned_" .. key)
	return if ok then store else nil
end

---------------------------------------------------------------- Saving earnings

local function setPersonal(player, periodId, value)
	player:SetAttribute("Earned_" .. periodId, value)
end

local function loadPersonal(player)
	local now = os.time()
	for _, period in Leaderboards.Periods do
		local store = storeFor(Leaderboards.keyOf(period.Id, now))
		local ok, value = pcall(function()
			return store and store:GetAsync(tostring(player.UserId))
		end)
		setPersonal(player, period.Id, if ok and value then value else 0)
	end
end

local function saveEarnings(player)
	local amount = InventoryService.unsavedEarnings[player]
	InventoryService.unsavedEarnings[player] = nil
	if not amount or amount <= 0 then
		return
	end
	local now = os.time()
	for _, period in Leaderboards.Periods do
		local store = storeFor(Leaderboards.keyOf(period.Id, now))
		local ok, total = pcall(function()
			return store and store:IncrementAsync(tostring(player.UserId), amount)
		end)
		if ok and total and player.Parent then
			setPersonal(player, period.Id, total)
		end
	end
end

---------------------------------------------------------------- Tags over the top players' heads

local function updateTag(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then
		return
	end
	local tag = head:FindFirstChild("LeaderTag")
	local text = player:GetAttribute("LeaderTag")
	if not text then
		if tag then
			tag:Destroy()
		end
		return
	end

	if not tag then
		tag = Instance.new("BillboardGui")
		tag.Name = "LeaderTag"
		tag.Size = UDim2.fromOffset(200, 30)
		tag.StudsOffset = Vector3.new(0, 2.6, 0)
		tag.MaxDistance = 100
		tag.Parent = head
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = FONT
		label.TextScaled = true
		label.TextStrokeTransparency = 0
		label.Parent = tag
	end
	local label = tag:FindFirstChildOfClass("TextLabel")
	label.Text = text
	label.TextColor3 = player:GetAttribute("LeaderTagColor") or Color3.new(1, 1, 1)
end

-- Your best spot on any board, like "👑 #1 This Week"
local function pickTags()
	for _, player in Players:GetPlayers() do
		local best = nil
		for _, periodId in Leaderboards.TagOrder do
			for rank, entry in boards[periodId].Entries do
				if rank > #Leaderboards.Tags then
					break
				end
				if entry.UserId == player.UserId and (not best or rank < best.Rank) then
					best = { Rank = rank, Period = Leaderboards.PeriodsById[periodId] }
				end
			end
		end
		if best then
			local tag = Leaderboards.Tags[best.Rank]
			player:SetAttribute("LeaderTag", tag.Text .. " " .. best.Period.Name)
			player:SetAttribute("LeaderTagColor", tag.Color)
		else
			player:SetAttribute("LeaderTag", nil)
			player:SetAttribute("LeaderTagColor", nil)
		end
		updateTag(player)
	end
end

---------------------------------------------------------------- Reading the boards

local names = {}
local function nameOf(userId)
	if not names[userId] then
		local player = Players:GetPlayerByUserId(userId)
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		names[userId] = if player then player.DisplayName elseif ok then name else "Player"
	end
	return names[userId]
end

local lastKeys = {}
local function refreshBoards()
	local now = os.time()
	for _, period in Leaderboards.Periods do
		local key = Leaderboards.keyOf(period.Id, now)
		-- A new day/week/month started, so everyone's back to 0
		if lastKeys[period.Id] and lastKeys[period.Id] ~= key then
			for _, player in Players:GetPlayers() do
				setPersonal(player, period.Id, 0)
			end
		end
		lastKeys[period.Id] = key

		local store = storeFor(key)
		local ok, page = pcall(function()
			return store and store:GetSortedAsync(false, Leaderboards.TOP):GetCurrentPage()
		end)
		if ok and page then
			local entries = {}
			for _, entry in page do
				local userId = tonumber(entry.key)
				table.insert(entries, { UserId = userId, Name = nameOf(userId), Value = entry.value })
			end
			boards[period.Id].Entries = entries
			boards[period.Id].Value.Value = HttpService:JSONEncode({ Key = key, Entries = entries })
		end
	end
	pickTags()
end

---------------------------------------------------------------- Prizes when a week or month ends

-- Gives a player any prizes waiting for them
local function claimPrizes(player)
	if not prizeStore or not player:WaitForChild("Inventory", 30) then
		return
	end
	local taken = nil
	pcall(prizeStore.UpdateAsync, prizeStore, "Prizes_" .. player.UserId, function(list)
		taken = nil
		if not list or #list == 0 then
			return nil
		end
		taken = list
		return {}
	end)
	for _, prize in taken or {} do
		InventoryService.add(player, prize.Squishy, {})
		notify(player, "🏆 You won " .. prize.Squishy .. " for being #" .. prize.Place .. " " .. prize.Period .. "!")
	end
end

local function awardPrizes()
	if not prizeStore then
		return
	end
	local now = os.time()
	for periodId, prize in Leaderboards.Prizes do
		local key = Leaderboards.previousKey(periodId, now)
		local doneKey = "Awarded_" .. key
		local ok, done = pcall(prizeStore.GetAsync, prizeStore, doneKey)
		local store = storeFor(key)
		if ok and not done and store then
			local gotWinners, page = pcall(function()
				return store:GetSortedAsync(false, prize.Places):GetCurrentPage()
			end)
			if gotWinners then
				local winners = {}
				for _, entry in page do
					table.insert(winners, tonumber(entry.key))
				end

				-- Lots of servers might try this at once. Only the one that marks it done hands out prizes
				local won = false
				pcall(prizeStore.UpdateAsync, prizeStore, doneKey, function(old)
					won = old == nil
					return if won then winners else nil
				end)

				if won then
					local periodName = string.lower(Leaderboards.PeriodsById[periodId].Name)
					periodName = string.gsub(periodName, "this ", "last ")
					for place, userId in winners do
						pcall(prizeStore.UpdateAsync, prizeStore, "Prizes_" .. userId, function(list)
							list = list or {}
							table.insert(list, { Squishy = prize.Squishy, Place = place, Period = periodName })
							return list
						end)
						local winner = Players:GetPlayerByUserId(userId)
						if winner then
							task.spawn(claimPrizes, winner)
						end
					end
				end
			end
		end
	end
end

---------------------------------------------------------------- The board in the lobby

local function makeBoard(angle)
	local position = Lobby.CENTER + Vector3.new(math.sin(angle), 0, math.cos(angle)) * (Lobby.RADIUS - 3)
	local board = Instance.new("Part")
	board.Name = "Leaderboard"
	board.Anchored = true
	board.Size = Vector3.new(14, 17, 0.6)
	board.CFrame = CFrame.lookAt(position + Vector3.new(0, 9.5, 0), Lobby.CENTER + Vector3.new(0, 9.5, 0))
	board.Color = Color3.fromRGB(255, 230, 245)
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = workspace:WaitForChild("Lobby")

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = board

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 14)
	padding.Parent = gui

	local function line(order, height, color)
		local label = Instance.new("TextLabel")
		label.LayoutOrder = order
		label.Size = UDim2.new(1, -30, 0, height)
		label.BackgroundTransparency = 1
		label.Font = FONT
		label.TextScaled = true
		label.TextColor3 = color
		label.Text = ""
		label.Parent = gui
		return label
	end

	local title = line(0, 60, Color3.fromRGB(255, 110, 190))
	local timer = line(1, 28, Color3.fromRGB(150, 110, 140))
	local rows = {}
	for i = 1, BOARD_ROWS do
		rows[i] = line(i + 1, 34, Color3.fromRGB(90, 60, 80))
		rows[i].TextXAlignment = Enum.TextXAlignment.Left
	end
	for i, tag in Leaderboards.Tags do
		rows[i].TextColor3 = tag.Color:Lerp(Color3.fromRGB(90, 60, 80), 0.35)
	end
	return { Title = title, Timer = timer, Rows = rows }
end

local lobbyBoards = { makeBoard(math.rad(90)), makeBoard(math.rad(270)) }

local function showOnBoard(board, period)
	local endsAt = Leaderboards.endOf(period.Id, os.time())
	board.Title.Text = period.Icon .. " " .. period.Name .. " 🏆"
	board.Timer.Text = Leaderboards.STAT_NAME .. (if endsAt then " • resets in " .. Leaderboards.formatTimeLeft(endsAt - os.time()) else "")
	local entries = boards[period.Id].Entries
	for i, row in board.Rows do
		local entry = entries[i]
		row.Text = if entry then "#" .. i .. "  " .. entry.Name .. "  " .. Format.money(entry.Value) else "#" .. i .. "  ..."
	end
end

task.spawn(function()
	local index = 0
	while true do
		index += 1
		for i, board in lobbyBoards do
			-- The two boards show different periods
			showOnBoard(board, Leaderboards.Periods[(index + (i - 1) * 2 - 1) % #Leaderboards.Periods + 1])
		end
		task.wait(BOARD_CYCLE_TIME)
	end
end)

---------------------------------------------------------------- Players

local function setup(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Head")
		updateTag(player)
	end)
	task.spawn(loadPersonal, player)
	task.spawn(claimPrizes, player)
end

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do
	task.spawn(setup, player)
end
Players.PlayerRemoving:Connect(saveEarnings)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(saveEarnings, player)
	end
	task.wait(2)
end)

local sinceAwards = math.huge
while true do
	for _, player in Players:GetPlayers() do
		saveEarnings(player)
	end
	refreshBoards()
	-- Check for finished weeks/months every 10 minutes
	sinceAwards += Leaderboards.REFRESH_TIME
	if sinceAwards >= 600 then
		sinceAwards = 0
		awardPrizes()
	end
	task.wait(Leaderboards.REFRESH_TIME)
end
