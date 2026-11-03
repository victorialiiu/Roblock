-- One button to hop between the lobby and the hunting map (same as walking into a portal)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage.Shared.World)
local UI = require(ReplicatedStorage.Shared.UI)

local player = Players.LocalPlayer
local travelRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Travel")

local gui = Instance.new("ScreenGui")
gui.Name = "Travel"
gui.ResetOnSpawn = false

local button = UI.menuButton(gui, "", UI.BLUE, "left", 4)

local function onMap()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and World.contains(root.Position)
end

button.Activated:Connect(function()
	travelRemote:FireServer(if onMap() then "Lobby" else "World")
end)

gui.Parent = player:WaitForChild("PlayerGui")

while true do
	local hunting = onMap()
	button.Text = if hunting then "🏠 Lobby" else "🌧️ Go Hunt"
	button.BackgroundColor3 = if hunting then UI.PINK else UI.BLUE
	task.wait(0.5)
end
