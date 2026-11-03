-- Squishy Pass XP. MakeSquishy calls addCatchXp when someone catches a squishy.
-- Settings and rewards are in src/shared/SquishyPass.luau, claiming is in SquishyPass.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SquishyPass = require(ReplicatedStorage.Shared.SquishyPass)
local notify = require(script.Parent.Notify)

local SquishyPassService = {}

function SquishyPassService.addXp(player, amount)
	if player:GetAttribute("PassSeason") ~= SquishyPass.SEASON then
		-- Their save hasn't loaded yet
		return
	end
	if SquishyPass.isPremium(player) then
		amount *= SquishyPass.PREMIUM_XP
	end
	local before = SquishyPass.getXp(player)
	local after = before + math.max(1, math.floor(amount))
	player:SetAttribute("PassXp", after)

	local tier = SquishyPass.tierOf(after)
	if tier > SquishyPass.tierOf(before) then
		notify(player, "🎟️ Squishy Pass tier " .. tier .. " unlocked! Claim your rewards")
	end
end

function SquishyPassService.addCatchXp(player, squishy, mutations, amount)
	local xp = (SquishyPass.XP_PER_CATCH[squishy.Rarity] or 1) + #mutations * SquishyPass.XP_PER_ATTRIBUTE
	SquishyPassService.addXp(player, xp * (amount or 1))
end

return SquishyPassService
