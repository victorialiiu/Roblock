-- Builds the land: hills, cliffs, lakes, and props for every region (src/shared/Regions/).
-- Every server rolls a random seed, so each server gets its own map. The seed is saved on
-- workspace as the "TerrainSeed" attribute. Put a number in FIXED_SEED to get the same map every time.
--
-- Terrain settings in a region file:
--   Material, HighMaterial: ground, and the ground on the tops of hills
--   Height: how tall the hills get. Scale: how wide they are (smaller = bumpier)
--   Step: hills go up in flat terraces this tall, for a cartoony look (leave it out for smooth hills)
--   Water: low spots fill with water
--   Colors: { [Material] = Color3 } bright colors for the materials. Terrain colors are shared by the
--     whole map, so two regions shouldn't use the same material with different colors
--   Patches: optional { Material = ..., Color = ..., Amount = 0.3 } splotches of a second material
--     (like flower fields). Bigger Amount = more of it
--   Props: { PropName = chance per patch }, built by src/server/TerrainProps.luau
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Regions = require(ReplicatedStorage.Shared.Regions)
local World = require(ReplicatedStorage.Shared.World)
local TerrainProps = require(script.Parent.TerrainProps)

local FIXED_SEED = nil
local CELL = 8
-- The baseplate (now below the terrain, to catch anyone who falls) is 2048 wide
local MAP_HALF = World.HALF_SIZE
local FLOOR = -16
local WATER_LEVEL = -0.5
-- Terrain settings fade between regions over this many studs, so there's no wall at the edge
local BLEND = 40
-- How far hills take to rise next to the spawn pad
local RAMP = 25
-- How long to spend building each frame. The map builds from the spawn pad outward
local FRAME_BUDGET = 0.012
local SIGNS_PER_RING = 6
local FONT = Enum.Font.FredokaOne

local terrain = workspace.Terrain
local seed = FIXED_SEED or Random.new():NextInteger(1, 2 ^ 30)
workspace:SetAttribute("TerrainSeed", seed)
print("Terrain seed: " .. seed)

local rng = Random.new(seed)
local offsetX = rng:NextNumber(-5000, 5000)
local offsetZ = rng:NextNumber(-5000, 5000)

local folder = Instance.new("Folder")
folder.Name = "World"
folder.Parent = workspace

-- 0 means keep it flat (around the spawn pad), 1 means full hills
local function hilliness(distance)
	return math.clamp((distance - (World.SPAWN_RADIUS + 10)) / RAMP, 0, 1)
end

-- Height and Scale, faded in from the region inside it near the edge
local function settingsAt(region, index, distance)
	local settings = region.Terrain
	local into = distance - region.Inner
	if index > 1 and into < BLEND then
		local previous = Regions.List[index - 1].Terrain
		local alpha = math.clamp(into / BLEND, 0, 1)
		return previous.Height + (settings.Height - previous.Height) * alpha, previous.Scale + (settings.Scale - previous.Scale) * alpha
	end
	return settings.Height, settings.Scale
end

