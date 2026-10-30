local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Shop = require(ReplicatedStorage.Shared.Shop)

local BASE_SPEED = 16
local BASE_JUMP = 7.2
local BASE_HEALTH = 100
local SUPER_JUMP = 15

local function apply(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local inventory = player:FindFirstChild("Inventory")
	if not humanoid or not inventory then
		return
	end

	local boosts = SquishyTypes.getPassives(inventory)
	local speed = BASE_SPEED + boosts.Speed + 2 * Shop.getLevel(player, "Speed")
	if Shop.boostActive(player, "Speed") then
		speed *= 2
	end
	humanoid.WalkSpeed = speed

	humanoid.UseJumpPower = false
	humanoid.JumpHeight = BASE_JUMP + boosts.Jump + (if Shop.boostActive(player, "Jump") then SUPER_JUMP else 0)

	local healthPercent = humanoid.Health / humanoid.MaxHealth
	humanoid.MaxHealth = BASE_HEALTH + boosts.Strength
	humanoid.Health = humanoid.MaxHealth * healthPercent

	local scale = 1 + boosts.Size
	if math.abs(character:GetScale() - scale) > 0.001 then
		character:ScaleTo(scale)
	end
end

local function setup(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		apply(player)
	end)

	local inventory = player:WaitForChild("Inventory")
	local function watch(count)
		count.Changed:Connect(function()
			apply(player)
		end)
		apply(player)
	end
	inventory.ChildAdded:Connect(watch)
	for _, count in inventory:GetChildren() do
		watch(count)
	end

	-- Re-apply when an upgrade is bought, a boost starts, and when that boost runs out
	player.AttributeChanged:Connect(function(name)
		apply(player)
		if string.sub(name, 1, 6) == "Boost_" then
			task.delay(Shop.boostTimeLeft(player, string.sub(name, 7)) + 0.1, apply, player)
		end
	end)
end

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do
	task.spawn(setup, player)
end
