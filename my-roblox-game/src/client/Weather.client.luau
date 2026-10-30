local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Weather = require(ReplicatedStorage.Shared.Weather)

local currentEvent = ReplicatedStorage:WaitForChild("CurrentEvent")
local camera = workspace.CurrentCamera

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 230, 120)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 255, 160)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(130, 190, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 140, 255)),
})

-- An invisible sky above your camera that drops the weather particles
local sky = Instance.new("Part")
sky.Name = "WeatherSky"
sky.Size = Vector3.new(150, 1, 150)
sky.Transparency = 1
sky.Anchored = true
sky.CanCollide = false
sky.CanTouch = false
sky.CanQuery = false
sky.Parent = workspace

local emitter = Instance.new("ParticleEmitter")
emitter.EmissionDirection = Enum.NormalId.Bottom
emitter.Rate = 0
emitter.LightEmission = 0.5
emitter.Parent = sky

local function update(name)
	local weather = Weather.ByName[name]
	if not weather then
		emitter.Rate = 0
		return
	end

	local particles = weather.Particles
	emitter.Color = if particles.Rainbow then RAINBOW else ColorSequence.new(particles.Color)
	emitter.Speed = NumberRange.new(particles.Speed)
	emitter.Lifetime = NumberRange.new(60 / particles.Speed + 0.5)
	emitter.Size = NumberSequence.new(particles.Size)
	emitter.Rate = particles.Rate
end

update(currentEvent.Value)
currentEvent.Changed:Connect(update)

RunService.RenderStepped:Connect(function()
	sky.Position = camera.CFrame.Position + Vector3.new(0, 40, 0)
end)