local function regionAt(distance)
	for index, region in Regions.List do
		if distance < region.Outer then
			return region, index
		end
	end
	return Regions.List[#Regions.List], #Regions.List
end

local function heightAt(x, z)
	local distance = Regions.distanceOf(Vector3.new(x, 0, z))
	local region, index = regionAt(distance)
	local height, scale = settingsAt(region, index, distance)

	-- Big rolling hills plus smaller bumps on top
	local noise = math.noise(x / scale + offsetX, z / scale + offsetZ)
		+ 0.4 * math.noise(x / (scale * 0.35) + offsetZ, z / (scale * 0.35) + offsetX)
	local h = (noise + 0.3) * height
	if not region.Terrain.Water then
		h = math.max(h, 0)
	end
	h *= hilliness(distance)
	if region.Terrain.Step and h > 0 then
		h = math.floor(h / region.Terrain.Step + 0.5) * region.Terrain.Step
	end
	return h, region, distance
end

---------------------------------------------------------------- Cartoon look

for _, region in Regions.List do
	for material, color in region.Terrain.Colors or {} do
		terrain:SetMaterialColor(material, color)
	end
	local patches = region.Terrain.Patches
	if patches and patches.Color then
		terrain:SetMaterialColor(patches.Material, patches.Color)
	end
end
-- No realistic grass blades, and bright candy-blue water
terrain.Decoration = false
terrain.WaterColor = Color3.fromRGB(90, 210, 255)
terrain.WaterTransparency = 0.4
terrain.WaterReflectance = 0.2
terrain.WaterWaveSize = 0.05

-- Extra colorful and soft, like a toy
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Saturation = 0.25
colorCorrection.Contrast = 0.05
colorCorrection.Brightness = 0.03
colorCorrection.TintColor = Color3.fromRGB(255, 248, 252)
colorCorrection.Parent = Lighting
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.4
bloom.Size = 24
bloom.Threshold = 1.6
bloom.Parent = Lighting

-- Splotches of the region's patch material, using a different noise from the hills
local function materialAt(settings, x, z, h)
	local patches = settings.Patches
	if patches then
		local splotch = math.noise(x / 45 + offsetZ * 0.5, z / 45 - offsetX * 0.5)
		if splotch > 0.5 - patches.Amount then
			return patches.Material
		end
	end
	return if h > settings.Height * 0.6 then settings.HighMaterial else settings.Material
end

-- Every patch of ground, closest to the spawn pad first, so the area you arrive in shows up right away
local spots = {}
for x = -MAP_HALF, MAP_HALF - CELL, CELL do
	for z = -MAP_HALF, MAP_HALF - CELL, CELL do
		table.insert(spots, Vector2.new(x + CELL / 2, z + CELL / 2))
	end
end
table.sort(spots, function(a, b)
	return (a.X - World.CENTER.X) ^ 2 + (a.Y - World.CENTER.Z) ^ 2 < (b.X - World.CENTER.X) ^ 2 + (b.Y - World.CENTER.Z) ^ 2
end)

local frameStart = os.clock()
for _, spot in spots do
	local cx, cz = spot.X, spot.Y
	local h, region, distance = heightAt(cx, cz)
	local settings = region.Terrain
	local material = materialAt(settings, cx, cz, h)

	terrain:FillBlock(CFrame.new(cx, (FLOOR + h) / 2, cz), Vector3.new(CELL, h - FLOOR, CELL), material)
	if settings.Water and h < WATER_LEVEL then
		terrain:FillBlock(CFrame.new(cx, (h + WATER_LEVEL) / 2, cz), Vector3.new(CELL, WATER_LEVEL - h, CELL), Enum.Material.Water)
	end

	-- At most one prop per patch, never by the spawn pad or in water
	if hilliness(distance) >= 1 and h >= 0 then
		for propName, chance in settings.Props or {} do
			if rng:NextNumber() < chance and TerrainProps[propName] then
				local propSpot = Vector3.new(cx + rng:NextNumber(-2, 2), h - 0.5, cz + rng:NextNumber(-2, 2))
				TerrainProps[propName](propSpot, rng, folder)
				break
			end
		end
	end

	if os.clock() - frameStart > FRAME_BUDGET then
		task.wait()
		frameStart = os.clock()
	end
end
print("Terrain done")

---------------------------------------------------------------- Signs at each region's edge

local function makeSign(region, position)
	local post = Instance.new("Part")
	post.Anchored = true
	post.Size = Vector3.new(0.8, 10, 0.8)
	post.Position = position + Vector3.new(0, 5, 0)
	post.Color = Color3.new(1, 1, 1)
	post.Material = Enum.Material.SmoothPlastic
	post.Parent = folder

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 70)
	gui.StudsOffset = Vector3.new(0, 7, 0)
	gui.MaxDistance = 250
	gui.Parent = post

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0.6)
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = region.Color:Lerp(Color3.new(1, 1, 1), 0.3)
	label.TextStrokeTransparency = 0
	label.Text = region.Icon .. " " .. region.Name
	label.Parent = gui

	local info = label:Clone()
	info.Position = UDim2.fromScale(0, 0.6)
	info.Size = UDim2.fromScale(1, 0.4)
	info.TextColor3 = Color3.new(1, 1, 1)
	info.Text = "x" .. region.Luck .. " luck" .. (if region.Mutation then " • " .. region.Mutation .. " squishies" else "")
	info.Parent = gui
end

for _, region in Regions.List do
	if region.Inner > World.SPAWN_RADIUS then
		for i = 1, SIGNS_PER_RING do
			local angle = (i / SIGNS_PER_RING) * math.pi * 2
			local spot = World.CENTER + Vector3.new(math.sin(angle), 0, math.cos(angle)) * (region.Inner + 4)
			local h = heightAt(spot.X, spot.Z)
			makeSign(region, Vector3.new(spot.X, math.max(h, WATER_LEVEL), spot.Z))
		end
	end
end

workspace:SetAttribute("TerrainReady", true)
