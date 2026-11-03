-- Every squishy in the game. Add a new line to List to add a new squishy!
--
-- Squishies are modular: each one is a base archetype (Butter, Donut...) plus any number of
-- attributes stacked on top (Wet, Shocked, Rainbow...). "Wet Shocked Butter" is Butter with two attributes.
local SquishyTypes = {}

SquishyTypes.EVIL_CHANCE = 0.12
-- Each attribute on an equipped squishy makes its stat boost this much stronger
SquishyTypes.ATTRIBUTE_BOOST = 0.25

SquishyTypes.Rarities = {
	Common = { Order = 1, Color = Color3.fromRGB(170, 170, 185), Weight = 60, Size = 2.5 },
	Uncommon = { Order = 2, Color = Color3.fromRGB(90, 210, 120), Weight = 25, Size = 3 },
	Rare = { Order = 3, Color = Color3.fromRGB(80, 160, 255), Weight = 10, Size = 3.5 },
	Epic = { Order = 4, Color = Color3.fromRGB(170, 90, 255), Weight = 4, Size = 4 },
	Legendary = { Order = 5, Color = Color3.fromRGB(255, 180, 30), Weight = 1, Size = 5 },
	Evil = { Order = 0, Color = Color3.fromRGB(230, 40, 60), Weight = 0, Size = 3.5 },
	-- Never falls. Only from leaderboard prizes and the Squishy Pass
	Exclusive = { Order = 6, Color = Color3.fromRGB(255, 110, 230), Weight = 0, Size = 5 },
}

-- Shape is the model from src/server/SquishyShapes.luau
-- Value is the money you get for selling one
-- Passive is the stat boost you get for each one you equip. Squishies with no Passive are just for selling
SquishyTypes.List = {
	{ Name = "Butter", Rarity = "Common", Shape = "Butter", Icon = "🧈", Color = Color3.fromRGB(255, 225, 110), Value = 5 },
	{ Name = "Potato", Rarity = "Common", Shape = "Potato", Icon = "🥔", Color = Color3.fromRGB(205, 155, 95), Value = 5 },
	{ Name = "Toast", Rarity = "Common", Shape = "Toast", Icon = "🍞", Color = Color3.fromRGB(255, 225, 165), Value = 6 },
	{ Name = "Egg", Rarity = "Common", Shape = "Egg", Icon = "🥚", Color = Color3.fromRGB(255, 250, 240), Value = 8 },
	{ Name = "Cheese", Rarity = "Uncommon", Shape = "Cheese", Icon = "🧀", Color = Color3.fromRGB(255, 205, 60), Value = 25, Passive = "Strength", Boost = 15 },
	{ Name = "Dumpling", Rarity = "Uncommon", Shape = "Dumpling", Icon = "🥟", Color = Color3.fromRGB(250, 245, 235), Value = 30, Passive = "Jump", Boost = 2 },
	{ Name = "Strawberry", Rarity = "Uncommon", Shape = "Strawberry", Icon = "🍓", Color = Color3.fromRGB(255, 80, 100), Value = 30, Passive = "Speed", Boost = 2 },
	{ Name = "Donut", Rarity = "Rare", Shape = "Donut", Icon = "🍩", Color = Color3.fromRGB(255, 150, 190), Value = 90, Passive = "Luck", Boost = 0.15 },
	{ Name = "Cupcake", Rarity = "Rare", Shape = "Cupcake", Icon = "🧁", Color = Color3.fromRGB(255, 190, 220), Value = 110, Passive = "Money", Boost = 0.15 },
	{ Name = "Watermelon", Rarity = "Epic", Shape = "Watermelon", Icon = "🍉", Color = Color3.fromRGB(255, 90, 100), Value = 350, Passive = "Speed", Boost = 5 },
	{ Name = "Sushi", Rarity = "Epic", Shape = "Sushi", Icon = "🍣", Color = Color3.fromRGB(255, 140, 90), Value = 450, Passive = "Money", Boost = 0.4 },
	{ Name = "Boba Tea", Rarity = "Legendary", Shape = "Boba", Icon = "🧋", Color = Color3.fromRGB(245, 215, 170), Value = 2500, Passive = "Luck", Boost = 0.75 },

	-- Exclusives (names and looks are placeholders, TBD!)
	-- Weekly leaderboard #1
	{ Name = "Crowned Dumpling", Rarity = "Exclusive", Shape = "Dumpling", Icon = "👑", Color = Color3.fromRGB(255, 215, 90), Value = 25000, Passive = "Money", Boost = 0.75 },
	-- Monthly leaderboard #1
	{ Name = "Royal Boba", Rarity = "Exclusive", Shape = "Boba", Icon = "💎", Color = Color3.fromRGB(190, 140, 255), Value = 100000, Passive = "Luck", Boost = 1.5 },
	-- Squishy Pass Season 1 final premium reward
	{ Name = "Sprinkle Star Cupcake", Rarity = "Exclusive", Shape = "Cupcake", Icon = "🌟", Color = Color3.fromRGB(255, 160, 230), Value = 50000, Passive = "Speed", Boost = 10 },

	-- Evil squishies hurt you and steal money instead of being collected
	{ Name = "Moldy Toast", Rarity = "Evil", Shape = "MoldyToast", Icon = "🦠", Color = Color3.fromRGB(140, 160, 90), Damage = 25 },
	{ Name = "Angry Chili", Rarity = "Evil", Shape = "Chili", Icon = "🌶️", Color = Color3.fromRGB(230, 30, 30), Damage = 35 },
}

