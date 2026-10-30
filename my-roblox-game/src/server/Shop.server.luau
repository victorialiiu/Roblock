local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage.Shared.Shop)
local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Weather = require(ReplicatedStorage.Shared.Weather)
local InventoryService = require(script.Parent.InventoryService)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

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

-- Returns the squishy name and mutation you rolled, or nil if you can't roll right now
rollRemote.OnServerInvoke = function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or spinning[player] or leaderstats.Money.Value < Shop.ROLL_COST then
		return nil
	end
	spinning[player] = true
	leaderstats.Money.Value -= Shop.ROLL_COST

	local squishy = SquishyTypes.pickRandom(Shop.getLuck(player), false)
	local mutationName = nil
	if math.random() < Shop.getMutationChance(player, false) then
		mutationName = Weather.pickRandom().Mutation
	end

	task.delay(Shop.SPIN_TIME, function()
		spinning[player] = nil
		if player.Parent then
			InventoryService.add(player, squishy.Name, mutationName)
		end
	end)

	return squishy.Name, mutationName
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
