-- Little things scattered on the ground. Regions list them in Terrain.Props, like { Tree = 0.01 }
-- (the chance per 8x8 patch of ground). To add one, add a function here that builds it at position.
local V = Vector3.new
local C = Color3.fromRGB

local function part(parent, size, cframe, color, material, shape)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local TerrainProps = {}

function TerrainProps.Tree(position, rng, parent)
	local m = model(parent, "Tree")
	local height = rng:NextNumber(8, 14)
	part(m, V(1.6, height, 1.6), CFrame.new(position + V(0, height / 2, 0)), C(190, 130, 90))
	-- Cotton-candy colored leaves, sometimes pink!
	local palette = { C(110, 220, 120), C(150, 235, 110), C(255, 170, 210), C(130, 220, 200) }
	local leaves = palette[rng:NextInteger(1, #palette)]
	for _ = 1, 3 do
		local size = rng:NextNumber(6, 9)
		local offset = V(rng:NextNumber(-2, 2), height + rng:NextNumber(-1, 2), rng:NextNumber(-2, 2))
		part(m, V(size, size, size), CFrame.new(position + offset), leaves, nil, Enum.PartType.Ball)
	end
end

function TerrainProps.Flower(position, rng, parent)
	local m = model(parent, "Flower")
	local colors = { C(255, 140, 200), C(255, 230, 100), C(200, 160, 255), C(255, 255, 255) }
	part(m, V(0.3, 1.6, 0.3), CFrame.new(position + V(0, 0.8, 0)), C(90, 170, 80))
	local petals = part(m, V(1.2, 0.4, 1.2), CFrame.new(position + V(0, 1.7, 0)), colors[rng:NextInteger(1, #colors)], nil, Enum.PartType.Ball)
	petals.CanCollide = false
	m:GetChildren()[1].CanCollide = false
end

function TerrainProps.Rock(position, rng, parent)
	local size = rng:NextNumber(3, 7)
	local rock = part(parent, V(size, size * 0.7, size), CFrame.new(position + V(0, size * 0.25, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), C(200, 190, 230), nil, Enum.PartType.Ball)
	rock.Name = "Rock"
end

-- Giant loaf of bread
function TerrainProps.Bread(position, rng, parent)
	local m = model(parent, "Bread")
	local turn = CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
	local base = CFrame.new(position + V(0, 2, 0)) * turn
	part(m, V(10, 4, 6), base, C(255, 215, 150))
	-- Cylinders lie along X, which makes the rounded top crust
	part(m, V(10.4, 6, 6), base * CFrame.new(0, 1.5, 0), C(225, 150, 80), nil, Enum.PartType.Cylinder)
end

function TerrainProps.Lollipop(position, rng, parent)
	local m = model(parent, "Lollipop")
	local height = rng:NextNumber(8, 14)
	local colors = { C(255, 90, 160), C(120, 200, 255), C(255, 200, 80), C(170, 120, 255) }
	part(m, V(0.8, height, 0.8), CFrame.new(position + V(0, height / 2, 0)), C(255, 255, 255))
	local candy = part(m, V(1.2, 7, 7), CFrame.new(position + V(0, height + 3, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), colors[rng:NextInteger(1, #colors)], Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	candy.Name = "Candy"
end

function TerrainProps.Crystal(position, rng, parent)
	local m = model(parent, "Crystal")
	local color = C(170, 130, 255):Lerp(C(120, 220, 255), rng:NextNumber())
	for _ = 1, rng:NextInteger(2, 4) do
		local height = rng:NextNumber(4, 12)
		local tilt = CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.28), rng:NextNumber(-0.4, 0.4))
		local crystal = part(m, V(1.6, height, 1.6), CFrame.new(position) * tilt * CFrame.new(0, height / 2, 0), color, Enum.Material.Neon)
		crystal.Transparency = 0.2
	end
end


-- Round puffy bush, a few balls squished together
function TerrainProps.Bush(position, rng, parent)
	local m = model(parent, "Bush")
	local palette = { C(100, 210, 110), C(140, 230, 120), C(90, 200, 150) }
	local color = palette[rng:NextInteger(1, #palette)]
	for _ = 1, 3 do
		local size = rng:NextNumber(3, 5)
		part(m, V(size, size * 0.8, size), CFrame.new(position + V(rng:NextNumber(-1.5, 1.5), size * 0.3, rng:NextNumber(-1.5, 1.5))), color, nil, Enum.PartType.Ball)
	end
	-- Sometimes it has berries
	if rng:NextNumber() < 0.5 then
		for _ = 1, 4 do
			local berry = part(m, V(0.6, 0.6, 0.6), CFrame.new(position + V(rng:NextNumber(-2, 2), rng:NextNumber(1.5, 3), rng:NextNumber(-2, 2))), C(255, 80, 120), nil, Enum.PartType.Ball)
			berry.CanCollide = false
		end
	end
end

-- Big spotty toadstool
function TerrainProps.Mushroom(position, rng, parent)
	local m = model(parent, "Mushroom")
	local caps = { C(255, 90, 110), C(180, 120, 255), C(255, 170, 60), C(90, 200, 255) }
	local cap = caps[rng:NextInteger(1, #caps)]
	local height = rng:NextNumber(3, 7)
	local width = height * 1.4
	part(m, V(height, 1.6, 1.6), CFrame.new(position + V(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), C(255, 245, 230), nil, Enum.PartType.Cylinder)
	part(m, V(width, width * 0.55, width), CFrame.new(position + V(0, height, 0)), cap, nil, Enum.PartType.Ball)
	for _ = 1, 4 do
		local angle = rng:NextNumber(0, 6.28)
		local dot = part(m, V(0.8, 0.4, 0.8), CFrame.new(position + V(math.cos(angle) * width * 0.25, height + width * 0.24, math.sin(angle) * width * 0.25)), C(255, 255, 255), nil, Enum.PartType.Ball)
		dot.CanCollide = false
	end
end

-- Shiny gumdrop candy
function TerrainProps.Gumdrop(position, rng, parent)
	local colors = { C(255, 100, 150), C(120, 220, 140), C(255, 220, 90), C(150, 140, 255), C(255, 150, 80) }
	local size = rng:NextNumber(3, 6)
	local drop = part(parent, V(size, size * 1.1, size), CFrame.new(position + V(0, size * 0.35, 0)), colors[rng:NextInteger(1, #colors)], Enum.Material.Glass, Enum.PartType.Ball)
	drop.Name = "Gumdrop"
end

return TerrainProps
