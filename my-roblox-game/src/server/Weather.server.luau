local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Weather = require(ReplicatedStorage.Shared.Weather)
local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)

local CALM_TIME = 60
local WEATHER_TIME = 45
-- Chance of an event instead of weather, if there are any events
local EVENT_CHANCE = 0.2

local status = Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local currentEvent = Instance.new("StringValue")
currentEvent.Name = "CurrentEvent"
currentEvent.Parent = ReplicatedStorage

-- Every ModuleScript in src/server/Events (if that folder exists) is a possible event
local events = {}
local eventsFolder = script.Parent:FindFirstChild("Events")
for _, module in if eventsFolder then eventsFolder:GetChildren() else {} do
	table.insert(events, require(module))
end

local defaultLighting = {}
for _, key in { "Brightness", "ClockTime", "FogEnd", "FogColor" } do
	defaultLighting[key] = Lighting[key]
end

local function tweenLighting(goal)
	TweenService:Create(Lighting, TweenInfo.new(3), goal):Play()
end

local function countdown(seconds, text)
	for i = seconds, 1, -1 do
		status.Value = string.format("%s %d:%02d", text, i // 60, i % 60)
		task.wait(1)
	end
end

while true do
	countdown(CALM_TIME, "Next weather in")

	if #events > 0 and math.random() < EVENT_CHANCE then
		local event = events[math.random(#events)]
		currentEvent.Value = event.Name
		event.Start()
		countdown(WEATHER_TIME, event.Name .. "!")
		event.Stop()
	else
		local weather = Weather.pickRandom()
		local mutation = SquishyTypes.Mutations[weather.Mutation]
		currentEvent.Value = weather.Name
		tweenLighting(weather.Lighting)
		countdown(WEATHER_TIME, weather.Name .. "! " .. weather.Mutation .. " x" .. mutation.Multiplier)
		tweenLighting(defaultLighting)
	end

	currentEvent.Value = ""
end