-- Attributes (also called mutations) come from weather and regions. They stack, and their
-- multipliers multiply: Wet x2 + Shocked x5 = x10. Order is where it goes in the name
SquishyTypes.Mutations = {
	Toasted = { Order = 1, Multiplier = 3, Color = Color3.fromRGB(200, 130, 60), Material = Enum.Material.Sand, Tint = Color3.fromRGB(170, 100, 40) },
	Sticky = { Order = 2, Multiplier = 4, Color = Color3.fromRGB(255, 130, 200), Material = Enum.Material.Glass, Tint = Color3.fromRGB(255, 150, 220) },
	Wet = { Order = 3, Multiplier = 2, Color = Color3.fromRGB(90, 170, 255), Material = Enum.Material.Glass, Tint = Color3.fromRGB(120, 180, 255) },
	Frozen = { Order = 4, Multiplier = 3, Color = Color3.fromRGB(130, 210, 255), Material = Enum.Material.Ice, Tint = Color3.fromRGB(210, 245, 255) },
	Shocked = { Order = 5, Multiplier = 5, Color = Color3.fromRGB(240, 200, 0), Material = Enum.Material.Neon, Tint = Color3.fromRGB(255, 245, 140) },
	Starlit = { Order = 6, Multiplier = 8, Color = Color3.fromRGB(190, 170, 255), Material = Enum.Material.Neon, Tint = Color3.fromRGB(200, 190, 255) },
	Golden = { Order = 7, Multiplier = 10, Color = Color3.fromRGB(255, 170, 0), Material = Enum.Material.Foil, Tint = Color3.fromRGB(255, 200, 50) },
	Rainbow = { Order = 8, Multiplier = 20, Color = Color3.fromRGB(255, 80, 200), Rainbow = true },
	Cosmic = { Order = 9, Multiplier = 50, Color = Color3.fromRGB(140, 70, 255), Material = Enum.Material.ForceField, Tint = Color3.fromRGB(80, 30, 170) },
}

-- Boosts from equipped squishies stack up to Max
SquishyTypes.Passives = {
	Speed = { Max = 34, Label = "Speed" },
	Jump = { Max = 25, Label = "Jump" },
	Strength = { Max = 400, Label = "Max HP" },
	Luck = { Max = 3, Label = "Luck", Percent = true },
	Money = { Max = 3, Label = "Money", Percent = true },
}

SquishyTypes.ByName = {}
for _, squishy in SquishyTypes.List do
	SquishyTypes.ByName[squishy.Name] = squishy
