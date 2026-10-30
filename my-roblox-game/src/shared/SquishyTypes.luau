-- Every squishy in the game. Add a new line to List to add a new squishy!
local SquishyTypes = {}

SquishyTypes.EVIL_CHANCE = 0.12

SquishyTypes.Rarities = {
	Common = { Order = 1, Color = Color3.fromRGB(170, 170, 185), Weight = 60, Size = 2.5 },
	Uncommon = { Order = 2, Color = Color3.fromRGB(90, 210, 120), Weight = 25, Size = 3 },
	Rare = { Order = 3, Color = Color3.fromRGB(80, 160, 255), Weight = 10, Size = 3.5 },
	Epic = { Order = 4, Color = Color3.fromRGB(170, 90, 255), Weight = 4, Size = 4 },
	Legendary = { Order = 5, Color = Color3.fromRGB(255, 180, 30), Weight = 1, Size = 5 },
	Evil = { Order = 0, Color = Color3.fromRGB(230, 40, 60), Weight = 0, Size = 3.5 },
}

-- Shape is the model from src/server/SquishyShapes.luau
-- Value is the money you get for catching one
-- Passive is the boost you get for each one you own
SquishyTypes.List = {
	{ Name = "Butter", Rarity = "Common", Shape = "Butter", Icon = "🧈", Color = Color3.fromRGB(255, 225, 110), Value = 5, Passive = "Speed", Boost = 0.5 },
	{ Name = "Potato", Rarity = "Common", Shape = "Potato", Icon = "🥔", Color = Color3.fromRGB(205, 155, 95), Value = 5, Passive = "Strength", Boost = 3 },
	{ Name = "Toast", Rarity = "Common", Shape = "Toast", Icon = "🍞", Color = Color3.fromRGB(255, 225, 165), Value = 6, Passive = "Jump", Boost = 0.3 },
	{ Name = "Egg", Rarity = "Common", Shape = "Egg", Icon = "🥚", Color = Color3.fromRGB(255, 250, 240), Value = 8, Passive = "Size", Boost = 0.01 },
	{ Name = "Cheese", Rarity = "Uncommon", Shape = "Cheese", Icon = "🧀", Color = Color3.fromRGB(255, 205, 60), Value = 25, Passive = "Strength", Boost = 6 },
	{ Name = "Dumpling", Rarity = "Uncommon", Shape = "Dumpling", Icon = "🥟", Color = Color3.fromRGB(250, 245, 235), Value = 30, Passive = "Jump", Boost = 1 },
	{ Name = "Strawberry", Rarity = "Uncommon", Shape = "Strawberry", Icon = "🍓", Color = Color3.fromRGB(255, 80, 100), Value = 30, Passive = "Speed", Boost = 1 },
	{ Name = "Donut", Rarity = "Rare", Shape = "Donut", Icon = "🍩", Color = Color3.fromRGB(255, 150, 190), Value = 90, Passive = "Jump", Boost = 2 },
	{ Name = "Cupcake", Rarity = "Rare", Shape = "Cupcake", Icon = "🧁", Color = Color3.fromRGB(255, 190, 220), Value = 110, Passive = "Speed", Boost = 2 },
	{ Name = "Watermelon", Rarity = "Epic", Shape = "Watermelon", Icon = "🍉", Color = Color3.fromRGB(255, 90, 100), Value = 350, Passive = "Size", Boost = 0.05 },
	{ Name = "Sushi", Rarity = "Epic", Shape = "Sushi", Icon = "🍣", Color = Color3.fromRGB(255, 140, 90), Value = 450, Passive = "Strength", Boost = 25 },
	{ Name = "Boba Tea", Rarity = "Legendary", Shape = "Boba", Icon = "🧋", Color = Color3.fromRGB(245, 215, 170), Value = 2500, Passive = "Speed", Boost = 5 },

	-- Evil squishies hurt you and steal money instead of being collected
	{ Name = "Moldy Toast", Rarity = "Evil", Shape = "MoldyToast", Icon = "🦠", Color = Color3.fromRGB(140, 160, 90), Damage = 25 },
	{ Name = "Angry Chili", Rarity = "Evil", Shape = "Chili", Icon = "🌶️", Color = Color3.fromRGB(230, 30, 30), Damage = 35 },
}

-- Weather gives squishies mutations. Better mutation = more money when caught
SquishyTypes.Mutations = {
	Wet = { Multiplier = 2, Color = Color3.fromRGB(90, 170, 255), Material = Enum.Material.Glass, Tint = Color3.fromRGB(120, 180, 255) },
	Frozen = { Multiplier = 3, Color = Color3.fromRGB(130, 210, 255), Material = Enum.Material.Ice, Tint = Color3.fromRGB(210, 245, 255) },
	Shocked = { Multiplier = 5, Color = Color3.fromRGB(240, 200, 0), Material = Enum.Material.Neon, Tint = Color3.fromRGB(255, 245, 140) },
	Golden = { Multiplier = 10, Color = Color3.fromRGB(255, 170, 0), Material = Enum.Material.Foil, Tint = Color3.fromRGB(255, 200, 50) },
	Rainbow = { Multiplier = 20, Color = Color3.fromRGB(255, 80, 200), Rainbow = true },
	Cosmic = { Multiplier = 50, Color = Color3.fromRGB(140, 70, 255), Material = Enum.Material.ForceField, Tint = Color3.fromRGB(80, 30, 170) },
}

