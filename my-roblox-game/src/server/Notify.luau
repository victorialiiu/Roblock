-- Little pop-up messages on one player's screen: notify(player, "Your bag is full!")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- The same message won't show again this soon, so touching things over and over doesn't spam
local REPEAT_TIME = 3

local remote = Instance.new("RemoteEvent")
remote.Name = "Notify"
remote.Parent = ReplicatedStorage:WaitForChild("Remotes")

local lastSent = setmetatable({}, { __mode = "k" })

return function(player, text)
	local sent = lastSent[player]
	if sent and sent.Text == text and os.clock() - sent.At < REPEAT_TIME then
		return
	end
	lastSent[player] = { Text = text, At = os.clock() }
	remote:FireClient(player, text)
end
