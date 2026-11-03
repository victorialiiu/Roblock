local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage.Shared.Shop)
local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Weather = require(ReplicatedStorage.Shared.Weather)
local InventoryService = require(script.Parent.InventoryService)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

-- Needs the Remotes folder, so it's required after making it
local notify = require(script.Parent.Notify)

local spinRemote = Instance.new("RemoteFunction")
spinRemote.Name = "Spin"
spinRemote.Parent = remotes

local buyRemote = Instance.new("RemoteFunction")
buyRemote.Name = "BuyUpgrade"
buyRemote.Parent = remotes

local rollRemote = Instance.new("RemoteFunction")
rollRemote.Name = "Roll"
rollRemote.Parent = remotes

local sellRemote = Instance.new("RemoteFunction")
sellRemote.Name = "Sell"
sellRemote.Parent = remotes

local sellAllRemote = Instance.new("RemoteFunction")
sellAllRemote.Name = "SellAll"
sellAllRemote.Parent = remotes

local equipRemote = Instance.new("RemoteFunction")
equipRemote.Name = "Equip"
equipRemote.Parent = remotes

-- Players in the middle of a spin or roll
local spinning = {}

-- Returns the prize id, or nil if you can't spin right now
spinRemote.OnServerInvoke = function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or spinning[player] or leaderstats.Money.Value < Shop.SPIN_COST then
		return nil
	end
	spinning[player] = true
	leaderstats.Money.Value -= Shop.SPIN_COST

	local prize = Shop.pickPrize()

	-- Give the prize when the wheel stops spinning on screen
	task.delay(Shop.SPIN_TIME, function()
		spinning[player] = nil
		if not player.Parent then
			return
		end
		if prize.Duration then
			-- Winning the same boost again adds more time
			local key = "Boost_" .. prize.Id
			local now = workspace:GetServerTimeNow()
			player:SetAttribute(key, math.max(now, player:GetAttribute(key) or 0) + prize.Duration)
		elseif prize.Refund then
			leaderstats.Money.Value += math.floor(Shop.SPIN_COST * prize.Refund)
		end
	end)

	return prize.Id
end

buyRemote.OnServerInvoke = function(player, upgradeId)
	local upgrade = Shop.UpgradesById[upgradeId]
	local leaderstats = player:FindFirstChild("leaderstats")
	if not upgrade or not leaderstats then
		return false
	end

	local level = Shop.getLevel(player, upgradeId)
	local cost = Shop.upgradeCost(upgrade, level)
	if level >= upgrade.MaxLevel or leaderstats.Money.Value < cost then
		return false
	end

	leaderstats.Money.Value -= cost
	player:SetAttribute("Upgrade_" .. upgradeId, level + 1)
	return true
end

-- Returns the squishy name and attribute list you rolled, or nil if you can't roll right now
rollRemote.OnServerInvoke = function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or spinning[player] or leaderstats.Money.Value < Shop.ROLL_COST then
		return nil
	end
	if InventoryService.isFull(player) then
		notify(player, "🎒 Your bag is full! Sell some squishies first")
		return nil
	end
	spinning[player] = true
	leaderstats.Money.Value -= Shop.ROLL_COST

	local squishy = SquishyTypes.pickRandom(Shop.getLuck(player), false)
	local mutations = {}
	if math.random() < Shop.getMutationChance(player, false) then
		table.insert(mutations, Weather.pickRandom().Mutation)
	end

	task.delay(Shop.SPIN_TIME, function()
		spinning[player] = nil
		if player.Parent then
			InventoryService.add(player, squishy.Name, mutations)
		end
	end)

	return squishy.Name, mutations
end

sellRemote.OnServerInvoke = function(player, itemName, amount)
	if typeof(itemName) ~= "string" or typeof(amount) ~= "number" then
		return 0
	end
	return InventoryService.sell(player, itemName, math.floor(amount))
end

sellAllRemote.OnServerInvoke = function(player)
	return InventoryService.sellAll(player)
end

-- change is 1 to equip one more, -1 to take one off
equipRemote.OnServerInvoke = function(player, itemName, change)
	if typeof(itemName) ~= "string" or (change ~= 1 and change ~= -1) then
		return false
	end
	return InventoryService.equip(player, itemName, change)
end
