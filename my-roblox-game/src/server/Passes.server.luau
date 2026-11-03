-- Gamepasses (Auto Sell, Magnet, Pet) and the Lucky Box. Ids and descriptions are in src/shared/Passes.luau.
-- Auto Sell happens when you catch something, in MakeSquishy.luau. The rest is here.
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Passes = require(ReplicatedStorage.Shared.Passes)
local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local buildSquishy = require(script.Parent.MakeSquishy).build
local notify = require(script.Parent.Notify)
local openBox = require(script.Parent.LuckyBox)

local MAGNET_SPEED = 45
local PET_SQUISHY = "Egg"
local PET_OFFSET = Vector3.new(3, 1.5, 2)

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local buyPassRemote = Instance.new("RemoteEvent")
buyPassRemote.Name = "BuyPass"
buyPassRemote.Parent = remotes

local buyBoxRemote = Instance.new("RemoteEvent")
buyBoxRemote.Name = "BuyBox"
buyBoxRemote.Parent = remotes

local petFolder = Instance.new("Folder")
petFolder.Name = "Pets"
petFolder.Parent = workspace

local pets = {}

---------------------------------------------------------------- Pet

local function removePet(player)
	if pets[player] then
		pets[player]:Destroy()
		pets[player] = nil
	end
end

-- A little squishy that floats next to you
local function givePet(player)
	removePet(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not Passes.owns(player, "Pet") then
		return
	end

	local body = buildSquishy(SquishyTypes.ByName[PET_SQUISHY], {}, 1.6, root.CFrame * CFrame.new(PET_OFFSET))
	body.Name = player.Name .. "'s Buddy"
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = false
	body.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0, 0)
	for _, child in body:GetChildren() do
		if child:IsA("BillboardGui") then
			child:Destroy()
		end
	end

	local petAttachment = Instance.new("Attachment")
	petAttachment.Parent = body
	local rootAttachment = Instance.new("Attachment")
	rootAttachment.Name = "PetSpot"
	rootAttachment.Position = PET_OFFSET
	rootAttachment.Parent = root

	local follow = Instance.new("AlignPosition")
	follow.Attachment0 = petAttachment
	follow.Attachment1 = rootAttachment
	follow.MaxForce = 100000
	follow.Responsiveness = 30
	follow.Parent = body

	local face = Instance.new("AlignOrientation")
	face.Attachment0 = petAttachment
	face.Attachment1 = rootAttachment
	face.Responsiveness = 30
	face.Parent = body

	body.Parent = petFolder
	body:SetNetworkOwner(player)
	pets[player] = body
end

---------------------------------------------------------------- Owning passes

local function grant(player, passId)
	player:SetAttribute("Pass_" .. passId, true)
	if passId == "Pet" then
		givePet(player)
	end
end

local function checkPasses(player)
	for _, pass in Passes.List do
		if pass.PassId ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.PassId)
			if ok and owns then
				grant(player, pass.Id)
			end
		end
	end
end

local function setup(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		givePet(player)
	end)
	checkPasses(player)
end

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do
	task.spawn(setup, player)
end

Players.PlayerRemoving:Connect(removePet)

buyPassRemote.OnServerEvent:Connect(function(player, passId)
	local pass = Passes.ById[passId]
	if not pass or Passes.owns(player, passId) then
		return
	end
	if pass.PassId ~= 0 then
		MarketplaceService:PromptGamePassPurchase(player, pass.PassId)
	elseif RunService:IsStudio() then
		grant(player, passId)
		notify(player, pass.Icon .. " " .. pass.Name .. " unlocked (free while testing in Studio)")
	else
		notify(player, pass.Name .. " isn't for sale yet!")
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if not purchased then
		return
	end
	for _, pass in Passes.List do
		if pass.PassId == gamePassId then
			grant(player, pass.Id)
			notify(player, pass.Icon .. " " .. pass.Name .. " unlocked! Thank you! 💖")
		end
	end
end)

---------------------------------------------------------------- Lucky Box

buyBoxRemote.OnServerEvent:Connect(function(player)
	local box = Passes.LuckyBox
	if box.ProductId ~= 0 then
		MarketplaceService:PromptProductPurchase(player, box.ProductId)
	elseif RunService:IsStudio() then
		openBox(player)
	else
		notify(player, box.Name .. " isn't for sale yet!")
	end
end)

MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player or receipt.ProductId ~= Passes.LuckyBox.ProductId then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	openBox(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

---------------------------------------------------------------- Magnet

while true do
	task.wait(0.1)
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and Passes.owns(player, "Magnet") then
			for _, body in CollectionService:GetTagged("FallingSquishy") do
				local offset = root.Position - body.Position
				if not body.Anchored and offset.Magnitude < Passes.MAGNET_RANGE and offset.Magnitude > 0.1 then
					-- The server has to own it for the pull to stick
					pcall(body.SetNetworkOwner, body, nil)
					body.AssemblyLinearVelocity = offset.Unit * MAGNET_SPEED
				end
			end
		end
	end
end
