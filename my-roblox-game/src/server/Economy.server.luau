-- Sets up each player's money and inventory, and saves them with DataStores.
-- To save in Studio: Game Settings → Security → turn on "Enable Studio Access to API Services".
-- Without that, everything still works, it just starts fresh every time.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage.Shared.Shop)
local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)

local AUTOSAVE_TIME = 120
-- Player attributes that get saved as they are. Add yours here to save something new
local SAVED_ATTRIBUTES = { "PassSeason", "PassXp", "PassClaimed", "UnlockedRegions" }

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore("PlayerData_v1")
end)

-- Players whose data loaded fine. We never save over data we couldn't read
local loaded = {}

local function load(player)
	if not store then
		return {}, true
	end
	local ok, data = pcall(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if not ok then
		warn("Couldn't load data for " .. player.Name .. ": " .. tostring(data))
		return {}, false
	end
	return data or {}, true
end

local function snapshot(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local inventory = player:FindFirstChild("Inventory")
	if not leaderstats or not inventory then
		return nil
	end

	local upgrades = {}
	for _, upgrade in Shop.Upgrades do
		upgrades[upgrade.Id] = Shop.getLevel(player, upgrade.Id)
	end

	local items = {}
	for _, count in inventory:GetChildren() do
		table.insert(items, {
			Squishy = count:GetAttribute("Squishy"),
			Mutations = count:GetAttribute("Mutations"),
			Count = count.Value,
			Equipped = count:GetAttribute("Equipped"),
		})
	end

	local attributes = {}
	for _, name in SAVED_ATTRIBUTES do
		attributes[name] = player:GetAttribute(name)
	end

	return {
		Attributes = attributes,
		Money = leaderstats.Money.Value,
		Squishies = leaderstats.Squishies.Value,
		Rebirths = Shop.getRebirths(player),
		Upgrades = upgrades,
		Items = items,
	}
end

local function save(player)
	if not store or not loaded[player] then
		return
	end
	local data = snapshot(player)
	if not data then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(tostring(player.UserId), data)
	end)
	if not ok then
		warn("Couldn't save data for " .. player.Name .. ": " .. tostring(err))
	end
end

local function setup(player)
	local data, ok = load(player)
	if not player.Parent then
		return
	end
	loaded[player] = ok

	player:SetAttribute("Rebirths", data.Rebirths or 0)
	for _, name in SAVED_ATTRIBUTES do
		local value = (data.Attributes or {})[name]
		if value ~= nil then
			player:SetAttribute(name, value)
		end
	end
	for upgradeId, level in data.Upgrades or {} do
		if Shop.UpgradesById[upgradeId] then
			player:SetAttribute("Upgrade_" .. upgradeId, level)
		end
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = data.Money or 0
	money.Parent = leaderstats

	local squishies = Instance.new("IntValue")
	squishies.Name = "Squishies"
	squishies.Value = data.Squishies or 0
	squishies.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = data.Rebirths or 0
	rebirths.Parent = leaderstats
	player:GetAttributeChangedSignal("Rebirths"):Connect(function()
		rebirths.Value = Shop.getRebirths(player)
	end)

	leaderstats.Parent = player

	-- One IntValue per squishy + attribute combo you've caught. Filled before it's
	-- parented so the UI doesn't think you just caught everything you saved
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	for _, item in data.Items or {} do
		local squishy = SquishyTypes.ByName[item.Squishy]
		if squishy and squishy.Value and (item.Count or 0) > 0 then
			local mutations = SquishyTypes.splitMutations(item.Mutations)
			local count = Instance.new("IntValue")
			count.Name = SquishyTypes.itemName(squishy.Name, mutations)
			count.Value = item.Count
			count:SetAttribute("Squishy", squishy.Name)
			count:SetAttribute("Mutations", SquishyTypes.joinMutations(mutations))
			if squishy.Passive and (item.Equipped or 0) > 0 then
				count:SetAttribute("Equipped", math.min(item.Equipped, item.Count))
			end
			count.Parent = inventory
		end
	end
	inventory.Parent = player
end

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do
	task.spawn(setup, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
	task.wait(3)
end)

while true do
	task.wait(AUTOSAVE_TIME)
	for _, player in Players:GetPlayers() do
		task.spawn(save, player)
	end
end
