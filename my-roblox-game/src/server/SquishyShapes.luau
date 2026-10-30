-- How each squishy is built out of simple parts.
-- Sizes and positions get multiplied by the squishy's size.
-- Each piece is { kind, size, position, color }. kind is "Ball", "Block", "Cylinder", or "Wedge".
-- tint = true means weather mutations recolor that piece. rot is a rotation in degrees.
local V = Vector3.new
local C = Color3.fromRGB

local function toast(crust, inside, extras)
	local pieces = {
		{ "Block", V(1, 0.85, 0.3), V(0, -0.1, 0), crust, tint = true },
		{ "Ball", V(1.05, 0.55, 0.3), V(0, 0.32, 0), crust, tint = true },
		{ "Block", V(0.86, 0.75, 0.32), V(0, -0.12, 0), inside, tint = true },
		{ "Ball", V(0.9, 0.45, 0.32), V(0, 0.3, 0), inside, tint = true },
	}
	for _, piece in extras or {} do
		table.insert(pieces, piece)
	end
	return {
		Hitbox = V(1, 1.15, 0.3),
		Face = { Position = V(0, 0, -0.16), Scale = 0.55 },
		Pieces = pieces,
	}
end

local SPRINKLES = {}
for i, color in { C(255, 255, 255), C(120, 200, 255), C(255, 240, 100), C(140, 230, 140), C(200, 140, 255), C(255, 255, 255) } do
	local angle = i * math.pi / 3
	table.insert(SPRINKLES, {
		"Block",
		V(0.12, 0.03, 0.04),
		V(math.cos(angle) * 0.32, 0.27, math.sin(angle) * 0.32),
		color,
		rot = V(0, i * 50, 0),
	})
end

