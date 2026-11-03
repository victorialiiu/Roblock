local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Weather = require(ReplicatedStorage.Shared.Weather)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Regions = require(ReplicatedStorage.Shared.Regions)
local World = require(ReplicatedStorage.Shared.World)
local makeSquishy = require(script.Parent.MakeSquishy).spawn

local SPAWN_DELAY = 0.4
local SPAWN_RADIUS = 60

local currentEvent = ReplicatedStorage:WaitForChild("CurrentEvent")

-- Attributes stack: each weather that's on can add its own, and the region can add one too
local function pickMutations(squishy, player, region)
	local mutations = {}
	if not squishy.Value then
		return mutations
	end

	local weathers = Weather.parse(currentEvent.Value)
	if #weathers > 0 then
		for _, weather in weathers do
			if math.random() < Shop.getMutationChance(player, true) then
				table.insert(mutations, weather.Mutation)
			end
		end
	elseif math.random() < Shop.getMutationChance(player, false) then
		table.insert(mutations, Weather.pickRandom().Mutation)
	end

	if region.Mutation and math.random() < Regions.MUTATION_CHANCE then
		table.insert(mutations, region.Mutation)
	end
	return mutations
end

-- Players out on the hunting map (not in the lobby)
local function hunters()
	local list = {}
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and World.contains(root.Position) then
			table.insert(list, player)
		end
	end
	return list
end

-- Rain around a random hunter, using that player's luck and the region the squishy lands in
while true do
	local players = hunters()
	if #players > 0 then
		local player = players[math.random(#players)]
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			-- Try a few spots so nothing lands on the spawn pad
			for _ = 1, 5 do
				local position = root.Position
					+ Vector3.new(math.random(-SPAWN_RADIUS, SPAWN_RADIUS), 70, math.random(-SPAWN_RADIUS, SPAWN_RADIUS))
				local region = Regions.at(position)
				if region then
					local squishy = SquishyTypes.pickRandom(Shop.getLuck(player) * region.Luck, true, region)
					makeSquishy(squishy, position, pickMutations(squishy, player, region), region)
					break
				end
			end
		end
	end
	task.wait(SPAWN_DELAY)
end
