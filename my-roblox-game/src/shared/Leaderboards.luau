-- Leaderboard settings, shared by the server and the UI.
-- Players are ranked by money EARNED (selling + base income) during each period, not money held,
-- so spending never pushes you down. Every period resets on its own at midnight UTC.
local Leaderboards = {}

Leaderboards.STAT_NAME = "Money Earned"
-- How many players show on each board
Leaderboards.TOP = 25
-- How often the server adds earnings and refreshes the boards (seconds)
Leaderboards.REFRESH_TIME = 60

Leaderboards.Periods = {
	{ Id = "Daily", Name = "Today", Icon = "☀️" },
	{ Id = "Weekly", Name = "This Week", Icon = "📅" },
	{ Id = "Monthly", Name = "This Month", Icon = "🗓️" },
	{ Id = "AllTime", Name = "All Time", Icon = "🏆" },
}

-- Overhead tags for the top 3 (TBD: swap for the real designs). A player shows their best one,
-- and the boards earlier in Periods win ties, so a weekly #1 beats a daily #1
Leaderboards.TagOrder = { "Monthly", "Weekly", "AllTime", "Daily" }
Leaderboards.Tags = {
	{ Text = "👑 #1", Color = Color3.fromRGB(255, 205, 50) },
	{ Text = "🥈 #2", Color = Color3.fromRGB(210, 220, 235) },
	{ Text = "🥉 #3", Color = Color3.fromRGB(230, 160, 100) },
}

-- Exclusive squishies for finishing on top when a period ends (TBD: final squishies).
-- Places = how many of the top players get it
Leaderboards.Prizes = {
	Weekly = { Squishy = "Crowned Dumpling", Places = 1 },
	Monthly = { Squishy = "Royal Boba", Places = 1 },
}

Leaderboards.PeriodsById = {}
for _, period in Leaderboards.Periods do
	Leaderboards.PeriodsById[period.Id] = period
end

local DAY = 86400
local WEEK = 7 * DAY
-- Jan 1 1970 was a Thursday, so shift by 3 days to make weeks start on Monday
local WEEK_SHIFT = 3 * DAY

local function utc(time)
	return DateTime.fromUnixTimestamp(time):ToUniversalTime()
end

local function monthStart(time, monthsLater)
	local date = utc(time)
	local month = date.Month - 1 + monthsLater
	return DateTime.fromUniversalTime(date.Year + month // 12, month % 12 + 1, 1).UnixTimestamp
end

-- The DataStore name for the period that time is in, like "Daily_2026-11-02"
function Leaderboards.keyOf(periodId, time)
	if periodId == "Daily" then
		local date = utc(time)
		return string.format("Daily_%04d-%02d-%02d", date.Year, date.Month, date.Day)
	elseif periodId == "Weekly" then
		return "Weekly_" .. (time + WEEK_SHIFT) // WEEK
	elseif periodId == "Monthly" then
		local date = utc(time)
		return string.format("Monthly_%04d-%02d", date.Year, date.Month)
	end
	return "AllTime"
end

-- When the period that time is in ends (nil for All Time)
function Leaderboards.endOf(periodId, time)
	if periodId == "Daily" then
		return (time // DAY + 1) * DAY
	elseif periodId == "Weekly" then
		return ((time + WEEK_SHIFT) // WEEK + 1) * WEEK - WEEK_SHIFT
	elseif periodId == "Monthly" then
		return monthStart(time, 1)
	end
	return nil
end

-- The key of the period just before the one time is in
function Leaderboards.previousKey(periodId, time)
	if periodId == "Daily" then
		return Leaderboards.keyOf(periodId, time - DAY)
	elseif periodId == "Weekly" then
		return Leaderboards.keyOf(periodId, time - WEEK)
	elseif periodId == "Monthly" then
		return Leaderboards.keyOf(periodId, monthStart(time, 0) - 1)
	end
	return nil
end

-- "2d 5h" / "3h 12m" / "4m"
function Leaderboards.formatTimeLeft(seconds)
	seconds = math.max(0, math.floor(seconds))
	local days, hours, minutes = seconds // DAY, seconds % DAY // 3600, seconds % 3600 // 60
	if days > 0 then
		return days .. "d " .. hours .. "h"
	elseif hours > 0 then
		return hours .. "h " .. minutes .. "m"
	end
	return math.max(minutes, 1) .. "m"
end

return Leaderboards
