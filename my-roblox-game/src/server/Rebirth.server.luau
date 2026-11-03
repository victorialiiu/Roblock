-- Rebirth: give up your money and upgrades for a money multiplier, more pedestals,
-- more equip slots, and a bigger bag. You keep all your squishies. Numbers are in src/shared/Shop.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = require(ReplicatedStorage.Shared.Shop)
local Format = require(ReplicatedStorage.Shared.Format)
local InventoryService = require(script.Parent.InventoryService)
local notify = require(script.Parent.Notify)

local rebirthRemote = Instance.new("RemoteFunction")
rebirthRemote.Name = "Rebirth"
rebirthRemote.Parent = ReplicatedStorage:WaitForChild("Remotes")

rebirthRemote.OnServerInvoke = function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirths = Shop.getRebirths(player)
	local cost = Shop.rebirthCost(rebirths)
	if not leaderstats or leaderstats.Money.Value < cost then
		return false
	end

	leaderstats.Money.Value = 0
	for _, upgrade in Shop.Upgrades do
		player:SetAttribute("Upgrade_" .. upgrade.Id, nil)
	end
	player:SetAttribute("Rebirths", rebirths + 1)
	InventoryService.fixEquipped(player)

	notify(player, "🌟 Rebirth " .. rebirths + 1 .. "! Next one costs " .. Format.money(Shop.rebirthCost(rebirths + 1)))
	return true
end
