-- Opens a Lucky Box for a player: always Epic or Legendary, often with attributes.
-- It skips the bag limit since it was paid for. Used by the Passes shop and the Squishy Pass
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Passes = require(ReplicatedStorage.Shared.Passes)
local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Weather = require(ReplicatedStorage.Shared.Weather)
local InventoryService = require(script.Parent.InventoryService)
local notify = require(script.Parent.Notify)

return function(player)
	local choices, total = {}, 0
	for _, squishy in SquishyTypes.List do
		local rarity = SquishyTypes.Rarities[squishy.Rarity]
		if squishy.Value and rarity.Order >= 4 and rarity.Weight > 0 then
			table.insert(choices, squishy)
			total += rarity.Weight
		end
	end
	local roll = math.random() * total
	local squishy = choices[1]
	for _, choice in choices do
		roll -= SquishyTypes.Rarities[choice.Rarity].Weight
		if roll <= 0 then
			squishy = choice
			break
		end
	end

	local mutations = {}
	while #mutations < 3 and math.random() < Passes.LuckyBox.MutationChance do
		table.insert(mutations, Weather.pickRandom().Mutation)
	end

	local itemName = InventoryService.add(player, squishy.Name, mutations)
	notify(player, Passes.LuckyBox.Icon .. " You got " .. itemName .. "!")
	return itemName
end
