local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryService = require(script.Parent.InventoryService)

local REQUEST_TIMEOUT = 20
-- Both players have to stay ready this long before the swap happens, so nobody can sneak in a last-second change
local CONFIRM_TIME = 3

local tradeRemote = Instance.new("RemoteEvent")
tradeRemote.Name = "Trade"
tradeRemote.Parent = ReplicatedStorage:WaitForChild("Remotes")

local requests = {}
local trades = {}

local function partnerOf(session, player)
	return if session.A == player then session.B else session.A
end

local function sendState(session)
	for _, player in { session.A, session.B } do
		local partner = partnerOf(session, player)
		tradeRemote:FireClient(player, "state", {
			Partner = partner,
			Mine = session.Offers[player],
			Theirs = session.Offers[partner],
			MyReady = session.Ready[player] == true,
			TheirReady = session.Ready[partner] == true,
			Countdown = session.Countdown,
		})
	end
end

local function close(session, reason)
	session.Token += 1
	for _, player in { session.A, session.B } do
		trades[player] = nil
		if player.Parent then
			tradeRemote:FireClient(player, "closed", reason)
		end
	end
end

local function unready(session)
	session.Ready = {}
	session.Countdown = nil
	session.Token += 1
end

local function finish(session)
	-- Make sure both players still have everything they offered
	for _, player in { session.A, session.B } do
		for itemName, amount in session.Offers[player] do
			if InventoryService.count(player, itemName) < amount then
				close(session, player.DisplayName .. " doesn't have those squishies anymore")
				return
			end
		end
	end

	local moving = {}
	for _, player in { session.A, session.B } do
		moving[player] = {}
		for itemName, amount in session.Offers[player] do
			local squishy, mutationName = InventoryService.describe(player, itemName)
			InventoryService.remove(player, itemName, amount)
			table.insert(moving[player], { Squishy = squishy.Name, Mutation = mutationName, Amount = amount })
		end
	end
	for _, player in { session.A, session.B } do
		local partner = partnerOf(session, player)
		for _, item in moving[player] do
			InventoryService.add(partner, item.Squishy, item.Mutation, item.Amount)
		end
	end

	close(session, "Trade complete! 🎉")
end

local handlers = {}

function handlers.request(player, target)
	if typeof(target) ~= "Instance" or not target:IsA("Player") or target == player then
		return
	end
	if trades[player] or trades[target] then
		tradeRemote:FireClient(player, "closed", target.DisplayName .. " is busy right now")
		return
	end
	requests[target] = { From = player, At = os.clock() }
	tradeRemote:FireClient(target, "incoming", player)
end

function handlers.respond(player, from, accept)
	local request = requests[player]
	if not request or request.From ~= from then
		return
	end
	requests[player] = nil

	local expired = os.clock() - request.At > REQUEST_TIMEOUT
	if accept ~= true or expired or trades[player] or trades[from] or not from.Parent then
		if from.Parent then
			tradeRemote:FireClient(from, "closed", player.DisplayName .. " said no")
		end
		return
	end

	local session = { A = from, B = player, Offers = { [from] = {}, [player] = {} }, Ready = {}, Token = 0 }
	trades[from] = session
	trades[player] = session
	sendState(session)
end

-- Sets how many of one squishy you're offering (0 takes it out)
function handlers.offer(player, itemName, amount)
	local session = trades[player]
	if not session or typeof(itemName) ~= "string" or typeof(amount) ~= "number" then
		return
	end
	amount = math.clamp(math.floor(amount), 0, InventoryService.count(player, itemName))
	session.Offers[player][itemName] = if amount > 0 then amount else nil
	unready(session)
	sendState(session)
end

function handlers.ready(player, isReady)
	local session = trades[player]
	if not session then
		return
	end
	if isReady ~= true then
		unready(session)
		sendState(session)
		return
	end

	session.Ready[player] = true
	if session.Ready[partnerOf(session, player)] then
		session.Token += 1
		local token = session.Token
		session.Countdown = CONFIRM_TIME
		task.delay(CONFIRM_TIME, function()
			if session.Token == token then
				finish(session)
			end
		end)
	end
	sendState(session)
end

function handlers.cancel(player)
	local session = trades[player]
	if session then
		close(session, player.DisplayName .. " cancelled the trade")
	end
end

tradeRemote.OnServerEvent:Connect(function(player, action, ...)
	local handler = handlers[action]
	if handler then
		handler(player, ...)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	requests[player] = nil
	local session = trades[player]
	if session then
		close(session, player.DisplayName .. " left the game")
	end
end)
