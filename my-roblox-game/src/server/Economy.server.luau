local Players = game:GetService("Players")

local function setup(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Parent = leaderstats

	local squishies = Instance.new("IntValue")
	squishies.Name = "Squishies"
	squishies.Parent = leaderstats

	leaderstats.Parent = player

	-- Filled with one IntValue per squishy + mutation you've caught
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player
end

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do
	setup(player)
end
