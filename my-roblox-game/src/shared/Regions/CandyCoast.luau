return {
	Name = "Candy Coast",
	Icon = "🍬",
	Color = Color3.fromRGB(255, 185, 220),
	Order = 3,
	Width = 120,
	Luck = 2,
	Unlock = { Rebirths = 1, Cost = 50000 },
	EvilChance = 0.15,
	Mutation = "Sticky",
	Squishies = { "Strawberry", "Donut", "Cupcake", "Watermelon", "Boba Tea", "Angry Chili" },
	Terrain = {
		Material = Enum.Material.Snow,
		HighMaterial = Enum.Material.Salt,
		Colors = { [Enum.Material.Snow] = Color3.fromRGB(255, 185, 225), [Enum.Material.Salt] = Color3.fromRGB(200, 170, 255) },
		Height = 12,
		Step = 3,
		Scale = 70,
		-- Low spots fill with water
		Water = true,
		Patches = { Material = Enum.Material.Pavement, Color = Color3.fromRGB(150, 230, 255), Amount = 0.2 },
		Props = { Lollipop = 0.03, Gumdrop = 0.04 },
	},
}