end

---------------------------------------------------------------- Attributes

-- Puts attribute names in name order and drops repeats and unknown ones
function SquishyTypes.sortMutations(mutations)
	local seen = {}
	local sorted = {}
	for _, name in mutations or {} do
		if SquishyTypes.Mutations[name] and not seen[name] then
			seen[name] = true
			table.insert(sorted, name)
		end
	end
	table.sort(sorted, function(a, b)
		return SquishyTypes.Mutations[a].Order < SquishyTypes.Mutations[b].Order
	end)
	return sorted
end

-- Inventory items store their attributes as "Wet,Shocked"
function SquishyTypes.joinMutations(mutations)
	local sorted = SquishyTypes.sortMutations(mutations)
	return if #sorted > 0 then table.concat(sorted, ",") else nil
end

function SquishyTypes.splitMutations(text)
	if not text or text == "" then
		return {}
	end
	return SquishyTypes.sortMutations(string.split(text, ","))
end

-- The attribute with the biggest multiplier, used for colors
function SquishyTypes.mainMutation(mutations)
	local best, bestName = nil, nil
	for _, name in mutations or {} do
		local mutation = SquishyTypes.Mutations[name]
		if mutation and (not best or mutation.Multiplier > best.Multiplier) then
			best, bestName = mutation, name
		end
	end
	return best, bestName
end

function SquishyTypes.multiplierOf(mutations)
	local multiplier = 1
	for _, name in mutations or {} do
		local mutation = SquishyTypes.Mutations[name]
		if mutation then
			multiplier *= mutation.Multiplier
		end
	end
	return multiplier
end

function SquishyTypes.hasRainbow(mutations)
	for _, name in mutations or {} do
		if SquishyTypes.Mutations[name] and SquishyTypes.Mutations[name].Rainbow then
			return true
		end
	end
	return false
end

-- "Wet + Shocked x10"
function SquishyTypes.formatMutations(mutations)
	if #mutations == 0 then
		return ""
	end
	return table.concat(mutations, " + ") .. " x" .. SquishyTypes.multiplierOf(mutations)
end

---------------------------------------------------------------- Picking random squishies

-- region comes from Regions.luau. Without one, every squishy can show up
local function candidates(rarityName, region)
	local list = {}
	for _, squishy in SquishyTypes.List do
		if squishy.Rarity == rarityName and (not region or region.Allows[squishy.Name]) then
			table.insert(list, squishy)
		end
	end
	return list
end

-- Luck makes everything rarer than Common more likely
local function weightOf(rarity, luck)
	if rarity.Order >= 2 then
		return rarity.Weight * luck
	end
	return rarity.Weight
end

local function rarityWeights(luck, region)
	local weights = {}
	local total = 0
	for name, rarity in SquishyTypes.Rarities do
		if rarity.Weight > 0 and #candidates(name, region) > 0 then
			weights[name] = weightOf(rarity, luck)
			total += weights[name]
		end
	end
	return weights, total
end

local function pickRarity(luck, region)
	local weights, total = rarityWeights(luck, region)
	local roll = math.random() * total
	for name, weight in weights do
		roll -= weight
		if roll <= 0 then
			return name
		end
	end
	return next(weights) or "Common"
end

local function evilChanceIn(region)
	return if region then region.EvilChance else SquishyTypes.EVIL_CHANCE
end

