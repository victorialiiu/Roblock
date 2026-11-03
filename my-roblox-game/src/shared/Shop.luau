-- Upgrade shop, Lucky Spin, and Rebirth settings, shared by the server and the UI
local SquishyTypes = require(script.Parent.SquishyTypes)
local Passes = require(script.Parent.Passes)

local Shop = {}

Shop.SPIN_COST = 100
Shop.ROLL_COST = 100
Shop.SPIN_TIME = 3
Shop.COST_GROWTH = 1.7

-- Each squishy on a base pedestal earns this much of its value every second
Shop.INCOME_RATE = 0.02

-- Rebirthing resets your money and upgrades. You keep your squishies, and get:
Shop.REBIRTH_BASE_COST = 25000
Shop.REBIRTH_COST_GROWTH = 4
Shop.REBIRTH_MONEY = 0.5 -- +50% money per rebirth
Shop.BASE_PLOTS = 4
Shop.PLOTS_PER_REBIRTH = 2
Shop.MAX_PLOTS = 16
Shop.BASE_BAG = 50
Shop.BAG_PER_REBIRTH = 25
Shop.BASE_EQUIPS = 3
Shop.EQUIPS_PER_REBIRTH = 1
Shop.MAX_EQUIPS = 10

-- Permanent upgrades. Price goes up each level
Shop.Upgrades = {
	{ Id = "Luck", Name = "Luck", Icon = "🍀", Description = "+15% rare squishies", MaxLevel = 10, BaseCost = 200 },
	{ Id = "Speed", Name = "Walk Speed", Icon = "👟", Description = "+2 walk speed", MaxLevel = 10, BaseCost = 150 },
	{ Id = "Mutation", Name = "Mutation Chance", Icon = "✨", Description = "+5% mutations in weather, +1% anytime", MaxLevel = 10, BaseCost = 250 },
}

-- Lucky Spin prizes. Weight is how likely it is (the UI shows these as %)
Shop.Prizes = {
	{ Id = "Speed", Name = "x2 Speed", Icon = "⚡", Weight = 25, Duration = 30 },
	{ Id = "Money", Name = "x2 Money", Icon = "💰", Weight = 25, Duration = 30 },
	{ Id = "Luck", Name = "x3 Luck", Icon = "🍀", Weight = 15, Duration = 30 },
	{ Id = "Jump", Name = "Super Jump", Icon = "🦘", Weight = 15, Duration = 30 },
	{ Id = "Mutation", Name = "Mutation Storm", Icon = "🌈", Weight = 8, Duration = 30 },
	{ Id = "Jackpot", Name = "JACKPOT x5 Money", Icon = "💎", Weight = 2, Duration = 30 },
	{ Id = "Candy", Name = "Half Refund", Icon = "🍬", Weight = 10, Refund = 0.5 },
}

Shop.UpgradesById = {}
for _, upgrade in Shop.Upgrades do
	Shop.UpgradesById[upgrade.Id] = upgrade
end

Shop.PrizesById = {}
for _, prize in Shop.Prizes do
	Shop.PrizesById[prize.Id] = prize
end

function Shop.upgradeCost(upgrade, level)
	return math.floor(upgrade.BaseCost * Shop.COST_GROWTH ^ level)
end

function Shop.getLevel(player, upgradeId)
	return player:GetAttribute("Upgrade_" .. upgradeId) or 0
end

-- Boosts are stored as the server time they run out
function Shop.boostTimeLeft(player, prizeId)
	local endsAt = player:GetAttribute("Boost_" .. prizeId) or 0
	return math.max(0, endsAt - workspace:GetServerTimeNow())
end

function Shop.boostActive(player, prizeId)
	return Shop.boostTimeLeft(player, prizeId) > 0
end

function Shop.pickPrize()
	local total = 0
	for _, prize in Shop.Prizes do
		total += prize.Weight
	end
	local roll = math.random() * total
	for _, prize in Shop.Prizes do
		roll -= prize.Weight
		if roll <= 0 then
			return prize
		end
	end
	return Shop.Prizes[1]
end

function Shop.getRebirths(player)
	return player:GetAttribute("Rebirths") or 0
end

function Shop.rebirthCost(rebirths)
	return math.floor(Shop.REBIRTH_BASE_COST * Shop.REBIRTH_COST_GROWTH ^ rebirths)
end

-- How many pedestals on your base you can use
function Shop.plotCount(player)
	return math.min(Shop.BASE_PLOTS + Shop.PLOTS_PER_REBIRTH * Shop.getRebirths(player), Shop.MAX_PLOTS)
end

-- How many squishies fit in your inventory
function Shop.bagSize(player)
	return Shop.BASE_BAG + Shop.BAG_PER_REBIRTH * Shop.getRebirths(player)
end

-- How many squishies you can equip for their stats
function Shop.equipSlots(player)
	return math.min(Shop.BASE_EQUIPS + Shop.EQUIPS_PER_REBIRTH * Shop.getRebirths(player), Shop.MAX_EQUIPS)
end

local function passives(player)
	return SquishyTypes.getPassives(player:FindFirstChild("Inventory"))
end

function Shop.getLuck(player)
	local luck = (1 + 0.15 * Shop.getLevel(player, "Luck")) * (1 + passives(player).Luck)
	if Shop.boostActive(player, "Luck") then
		luck *= 3
	end
	return luck
end

function Shop.getMutationChance(player, inWeather)
	if Shop.boostActive(player, "Mutation") then
		return 1
	end
	local level = Shop.getLevel(player, "Mutation")
	if inWeather then
		return math.min(0.5 + 0.05 * level, 0.95)
	end
	return 0.01 * level
end

function Shop.moneyMultiplier(player)
	local multiplier = (1 + Shop.REBIRTH_MONEY * Shop.getRebirths(player)) * (1 + passives(player).Money)
	if Passes.owns(player, "Pet") then
		multiplier *= Passes.PET_MONEY
	end
	if Shop.boostActive(player, "Money") then
		multiplier *= 2
	end
	if Shop.boostActive(player, "Jackpot") then
		multiplier *= 5
	end
	return multiplier
end

return Shop
