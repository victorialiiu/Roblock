local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SquishyTypes = require(ReplicatedStorage.Shared.SquishyTypes)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local SquishyShapes = require(script.Parent.SquishyShapes)
local InventoryService = require(script.Parent.InventoryService)

local LIFETIME = 20
local STEAL_PERCENT = 0.1
local CHASE_RANGE = 40
local CHASE_SPEED = 14

local BLACK = Color3.fromRGB(40, 30, 40)
local WHITE = Color3.new(1, 1, 1)
local BLUSH = Color3.fromRGB(255, 120, 160)

local function weld(body, part)
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true

	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = body
	constraint.Part1 = part
	constraint.Parent = part
	part.Parent = body
end

local function buildPiece(body, spec, size)
	local kind = spec[1]
	local part = if kind == "Wedge" then Instance.new("WedgePart") else Instance.new("Part")
	local partSize = spec[2] * size
	local turn = CFrame.identity

	if kind == "Ball" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	elseif kind == "Cylinder" then
		-- Roblox cylinders lie on their side, so stand them up
		part.Shape = Enum.PartType.Cylinder
		partSize = Vector3.new(partSize.Y, partSize.X, partSize.X)
		turn = CFrame.Angles(0, 0, math.pi / 2)
	end

	local rot = spec.rot or Vector3.zero
	part.Size = partSize
	part.CFrame = body.CFrame
		* CFrame.new(spec[3] * size)
		* CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
		* turn
	part.Color = spec[4]
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = spec.alpha or 0
	weld(body, part)
	return part
end

-- A little oval stuck onto the face (eyes, cheeks, mouth...)
local function addBlob(body, size, cframe, color, meshType)
	local blob = Instance.new("Part")
	blob.Size = size
	blob.CFrame = cframe
	blob.Color = color
	blob.Material = Enum.Material.SmoothPlastic

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = meshType or Enum.MeshType.Sphere
	mesh.Parent = blob

	weld(body, blob)
	return blob
end

local function addFace(body, face, f, evil)
	local eyeColor = if evil then Color3.fromRGB(220, 0, 30) else BLACK

	for _, side in { -1, 1 } do
		local x = side * f * 0.2
		addBlob(body, Vector3.new(0.16, 0.2, 0.08) * f, face * CFrame.new(x, f * 0.08, 0), eyeColor)
		addBlob(body, Vector3.new(0.06, 0.06, 0.03) * f, face * CFrame.new(x + f * 0.03, f * 0.12, -f * 0.04), WHITE)

		if evil then
			-- Angry eyebrows
			addBlob(
				body,
				Vector3.new(0.22, 0.05, 0.05) * f,
				face * CFrame.new(x, f * 0.24, 0) * CFrame.Angles(0, 0, side * 0.4),
				BLACK,
				Enum.MeshType.Brick
			)
		else
			local cheek = addBlob(body, Vector3.new(0.14, 0.07, 0.06) * f, face * CFrame.new(side * f * 0.32, -f * 0.05, 0), BLUSH)
			cheek.Transparency = 0.2
		end
	end

	local mouthSize = if evil then Vector3.new(0.2, 0.06, 0.04) else Vector3.new(0.1, 0.05, 0.04)
	addBlob(body, mouthSize * f, face * CFrame.new(0, -f * 0.1, 0), BLACK)
end

-- Builds the squishy from SquishyShapes. Returns the invisible hitbox and the pieces mutations recolor.
local function buildFromShape(squishy, size, cframe)
	local shape = SquishyShapes[squishy.Shape]

	local body = Instance.new("Part")
	body.Size = shape.Hitbox * size
	body.CFrame = cframe
	body.Transparency = 1

	local tintable = {}
	for _, spec in shape.Pieces do
		local part = buildPiece(body, spec, size)
		if spec.tint then
			table.insert(tintable, part)
		end
	end

	addFace(body, cframe * CFrame.new(shape.Face.Position * size), shape.Face.Scale * size, squishy.Rarity == "Evil")
	return body, tintable
end

-- Uses a real model if someone saved one as src/shared/Models/<Squishy Name>.rbxm
local function buildFromModel(model, size, cframe)
	model = model:Clone()
	local parts = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end

	local extents = model:GetExtentsSize()
	model:ScaleTo(model:GetScale() * size / math.max(extents.X, extents.Y, extents.Z))
	model:PivotTo(cframe)

	local body = Instance.new("Part")
	body.Size = model:GetExtentsSize()
	body.CFrame = cframe
	body.Transparency = 1

	for _, part in parts do
		part.Anchored = false
		weld(body, part)
	end
	model:Destroy()
	return body, parts
end

local function applyMutation(parts, mutation)
	for _, part in parts do
		if mutation.Tint then
			part.Color = part.Color:Lerp(mutation.Tint, 0.6)
		end
		if mutation.Material then
			part.Material = mutation.Material
		end
	end
end

