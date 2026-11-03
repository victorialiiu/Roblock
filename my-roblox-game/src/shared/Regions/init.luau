-- The hunting map (World.luau) is rings of regions around the spawn pad. The farther out you go, the rarer the
-- squishies and the more evil ones. Each region also has its own attribute and its own terrain.
--
-- Every region is its own file in this folder. To add one, copy a region file, rename it, and give
-- it an Order. Rings are laid out by Order, each one Width studs wide. The last ring goes on forever.
--
-- What goes in a region file:
--   Name, Icon, Color (for signs and the HUD)
--   Order, Width
--   Luck: multiplies the player's luck while they're in the region
--   EvilChance: chance a falling squishy is evil
--   Mutation: optional attribute that only falls here
--   Squishies: names of every squishy that can fall here (include at least one Evil one)
--   Unlock: optional { Rebirths = 1, Cost = 50000 }. You need that many rebirths, then pay Cost once
--     at the gate to get in. Leave it out and anyone can walk in. Gates are in RegionGates.server.luau
--   Terrain: how the ground looks. See src/server/Terrain.server.luau
local World = require(script.Parent.World)

local Regions = {}

-- Chance a squishy falling in a region gets that region's attribute
Regions.MUTATION_CHANCE = 0.1

Regions.List = {}
for _, module in script:GetChildren() do
	if module:IsA("ModuleScript") then
		table.insert(Regions.List, require(module))
	end
end
table.sort(Regions.List, function(a, b)
	return a.Order < b.Order
end)

Regions.ByName = {}
local inner = World.SPAWN_RADIUS
for i, region in Regions.List do
	region.Inner = inner
	region.Outer = if i == #Regions.List then math.huge else inner + region.Width
	inner = region.Outer

	region.Allows = {}
	for _, name in region.Squishies do
		region.Allows[name] = true
	end
	Regions.ByName[region.Name] = region
end

function Regions.distanceOf(position)
	return World.distanceOf(position)
end

---------------------------------------------------------------- Unlocking

-- Paid-for regions are saved as "Bakery Hills,Candy Coast"
function Regions.hasPaid(player, region)
	local paid = "," .. (player:GetAttribute("UnlockedRegions") or "") .. ","
	return string.find(paid, "," .. region.Name .. ",", 1, true) ~= nil
end

function Regions.hasRebirths(player, region)
	return (player:GetAttribute("Rebirths") or 0) >= (region.Unlock and region.Unlock.Rebirths or 0)
end

function Regions.canEnter(player, region)
	if not region.Unlock then
		return true
	end
	return Regions.hasRebirths(player, region) and (region.Unlock.Cost == 0 or Regions.hasPaid(player, region))
end

---------------------------------------------------------------- Finding regions

-- nil in the lobby, on the spawn pad, or off the map
function Regions.at(position)
	if not World.contains(position) or World.inSpawn(position) then
		return nil
	end
	local distance = Regions.distanceOf(position)
	for _, region in Regions.List do
		if distance >= region.Inner and distance < region.Outer then
			return region
		end
	end
	return nil
end

return Regions
