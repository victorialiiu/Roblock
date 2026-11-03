-- Every kind of weather. Each one gives falling squishies an attribute.
-- Sometimes two happen at once, and squishies can get both attributes!
local Weather = {}

Weather.MUTATION_CHANCE = 0.5
-- Chance the weather is a combo of two
Weather.COMBO_CHANCE = 0.25
-- CurrentEvent holds one weather name, or two joined like "Rain + Thunderstorm"
Weather.SEPARATOR = " + "

Weather.List = {
	{
		Name = "Rain",
		Mutation = "Wet",
		Weight = 30,
		Particles = { Color = Color3.fromRGB(150, 190, 255), Rate = 400, Speed = 60, Size = 0.15 },
		Lighting = { Brightness = 1, ClockTime = 14, FogEnd = 300, FogColor = Color3.fromRGB(150, 160, 180) },
	},
	{
		Name = "Snow",
		Mutation = "Frozen",
		Weight = 25,
		Particles = { Color = Color3.new(1, 1, 1), Rate = 200, Speed = 8, Size = 0.4 },
		Lighting = { Brightness = 1.5, ClockTime = 14, FogEnd = 250, FogColor = Color3.fromRGB(230, 240, 255) },
	},
	{
		Name = "Thunderstorm",
		Mutation = "Shocked",
		Weight = 20,
		Particles = { Color = Color3.fromRGB(180, 180, 220), Rate = 600, Speed = 80, Size = 0.15 },
		Lighting = { Brightness = 0.5, ClockTime = 19, FogEnd = 200, FogColor = Color3.fromRGB(60, 60, 80) },
	},
	{
		Name = "Golden Hour",
		Mutation = "Golden",
		Weight = 12,
		Particles = { Color = Color3.fromRGB(255, 210, 80), Rate = 80, Speed = 5, Size = 0.3 },
		Lighting = { Brightness = 2.5, ClockTime = 17.6, FogEnd = 600, FogColor = Color3.fromRGB(255, 200, 120) },
	},
	{
		Name = "Rainbow Rain",
		Mutation = "Rainbow",
		Weight = 8,
		Particles = { Rainbow = true, Rate = 300, Speed = 40, Size = 0.3 },
		Lighting = { Brightness = 2, ClockTime = 12, FogEnd = 800, FogColor = Color3.fromRGB(255, 220, 255) },
	},
	{
		Name = "Starfall",
		Mutation = "Cosmic",
		Weight = 5,
		Particles = { Color = Color3.fromRGB(200, 160, 255), Rate = 150, Speed = 30, Size = 0.5 },
		Lighting = { Brightness = 1, ClockTime = 0, FogEnd = 500, FogColor = Color3.fromRGB(40, 20, 80) },
	},
}

Weather.ByName = {}
for _, weather in Weather.List do
	Weather.ByName[weather.Name] = weather
end

function Weather.pickRandom(except)
	local total = 0
	for _, weather in Weather.List do
		if weather ~= except then
			total += weather.Weight
		end
	end
	local roll = math.random() * total
	for _, weather in Weather.List do
		if weather ~= except then
			roll -= weather.Weight
			if roll <= 0 then
				return weather
			end
		end
	end
	return Weather.List[1]
end

-- One weather, or sometimes two different ones
function Weather.pickCombo()
	local first = Weather.pickRandom()
	if math.random() < Weather.COMBO_CHANCE then
		return { first, Weather.pickRandom(first) }
	end
	return { first }
end

-- The weathers in a CurrentEvent value. Empty if it's calm or a non-weather event
function Weather.parse(value)
	local list = {}
	for _, name in string.split(value or "", Weather.SEPARATOR) do
		local weather = Weather.ByName[name]
		if weather then
			table.insert(list, weather)
		end
	end
	return list
end

function Weather.nameOf(list)
	local names = {}
	for _, weather in list do
		table.insert(names, weather.Name)
	end
	return table.concat(names, Weather.SEPARATOR)
end

function Weather.mutationsOf(list)
	local mutations = {}
	for _, weather in list do
		table.insert(mutations, weather.Mutation)
	end
	return mutations
end

return Weather
