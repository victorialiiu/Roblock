-- Adding, removing, selling, and equipping squishies in a player's Inventory folder.
-- Items are IntValues named like "Wet Shocked Butter" with these attributes:
--   Squishy = "Butter", Mutations = "Wet,Shocked"
--   Equipped = how many are equipped for their stats
--   Showcased = how many are on pedestals at their base
-- Equipped and showcased squishies are held: they can't be sold or traded until you take them off.
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

-- How many aren't equipped or showcased
function InventoryService.free(player, itemName)
	local count = find(player, itemName)
	return if count then SquishyTypes.freeCount(count) else 0
end

-- Returns the squishy and attribute list for an item the player owns
function InventoryService.describe(player, itemName)
	local count = find(player, itemName)
	if not count then
		return nil, nil
	end
	return SquishyTypes.describe(count)
end

function InventoryService.total(player)
	local inventory = player:FindFirstChild("Inventory")
	local total = 0
	for _, count in if inventory then inventory:GetChildren() else {} do
		total += count.Value
	end
	return total
end

function InventoryService.isFull(player)
	return InventoryService.total(player) >= Shop.bagSize(player)
end

-- Returns the item name. Doesn't check if the bag is full, so callers that care should check isFull first
function InventoryService.add(player, squishyName, mutations, amount)
	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		return nil
	end

	local itemName = SquishyTypes.itemName(squishyName, mutations)
	local count = inventory:FindFirstChild(itemName)
	if count then
		count.Value += amount or 1
	else
		count = Instance.new("IntValue")
		count.Name = itemName
		count.Value = amount or 1
		count:SetAttribute("Squishy", squishyName)
		count:SetAttribute("Mutations", SquishyTypes.joinMutations(mutations))
		count.Parent = inventory
	end
	return itemName
end

-- Only takes free ones. Returns false if they don't have enough
function InventoryService.remove(player, itemName, amount)
	local count = find(player, itemName)
	if not count or amount < 1 or SquishyTypes.freeCount(count) < amount then
		return false
	end
	count.Value -= amount
	if count.Value <= 0 then
		count:Destroy()
	end
	return true
end

-- Money for selling, with all of the player's boosts
function InventoryService.priceOf(player, squishy, mutations, amount)
	return SquishyTypes.valueOf(squishy, mutations) * amount * Shop.moneyMultiplier(player)
end

-- Money earned that the leaderboards haven't counted yet. Leaderboard.server.luau empties it
InventoryService.unsavedEarnings = {}

-- Use this for money players earn (selling, base income), so it counts on the leaderboards
function InventoryService.giveMoney(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	amount = math.floor(amount)
	if leaderstats and amount > 0 then
		leaderstats.Money.Value += amount
		InventoryService.unsavedEarnings[player] = (InventoryService.unsavedEarnings[player] or 0) + amount
	end
end

-- Returns how much money they got
function InventoryService.sell(player, itemName, amount)
	local squishy, mutations = InventoryService.describe(player, itemName)
	if not squishy or not InventoryService.remove(player, itemName, amount) then
		return 0
	end
	local earned = InventoryService.priceOf(player, squishy, mutations, amount)
	InventoryService.giveMoney(player, earned)
	return earned
end

-- Sells everything that isn't equipped or showcased
function InventoryService.sellAll(player)
	local inventory = player:FindFirstChild("Inventory")
	local total = 0
	for _, count in if inventory then inventory:GetChildren() else {} do
		local free = SquishyTypes.freeCount(count)
		if free > 0 then
			total += InventoryService.sell(player, count.Name, free)
		end
	end
	return total
end

function InventoryService.equippedTotal(player)
	local inventory = player:FindFirstChild("Inventory")
	local total = 0
	for _, count in if inventory then inventory:GetChildren() else {} do
		total += count:GetAttribute("Equipped") or 0
	end
	return total
end

-- change is +1 to equip one more or -1 to take one off. Returns true if it worked
function InventoryService.equip(player, itemName, change)
	local count = find(player, itemName)
	local squishy = count and SquishyTypes.describe(count)
	if not squishy or not squishy.Passive then
		return false
	end
	local equipped = count:GetAttribute("Equipped") or 0
	if change > 0 then
		if SquishyTypes.freeCount(count) < 1 or InventoryService.equippedTotal(player) >= Shop.equipSlots(player) then
			return false
		end
		count:SetAttribute("Equipped", equipped + 1)
	else
		if equipped < 1 then
			return false
		end
		count:SetAttribute("Equipped", if equipped > 1 then equipped - 1 else nil)
	end
	return true
end

-- Takes off squishies until you're within your equip slots (after a rebirth changes them, or loading old saves)
function InventoryService.fixEquipped(player)
	local inventory = player:FindFirstChild("Inventory")
	local over = InventoryService.equippedTotal(player) - Shop.equipSlots(player)
	for _, count in if inventory then inventory:GetChildren() else {} do
		while over > 0 and (count:GetAttribute("Equipped") or 0) > 0 do
			InventoryService.equip(player, count.Name, -1)
			over -= 1
		end
	end
end

function InventoryService.setShowcased(player, itemName, amount)
	local count = find(player, itemName)
	if count then
		count:SetAttribute("Showcased", if amount > 0 then amount else nil)
	end
end

return InventoryService
