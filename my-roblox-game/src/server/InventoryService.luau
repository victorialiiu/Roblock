-- Adding, removing, and selling squishies in a player's Inventory folder.
-- Items are IntValues named like "Golden Butter" with Squishy and Mutation attributes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Shop = require(ReplicatedStorage.Shared.Shop)

local InventoryService = {}

local function find(player, itemName)
	local inventory = player:FindFirstChild("Inventory")
	return inventory and inventory:FindFirstChild(itemName)
end

function InventoryService.count(player, itemName)
	local count = find(player, itemName)
	return if count then count.Value else 0
end

-- Returns the squishy and mutation name for an item the player owns
function InventoryService.describe(player, itemName)
	local count = find(player, itemName)
	if not count then
		return nil, nil
	end
	return SquishyTypes.ByName[count:GetAttribute("Squishy")], count:GetAttribute("Mutation")
end

function InventoryService.add(player, squishyName, mutationName, amount)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		return
	end

	local itemName = SquishyTypes.itemName(squishyName, mutationName)
	local count = inventory:FindFirstChild(itemName)
	if count then
		count.Value += amount or 1
	else
		count = Instance.new("IntValue")
		count.Name = itemName
		count.Value = amount or 1
		count:SetAttribute("Squishy", squishyName)
		count:SetAttribute("Mutation", mutationName)
		count.Parent = inventory
	end
end

-- Returns false if they don't have enough
function InventoryService.remove(player, itemName, amount)
	local count = find(player, itemName)
	if not count or amount < 1 or count.Value < amount then
		return false
	end
	count.Value -= amount
	if count.Value <= 0 then
		count:Destroy()
	end
	return true
end

-- Returns how much money they got
function InventoryService.sell(player, itemName, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	local squishy, mutationName = InventoryService.describe(player, itemName)
	if not leaderstats or not squishy or not InventoryService.remove(player, itemName, amount) then
		return 0
	end

	local earned = SquishyTypes.valueOf(squishy, mutationName) * amount * Shop.moneyMultiplier(player)
	leaderstats.Money.Value += earned
	return earned
end

function InventoryService.sellAll(player)
	local inventory = player:FindFirstChild("Inventory")
	local total = 0
	for _, count in if inventory then inventory:GetChildren() else {} do
		total += InventoryService.sell(player, count.Name, count.Value)
	end
	return total
end

return InventoryService