-- Boosts from owned squishies stack up to Max
SquishyTypes.Passives = {
	Speed = { Max = 34, Label = "Speed" },
	Jump = { Max = 25, Label = "Jump" },
	Strength = { Max = 400, Label = "Max HP" },
	Size = { Max = 1.5, Label = "Size", Percent = true },
}

SquishyTypes.ByName = {}
for _, squishy in SquishyTypes.List do
	SquishyTypes.ByName[squishy.Name] = squishy
end

-- Luck makes everything rarer than Common more likely
local function weightOf(rarity, luck)
	if rarity.Order >= 2 then
		return rarity.Weight * luck
	end
	return rarity.Weight
end

local function pickRarity(luck, allowEvil)
	if allowEvil and math.random() < SquishyTypes.EVIL_CHANCE then
		return "Evil"
	end

	local total = 0
	for _, rarity in SquishyTypes.Rarities do
		total += weightOf(rarity, luck)
	end

	local roll = math.random() * total
	for name, rarity in SquishyTypes.Rarities do
		roll -= weightOf(rarity, luck)
		if rarity.Weight > 0 and roll <= 0 then
			return name
		end
	end
	return "Common"
end

-- Rolls in the lobby pass allowEvil = false
function SquishyTypes.pickRandom(luck, allowEvil)
	local rarity = pickRarity(luck or 1, allowEvil ~= false)
	local choices = {}
	for _, squishy in SquishyTypes.List do
		if squishy.Rarity == rarity then
			table.insert(choices, squishy)
		end
	end
	return choices[math.random(#choices)]
end

-- Inventory items are named like "Golden Mochi"
function SquishyTypes.itemName(squishyName, mutationName)
	if mutationName then
		return mutationName .. " " .. squishyName
	end
	return squishyName
end

function SquishyTypes.colorFor(squishy, mutationName)
	local mutation = SquishyTypes.Mutations[mutationName]
	if mutation and mutation.Tint then
		return squishy.Color:Lerp(mutation.Tint, 0.6)
	end
	return squishy.Color
end

-- Turns "Golden Butter" back into the Butter squishy and "Golden"
function SquishyTypes.parseItem(itemName)
	for mutationName in SquishyTypes.Mutations do
		local prefix = mutationName .. " "
		if string.sub(itemName, 1, #prefix) == prefix then
			return SquishyTypes.ByName[string.sub(itemName, #prefix + 1)], mutationName
		end
	end
	return SquishyTypes.ByName[itemName], nil
end

-- Chance that a falling squishy is this one, with no luck boosts
function SquishyTypes.chanceOf(squishy)
	local sameRarity = 0
	for _, other in SquishyTypes.List do
		if other.Rarity == squishy.Rarity then
			sameRarity += 1
		end
	end
	if squishy.Rarity == "Evil" then
		return SquishyTypes.EVIL_CHANCE / sameRarity
	end

	local total = 0
	for _, rarity in SquishyTypes.Rarities do
		total += rarity.Weight
	end
	return (1 - SquishyTypes.EVIL_CHANCE) * SquishyTypes.Rarities[squishy.Rarity].Weight / total / sameRarity
end

-- 0.02 -> "1 in 50"
function SquishyTypes.formatChance(chance)
	return "1 in " .. math.max(1, math.floor(1 / chance + 0.5))
end

-- Money for selling one, before boosts
function SquishyTypes.valueOf(squishy, mutationName)
	local mutation = SquishyTypes.Mutations[mutationName]
	return squishy.Value * (if mutation then mutation.Multiplier else 1)
end

function SquishyTypes.formatBoost(passiveName, amount)
	local passive = SquishyTypes.Passives[passiveName]
	if passive.Percent then
		return "+" .. math.floor(amount * 100 + 0.5) .. "% " .. passive.Label
	end
	return "+" .. string.format("%g", amount) .. " " .. passive.Label
end

-- Total boosts from a player's Inventory folder, like { Speed = 4, Jump = 1, ... }
function SquishyTypes.getPassives(inventory)
	local totals = {}
	for name in SquishyTypes.Passives do
		totals[name] = 0
	end
	for _, count in inventory:GetChildren() do
		local squishy = SquishyTypes.ByName[count:GetAttribute("Squishy")]
		if squishy and squishy.Passive then
			totals[squishy.Passive] += squishy.Boost * count.Value
		end
	end
	for name, passive in SquishyTypes.Passives do
		totals[name] = math.min(totals[name], passive.Max)
	end
	return totals
end

return SquishyTypes