-- Name, rarity, drop rate, and value floating over its head
local function addNameTag(body, squishy, mutationName, rarity)
	local mutation = SquishyTypes.Mutations[mutationName]

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(170, 62)
	tag.StudsOffset = Vector3.new(0, body.Size.Y / 2 + 2, 0)
	tag.MaxDistance = 60
	tag.Parent = body

	local function addLine(text, color, top, height)
		local label = Instance.new("TextLabel")
		label.Position = UDim2.fromScale(0, top)
		label.Size = UDim2.fromScale(1, height)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.3
		label.Text = text
		label.Parent = tag
	end

	addLine(SquishyTypes.itemName(squishy.Name, mutationName), if mutation then mutation.Color else WHITE, 0, 0.4)
	addLine(squishy.Rarity .. " • " .. SquishyTypes.formatChance(SquishyTypes.chanceOf(squishy)), rarity.Color, 0.4, 0.3)
	if squishy.Value then
		addLine("Worth $" .. SquishyTypes.valueOf(squishy, mutationName), Color3.fromRGB(140, 255, 150), 0.7, 0.3)
	else
		addLine("Steals your money! RUN!", Color3.fromRGB(255, 80, 80), 0.7, 0.3)
	end
end

local function nearestRoot(position)
	local nearest, nearestDistance = nil, CHASE_RANGE
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and not Lobby.contains(root.Position) then
			local distance = (root.Position - position).Magnitude
			if distance < nearestDistance then
				nearest, nearestDistance = root, distance
			end
		end
	end
	return nearest
end

local function collect(player, squishy, mutationName)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		InventoryService.add(player, squishy.Name, mutationName)
		leaderstats.Squishies.Value += 1
	end
end

local function hurt(player, humanoid, squishy)
	humanoid:TakeDamage(squishy.Damage)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local money = leaderstats.Money
		money.Value -= math.floor(money.Value * STEAL_PERCENT)
	end
end

-- Poof! Hide the squishy and burst into particles
local function pop(body, color)
	body.Anchored = true
	body.CanTouch = false
	body.CanCollide = false
	for _, child in body:GetDescendants() do
		if child:IsA("BasePart") then
			child.Transparency = 1
		elseif child:IsA("BillboardGui") or child:IsA("Sparkles") or child:IsA("PointLight") then
			child:Destroy()
		end
	end

	local burst = Instance.new("ParticleEmitter")
	burst.Rate = 0
	burst.Color = ColorSequence.new(color)
	burst.Speed = NumberRange.new(10, 20)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Lifetime = NumberRange.new(0.3, 0.5)
	burst.Size = NumberSequence.new(0.5, 0)
	burst.Parent = body
	burst:Emit(20)

	task.wait(0.6)
	body:Destroy()
end

-- Builds the squishy's look with no gameplay. Used for falling squishies and base showcases
local function build(squishy, mutationName, size, cframe)
	local rarity = SquishyTypes.Rarities[squishy.Rarity]
	local mutation = SquishyTypes.Mutations[mutationName]
	local evil = squishy.Rarity == "Evil"

	local models = ReplicatedStorage.Shared:FindFirstChild("Models")
	local model = models and models:FindFirstChild(squishy.Name)
	local body, tintable
	if model then
		body, tintable = buildFromModel(model, size, cframe)
	else
		body, tintable = buildFromShape(squishy, size, cframe)
	end
	body.Name = "Squishy"

	if mutation then
		applyMutation(tintable, mutation)
	end
	addNameTag(body, squishy, mutationName, rarity)

	if rarity.Order >= 3 or mutation then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = if mutation then mutation.Color else rarity.Color
		sparkles.Parent = body
	end
	if rarity.Order >= 4 or evil then
		local light = Instance.new("PointLight")
		light.Color = rarity.Color
		light.Range = 12
		light.Parent = body
	end

	return body, tintable
end

local function makeSquishy(squishy, position, mutationName)
	local rarity = SquishyTypes.Rarities[squishy.Rarity]
	local mutation = SquishyTypes.Mutations[mutationName]
	local size = rarity.Size * math.random(90, 110) / 100
	local evil = squishy.Rarity == "Evil"
	local cframe = CFrame.new(position) * CFrame.Angles(0, math.random() * math.pi * 2, 0)

	local body, tintable = build(squishy, mutationName, size, cframe)
	-- Light and bouncy
	body.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.5, 0.8)

	-- Keep it upright instead of tumbling around
	local attachment = Instance.new("Attachment")
	attachment.Parent = body
	local align = Instance.new("AlignOrientation")
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.RigidityEnabled = true
	align.CFrame = cframe.Rotation
	align.Parent = body

	local done = false
	body.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if done or not player or not humanoid or humanoid.Health <= 0 then
			return
		end
		done = true

		if evil then
			hurt(player, humanoid, squishy)
		else
			collect(player, squishy, mutationName)
		end
		pop(body, if mutation then mutation.Color else squishy.Color)
	end)

	body.Parent = workspace
	Debris:AddItem(body, LIFETIME)

	if mutation and mutation.Rainbow then
		task.spawn(function()
			local hue = 0
			while body.Parent and not done do
				hue = (hue + 0.02) % 1
				for _, part in tintable do
					part.Color = Color3.fromHSV(hue, 0.5, 1)
				end
				task.wait(0.1)
			end
		end)
	end

	-- Evil squishies chase the nearest player
	if evil then
		body:SetNetworkOwner(nil)
		task.spawn(function()
			while body.Parent and not done do
				local target = nearestRoot(body.Position)
				if target then
					local direction = (target.Position - body.Position) * Vector3.new(1, 0, 1)
					if direction.Magnitude > 0.1 then
						direction = direction.Unit
						body.AssemblyLinearVelocity = direction * CHASE_SPEED + Vector3.new(0, body.AssemblyLinearVelocity.Y, 0)
						align.CFrame = CFrame.lookAt(Vector3.zero, direction)
					end
				end
				task.wait(0.2)
			end
		end)
	end
end

return {
	spawn = makeSquishy,
	build = build,
}
