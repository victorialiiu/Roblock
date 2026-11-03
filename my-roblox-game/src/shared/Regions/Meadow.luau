return {
	Name = "Meadow",
	Icon = "🌼",
	Color = Color3.fromRGB(120, 210, 95),
	Order = 1,
	Width = 135,
	Luck = 1,
	EvilChance = 0.08,
	Squishies = { "Butter", "Potato", "Toast", "Egg", "Cheese", "Strawberry", "Dumpling", "Donut", "Moldy Toast" },
	Terrain = {
		Material = Enum.Material.Grass,
		HighMaterial = Enum.Material.LeafyGrass,
		Colors = { [Enum.Material.Grass] = Color3.fromRGB(120, 230, 100), [Enum.Material.LeafyGrass] = Color3.fromRGB(80, 205, 120) },
		Height = 18,
		Step = 3,
		Scale = 110,
		-- Little ponds in the low spots
		Water = true,
		-- Pink flower fields
		Patches = { Material = Enum.Material.Ground, Color = Color3.fromRGB(255, 175, 215), Amount = 0.25 },
		Props = { Tree = 0.035, Flower = 0.08, Bush = 0.03, Mushroom = 0.015, Rock = 0.01 },
	},
}