-- Rolls in the lobby pass allowEvil = false
function SquishyTypes.pickRandom(luck, allowEvil, region)
	local rarity
	if allowEvil ~= false and math.random() < evilChanceIn(region) and #candidates("Evil", region) > 0 then
		rarity = "Evil"
	else
		rarity = pickRarity(luck or 1, region)
	end
	local choices = candidates(rarity, region)
	return choices[math.random(#choices)]
end

-- Chance that a falling squishy is this one, with no luck boosts
function SquishyTypes.chanceOf(squishy, region)
	if region and not region.Allows[squishy.Name] then
		region = nil
	end
	local sameRarity = #candidates(squishy.Rarity, region)
	local evilChance = evilChanceIn(region)
	if squishy.Rarity == "Evil" then
		return evilChance / sameRarity
	end

	local weights, total = rarityWeights(1, region)
	return (1 - evilChance) * weights[squishy.Rarity] / total / sameRarity
end

-- 0.02 -> "1 in 50"
function SquishyTypes.formatChance(chance)
	return "1 in " .. math.max(1, math.floor(1 / chance + 0.5))
end

---------------------------------------------------------------- Items

-- Inventory items are named like "Wet Shocked Butter"
function SquishyTypes.itemName(squishyName, mutations)
	local sorted = SquishyTypes.sortMutations(mutations)
	table.insert(sorted, squishyName)
	return table.concat(sorted, " ")
end

-- Turns "Wet Shocked Butter" back into the Butter squishy and { "Wet", "Shocked" }
function SquishyTypes.parseItem(itemName)
	local mutations = {}
	local rest = itemName
	local found = true
	while found do
		found = false
		for mutationName in SquishyTypes.Mutations do
			local prefix = mutationName .. " "
			if string.sub(rest, 1, #prefix) == prefix then
				table.insert(mutations, mutationName)
				rest = string.sub(rest, #prefix + 1)
				found = true
				break
			end
		end
	end
	return SquishyTypes.ByName[rest], SquishyTypes.sortMutations(mutations)
end

function SquishyTypes.colorFor(squishy, mutations)
	local mutation = SquishyTypes.mainMutation(mutations)
	if mutation and mutation.Tint then
		return squishy.Color:Lerp(mutation.Tint, 0.6)
	end
	return squishy.Color
end

-- Color for name tags and inventory cards
function SquishyTypes.highlightFor(squishy, mutations)
	local mutation = SquishyTypes.mainMutation(mutations)
	return if mutation then mutation.Color else SquishyTypes.Rarities[squishy.Rarity].Color
end

-- Money for selling one, before boosts
function SquishyTypes.valueOf(squishy, mutations)
	return squishy.Value * SquishyTypes.multiplierOf(mutations)
end

-- Stat boost for equipping one of these
function SquishyTypes.boostOf(squishy, mutations)
	if not squishy.Passive then
		return 0
	end
	return squishy.Boost * (1 + SquishyTypes.ATTRIBUTE_BOOST * #(mutations or {}))
end

function SquishyTypes.formatBoost(passiveName, amount)
	local passive = SquishyTypes.Passives[passiveName]
	if passive.Percent then
		return "+" .. math.floor(amount * 100 + 0.5) .. "% " .. passive.Label
	end
	return "+" .. string.format("%g", math.floor(amount * 10 + 0.5) / 10) .. " " .. passive.Label
end

-- The squishy and attributes of one IntValue in an Inventory folder
function SquishyTypes.describe(count)
	return SquishyTypes.ByName[count:GetAttribute("Squishy")], SquishyTypes.splitMutations(count:GetAttribute("Mutations"))
end

-- How many of an inventory item aren't equipped or on a pedestal (so you can sell or trade them)
function SquishyTypes.freeCount(count)
	return count.Value - (count:GetAttribute("Equipped") or 0) - (count:GetAttribute("Showcased") or 0)
end

-- Total boosts from equipped squishies in an Inventory folder, like { Speed = 4, Luck = 0.3, ... }
function SquishyTypes.getPassives(inventory)
	local totals = {}
	for name in SquishyTypes.Passives do
		totals[name] = 0
	end
	for _, count in if inventory then inventory:GetChildren() else {} do
		local squishy, mutations = SquishyTypes.describe(count)
		local equipped = count:GetAttribute("Equipped") or 0
		if squishy and squishy.Passive and equipped > 0 then
			totals[squishy.Passive] += SquishyTypes.boostOf(squishy, mutations) * equipped
		end
	end
	for name, passive in SquishyTypes.Passives do
		totals[name] = math.min(totals[name], passive.Max)
	end
	return totals
end

return SquishyTypes