local SquishyShapes = {
	Butter = {
		Hitbox = V(1.2, 0.55, 0.8),
		Face = { Position = V(0, -0.02, -0.4), Scale = 0.45 },
		Pieces = {
			{ "Block", V(1.2, 0.5, 0.8), V(0, -0.025, 0), C(255, 225, 110), tint = true },
			{ "Block", V(0.55, 0.1, 0.4), V(0.1, 0.27, 0.05), C(255, 240, 170), tint = true, rot = V(0, 12, 0) },
		},
	},

	Potato = {
		Hitbox = V(1.2, 0.8, 0.8),
		Face = { Position = V(0, 0, -0.37), Scale = 0.5 },
		Pieces = {
			{ "Ball", V(1.1, 0.75, 0.8), V(0, 0, 0), C(205, 155, 95), tint = true },
			{ "Ball", V(0.6, 0.55, 0.6), V(0.35, 0.08, 0.08), C(205, 155, 95), tint = true },
			{ "Ball", V(0.55, 0.5, 0.55), V(-0.33, -0.05, 0.1), C(205, 155, 95), tint = true },
			{ "Ball", V(0.1, 0.08, 0.06), V(0.3, 0.2, -0.3), C(150, 100, 55) },
			{ "Ball", V(0.08, 0.07, 0.06), V(-0.35, 0.15, -0.25), C(150, 100, 55) },
			{ "Ball", V(0.09, 0.07, 0.06), V(0.15, -0.25, -0.3), C(150, 100, 55) },
		},
	},

	Toast = toast(C(185, 115, 55), C(255, 225, 165)),

	Egg = {
		Hitbox = V(0.75, 1, 0.75),
		Face = { Position = V(0, -0.05, -0.35), Scale = 0.45 },
		Pieces = {
			{ "Ball", V(0.75, 1, 0.75), V(0, 0, 0), C(255, 250, 240), tint = true },
		},
	},

	Cheese = {
		Hitbox = V(1.2, 0.8, 0.8),
		Face = { Position = V(0.15, -0.15, -0.4), Scale = 0.4 },
		Pieces = {
			{ "Wedge", V(0.8, 0.8, 1.2), V(0, 0, 0), C(255, 205, 60), tint = true, rot = V(0, 90, 0) },
			{ "Ball", V(0.15, 0.15, 0.04), V(0.4, 0.1, -0.4), C(225, 165, 30) },
			{ "Ball", V(0.1, 0.1, 0.04), V(-0.25, -0.25, -0.4), C(225, 165, 30) },
			{ "Ball", V(0.18, 0.18, 0.04), V(0.2, -0.1, 0.4), C(225, 165, 30) },
		},
	},

	Dumpling = {
		Hitbox = V(1, 0.7, 0.9),
		Face = { Position = V(0, -0.05, -0.42), Scale = 0.45 },
		Pieces = {
			{ "Ball", V(1, 0.6, 0.9), V(0, -0.05, 0), C(250, 245, 235), tint = true },
			{ "Ball", V(0.85, 0.25, 0.25), V(0, 0.22, 0.05), C(245, 238, 225), tint = true },
			{ "Ball", V(0.12, 0.18, 0.2), V(-0.25, 0.3, 0.05), C(245, 238, 225), tint = true },
			{ "Ball", V(0.12, 0.18, 0.2), V(0, 0.32, 0.05), C(245, 238, 225), tint = true },
			{ "Ball", V(0.12, 0.18, 0.2), V(0.25, 0.3, 0.05), C(245, 238, 225), tint = true },
		},
	},

	Strawberry = {
		Hitbox = V(0.8, 1.1, 0.8),
		Face = { Position = V(0, -0.02, -0.37), Scale = 0.45 },
		Pieces = {
			{ "Ball", V(0.8, 0.9, 0.8), V(0, 0.02, 0), C(255, 80, 100), tint = true },
			{ "Ball", V(0.5, 0.5, 0.5), V(0, -0.32, 0), C(255, 80, 100), tint = true },
			{ "Ball", V(0.55, 0.08, 0.2), V(0, 0.45, 0), C(90, 190, 90) },
			{ "Ball", V(0.55, 0.08, 0.2), V(0, 0.45, 0), C(90, 190, 90), rot = V(0, 60, 0) },
			{ "Ball", V(0.55, 0.08, 0.2), V(0, 0.45, 0), C(90, 190, 90), rot = V(0, 120, 0) },
			{ "Cylinder", V(0.06, 0.15, 0.06), V(0, 0.53, 0), C(70, 150, 70) },
			{ "Ball", V(0.05, 0.07, 0.03), V(-0.2, 0.18, -0.3), C(255, 230, 120) },
			{ "Ball", V(0.05, 0.07, 0.03), V(0.2, 0.18, -0.3), C(255, 230, 120) },
			{ "Ball", V(0.05, 0.07, 0.03), V(0, 0.3, -0.29), C(255, 230, 120) },
			{ "Ball", V(0.05, 0.07, 0.03), V(-0.2, -0.15, -0.31), C(255, 230, 120) },
			{ "Ball", V(0.05, 0.07, 0.03), V(0.2, -0.15, -0.31), C(255, 230, 120) },
		},
	},

	Donut = {
		Hitbox = V(1.1, 0.45, 1.1),
		Face = { Position = V(0, -0.02, -0.55), Scale = 0.38 },
		Pieces = {
			{ "Cylinder", V(1.1, 0.4, 1.1), V(0, -0.02, 0), C(225, 165, 95), tint = true },
			{ "Cylinder", V(1, 0.12, 1), V(0, 0.2, 0), C(255, 150, 190), tint = true },
			{ "Cylinder", V(0.3, 0.14, 0.3), V(0, 0.21, 0), C(200, 140, 80) },
			table.unpack(SPRINKLES),
		},
	},

	Cupcake = {
		Hitbox = V(0.9, 1, 0.9),
		Face = { Position = V(0, -0.25, -0.4), Scale = 0.38 },
		Pieces = {
			{ "Cylinder", V(0.8, 0.5, 0.8), V(0, -0.25, 0), C(150, 200, 255), tint = true },
			{ "Ball", V(0.95, 0.5, 0.95), V(0, 0.08, 0), C(255, 190, 220), tint = true },
			{ "Ball", V(0.6, 0.4, 0.6), V(0, 0.3, 0), C(255, 190, 220), tint = true },
			{ "Ball", V(0.18, 0.18, 0.18), V(0, 0.52, 0), C(230, 30, 60) },
		},
	},

	Watermelon = {
		Hitbox = V(1.2, 1, 0.8),
		Face = { Position = V(0, -0.2, -0.41), Scale = 0.35 },
		Pieces = {
			{ "Wedge", V(0.8, 1, 0.6), V(0.3, 0, 0), C(255, 90, 100), tint = true, rot = V(0, -90, 0) },
			{ "Wedge", V(0.8, 1, 0.6), V(-0.3, 0, 0), C(255, 90, 100), tint = true, rot = V(0, 90, 0) },
			{ "Block", V(1.2, 0.06, 0.81), V(0, -0.4, 0), C(200, 240, 170) },
			{ "Block", V(1.22, 0.1, 0.82), V(0, -0.47, 0), C(60, 150, 60) },
			{ "Ball", V(0.05, 0.08, 0.03), V(-0.3, -0.3, -0.41), C(30, 20, 20) },
			{ "Ball", V(0.05, 0.08, 0.03), V(0.3, -0.3, -0.41), C(30, 20, 20) },
			{ "Ball", V(0.05, 0.08, 0.03), V(0, 0.15, -0.41), C(30, 20, 20) },
		},
	},

	Sushi = {
		Hitbox = V(1.1, 0.7, 0.6),
		Face = { Position = V(0, -0.12, -0.29), Scale = 0.35 },
		Pieces = {
			{ "Ball", V(1.1, 0.45, 0.6), V(0, -0.1, 0), C(250, 250, 245), tint = true },
			{ "Ball", V(1.2, 0.25, 0.65), V(0, 0.18, 0), C(255, 140, 90), tint = true },
			{ "Block", V(0.04, 0.05, 0.5), V(-0.3, 0.29, 0), C(255, 220, 200), rot = V(0, 0, 20) },
			{ "Block", V(0.04, 0.05, 0.5), V(0, 0.3, 0), C(255, 220, 200), rot = V(0, 0, 20) },
			{ "Block", V(0.04, 0.05, 0.5), V(0.3, 0.29, 0), C(255, 220, 200), rot = V(0, 0, 20) },
		},
	},

	Boba = {
		Hitbox = V(0.8, 1.3, 0.8),
		Face = { Position = V(0, 0.05, -0.4), Scale = 0.4 },
		Pieces = {
			{ "Cylinder", V(0.8, 1, 0.8), V(0, -0.1, 0), C(245, 215, 170), tint = true },
			{ "Ball", V(0.82, 0.3, 0.82), V(0, 0.42, 0), C(255, 255, 255), alpha = 0.3 },
			{ "Cylinder", V(0.1, 0.6, 0.1), V(0.12, 0.75, 0), C(255, 120, 180), rot = V(0, 0, -15) },
			{ "Ball", V(0.15, 0.15, 0.15), V(-0.2, -0.45, -0.35), C(40, 25, 20) },
			{ "Ball", V(0.15, 0.15, 0.15), V(0, -0.48, -0.37), C(40, 25, 20) },
			{ "Ball", V(0.15, 0.15, 0.15), V(0.2, -0.45, -0.35), C(40, 25, 20) },
			{ "Ball", V(0.15, 0.15, 0.15), V(-0.1, -0.35, -0.38), C(40, 25, 20) },
			{ "Ball", V(0.15, 0.15, 0.15), V(0.1, -0.35, -0.38), C(40, 25, 20) },
		},
	},

	MoldyToast = toast(C(110, 120, 70), C(170, 190, 120), {
		{ "Ball", V(0.2, 0.15, 0.04), V(0.25, 0.25, -0.16), C(70, 140, 60) },
		{ "Ball", V(0.15, 0.12, 0.04), V(-0.3, -0.35, -0.16), C(70, 140, 60) },
		{ "Ball", V(0.25, 0.18, 0.04), V(-0.2, 0.3, 0.16), C(70, 140, 60) },
	}),

	Chili = {
		Hitbox = V(0.5, 1.2, 0.5),
		Face = { Position = V(0, 0.05, -0.23), Scale = 0.3 },
		Pieces = {
			{ "Ball", V(0.5, 1, 0.5), V(0, -0.05, 0), C(230, 30, 30), tint = true },
			{ "Ball", V(0.3, 0.4, 0.3), V(0.05, -0.5, 0), C(230, 30, 30), tint = true },
			{ "Ball", V(0.35, 0.12, 0.35), V(0, 0.45, 0), C(60, 140, 50) },
			{ "Cylinder", V(0.12, 0.25, 0.12), V(0, 0.55, 0), C(60, 140, 50) },
		},
	},
}

return SquishyShapes
