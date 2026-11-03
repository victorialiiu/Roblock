-- Squishy Pass: starting each season, buying premium, and claiming tier rewards.
-- Progress (PassSeason, PassXp, PassClaimed) is saved by Economy.server.luau
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SquishyPass = require(ReplicatedStorage.Shared.SquishyPass)
local InventoryService = require(script.Parent.InventoryService)
local notify = require(script.Parent.Notify)
local openBox = require(script.Parent.LuckyBox)

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local claimRemote = Instance.new("RemoteFunction")
claimRemote.Name = "ClaimPassTier"
claimRemote.Parent = remotes

local buyPremiumRemote = Instance.new("RemoteEvent")
buyPremiumRemote.Name = "BuyPassPremium"
buyPremiumRemote.Parent = remotes

local function give(player, reward)
	if reward.Type == "Money" then
		-- Not "earned", so it doesn't count on the leaderboards
		player.leaderstats.Money.Value += reward.Amount
	elseif reward.Type == "Squishy" then
		InventoryService.add(player, reward.Squishy, reward.Mutations or {})
	elseif reward.Type == "Boost" then
		local key = "Boost_" .. reward.Prize
		local now = workspace:GetServerTimeNow()
		player:SetAttribute(key, math.max(now, player:GetAttribute(key) or 0) + reward.Duration)
	elseif reward.Type == "Box" then
		openBox(player)
	end
end

claimRemote.OnServerInvoke = function(player, tier, premium)
	local tierInfo = SquishyPass.Tiers[tier]
	premium = premium == true
	if typeof(tier) ~= "number" or not tierInfo or not player:FindFirstChild("leaderstats") then
		return false
	end
	local reward = if premium then tierInfo.Premium else tierInfo.Free
	if not reward or SquishyPass.tierOf(SquishyPass.getXp(player)) < tier or SquishyPass.isClaimed(player, tier, premium) then
		return false
	end
	if premium and not SquishyPass.isPremium(player) then
		return false
	end

	local claimed = player:GetAttribute("PassClaimed") or ""
	player:SetAttribute("PassClaimed", (if claimed == "" then "" else claimed .. ",") .. SquishyPass.claimKey(tier, premium))
	give(player, reward)
	return true
end

---------------------------------------------------------------- Premium

local function grantPremium(player)
	player:SetAttribute("PassPremium", true)
end

buyPremiumRemote.OnServerEvent:Connect(function(player)
	if SquishyPass.isPremium(player) then
		return
	end
	if SquishyPass.PREMIUM_PASS_ID ~= 0 then
		MarketplaceService:PromptGamePassPurchase(player, SquishyPass.PREMIUM_PASS_ID)
	elseif RunService:IsStudio() then
		grantPremium(player)
		notify(player, "🎟️ Premium Squishy Pass unlocked (free while testing in Studio)")
	else
		notify(player, "The Premium Squishy Pass isn't for sale yet!")
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if purchased and gamePassId == SquishyPass.PREMIUM_PASS_ID and gamePassId ~= 0 then
		grantPremium(player)
		notify(player, "🎟️ Premium Squishy Pass unlocked! Go claim your rewards 💖")
	end
end)

---------------------------------------------------------------- New players and new seasons

local function setup(player)
	-- Wait for Economy.server.luau to load their save
	if not player:WaitForChild("Inventory", 60) then
		return
	end
	if player:GetAttribute("PassSeason") ~= SquishyPass.SEASON then
		player:SetAttribute("PassXp", 0)
		player:SetAttribute("PassClaimed", "")
		player:SetAttribute("PassSeason", SquishyPass.SEASON)
	end
	if SquishyPass.PREMIUM_PASS_ID ~= 0 then
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, SquishyPass.PREMIUM_PASS_ID)
		if ok and owns then
			grantPremium(player)
		end
	end
end

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do
	task.spawn(setup, player)
end
