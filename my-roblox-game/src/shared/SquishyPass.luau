-- The Squishy Pass (our battle pass). TEMPLATE: tune the numbers and rewards each season!
--
-- Catch squishies to earn XP. Every XP_PER_TIER unlocks a tier with two rewards:
--   Free: everyone gets it (kinda mid on purpose)
--   Premium: only with the Premium Squishy Pass gamepass (the good stuff)
-- The last premium tier is the season exclusive squishy.
--
-- New season: bump SEASON (resets everyone's progress), change the name/end date, and swap the Tiers.
--
-- Reward types:
--   { Type = "Money", Amount = 500 }
--   { Type = "Squishy", Squishy = "Donut", Mutations = { "Golden" } }
--   { Type = "Boost", Prize = "Luck", Duration = 120 }   -- any Lucky Spin prize id with a Duration
--   { Type = "Box" }                                     -- opens a Lucky Box
local SquishyPass = {}

SquishyPass.SEASON = 1
SquishyPass.SEASON_NAME = "Season 1: Sweet Beginnings"
-- When the season ends (UTC)
SquishyPass.ENDS_AT = DateTime.fromUniversalTime(2027, 1, 1).UnixTimestamp
-- Gamepass id for premium. While it's 0, Studio gives premium for free so you can test it
SquishyPass.PREMIUM_PASS_ID = 0

SquishyPass.XP_PER_TIER = 100
-- XP for each squishy you catch, by rarity
SquishyPass.XP_PER_CATCH = { Common = 1, Uncommon = 2, Rare = 5, Epic = 15, Legendary = 50 }
-- Each attribute on a caught squishy adds this much XP
SquishyPass.XP_PER_ATTRIBUTE = 3
-- Premium players earn XP faster
SquishyPass.PREMIUM_XP = 1.5

local function money(amount)
	return { Type = "Money", Amount = amount }
end
local function squishy(name, mutations)
	return { Type = "Squishy", Squishy = name, Mutations = mutations }
end
local function boost(prize, duration)
	return { Type = "Boost", Prize = prize, Duration = duration }
end
local BOX = { Type = "Box" }

-- Free = nil means that tier has nothing on the free track
SquishyPass.Tiers = {
	{ Free = money(50), Premium = money(1000) },
	{ Free = nil, Premium = squishy("Strawberry", { "Wet" }) },
	{ Free = squishy("Butter"), Premium = boost("Luck", 300) },
	{ Free = nil, Premium = money(5000) },
	{ Free = money(150), Premium = squishy("Donut", { "Golden" }) },
	{ Free = nil, Premium = BOX },
	{ Free = boost("Speed", 60), Premium = boost("Money", 600) },
	{ Free = nil, Premium = squishy("Cupcake", { "Sticky", "Shocked" }) },
	{ Free = squishy("Cheese"), Premium = money(25000) },
	{ Free = nil, Premium = BOX },
	{ Free = money(400), Premium = squishy("Watermelon", { "Rainbow" }) },
	{ Free = nil, Premium = boost("Jackpot", 300) },
	{ Free = squishy("Dumpling"), Premium = squishy("Sushi", { "Golden", "Starlit" }) },
	{ Free = nil, Premium = money(100000) },
	{ Free = money(1000), Premium = BOX },
	{ Free = nil, Premium = squishy("Boba Tea", { "Cosmic" }) },
	{ Free = boost("Luck", 120), Premium = boost("Mutation", 600) },
	{ Free = nil, Premium = money(250000) },
	{ Free = squishy("Donut"), Premium = squishy("Boba Tea", { "Rainbow", "Cosmic" }) },
	-- The season exclusive!
	{ Free = money(2500), Premium = squishy("Sprinkle Star Cupcake"), Exclusive = true },
}

function SquishyPass.tierOf(xp)
	return math.min(xp // SquishyPass.XP_PER_TIER, #SquishyPass.Tiers)
end

function SquishyPass.getXp(player)
	return player:GetAttribute("PassXp") or 0
end

function SquishyPass.isPremium(player)
	return player:GetAttribute("PassPremium") == true
end

-- Claimed rewards are saved as "F3,P3,P4" (F = free, P = premium, then the tier)
function SquishyPass.claimKey(tier, premium)
	return (if premium then "P" else "F") .. tier
end

function SquishyPass.isClaimed(player, tier, premium)
	local claimed = "," .. (player:GetAttribute("PassClaimed") or "") .. ","
	return string.find(claimed, "," .. SquishyPass.claimKey(tier, premium) .. ",", 1, true) ~= nil
end

-- Icon and text for showing a reward
function SquishyPass.describe(reward, SquishyTypes, Shop, Format)
	if reward.Type == "Money" then
		return "💰", Format.money(reward.Amount)
	elseif reward.Type == "Squishy" then
		local info = SquishyTypes.ByName[reward.Squishy]
		return info.Icon, SquishyTypes.itemName(reward.Squishy, reward.Mutations)
	elseif reward.Type == "Boost" then
		local prize = Shop.PrizesById[reward.Prize]
		return prize.Icon, prize.Name .. " " .. reward.Duration // 60 .. "m"
	end
	return "📦", "Lucky Box"
end

return SquishyPass
