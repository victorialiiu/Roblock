local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Weather = require(ReplicatedStorage.Shared.Weather)
local Shop = require(ReplicatedStorage.Shared.Shop)
local makeSquishy = require(script.Parent.MakeSquishy)

local SPAWN_DELAY = 0.25
local SPAWN_RADIUS = 60

local currentEvent = ReplicatedStorage:WaitForChild("CurrentEvent")

-- Mutations come from the current weather, or a random one with upgrades/boosts
local function pickMutation(squishy, player)
	if not squishy.Value then
		return nil
	end
	local weather = Weather.ByName[currentEvent.Value]
	if math.random() >= Shop.getMutationChance(player, weather ~= nil) then
		return nil
	end
	return (weather or Weather.pickRandom()).Mutation
end

-- Rain around a random player, using that player's luck
while true do
	local players = Players:GetPlayers()
	if #players > 0 then
		local player = players[math.random(#players)]
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local offset = Vector3.new(
				math.random(-SPAWN_RADIUS, SPAWN_RADIUS),
				70,
				math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
			)
			local squishy = SquishyTypes.pickRandom(Shop.getLuck(player))
			makeSquishy(squishy, root.Position + offset, pickMutation(squishy, player))
		end
	end
	task.wait(SPAWN_DELAY)
end
