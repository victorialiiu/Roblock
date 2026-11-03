-- Gamepasses and the Lucky Box, shared by the server and the UI.
--
-- To set them up for real: make each gamepass (and a Developer Product for the Lucky Box) on the
-- Roblox Creator Dashboard, then paste the ids here. While an id is 0, Studio gives it out for free
-- so you can test it. In a live game it just can't be bought yet.
local Passes = {}

Passes.List = {
	{ Id = "AutoSell", Name = "Auto Sell", Icon = "💸", PassId = 0, Description = "Commons and Uncommons sell the moment you catch them. Full bag? Everything sells." },
	{ Id = "Magnet", Name = "Squishy Magnet", Icon = "🧲", PassId = 0, Description = "Nearby squishies fly right to you" },
	{ Id = "Pet", Name = "Squishy Buddy", Icon = "🐣", PassId = 0, Description = "A pet that follows you around: x1.5 money and a 15% chance to catch double" },
}

Passes.LuckyBox = {
	Name = "Lucky Box",
	Icon = "📦",
	ProductId = 0,
	-- Roblox rules: anything random you pay Robux for has to show its odds before you buy.
	-- Keep this matching LuckyBox.luau (Epic weight 4, Legendary weight 1, MutationChance below)
	Description = "Epic 80% • Legendary 20% • 50% chance of each bonus attribute (up to 3)",
	-- Chance of getting each extra attribute
	MutationChance = 0.5,
}

-- Pet numbers
Passes.PET_MONEY = 1.5
Passes.PET_DOUBLE_CHANCE = 0.15
-- How far the magnet reaches
Passes.MAGNET_RANGE = 30

Passes.ById = {}
for _, pass in Passes.List do
	Passes.ById[pass.Id] = pass
end

-- The server sets these attributes when you own a pass
function Passes.owns(player, passId)
	return player:GetAttribute("Pass_" .. passId) == true
end

return Passes
